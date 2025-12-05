{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = [
    pkgs.nautilus
    pkgs.ghostty
    pkgs.brightnessctl
    pkgs.clipse
    pkgs.waybar
    pkgs.cava
    pkgs.spotify
    pkgs.fastfetch
    pkgs.kitty
    pkgs.waybar-mpris
    pkgs.slurp
    pkgs.playerctl
    pkgs.grim
    pkgs.grimblast
    pkgs.tmux
    pkgs.btop
    pkgs.wofi
    pkgs.discord
    pkgs.hyprpaper
    pkgs.hyprsunset
    pkgs.wl-clipboard
    pkgs.rose-pine-hyprcursor
    pkgs.libgcc
    pkgs.quickshell
    ];

  # Base
    home.sessionPath = [ "$HOME/bin" ];

    programs.bash = {
      enable = true;
      shellAliases = {
        nrs = "cd ~/nixos-config && git add . && (git commit -m 'Update NixOS config' || echo 'No changes to commit') && git push && sudo nixos-rebuild switch --flake ~/nixos-config";
      };
    };

  # Neovim
    programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Runtime deps specifically for this nvim
    extraPackages = with pkgs; [
      wl-clipboard          # gives nvim wl-copy/wl-paste inside its env
    ];

    extraConfig = ''
      " Use the system clipboard for all yanks / deletes / puts
      set clipboard=unnamedplus
    '';
  };
  # Enable Hyprland / Import Settings
  wayland.windowManager.hyprland = {
    enable = true;

    # use Hyprland from the NixOS module
    package = null;
    portalPackage = null;
    
    settings = import ./hyprland-conf.nix;
  };  

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


  # Import Waybar or Quickshell configs
  xdg.configFile."quickshell/shell.qml".source = ./qkshell/shell.qml;
  #xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  #xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  
  home.sessionVariables = {

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

