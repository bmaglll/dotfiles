#!/usr/bin/env bash

nrs() {
  cd ~/nixos-config || { echo "Folder not found"; return 1; }

  read -p "Use a custom commit message? (y/n): " yn

  if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
    read -p "Enter commit message: " msg
    git add .
    if git commit -m "$msg"; then
      echo "Committed with custom message."
    else
      echo "No changes to commit."
    fi
  else
    git add .
    if git commit -m "Update NixOS config"; then
      echo "Committed with default message."
    else
      echo "No changes to commit."
    fi
  fi

  git push

  local host
  host=$(hostname)

  if sudo nixos-rebuild switch --flake ~/nixos-config#"$host"; then
    if command -v notify-send >/dev/null; then
      notify-send -i ~/nixos-config/icons/NixOS.svg "NixOS Rebuild" "Switch successful"
    fi
    if command -v mpv >/dev/null && [[ -f ~/nixos-config/sounds/nrs_notification.mp3 ]]; then
      mpv --no-video ~/nixos-config/sounds/nrs_notification.mp3 &
    fi
  else
    if command -v notify-send >/dev/null; then
      notify-send -u critical -i ~/nixos-config/icons/NixOS.svg "NixOS Rebuild" "Switch failed"
    fi
    if command -v mpv >/dev/null && [[ -f ~/nixos-config/sounds/nrs_notification.mp3 ]]; then
      mpv --no-video ~/nixos-config/sounds/nrs_notification.mp3 &
    fi
  fi
}

