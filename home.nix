{ config, pkgs, ... }:

{
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11";

  # User packages
  home.packages = with pkgs; [
    nautilus
    ghostty
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
    wofi
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
  ];

  # Base PATH
  home.sessionPath = [ "$HOME/bin" ];

  programs.bash = {
    enable = true;

    shellAliases = { };

    # nrs: commit + push + rebuild
    initExtra = ''
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
    '';
  };

  # Neovim
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      wl-clipboard
    ];

    extraConfig = ''
      " Use the system clipboard for all yanks / deletes / puts
      set clipboard=unnamedplus
    '';
  };

  # Hyprland (user-side settings, system package comes from NixOS)
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    settings = import ./hyprland/hyprland-conf.nix;
  };

## Hyprlock
  programs.hyprlock = {
    enable = true;

    settings = {
      # 🌟 1. AUTHENTICATION (Top-level attributes in settings)
      "fingerprint:enabled" = true;
      "pam:enabled" = true;
      "fingerprint:ready_message" = "(Scan fingerprint to unlock)";
      "fingerprint:present_message" = "Scanning...";

      # 2. SECTIONS (Each section block now ends with a semicolon)
      general = {
        disable_loading_bar = false;
      }; # <- Semicolon here

      background = {
        monitor = "eDP-1"; # <- Semicolon here
        path = "/home/bmag/Pictures/wallpapers/ngc2899.png"; # <- Semicolon here
        blur_passes = 2; # <- Semicolon here
        blur_size = 3; # <- Semicolon here
      }; # <- Semicolon here

      label = {
        text = "bmag"; # <- Semicolon here
        position = "0, 50"; # <- Semicolon here
        halign = "center"; # <- Semicolon here
        valign = "center"; # <- Semicolon here
      }; # <- Semicolon here

      input-field = {
        size = "200, 40"; # <- Semicolon here
        position = "0, -50"; # <- Semicolon here
        halign = "center"; # <- Semicolon here
        valign = "center"; # <- Semicolon here
      }; # <- Semicolon here
    }; # <- Semicolon here
  };
  # Hypridle
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        inhibit_if_fullscreen = true;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "pidof hyprlock || hyprlock";
          on-resume = "";
        }
      ];
    };
  };

  # Hyprpaper
  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = [
        "/home/bmag/Pictures/wallpapers/ngc2899.png"
      ];

      wallpaper = [
        "eDP-1,/home/bmag/Pictures/wallpapers/ngc2899.png"
      ];
    };
  };

  # Quickshell config (bar)
  xdg.configFile."quickshell".source = ./quickshell;

  # Waybar configs (kept commented for now)
  # xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  # xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  # Spotify icon for system tray
  xdg.dataFile."icons/hicolor/128x128/apps/spotify-linux-32.png".source =
    ./icons/spotify-linux-32.png;

  # Session env vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}

