# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS configuration using Flakes and Home-Manager for a Framework 13 laptop (AMD 7040) running Hyprland on NixOS unstable.

## Build Commands

```bash
# Rebuild system (commits, pushes, then rebuilds)
nrs

# Manual rebuild
sudo nixos-rebuild switch --flake ~/nixos-config

# Test build without switching
sudo nixos-rebuild build --flake ~/nixos-config

# Update flake inputs
nix flake update

# Reload Quickshell bar (after editing QML files)
quickshell -r
```

## Architecture

### Entry Points
- `flake.nix` - Flake definition with inputs (nixpkgs-unstable, home-manager, nixos-hardware)
- `configuration.nix` - System-wide NixOS configuration
- `home.nix` - User configuration via Home-Manager
- `hardware-configuration.nix` - Auto-generated hardware config (do not edit manually)

### Configuration Pattern
Home-Manager is integrated within NixOS configuration (`useGlobalPkgs = true`). User "bmag" config is imported from `home.nix`.

### Directory Structure
- `hyprland/` - Hyprland window manager configs imported as Nix attribute sets
  - `hyprland-conf.nix` - Keybindings, window rules, settings (returns a Nix attribute set)
  - `hyprlock.nix` - Lock screen configuration
- `quickshell/` - QML-based status bar (Wayland panel)
  - `shell.qml` - Root application, creates one Bar per screen via Variants
  - `modules/` - Reusable QML components (Clock, Battery, Workspaces, Tray, etc.)
- `nvim/` - Neovim configuration (`init.lua`)
- `shell/` - Shell scripts (includes `nrs.sh` rebuild script)
- `wallpapers/` - Background images

### Technology Stack
- **Window Manager**: Hyprland (Wayland)
- **Status Bar**: Quickshell (QML)
- **Terminal**: Ghostty (primary), Kitty (backup)
- **Editor**: Neovim
- **Multiplexer**: Tmux
- **Login Manager**: greetd with tuigreet
- **Audio**: Pipewire

## Key Patterns

1. **Modular imports**: Hyprland configs are separate Nix files imported as attribute sets via `import ./hyprland/hyprland-conf.nix`
2. **XDG config files**: Dotfiles symlinked via Home-Manager's `xdg.configFile` (e.g., quickshell, nvim)
3. **Git-driven deployment**: The `nrs` function commits, pushes, then rebuilds
4. **Single machine config**: Only one host "nixos" defined

## Quickshell Development

Quickshell QML files are symlinked to `~/.config/quickshell/` via `xdg.configFile`. Changes to QML files in this repo take effect immediately without rebuild - just reload quickshell with `quickshell -r` or restart it.

Bar layout: Left (Workspaces) | Center (MprisMini, ActiveWindow) | Right (Tray, StatusCluster with Volume/Battery/Clock)

## Notes

- Uses nixos-unstable channel
- Framework 13 AMD 7040 hardware support via `nixos-hardware` module
- Fingerprint authentication enabled for login, sudo, and hyprlock
- State versions: NixOS 25.05, Home-Manager 25.11
