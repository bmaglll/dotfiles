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

# Commit (exit early if nothing to commit)
if ! git commit -m "$MSG"; then
  echo "Nothing to commit"
  exit 0
fi

# Push
git push

# Create a new tmux window for the rebuild and capture its index
WIN=$(tmux new-window -t Main -P -F '#{window_index}')

# Send rebuild command — auto-close window on success, stay open on failure
tmux send-keys -t "Main:${WIN}" 'pkexec nixos-rebuild switch --flake ~/nixos-config && exit' Enter
echo "Rebuild sent to Main:${WIN} — approve polkit popup"
