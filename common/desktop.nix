{ config, pkgs, inputs, ... }:

# Desktop system overlay: Hyprland, greetd, audio, printing, Bluetooth,
# Firefox, fonts, and the Home-Manager wiring for the desktop user
# environment. Imported on top of ./baseline.nix by the desktop hosts.
{
  # Desktop-specific: disable wifi powersave
  networking.networkmanager.wifi.powersave = false;

  # X11 / XDG portal (Hyprland + GTK backends)
  services.xserver.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Audio: PipeWire
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

  # Desktop-only user groups (list-merges with baseline's [networkmanager wheel])
  users.users.bmag.extraGroups = [ "input" "plugdev" ];

  # Hyprland
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Restore the setuid pkexec wrapper. Newer nixpkgs gates it behind this
  # option (default false); without it `pkexec` errors "must be setuid root".
  security.polkit.enablePkexecWrapper = true;

  # Home-Manager: baseline + desktop overlay for the desktop user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users."bmag".imports = [ ../home/baseline.nix ../home/desktop.nix ];
  };

  # Desktop-only programs
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

  # Desktop-only system packages (list-merges with baseline's [vim git])
  environment.systemPackages = with pkgs; [
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
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "90min";
  };
}
