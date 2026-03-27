#!/usr/bin/env bash
# Focus the correct Claude Code tmux window in the special workspace
SESSION_ID="$1"
hyprctl dispatch togglespecialworkspace magic
tmux select-window -t "Main:claude[$SESSION_ID]"
