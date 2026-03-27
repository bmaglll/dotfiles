{ config, pkgs, inputs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = 2;  # 2 = disable

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
      pkgs.xdg-desktop-portal-gtk
      ];
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

  # Login manager
  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
        user = "bmag";
      };
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

  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = {
      "bmag" = import ../home.nix;
    };
  };

  # Programs
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  programs.firefox = {
    enable = true;
    preferences = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.hardware-video-decoding.force-enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
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
  ];

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts.emoji = [ "Apple Color Emoji" ];
    };
    packages = with pkgs; [
      noto-fonts
      font-awesome
      roboto
      liberation_ttf
      nerd-fonts.jetbrains-mono
      (pkgs.runCommand "apple-emoji" {} ''
        mkdir -p $out/share/fonts/truetype
        cp ${../fonts/AppleColorEmoji-Linux.ttf} $out/share/fonts/truetype/
      '')
    ];
  };

  # Suspend-then-hibernate: suspend immediately, hibernate after 90 min
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=90min
  '';

  system.stateVersion = "25.05";
}
