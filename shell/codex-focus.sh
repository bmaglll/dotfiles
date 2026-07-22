#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="${1:-}"
SHORT_ID=${SESSION_ID: -6}

[ -n "$SHORT_ID" ] || exit 0

VISIBLE=$(hyprctl monitors -j | jq -r '.[] | select(.specialWorkspace.name == "special:magic") | .name')
# Hyprland's Lua config mode wraps `hyprctl dispatch` args as Lua, so the
# old `togglespecialworkspace magic` syntax now fails to parse. Use the
# hl.dsp namespace call form instead.
[ -z "$VISIBLE" ] && hyprctl dispatch 'hl.dsp.workspace.toggle_special("magic")'
tmux select-window -t "Main:codex[$SHORT_ID]"
