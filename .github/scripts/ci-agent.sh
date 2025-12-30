#!/bin/bash
# ci-agent-simple.sh - Minimal working version

set -euo pipefail

# Configuration
SERVER_URL="${LOG_SERVER_URL:-ws://129.154.46.198:8000}"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%s)}"
JOB_NAME="${GITHUB_JOB:-local-job}"
REPO="${GITHUB_REPOSITORY:-unknown/repo}"
BRANCH="${GITHUB_REF_NAME:-main}"
COMMIT="${GITHUB_SHA:-unknown}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[CI-AGENT]${NC} $1"; }
error() { echo -e "${RED}[CI-AGENT]${NC} $1"; }

# Send one log message
send_one_log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Simple JSON without jq dependencies
    local json_payload=$(cat <<EOF
{
  "type": "$type",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "timestamp": "$timestamp",
  "run_id": "$RUN_ID",
  "job": "$JOB_NAME",
  "repository": "$REPO",
  "branch": "$BRANCH",
  "commit": "$COMMIT"
}
EOF
    )
    
    # Send via websocat
    echo "$json_payload" | websocat "$SERVER_URL/ws/$RUN_ID" 2>/dev/null || true
}

main() {
    if [ $# -eq 0 ]; then
        error "Usage: $0 <command>"
        exit 1
    fi
    
    log "Starting CI Agent for run: $RUN_ID"
    log "Command: $*"
    
    # Send start message
    send_one_log "system" "🚀 Starting command: $*"
    
    # Execute command and capture output line by line
    while IFS= read -r line; do
        echo "$line"  # Print to console
        send_one_log "stdout" "$line"
    done < <(eval "$*" 2>&1; echo "EXIT_CODE:$?")
    
    # Note: We handle exit code in the loop above
    log "Command execution completed"
}

# Handle signals
trap 'send_one_log "system" "⚠️ Interrupted"; exit 130' INT TERM

main "$@"
