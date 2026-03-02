{ config, pkgs, inputs,  ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./laptop_gpu.nix
      # Framework 13 Laptop Flake
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Network Host Name
  networking.hostName = "lap-nix";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # XDG Portal Settings
  xdg.portal = {
    enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk  # optional – only if you actually need GTK portal
      ];
      # Make Hyprland the default portal
      config.common.default = [ "hyprland" "gtk" ];
    };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Services

  services.power-profiles-daemon.enable = true;

  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        # tuigreet is the login UI
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
        user = "bmag";
      };
  };
  };

  services.upower.enable = true;
  
  services.fprintd.enable = true;
  
  security.pam.services = {
     # Ensure login/tty login supports fingerprint
    login.fprintAuth = true; 
    
    # Ensure sudo supports fingerprint
    sudo.fprintAuth = true;
    # enable fingerprint for greetd service
    greetd = {
      fprintAuth = true; # Use fingerprint for the login screen itself
    };
    # enable fingerprint for hyprlock (via the "login" service)
    hyprlock = {
      fprintAuth = true;
      text = ''
        auth       sufficient   pam_fprintd.so
        auth       include      login
        account    include      login
        password   include      login
        session    include      login
      '';
    };
  };
  
  # User Info
  users.users.bmag = {
    isNormalUser = true;
    description = "Brandon";
    extraGroups = [ 
      "networkmanager"
      "wheel"
      "input"
      "plugdev"
    ];
    packages = with pkgs; [
    ];
  };

  ######### Hyprland ############
   
  programs.hyprland.enable = true; # enable Hyprland
  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager = {
    useGlobalPkgs = true;   # reuse the same pkgs as NixOS
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = {
      "bmag" = import ../../home.nix;
    };
  };
    
  # Programs
  programs.localsend = {
    enable = true;
    openFirewall = true;  # opens TCP/UDP 53317 for you
  };

  programs.firefox = {
    enable = true;
    preferences = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.hardware-video-decoding.force-enabled" = true;
      "media.ffvpx.enabled" = false;
      "media.rdd-ffmpeg.enabled" = true;
      "gfx.webrender.all" = true;
    };
  };

  # Allow unfree packages

  nixpkgs.config.allowUnfree = true;

  # Packages
  environment.systemPackages = with pkgs; [
  vim
  git
  hyprlock
  hypridle
  libfprint
  polkit_gnome
  ];
  # Fonts
  fonts = {
  enableDefaultPackages = true;
  fontconfig.enable = true;
  packages = with pkgs; [
    noto-fonts
    font-awesome
    roboto
    liberation_ttf
    nerd-fonts.jetbrains-mono
  ];
};

  system.stateVersion = "25.05";
}

