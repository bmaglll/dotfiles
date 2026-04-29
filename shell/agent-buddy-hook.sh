#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
EVENT="$1"
STATE_FILE="/tmp/agent-buddy-${SESSION_ID}"

case "$EVENT" in
    "session_start")  echo "idle" > "$STATE_FILE" ;;
    "tool_start")     echo "working" > "$STATE_FILE" ;;
    "tool_end")       echo "working" > "$STATE_FILE" ;;
    "ask_user")       echo "waiting" > "$STATE_FILE" ;;
    "stop")           echo "done" > "$STATE_FILE"
                      (sleep 600 && rm -f "$STATE_FILE") &
                      disown ;;
    "notification")   echo "waiting" > "$STATE_FILE" ;;
esac
