#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
ICON="/home/bmag/nixos-config/icons/claude.svg"
notify-send -a "Claude Code" -i "$ICON" -t 30000 "Waiting on You" "Claude [$SESSION_ID] needs your input"
