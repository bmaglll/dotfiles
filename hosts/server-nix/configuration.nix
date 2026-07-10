{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/baseline.nix
  ];

  networking.hostName = "server-nix";

  # Headless: never react to lid switches (device is a laptop with lid closed)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # No sleep, no power profiles
  powerManagement.enable = false;
  services.power-profiles-daemon.enable = false;

  # SSH: key-only, no root, closed to non-tailscale interfaces
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    # SSH is exposed only via tailscale0 (see firewall rule below)
    openFirewall = false;
  };

  # Server-specific user bits (merges with common/baseline.nix's users.users.bmag)
  users.users.bmag = {
    extraGroups = [ "docker" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLDb/A/HaIzdsXnpIYASxTTGKKSBSHiBCOvMmtzTs5 bmagll@proton.me"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  system.autoUpgrade = {
    enable = true;
    flake = "github:bmaglll/dotfiles#server-nix";
    flags = [ "--update-input" "nixpkgs" "-L" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };

  services.fail2ban.enable = true;

  services.journald.extraConfig = "SystemMaxUse=500M";

  # Docker + Home Assistant container
  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      volumes = [
        "/var/lib/hass:/config"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
        "--privileged"
      ];
      autoStart = true;
    };
  };

  # Only expose SSH + Home Assistant on tailscale0
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 8123 ];

  # Server-specific packages (list-merges with baseline's [vim git])
  environment.systemPackages = with pkgs; [
    curl
    wget
    htop
  ];

  # Home-Manager: baseline only (no desktop overlay on the server)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.bmag.imports = [ ../../home/baseline.nix ];
  };

  system.stateVersion = "25.11";
}
