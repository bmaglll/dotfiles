#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
EVENT="${1:-}"
STATE_FILE="/tmp/agent-buddy-${SESSION_ID}"

case "$EVENT" in
    "session_start")  # Clean up stale files from before boot
                      find /tmp -maxdepth 1 -name 'agent-buddy-*' ! -newer /proc/1/cmdline -delete 2>/dev/null
                      echo "idle" > "$STATE_FILE" ;;
    "tool_start")     echo "working" > "$STATE_FILE" ;;
    "tool_end")       echo "working" > "$STATE_FILE" ;;
    "ask_user")       echo "waiting" > "$STATE_FILE" ;;
    "stop")           echo "done" > "$STATE_FILE" ;;
    "notification")   echo "waiting" > "$STATE_FILE" ;;
esac
