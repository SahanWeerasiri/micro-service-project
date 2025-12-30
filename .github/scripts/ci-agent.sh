#!/bin/bash
# ci-agent.sh - Real-time Log Streaming Agent for GitHub Actions
# Usage: ./ci-agent.sh "npm test"

set -euo pipefail

# Configuration
SERVER_URL="${LOG_SERVER_URL:-ws://129.154.46.198:8000}"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%s)}"
JOB_NAME="${GITHUB_JOB:-local-job}"
REPO="${GITHUB_REPOSITORY:-unknown/repo}"
BRANCH="${GITHUB_REF_NAME:-main}"
COMMIT="${GITHUB_SHA:-unknown}"
TOKEN="${AGENT_TOKEN:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function for local output
log() {
    echo -e "${GREEN}[CI-AGENT]${NC} $1"
}

error() {
    echo -e "${RED}[CI-AGENT]${NC} $1"
}

# Check dependencies
check_deps() {
    local missing=()
    
    if ! command -v websocat &> /dev/null; then
        missing+=("websocat")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        log "Install with: sudo apt-get install ${missing[*]}"
        return 1
    fi
    return 0
}

# Send log to WebSocket server
send_log() {
    local type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Escape JSON special characters - FIXED
    message=$(echo "$message" | jq -R -s . | sed 's/^"//;s/"$//')
    
    # Create JSON payload
    local payload
    payload=$(jq -n \
        --arg type "$type" \
        --arg msg "$message" \
        --arg time "$timestamp" \
        --arg run_id "$RUN_ID" \
        --arg job "$JOB_NAME" \
        --arg repo "$REPO" \
        --arg branch "$BRANCH" \
        --arg commit "$COMMIT" \
        --arg token "$TOKEN" \
        '{
            type: $type,
            message: $msg,
            timestamp: $time,
            run_id: $run_id,
            job: $job,
            repository: $repo,
            branch: $branch,
            commit: $commit,
            token: $token
        }')
    
    # Try to send via websocat with timeout - FIXED
    echo "$payload" | timeout 5 websocat "$SERVER_URL/ws/$RUN_ID" 2>/dev/null || {
        # Log connection failure locally
        echo "[CI-AGENT DEBUG] Failed to send log to $SERVER_URL/ws/$RUN_ID" >&2
    }
}

# Execute command with real-time logging
execute_with_logs() {
    local cmd="$1"
    local line
    local exit_code=0
    
    log "Starting command execution"
    send_log "system" "🚀 Starting GitHub Action: $JOB_NAME"
    send_log "system" "📝 Repository: $REPO"
    send_log "system" "🌿 Branch: $BRANCH"
    send_log "system" "🔧 Command: $cmd"
    send_log "system" "⏰ Started at: $(date)"
    
    # Create a named pipe for non-blocking output
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    
    # Start WebSocket writer in background
    (
        while read -r line; do
            send_log "stdout" "$line"
        done < "$PIPE"
    ) &
    WS_PID=$!
    
    # Execute command, capture both stdout and stderr
    # Using tee to send to both console and our pipe
    {
        eval "$cmd" 2>&1 | tee "$PIPE"
        exit_code=${PIPESTATUS[0]}
    }
    
    # Cleanup
    rm -f "$PIPE"
    kill "$WS_PID" 2>/dev/null || true
    
    # Send completion status
    if [ $exit_code -eq 0 ]; then
        send_log "system" "✅ Command completed successfully"
        send_log "system" "🏁 Exit code: 0"
        log "Command completed successfully"
    else
        send_log "system" "❌ Command failed with exit code: $exit_code"
        send_log "system" "🏁 Exit code: $exit_code"
        error "Command failed with exit code: $exit_code"
    fi
    
    send_log "system" "⏰ Finished at: $(date)"
    
    return $exit_code
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        error "Usage: $0 <command>"
        error "Example: $0 'npm test'"
        error "Example: $0 'echo Hello && sleep 2 && echo World'"
        exit 1
    fi
    
    log "Initializing CI Agent..."
    log "Run ID: $RUN_ID"
    log "Job: $JOB_NAME"
    log "Server: $SERVER_URL"
    log "Command: $*"
    
    # Check dependencies
    if ! check_deps; then
        error "Dependency check failed. Falling back to direct execution."
        eval "$*"
        exit $?
    fi
    
    # Execute command with logging
    if ! execute_with_logs "$*"; then
        exit $?
    fi
}

# Handle signals
trap 'error "Interrupted by user"; send_log "system" "⚠️ Process interrupted by user"; exit 130' INT TERM

# Run main function
main "$@"
