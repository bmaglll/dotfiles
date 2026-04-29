#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
EVENT="${1:-}"
SHORT_ID=${SESSION_ID: -6}
STATE_FILE="/tmp/agent-buddy-${SHORT_ID}"

[ -n "$SHORT_ID" ] || exit 0

case "$EVENT" in
    "session_start")     echo "idle" > "$STATE_FILE" ;;
    "user_prompt_submit") echo "working" > "$STATE_FILE" ;;
    "pre_tool_use")      echo "working" > "$STATE_FILE" ;;
    "post_tool_use")     echo "working" > "$STATE_FILE" ;;
    "permission_request") echo "waiting" > "$STATE_FILE" ;;
    "notification")      echo "waiting" > "$STATE_FILE" ;;
    "stop")              echo "done" > "$STATE_FILE"
                         (sleep 600 && rm -f "$STATE_FILE") &
                         disown ;;
esac
