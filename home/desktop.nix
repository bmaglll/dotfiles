{ config, pkgs, lib, ... }:

# Home-Manager desktop overlay (Hyprland, GUI apps, bar, launcher, ...).
# Imported on top of ./baseline.nix by the desktop hosts. The server does
# NOT import this file.
{
  ###########################################################################################
  # Desktop packages
  ###########################################################################################
  home.packages = with pkgs; [
    # Framework mic hardware switch detector
    (stdenv.mkDerivation {
      pname = "framework-mic-switch";
      version = "1.0.0";
      src = ../quickshell/tools;
      buildInputs = [ alsa-lib ];
      buildPhase = ''
        $CC -O2 -Wall -o framework-mic-switch framework-mic-switch.c -lasound
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp framework-mic-switch $out/bin/
      '';
    })

    # User Added
    nautilus
    brightnessctl
    clipse
    waybar
    cava
    spotify  # temporarily disabled - snapcraft CDN down
    kitty
    waybar-mpris
    slurp
    playerctl
    grim
    grimblast
    discord
    hyprpaper
    hyprsunset
    rose-pine-hyprcursor
    libgcc
    quickshell
    networkmanagerapplet
    localsend
    sioyek
    wiremix
    hyprshot
    swaynotificationcenter
    ffmpeg
    codex
    obs-studio
    libnotify
    chromium
    moonlight-qt
    mpv
    bluetui
    wl-clipboard

    # Python environment with packages
    # TODO: remove inline-snapshot override once nixpkgs fixes upstream test_docs.py drift (added 2026-07-14).
    # Check with: nix build --no-link nixpkgs#python312Packages.inline-snapshot
    (let
      python = pkgs.python312.override {
        packageOverrides = pyself: pysuper: {
          inline-snapshot = pysuper.inline-snapshot.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      };
    in python.withPackages (ps: [
      ps.playwright
      ps.anthropic
      ps.pygobject3
    ]))
  ];

  ###########################################################################################
  # Neovim clipboard provider (Wayland-only; list-merges with baseline's extraPackages)
  ###########################################################################################
  programs.neovim.extraPackages = with pkgs; [ wl-clipboard ];

  ###########################################################################################
  # Bash (desktop extras on top of baseline)
  ###########################################################################################
  programs.bash.initExtra = lib.mkAfter ''
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -1)
  '';

  ###########################################################################################
  # tmux (fancy host-aware bar — overrides baseline's amber definition)
  ###########################################################################################
  programs.tmux.extraConfig = lib.mkForce ''
    setw -g mouse on
    bind BSpace kill-window
    set -g status-style 'bg=#{?#{==:#{pane_current_command},ssh},#ff5555,#{?#{==:#h,desk-nix},#00c8c8,#b388ff}},fg=#000000'
    set -g status-left '#{?#{==:#{pane_current_command},ssh},#[bg=#ff0000#,fg=#ffffff#,bold] SSH #[default] ,}'
    set -g status-left-length 20
    set -g status-right ""
    set -g renumber-windows on
    set -as terminal-features ",xterm-ghostty:sync"
    set -g allow-passthrough on
  '';

  ###########################################################################################
  # Ghostty
  ###########################################################################################
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = ["JetBrainsMono Nerd Font" "Apple Color Emoji"];
      command = "tmux new-session -A -s Main \\; new-window";
      keybind = "shift+enter=text:\\x1b\\r";
    };
  };
  xdg.configFile."ghostty/config".force = true;

  ###########################################################################################
  # Yazi (desktop opener rules on top of baseline)
  ###########################################################################################
  programs.yazi.settings = {
    opener = {
      browser = [
        { run = ''chromium %s''; desc = "Open in Chromium"; orphan = true; }
      ];
      # Override yazi's default `edit` opener (which runs $EDITOR in the
      # current terminal and blocks yazi). Inside tmux, spawn nvim as a new
      # tmux window so yazi stays open in the original pane; outside tmux,
      # fall back to opening nvim normally.
      edit = [
        {
          run = ''if [ -n "$TMUX" ]; then tmux neww -n nvim nvim "$@"; else nvim "$@"; fi'';
          desc = "nvim (new tmux window if in tmux)";
          block = false;
          orphan = true;
          for = "unix";
        }
      ];
    };
    open = {
      prepend_rules = [
        { url = "*.html"; use = ["browser"]; }
        { url = "*.htm"; use = ["browser"]; }
        { mime = "text/html"; use = ["browser"]; }
      ];
    };
  };

  ###########################################################################################
  # Hyprland
  ###########################################################################################
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    # hyprlang is deprecated since Hyprland 0.55; config is now Lua.
    configType = "lua";
    extraConfig = builtins.readFile ../hyprland/hyprland.lua;
  };
  ###########################################################################################
  # Hyprlock
  ###########################################################################################
  programs.hyprlock = {
    enable = true;
    settings = import ../hyprland/hyprlock.nix;
  };
  ###########################################################################################
  # Hypridle
  ###########################################################################################
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        # Hyprland's Lua config mode evaluates `hyprctl dispatch` args as Lua;
        # the old `dpms on` form no longer parses. Use the hl.dsp call form.
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms(\"on\")'";
        inhibit_if_fullscreen = true;
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || hyprlock";
          on-resume = "";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend-then-hibernate";
          on-resume = "";
        }
      ];
    };
  };
  ###########################################################################################
  # Hyprpaper
  ###########################################################################################
  services.hyprpaper = {
    enable = true;

    settings = {
      splash = false;

      wallpaper = [
        {
          monitor = "";
          path = "/home/bmag/nixos-config/wallpapers/ngc2899.png";
        }
      ];
    };
  };
  ###########################################################################################
  # Quickshell config (bar)
  ###########################################################################################
  xdg.configFile."quickshell".source = ../quickshell;

  # Spotify icon for system tray (temporarily disabled - snapcraft CDN down)
  # xdg.dataFile."icons/hicolor/128x128/apps/spotify-linux-32.png".source =
  #   ../icons/spotify-linux-32.png;

  # Claude icon, installed by NAME so notify-send can use `-i claude` (app_icon
  # field). Passing the file path directly makes notify-send emit an image-path
  # hint, which crashes swaync 0.12.6. See shell/claude-notify-*.sh.
  xdg.dataFile."icons/hicolor/scalable/apps/claude.svg".source =
    ../icons/claude.svg;

  ###########################################################################################
  # Swaync (notification center)
  ###########################################################################################
  services.swaync = {
    enable = true;
    settings = {
      notification-icon-size = 36;
      notification-body-image-height = 150;
      notification-body-image-width = 280;
      notification-window-width = 300;
      timeout = 10;
      hide-on-clear = false;
      hide-on-action = false;
      scripts = {
        notification-sound = {
          exec = "bash /home/bmag/nixos-config/shell/notification-sound.sh";
          app-name = "^(Claude Code|Codex)$";
        };
      };
    };
    style = ''
      .notification-row {
        padding: 6px 0;
      }
      .notification-row .notification-content .summary {
        font-size: 14px;
      }
      .notification-row .notification-content .body {
        font-size: 12px;
      }
      .close-button {
        min-width: 1px;
        min-height: 1px;
        padding: 0;
        margin: 0;
        border: none;
        background: transparent;
        opacity: 0;
      }
    '';
  };

  # Wofi dmenu style (no search bar)
  xdg.configFile."wofi/dmenu.css".text = ''
    #input {
      margin: 0;
      padding: 0;
      border: none;
      min-height: 0;
      height: 0;
      opacity: 0;
    }
    #input:focus {
      border: none;
      outline: none;
      box-shadow: none;
      background: transparent;
    }
    window {
      font-family: "JetBrainsMono Nerd Font", monospace;
      background-color: rgba(17, 17, 27, 0.85);
      border-radius: 12px;
      border: 2px solid rgba(205, 214, 244, 0.2);
    }
    #inner-box { margin: 4px 8px; }
    #outer-box { padding: 4px; }
    #entry { padding: 6px 12px; border-radius: 8px; color: #cdd6f4; }
    #entry:selected { background-color: rgba(205, 214, 244, 0.12); color: #e0e4f0; }
    #text { color: #cdd6f4; }
    #text:selected { color: #e0e4f0; }
  '';
  ###########################################################################################
  # Wofi (app launcher)
  ###########################################################################################
  programs.wofi = {
    enable = true;
    settings = {
      width = 500;
      height = 175;
      location = "center";
      show = "drun";
      prompt = "Search...";
      allow_markup = true;
      no_actions = true;
      insensitive = true;
      allow_images = true;
      image_size = 24;
      gtk_dark = true;
      layer = "overlay";
    };
    style = ''
      /* Main window */
      window {
        font-family: "JetBrainsMono Nerd Font", monospace;
        background-color: rgba(17, 17, 27, 0.85);
        border-radius: 12px;
        border: 2px solid rgba(205, 214, 244, 0.2);
      }

      /* Input field */
      #input {
        margin: 8px 12px;
        padding: 8px 12px;
        border: none;
        border-bottom: 2px solid rgba(205, 214, 244, 0.2);
        border-radius: 8px;
        background-color: rgba(30, 30, 46, 0.6);
        color: #cdd6f4;
        font-size: 14px;
        outline: none;
        box-shadow: none;
      }

      #input:focus {
        border-bottom-color: rgba(205, 214, 244, 0.5);
        outline: none;
        box-shadow: none;
      }

      /* Results list */
      #inner-box {
        margin: 4px 8px;
      }

      #outer-box {
        padding: 4px;
      }

      /* Each result row */
      #entry {
        padding: 6px 12px;
        border-radius: 8px;
        color: #cdd6f4;
      }

      #entry:selected {
        background-color: rgba(205, 214, 244, 0.12);
        color: #e0e4f0;
      }

      /* App icon */
      #img {
        margin-right: 8px;
      }

      /* Result text */
      #text {
        color: #cdd6f4;
      }

      #text:selected {
        color: #e0e4f0;
      }
    '';
  };

  ###########################################################################################
  # Polkit agent (hyprpolkitagent via systemd)
  ###########################################################################################
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Slice = "session.slice";
      TimeoutStopSec = "5s";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # UniFi Cams motion notification webhook listener
  systemd.user.services.unifi-notify = {
    Unit = {
      Description = "UniFi Cams Webhook Notification Listener";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/etc/profiles/per-user/bmag/bin/python3 /home/bmag/projects/personal/unifi-cams/unifi-notify.py";
      EnvironmentFile = "/home/bmag/projects/personal/unifi-cams/.env";
      Restart = "on-failure";
      RestartSec = "10";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Session env vars
  home.sessionVariables = {
    HYPRSHOT_DIR = "$HOME/Pictures/Screenshots";
  };
}
