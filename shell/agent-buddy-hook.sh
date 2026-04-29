#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
EVENT="${1:-}"
STATE_FILE="/tmp/agent-buddy-${SESSION_ID}"

case "$EVENT" in
    "session_start")  # Clean up stale files from before boot or with "done" state
                      find /tmp -maxdepth 1 -name 'agent-buddy-*' ! -newer /proc/1/cmdline -delete 2>/dev/null
                      for f in /tmp/agent-buddy-*; do
                          [ -f "$f" ] && [ "$(cat "$f")" = "done" ] && rm -f "$f"
                      done
                      echo "idle" > "$STATE_FILE" ;;
    "tool_start")     echo "working" > "$STATE_FILE" ;;
    "tool_end")       echo "working" > "$STATE_FILE" ;;
    "ask_user")       echo "waiting" > "$STATE_FILE" ;;
    "stop")           echo "done" > "$STATE_FILE"
                      (sleep 600 && rm -f "$STATE_FILE") &>/dev/null &
                      disown ;;
    "notification")   echo "waiting" > "$STATE_FILE" ;;
esac
