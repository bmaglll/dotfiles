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
  sudo nixos-rebuild switch --flake ~/nixos-config
}

