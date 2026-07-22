#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
# Icon-theme NAME, not a file path. notify-send maps a file path to the
# `image-path` hint, which crashes swaync 0.12.6 (double-free). A name goes in
# the app_icon field instead. Installed via xdg.dataFile in home/desktop.nix.
ICON="claude"
(
  ACTION=$(notify-send -a "Claude Code" -i "$ICON" -A "open=Open" "Waiting on You" "Claude [$SESSION_ID] needs your input")
  [ "$ACTION" = "open" ] && bash ~/nixos-config/shell/claude-focus.sh "$SESSION_ID"
) &>/dev/null &
disown
