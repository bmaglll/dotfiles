#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
ICON="/home/bmag/nixos-config/icons/claude.svg"
notify-send -a "Claude Code" -i "$ICON" "Task Complete" "Claude [$SESSION_ID] finished working"
