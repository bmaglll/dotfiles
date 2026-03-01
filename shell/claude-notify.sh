#!/usr/bin/env bash
# Read JSON from stdin and extract session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
ICON="/home/bmag/nixos-config/icons/claude.svg"

notify-send -a "Claude Code" -i "$ICON" "Claude [$SESSION_ID]" "Needs your attention"
