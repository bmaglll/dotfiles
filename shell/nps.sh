#!/usr/bin/env bash

# nps: pull latest config from origin and rebuild this machine
# Aborts if there are uncommitted local changes (commit them with `nrs` first).
nps() {
  cd ~/nixos-config || { echo "Folder not found"; return 1; }

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Uncommitted changes detected. Commit them first (use 'nrs') or stash."
    git status --short
    return 1
  fi

  echo "Pulling from origin..."
  if ! git pull --rebase --autostash; then
    echo "Pull failed. Resolve and retry."
    return 1
  fi

  local host
  host=$(hostname)
  echo "Rebuilding $host..."
  sudo nixos-rebuild switch --flake ~/nixos-config#"$host"
}
