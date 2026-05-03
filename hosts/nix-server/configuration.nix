{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nix-server";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    openFirewall = true;
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  users.users.bmag = {
    isNormalUser = true;
    description = "Brandon";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLDb/A/HaIzdsXnpIYASxTTGKKSBSHiBCOvMmtzTs5 bmagll@proton.me"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  system.autoUpgrade = {
    enable = true;
    flake = "github:bmaglll/dotfiles#nix-server";
    flags = [ "--update-input" "nixpkgs" "-L" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };

  services.fail2ban.enable = true;

  services.journald.extraConfig = "SystemMaxUse=500M";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.bmag = import ../../home-server.nix;
  };

  system.stateVersion = "25.11";
}
