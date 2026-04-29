#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-}"

if [ -z "$INPUT" ]; then
  INPUT=$(cat)
fi

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
SHORT_ID=${SESSION_ID: -6}
TITLE=$(printf '%s' "$INPUT" | jq -r '.title // "Task Complete"')
MESSAGE=$(printf '%s' "$INPUT" | jq -r '.message // .body // "finished working"')
ICON="/home/bmag/nixos-config/icons/NixOS.svg"

[ -n "$SHORT_ID" ] || exit 0

printf '%s' "$INPUT" | bash /home/bmag/nixos-config/shell/codex-agent-buddy-hook.sh stop

(
  ACTION=$(notify-send -a "Codex" -i "$ICON" -A "open=Open" "$TITLE" "Codex [$SHORT_ID] $MESSAGE")
  [ "$ACTION" = "open" ] && bash ~/nixos-config/shell/codex-focus.sh "$SESSION_ID"
) &>/dev/null &
disown
