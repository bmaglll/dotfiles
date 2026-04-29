#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="${1:-}"
SHORT_ID=${SESSION_ID: -6}

[ -n "$SHORT_ID" ] || exit 0

VISIBLE=$(hyprctl monitors -j | jq -r '.[] | select(.specialWorkspace.name == "special:magic") | .name')
[ -z "$VISIBLE" ] && hyprctl dispatch togglespecialworkspace magic
tmux select-window -t "Main:codex[$SHORT_ID]"
