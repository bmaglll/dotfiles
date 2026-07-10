{ config, pkgs, ... }:

# System baseline: shared by EVERY host (desktops + server).
# Desktop-only system config lives in ./desktop.nix. Server-only bits live
# directly in hosts/server-nix/configuration.nix.
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Nix / nixpkgs
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Networking
  networking.networkmanager.enable = true;

  # Locale / time
  time.timeZone = "America/Chicago";
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

  # Tailscale (all hosts). Per-host tweaks (e.g. useRoutingFeatures)
  # can override or extend this attrset in the host file.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  # User (shared attrs). Host-specific extraGroups list-merge on top.
  users.users.bmag = {
    isNormalUser = true;
    description = "Brandon";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Minimal shared system packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
