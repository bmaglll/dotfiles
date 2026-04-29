#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
SHORT_ID=${SESSION_ID: -6}
ICON="/home/bmag/nixos-config/icons/NixOS.svg"

[ -n "$SHORT_ID" ] || exit 0

(
  ACTION=$(notify-send -a "Codex" -i "$ICON" -A "open=Open" "Task Complete" "Codex [$SHORT_ID] finished working")
  [ "$ACTION" = "open" ] && bash ~/nixos-config/shell/codex-focus.sh "$SESSION_ID"
) &>/dev/null &
disown
