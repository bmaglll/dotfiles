#!/bin/bash

echo "Updating system..."
sudo pacman -Syu

echo "Installing pacman packages..."
xargs -a pkglist.txt sudo pacman -S --needed --noconfirm

echo "Installing AUR packages with yay..."
if command -v yay &> /dev/null; then
  xargs -a aurlist.txt yay -S --needed --noconfirm
else
  echo "Yay not found. Please install yay manually."
fi

echo "Installing Flatpak apps..."
if command -v flatpak &> /dev/null; then
  xargs -a flatpaklist.txt -I{} flatpak install -y flathub {}
else
  echo "Flatpak not found. Please install flatpak manually."
fi

