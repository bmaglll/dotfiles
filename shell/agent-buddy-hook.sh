#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
EVENT="${1:-}"
STATE_FILE="/tmp/agent-buddy-${SESSION_ID}"

PID_FILE="/tmp/agent-buddy-${SESSION_ID}.pid"

cancel_cleanup() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
}

case "$EVENT" in
    "session_start")  # Clean up stale files from before boot
                      find /tmp -maxdepth 1 -name 'agent-buddy-*' ! -newer /proc/1/cmdline -delete 2>/dev/null
                      cancel_cleanup
                      echo "idle" > "$STATE_FILE" ;;
    "tool_start")     cancel_cleanup
                      echo "working" > "$STATE_FILE" ;;
    "tool_end")       echo "working" > "$STATE_FILE" ;;
    "ask_user")       echo "waiting" > "$STATE_FILE" ;;
    "stop")           echo "done" > "$STATE_FILE"
                      cancel_cleanup
                      (sleep 300 && rm -f "$STATE_FILE" "$PID_FILE") &>/dev/null &
                      echo $! > "$PID_FILE"
                      disown ;;
    "notification")   echo "waiting" > "$STATE_FILE" ;;
esac
