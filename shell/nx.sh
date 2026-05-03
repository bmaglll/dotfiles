#!/usr/bin/env bash

# nx: one command for the nixos-config workflow.
#   nx          auto-detect (dirty=push, behind=pull, otherwise build)
#   nx push     commit (prompt) + push + rebuild
#   nx pull     require clean + pull --rebase + rebuild
#   nx build    rebuild only

_nx_repo="$HOME/nixos-config"

_nx_notify() {
  local urgency="$1" msg="$2"
  if command -v notify-send >/dev/null; then
    notify-send -u "$urgency" -i "$_nx_repo/icons/NixOS.svg" "NixOS Rebuild" "$msg"
  fi
  if command -v mpv >/dev/null && [[ -f "$_nx_repo/sounds/nrs_notification.mp3" ]]; then
    mpv --no-video "$_nx_repo/sounds/nrs_notification.mp3" >/dev/null 2>&1 &
  fi
}

_nx_rebuild() {
  local host
  host=$(hostname)
  echo "Rebuilding $host..."
  if sudo nixos-rebuild switch --flake "$_nx_repo#$host"; then
    _nx_notify normal "Switch successful"
    return 0
  else
    _nx_notify critical "Switch failed"
    return 1
  fi
}

_nx_push() {
  cd "$_nx_repo" || { echo "Folder not found"; return 1; }

  if git diff --quiet && git diff --cached --quiet && [[ -z $(git status --porcelain) ]]; then
    echo "No changes to commit."
  else
    read -p "Use a custom commit message? (y/n): " yn
    local msg="Update NixOS config"
    if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
      read -p "Enter commit message: " msg
    fi
    git add .
    git commit -m "$msg" || echo "Nothing to commit."
  fi

  git push
  _nx_rebuild
}

_nx_pull() {
  cd "$_nx_repo" || { echo "Folder not found"; return 1; }

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Uncommitted changes. Run 'nx push' or stash first."
    git status --short
    return 1
  fi

  echo "Pulling from origin..."
  if ! git pull --rebase --autostash; then
    echo "Pull failed. Resolve and retry."
    return 1
  fi

  _nx_rebuild
}

_nx_build() {
  cd "$_nx_repo" || { echo "Folder not found"; return 1; }
  _nx_rebuild
}

_nx_auto() {
  cd "$_nx_repo" || { echo "Folder not found"; return 1; }

  # Dirty? -> push flow
  if ! git diff --quiet || ! git diff --cached --quiet || [[ -n $(git status --porcelain) ]]; then
    echo "[nx] Dirty tree -> push flow"
    _nx_push
    return $?
  fi

  # Clean. Check whether remote is ahead.
  git fetch --quiet
  local local_ref upstream_ref
  local_ref=$(git rev-parse @ 2>/dev/null)
  upstream_ref=$(git rev-parse @{u} 2>/dev/null)

  if [[ "$local_ref" != "$upstream_ref" ]]; then
    local base
    base=$(git merge-base @ @{u} 2>/dev/null)
    if [[ "$local_ref" == "$base" ]]; then
      echo "[nx] Behind upstream -> pull flow"
      _nx_pull
      return $?
    fi
    if [[ "$upstream_ref" == "$base" ]]; then
      echo "[nx] Ahead of upstream -> pushing then rebuild"
      git push && _nx_rebuild
      return $?
    fi
    echo "[nx] Diverged from upstream. Resolve manually."
    return 1
  fi

  echo "[nx] Clean and in sync -> build only"
  _nx_build
}

nx() {
  case "${1:-}" in
    push)  _nx_push ;;
    pull)  _nx_pull ;;
    build) _nx_build ;;
    "")    _nx_auto ;;
    *)     echo "usage: nx [push|pull|build]"; return 2 ;;
  esac
}
