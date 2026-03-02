# System Guide

> Everything an agent (AI or human) needs to understand and work on this NixOS system.

---

## 1. Philosophy & Mantra

**Simplistic. Modular. KISS. Replicatable.**

This config is designed around separation of concerns:
- **One flake, multiple machines** — the same repo will drive a Framework 13 laptop (current) and a Windows 11 desktop (future NixOS conversion).
- **Hardware-specific files are isolated** (e.g., `laptop_gpu.nix`) so adding a second machine means adding one hardware file and one `nixosConfigurations` entry in `flake.nix` — nothing else changes.
- **Minimal abstraction** — no custom lib functions, no deep module nesting. Every config file is readable on its own.

---

## 2. Technology Stack

| Layer | Tool | Notes |
|---|---|---|
| OS | NixOS unstable + Flakes | Rolling release, declarative |
| User config | Home-Manager | Integrated into NixOS module (not standalone) |
| Compositor | Hyprland (Wayland) | Tiling, animations, special workspaces |
| Wallpaper | hyprpaper | Managed via Home-Manager `services.hyprpaper` |
| Lock screen | hyprlock | Fingerprint + password, transparent input field |
| Idle daemon | hypridle | Locks after 5 min inactivity |
| Color temp | hyprsunset | Manual invocation |
| Status bar | Quickshell (QML) | Wayland panel, one bar per screen |
| Notifications | SwayNC | Desktop notification center |
| Terminal | Ghostty (primary), Kitty (backup) | Ghostty auto-attaches to tmux |
| Multiplexer | tmux | vi keys, `Space` prefix, base index 1 |
| Editor | Neovim | Config in `nvim/init.lua` |
| Audio | PipeWire | Replaces PulseAudio |
| Login | greetd + tuigreet | TUI login with fingerprint support |
| Launcher | wofi | `Super+Space` |
| File manager | Nautilus | `Super+E` |
| Clipboard | clipse | `Super+V` opens Ghostty popup |
| Screenshots | hyprshot | `Super+Shift+S` region to clipboard |

---

## 3. Directory Structure

```
~/nixos-config/
├── flake.nix                  # Flake definition — inputs + per-machine outputs
├── flake.lock                 # Pinned input versions
├── configuration.nix          # System-level NixOS config (services, boot, users)
├── hardware-configuration.nix # Auto-generated hardware scan (DO NOT EDIT)
├── laptop_gpu.nix             # AMD Phoenix APU — hardware acceleration & VA-API
├── home.nix                   # User-level config (packages, dotfiles, HM services)
├── CLAUDE.md                  # Instructions for Claude Code
├── system_guide.md            # This file
├── linux_plans.md             # Personal planning notes
├── troubleshooting_system.md  # Troubleshooting log
│
├── hyprland/
│   ├── hyprland-conf.nix      # Keybindings, window rules, exec-once, settings
│   ├── hyprland-conf.nix.bak  # Backup of previous config
│   └── hyprlock.nix           # Lock screen layout & auth config
│
├── quickshell/
│   ├── shell.qml              # Root — creates one Bar per screen via Variants
│   └── modules/
│       ├── Bar.qml            # Main bar layout (Left | Center | Right)
│       ├── Workspaces.qml     # Hyprland workspace indicators
│       ├── ActiveWindow.qml   # Focused window title
│       ├── MprisMini.qml      # Now-playing media widget
│       ├── MediaCenter.qml    # Extended media controls
│       ├── Tray.qml           # System tray icons
│       ├── StatusCluster.qml  # Clickable container for Volume/Battery/Clock
│       ├── VolumeDisplay.qml  # Volume icon + percentage
│       ├── Battery.qml        # Battery icon + percentage + charging state
│       ├── Clock.qml          # Time display (compact/expanded)
│       └── SettingsDropdown.qml # Popup on StatusCluster click
│
├── nvim/
│   └── init.lua               # Neovim configuration
│
├── shell/
│   ├── nrs.sh                 # Interactive rebuild (prompts for commit msg, uses sudo)
│   ├── claude-nrs.sh          # Non-interactive rebuild for Claude Code (uses pkexec)
│   ├── claude-notify.sh       # SwayNC notification when Claude needs attention
│   └── claude-tmux-rename.sh  # Renames tmux window to claude[SESSION_ID]
│
├── icons/
│   ├── claude.svg             # Claude notification icon
│   └── spotify-linux-32.png   # Spotify tray icon override
│
├── wallpapers/                # Background images (ngc2899.png, hptau.jpg, etc.)
│
└── old-config/                # Pre-NixOS configs (Arch pkglists, old waybar/kitty/hypr)
```

---

## 4. NixOS + Flakes + Home-Manager Architecture

### flake.nix

Three inputs:
1. **nixpkgs** — `nixos-unstable` branch (rolling)
2. **home-manager** — follows the same nixpkgs (avoids version skew)
3. **nixos-hardware** — Framework 13 7040 AMD module

One output: `nixosConfigurations.nixos` which loads `configuration.nix` and the Home-Manager NixOS module.

**To add a second machine** (e.g., a desktop), add another entry:
```nix
nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    ./configuration-desktop.nix   # or share configuration.nix with conditionals
    inputs.home-manager.nixosModules.default
  ];
};
```

### configuration.nix (system-level)

Imports:
- `hardware-configuration.nix` — auto-generated, defines filesystems & kernel modules
- `laptop_gpu.nix` — AMD APU graphics packages and VA-API env vars
- `nixos-hardware` Framework module — firmware, power management, sensor drivers
- Home-Manager NixOS module (also imported via flake, belt-and-suspenders)

Key responsibilities:
- Boot (systemd-boot, latest kernel)
- Networking (NetworkManager)
- Services (greetd, PipeWire, fprintd, upower, printing, power-profiles-daemon)
- PAM (fingerprint auth for login, sudo, greetd, hyprlock)
- System packages (vim, git, hyprlock, hypridle, polkit_gnome)
- Fonts (JetBrainsMono Nerd Font, Noto, Roboto, Font Awesome)
- Hyprland enable + Wayland session vars
- Home-Manager integration with `useGlobalPkgs = true` and `useUserPackages = true`

### laptop_gpu.nix (hardware separation)

Isolated AMD Phoenix APU config:
- Enables `hardware.graphics` with VA-API packages (libva, vdpau)
- Sets `LIBVA_DRIVER_NAME=radeonsi` for Firefox hardware video decode

This file is the **template for hardware separation**. A desktop with an NVIDIA GPU would have `desktop_gpu.nix` with different drivers, and `configuration.nix` would import the appropriate one.

### home.nix (user-level)

User `bmag`'s config. Responsibilities:
- **Packages** — all user-facing apps (Ghostty, Spotify, Discord, quickshell, claude-code, etc.)
- **Shell** — Bash with custom PS1, sources `nrs.sh` for the `nrs` rebuild function
- **tmux** — vi mode, mouse, Space prefix, purple status bar, base index 1
- **Ghostty** — auto-attaches to tmux `Main` session on launch
- **Neovim** — enabled with vi/vim aliases, config symlinked from `nvim/`
- **Hyprland settings** — imported from `hyprland/hyprland-conf.nix` (function pattern)
- **hyprlock** — imported from `hyprland/hyprlock.nix`
- **hypridle** — locks after 300s inactivity
- **hyprpaper** — wallpaper for `eDP-1` monitor
- **SwayNC** — notification daemon config
- **Quickshell** — QML files symlinked via `xdg.configFile`

### Home-Manager Integration

```nix
# In configuration.nix:
home-manager = {
  useGlobalPkgs = true;    # HM uses the same nixpkgs as the system
  useUserPackages = true;   # user packages go to /etc/profiles/per-user/
  extraSpecialArgs = { inherit inputs; };
  users."bmag" = import ./home.nix;
};
```

This means Home-Manager is **not** run standalone — it's part of `nixos-rebuild switch`. One command rebuilds everything.

---

## 5. Hyprland Ecosystem

### hyprland-conf.nix

This file is a **Nix function** `{ pkgs }: { ... }` — it receives `pkgs` so it can reference Nix store paths (e.g., polkit agent). It returns a plain attribute set that becomes `wayland.windowManager.hyprland.settings`.

Called in `home.nix` as:
```nix
settings = import ./hyprland/hyprland-conf.nix { inherit pkgs; };
```

### Key Keybindings

| Binding | Action |
|---|---|
| `Super+Return` | New Ghostty terminal (new tmux session) |
| `Super+W` | Kill active window |
| `Super+Space` | App launcher (wofi) |
| `Super+E` | File manager (Nautilus) |
| `Super+F` | Toggle fullscreen |
| `Super+Z` | Toggle floating |
| `Super+L` | Lock screen (hyprlock) |
| `Super+grave` | Toggle special workspace "magic" |
| `Super+Shift+grave` | Move window to special workspace |
| `Super+V` | Clipboard manager (clipse in Ghostty popup) |
| `Super+Shift+S` | Screenshot region to clipboard |
| `Super+Q` | Move window to next empty workspace |
| `Super+Tab` | Cycle to next workspace |
| `Super+1-9` | Switch to workspace 1-9 |
| `Super+Shift+1-9` | Move window to workspace 1-9 |
| `XF86Audio*` | Volume up/down/mute (wpctl) |
| `XF86MonBrightness*` | Brightness up/down (brightnessctl) |

### exec-once Startup Chain

Order matters — these launch once at Hyprland start:
1. `swaync` — notification daemon (must be up before anything sends notifications)
2. `quickshell` — status bar
3. `nm-applet --indicator` — NetworkManager tray icon
4. `clipse -listen` — clipboard daemon
5. `playerctld daemon` — MPRIS player controller
6. `ghostty --class=ghostty.main -e tmux new-session -A -s Main` — main terminal in special workspace
7. `polkit-gnome-authentication-agent-1` — GUI auth popups

### Window Rules

Window rules use the **new matcher syntax**: `"action, match:property value"`.

Key rules:
- **Special workspace "magic"** — all windows float, purple border `#b388ff`, 70% opacity
- **ghostty.main** — auto-sent to `special:magic` silently (the main tmux terminal lives here)
- **ghostty.clipse** — floating clipboard popup, 622x600
- **ghostty.claude** — floating Claude Code terminal, 900x600, centered
- **Picture-in-Picture** — floating, pinned, bottom-right corner, 640x360
- **Discord** — floating, 722x600
- **Ghostty (general)** — 90% opacity when focused, inherits inactive_opacity (80%) otherwise

### Special Workspace "magic"

Acts as a **scratchpad**: `Super+grave` toggles it as a slide-down overlay. The main Ghostty terminal (tmux `Main` session) lives here permanently via the `ghostty.main` window rule. Windows in magic float by default with a purple border and slight transparency.

Animation: vertical slide (`slidevert`) instead of the default horizontal.

### hyprlock

Lock screen with:
- Blurred wallpaper background (`hptau.jpg`)
- Bold time at top center
- Transparent password input (white asterisks over blurred background)
- Red `$FAIL` message on wrong password
- PAM + fingerprint auth (just touch the sensor to unlock)

### hypridle

Simple config: locks the screen after 300 seconds of inactivity. Respects fullscreen (won't lock during video/games).

---

## 6. Quickshell Status Bar

### Architecture

```
shell.qml (Scope)
  └── Variants { model: Quickshell.screens }
        └── Bar.qml (PanelWindow) — one per screen
              ├── LEFT:   Workspaces
              ├── CENTER: MprisMini, ActiveWindow
              └── RIGHT:  Tray, StatusCluster
                            ├── VolumeDisplay
                            ├── Battery
                            └── Clock
                          + SettingsDropdown (PopupWindow)
```

### Bar Layout

- **Height**: 24px, transparent background, blur via layerrule
- **Font**: JetBrainsMono Nerd Font, 12px
- **Left**: Workspace indicators (Hyprland IPC)
- **Center**: Media now-playing (MprisMini) + active window title (auto-truncated to avoid overlap)
- **Right**: System tray icons + StatusCluster (clickable pill containing Volume, Battery, Clock)

### StatusCluster Interaction

- **Hover**: expands to show volume %, battery %, full time
- **Left click**: toggles SettingsDropdown popup (anchored below the cluster)
- **Right click hold**: shows expanded info
- **Click outside**: closes dropdown via `HyprlandFocusGrab`

### Development Workflow

QML files are **symlinked** to `~/.config/quickshell/` via Home-Manager's `xdg.configFile`. This means:
1. Edit QML files directly in `~/nixos-config/quickshell/`
2. Reload with `quickshell -r` (or restart quickshell)
3. **No nixos-rebuild needed** — changes are instant

---

## 7. SwayNC Notifications

Configured via Home-Manager `services.swaync` in `home.nix`:
- 48px notification icons
- 400px wide notification window
- Notifications persist (no auto-hide on clear/action)

Started by Hyprland's `exec-once` chain (first in the list so it's ready for all other services).

Used by Claude Code hooks to send desktop notifications when Claude needs attention (see section 9).

---

## 8. Workflow: Terminal Environment

### Ghostty + tmux Integration

Ghostty is configured to **auto-attach to tmux** on launch:
```
command = "tmux new-session -A -s Main \; new-window"
```
This creates or attaches to the `Main` tmux session and opens a new window.

### Main Terminal in Special Workspace

At Hyprland startup, a dedicated Ghostty instance launches with class `ghostty.main`:
```
ghostty --class=ghostty.main -e tmux new-session -A -s Main
```

The window rule `workspace special:magic silent, match:class (ghostty.main)` sends it to the special workspace automatically. Toggle with `Super+grave`.

### tmux Configuration

| Setting | Value |
|---|---|
| Prefix | `Space` (not Ctrl-b) |
| Key mode | vi |
| Mouse | enabled |
| Base index | 1 (windows start at 1, not 0) |
| Kill window | `Backspace` (after prefix) |
| Status bar | Purple background (#b388ff), black text |

---

## 9. Workflow: Agentic AI (Claude Code)

### Claude Code Hooks

Configured in `.claude/settings.local.json`. These run shell scripts on Claude Code lifecycle events:

| Hook | Script | What it does |
|---|---|---|
| `SessionStart` | `claude-tmux-rename.sh` | Renames the current tmux window to `claude[SESSION_ID]` (last 6 chars) |
| `Stop` | `claude-notify.sh` | Sends SwayNC notification "Needs your attention" with Claude icon |
| `Notification` | `claude-notify.sh` | Same notification for any Claude alert |
| `PreToolUse:AskUserQuestion` | `claude-notify.sh` | Notifies when Claude asks a question |

### claude-tmux-rename.sh
Reads JSON from stdin, extracts session_id, renames the tmux window:
```bash
tmux rename-window "claude[$SESSION_ID]"
```

### claude-notify.sh
Reads JSON from stdin, sends a desktop notification:
```bash
notify-send -a "Claude Code" -i "$ICON" "Claude [$SESSION_ID]" "Needs your attention"
```
Uses the custom `claude.svg` icon at `~/nixos-config/icons/claude.svg`.

### Window Rules for Claude Code

Claude Code runs in Ghostty with class `ghostty.claude`:
- Floating window (not tiled)
- Size: 900x600
- Centered on screen

### claude-nrs.sh (Non-Interactive Rebuild)

Purpose: lets Claude Code trigger a NixOS rebuild without interactive prompts or sudo password entry.

```bash
~/nixos-config/shell/claude-nrs.sh "commit message" [files...]
```

Flow:
1. `cd ~/nixos-config`
2. Stage specified files (or `git add -A` if none specified)
3. Commit with the provided message
4. `git push`
5. Create a new tmux window in the `Main` session
6. Send `pkexec nixos-rebuild switch --flake ~/nixos-config && exit` to that window
7. The `pkexec` triggers a **polkit GUI popup** for authentication (no terminal password prompt)
8. On success, the tmux window auto-closes (`&& exit`). On failure, it stays open for inspection.

After running, wait for the user to confirm the rebuild succeeded (they need to approve the polkit popup).

---

## 10. Deployment Workflow

### What Requires a Rebuild

Any change to **Nix files** requires `nixos-rebuild switch`:
- `flake.nix`, `configuration.nix`, `home.nix`
- `hyprland/hyprland-conf.nix`, `hyprland/hyprlock.nix`
- `laptop_gpu.nix`
- Adding/removing packages

This is because Nix files are evaluated at build time and produce immutable store paths.

### What Does NOT Require a Rebuild

Files that are **symlinked** via `xdg.configFile` are live:
- `quickshell/**/*.qml` — reload with `quickshell -r`
- `nvim/init.lua` — reloading Neovim picks up changes

Shell scripts (`shell/*.sh`) are also live — they're called by path, not from the Nix store.

### Interactive Rebuild: `nrs`

For humans at the terminal. Sourced into bash from `shell/nrs.sh`:
```bash
nrs
# Prompts: "Use a custom commit message? (y/n)"
# Commits, pushes, runs sudo nixos-rebuild switch
```

### Non-Interactive Rebuild: `claude-nrs.sh`

For Claude Code or other automation:
```bash
~/nixos-config/shell/claude-nrs.sh "add new package" home.nix
```
Uses pkexec (GUI polkit) instead of sudo. See section 9 for full details.

### Updating Flake Inputs

```bash
nix flake update              # update all inputs (nixpkgs, home-manager, nixos-hardware)
sudo nixos-rebuild switch --flake ~/nixos-config   # then rebuild
```

### Test Build (No Switch)

```bash
sudo nixos-rebuild build --flake ~/nixos-config
```
Builds the system closure without activating it. Useful to check for errors before committing.
