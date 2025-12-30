#!/bin/bash
# ci-agent.sh - Fixed version with proper error handling

set -euo pipefail

# Configuration
SERVER_URL="${LOG_SERVER_URL:-ws://129.154.46.198:8000}"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%s)}"
JOB_NAME="${GITHUB_JOB:-local-job}"
REPO="${GITHUB_REPOSITORY:-unknown/repo}"
BRANCH="${GITHUB_REF_NAME:-main}"
COMMIT="${GITHUB_SHA:-unknown}"
TOKEN="${AGENT_TOKEN:-}"
DEBUG="${DEBUG:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log() {
    echo -e "${GREEN}[CI-AGENT]${NC} $1"
}

error() {
    echo -e "${RED}[CI-AGENT]${NC} $1"
}

debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
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

# Test WebSocket connection
test_websocket() {
    debug "Testing connection to $SERVER_URL/ws/$RUN_ID"
    if timeout 5 websocat -t "$SERVER_URL/ws/$RUN_ID" <<< '{"test":"ping"}' 2>/dev/null; then
        debug "WebSocket connection test: SUCCESS"
        return 0
    else
        debug "WebSocket connection test: FAILED"
        return 1
    fi
}

# Send log to WebSocket server - SIMPLIFIED VERSION
send_log_simple() {
    local type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Simple JSON creation without jq if it fails
    local payload
    payload=$(cat <<EOF
{
    "type": "$type",
    "message": "$(echo "$message" | sed 's/"/\\"/g; s/\$/\\\$/g')",
    "timestamp": "$timestamp",
    "run_id": "$RUN_ID",
    "job": "$JOB_NAME",
    "repository": "$REPO",
    "branch": "$BRANCH",
    "commit": "$COMMIT"
}
EOF
    )
    
    # Try to send with timeout, but don't break if it fails
    echo "$payload" | timeout 2 websocat "$SERVER_URL/ws/$RUN_ID" 2>/dev/null || true
}

# Send log with jq if available
send_log() {
    local type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Try using jq first
    if command -v jq &> /dev/null; then
        local payload
        if payload=$(jq -n \
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
            }' 2>/dev/null); then
            echo "$payload" | timeout 2 websocat "$SERVER_URL/ws/$RUN_ID" 2>/dev/null || {
                debug "Failed to send log via jq method"
                send_log_simple "$type" "$message"
            }
        else
            send_log_simple "$type" "$message"
        fi
    else
        send_log_simple "$type" "$message"
    fi
}

# Execute command with real-time logging - SIMPLIFIED
execute_with_logs() {
    local cmd="$1"
    local line
    local exit_code=0
    
    log "Starting command execution"
    
    # Send initial logs directly (not in background)
    send_log "system" "🚀 Starting GitHub Action: $JOB_NAME"
    send_log "system" "📝 Repository: $REPO"
    send_log "system" "🌿 Branch: $BRANCH"
    send_log "system" "🔧 Command: $cmd"
    send_log "system" "⏰ Started at: $(date)"
    
    # Create temp file for output instead of named pipe
    TEMP_FILE=$(mktemp)
    
    # Execute command, capture output to temp file
    {
        eval "$cmd" 2>&1
        exit_code=$?
    } | tee "$TEMP_FILE"
    
    # Process the output file and send logs
    while IFS= read -r line || [ -n "$line" ]; do
        send_log "stdout" "$line"
    done < "$TEMP_FILE"
    
    # Cleanup
    rm -f "$TEMP_FILE"
    
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

# Alternative: Execute with line-by-line logging
execute_line_by_line() {
    local cmd="$1"
    local exit_code=0
    
    log "Starting line-by-line execution"
    
    # Send initial logs
    send_log "system" "🚀 Starting: $cmd"
    
    # Create a FIFO for real-time processing
    FIFO=$(mktemp -u)
    mkfifo "$FIFO"
    
    # Execute command, redirect to FIFO
    {
        eval "$cmd" 2>&1
        echo $? > /tmp/exit_code.$$
    } > "$FIFO" &
    
    CMD_PID=$!
    
    # Read from FIFO and send logs
    while IFS= read -r line; do
        echo "$line"  # Print to console
        send_log "stdout" "$line"
    done < "$FIFO"
    
    # Wait for command and get exit code
    wait $CMD_PID
    exit_code=$(cat /tmp/exit_code.$$)
    rm -f /tmp/exit_code.$$ "$FIFO"
    
    # Send completion
    send_log "system" "🏁 Exit code: $exit_code"
    
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
    
    # Test connection first
    if ! test_websocket; then
        error "Warning: Cannot connect to log server. Running command without streaming."
        log "Server may be down or unreachable. Command will still execute."
    fi
    
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
