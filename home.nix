{ config, pkgs, ... }:

{
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11";
  ###########################################################################################
  # User packages
  ###########################################################################################
  home.packages = with pkgs; [
    # User Added
    nautilus
    brightnessctl
    clipse
    waybar
    cava
    spotify
    fastfetch
    kitty
    waybar-mpris
    slurp
    playerctl
    grim
    grimblast
    tmux
    btop
    discord
    hyprpaper
    hyprsunset
    wl-clipboard
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
    yazi
    obs-studio
    libnotify
    jq
    chromium
    claude-code
    mpv
    gh
    obs-studio

    # Python environment with packages
    (python312.withPackages (ps: [
      ps.playwright
      ps.anthropic
    ]))
    # Added by Claude
  ];
  ###########################################################################################
  # Bash 
  ###########################################################################################
  home.sessionPath = [ "$HOME/bin" ];

  programs.bash = {
    enable = true;

    shellAliases = {
      lucas-cam = "~/projects/personal/unifi-pip-notifications/lucas-cam.sh 'rtsps://192.168.1.1:7441/bnwQ109pDsCuY3kf?enableSrtp'";
    };

    # nrs: commit + push + rebuild
    initExtra = ''
    source ~/nixos-config/shell/nrs.sh
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -1)
    PS1='\[\033[01;32m\][\D{%H:%M:%S}]\[\033[00m\] \[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  '';
  };
  ###########################################################################################
  # neovim
  ###########################################################################################
  programs.tmux = {
  enable = true;
  keyMode = "vi";
  mouse = true;
  shortcut = "space";
  baseIndex = 1;
  extraConfig = ''
  setw -g mouse on
  bind BSpace kill-window
  set -g status-style "bg=#b388ff,fg=#000000"
  set -g status-right ""
  set -g renumber-windows on
  set -as terminal-features ",xterm-ghostty:sync"
  '';
  };
  ###########################################################################################
  # Ghostty
  ###########################################################################################
  programs.ghostty = {
    enable = true;
    settings = {
      command = "tmux new-session -A -s Main \\; new-window";
      keybind = "shift+enter=text:\\x1b\\r";
    };
  };
  xdg.configFile."ghostty/config".force = true;
  ###########################################################################################
  # neovim
  ###########################################################################################
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
  
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  
    extraPackages = with pkgs; [
      wl-clipboard
    ];
  
    # IMPORTANT: stop using extraConfig once you're using init.lua
    extraConfig = "";
  };
  xdg.configFile."nvim".source = ./nvim;
  ###########################################################################################
  # Hyprland
  ###########################################################################################
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    settings = import ./hyprland/hyprland-conf.nix;
  };
  ###########################################################################################
  # Hyprlock
  ###########################################################################################
  programs.hyprlock = {
    enable = true;
    settings = import ./hyprland/hyprlock.nix;

  };
  ###########################################################################################
  # Hypridle
  ###########################################################################################
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        inhibit_if_fullscreen = true;
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || hyprlock";
          on-resume = "";
        }
        {
          timeout = 900;  # 15 min idle → suspend-then-hibernate
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
  xdg.configFile."quickshell".source = ./quickshell;


  # Spotify icon for system tray
  xdg.dataFile."icons/hicolor/128x128/apps/spotify-linux-32.png".source =
    ./icons/spotify-linux-32.png;

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
      hide-on-clear = false;
      hide-on-action = false;
      scripts = {
        notification-sound = {
          exec = "bash /home/bmag/nixos-config/sounds/notification-sound.sh";
          app-name = "Claude Code";
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

  # UniFi Protect motion notification webhook listener
  systemd.user.services.protect-notify = {
    Unit = {
      Description = "UniFi Protect Webhook Notification Listener";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/etc/profiles/per-user/bmag/bin/python3 /home/bmag/projects/personal/unifi-pip-notifications/protect-notify.py";
      EnvironmentFile = "/home/bmag/projects/personal/unifi-pip-notifications/.env";
      Restart = "on-failure";
      RestartSec = "10";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Session env vars
  home.sessionVariables = {
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}

