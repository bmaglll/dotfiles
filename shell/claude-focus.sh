#!/usr/bin/env bash
# Focus the correct Claude Code tmux window in the special workspace
SESSION_ID="$1"
# Only open special workspace if not already visible
VISIBLE=$(hyprctl monitors -j | jq -r '.[] | select(.specialWorkspace.name == "special:magic") | .name')
[ -z "$VISIBLE" ] && hyprctl dispatch togglespecialworkspace magic
tmux select-window -t "Main:claude[$SESSION_ID]"
