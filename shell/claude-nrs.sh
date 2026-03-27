#!/usr/bin/env bash
# claude-nrs: Non-interactive NixOS rebuild for Claude Code
# Usage: claude-nrs "commit message" [files...]
# If no files specified, stages all changes.

set -euo pipefail

cd ~/nixos-config || { echo "ERROR: ~/nixos-config not found"; exit 1; }

MSG="${1:?Usage: claude-nrs \"commit message\" [files...]}"
shift

# Stage files
if [ $# -gt 0 ]; then
  git add "$@"
else
  git add -A
fi

# Commit (skip if nothing to commit)
if ! git commit -m "$MSG"; then
  echo "Nothing new to commit"
fi

# Push if there are unpushed commits
if [ -n "$(git log @{u}..HEAD 2>/dev/null)" ]; then
  git push
else
  echo "Nothing to push"
fi

# Create a new tmux window for the rebuild and capture its index
WIN=$(tmux new-window -t Main -P -F '#{window_index}')

# Send rebuild command — auto-close window on success, stay open on failure
tmux send-keys -t "Main:${WIN}" 'if pkexec nixos-rebuild switch --flake ~/nixos-config#lap-nix; then notify-send -i ~/nixos-config/icons/NixOS.svg "NixOS Rebuild" "Switch successful"; mpv --no-video ~/nixos-config/sounds/nrs_tone.mp3 &; exit; else notify-send -u critical -i ~/nixos-config/icons/NixOS.svg "NixOS Rebuild" "Switch failed"; mpv --no-video ~/nixos-config/sounds/nrs_tone.mp3 &; fi' Enter
echo "Rebuild sent to Main:${WIN} — approve polkit popup"
