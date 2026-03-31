#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
ICON="/home/bmag/nixos-config/icons/claude.svg"
(
  ACTION=$(notify-send -a "Claude Code" -i "$ICON" -A "open=Open" "Waiting on You" "Claude [$SESSION_ID] needs your input")
  [ "$ACTION" = "open" ] && bash ~/nixos-config/shell/claude-focus.sh "$SESSION_ID"
) &>/dev/null &
disown
