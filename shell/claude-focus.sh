#!/usr/bin/env bash
# Focus the correct Claude Code tmux window in the special workspace
SESSION_ID="$1"
# Only open special workspace if not already visible
VISIBLE=$(hyprctl monitors -j | jq -r '.[] | select(.specialWorkspace.name == "special:magic") | .name')
# Hyprland's Lua config mode wraps `hyprctl dispatch` args as Lua, so the
# old `togglespecialworkspace magic` syntax now fails to parse. Use the
# hl.dsp namespace call form instead.
[ -z "$VISIBLE" ] && hyprctl dispatch 'hl.dsp.workspace.toggle_special("magic")'
tmux select-window -t "Main:claude[$SESSION_ID]"
