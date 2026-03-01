{ config, pkgs, ... }:

{
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11";
  ###########################################################################################
  # User packages
  ###########################################################################################
  home.packages = with pkgs; [
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
    wiremix
    hyprshot
    swaynotificationcenter
    libnotify

    chromium
    claude-code 
  ];
  ###########################################################################################
  # Bash 
  ###########################################################################################
  home.sessionPath = [ "$HOME/bin" ];

  programs.bash = {
    enable = true;

    shellAliases = { };

    # nrs: commit + push + rebuild
    initExtra = ''
    source ~/nixos-config/shell/nrs.sh
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
          timeout = 300;
          on-timeout = "pidof hyprlock || hyprlock";
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
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = [
        "/home/bmag/nixos-config/wallpapers/ngc2899.png"
      ];

      wallpaper = [
        "eDP-1,/home/bmag/nixos-config/wallpapers/ngc2899.png"
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
      notification-icon-size = 48;
      notification-body-image-height = 80;
      notification-body-image-width = 80;
    };
  };

  # Session env vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}

