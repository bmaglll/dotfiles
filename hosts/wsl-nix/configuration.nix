{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../common/baseline.nix
    # No desktop.nix, no hardware-configuration.nix — WSL supplies its own
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;
  wsl.defaultUser = "bmag";
  users.users.bmag.linger = true;
  wsl.wslConf.network.generateResolvConf = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  networking.hostName = "wsl-nix";

  # SSH: key-only, exposed only on tailscale0 (same pattern as server-nix).
  # Lets lap-nix `ssh bmag@wsl-nix` over the tailnet to drive the Windows tower.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    openFirewall = false;
  };

  users.users.bmag.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLDb/A/HaIzdsXnpIYASxTTGKKSBSHiBCOvMmtzTs5 bmagll@proton.me"
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # Force eth0 MTU to 1500. WSL can bring eth0 up at a lower MTU, which
  # black-holes large post-quantum SSH key-exchange packets over Tailscale
  # (the handshake stalls at preauth). Oneshot at boot — eth0 exists by then.
  systemd.services.fix-eth0-mtu = {
    description = "Set eth0 MTU to 1500";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip link set dev eth0 mtu 1500";
    };
  };

  # Override baseline's physical-host assumptions — WSL handles these itself
  boot.loader.systemd-boot.enable      = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.kernelPackages                  = lib.mkForce pkgs.linuxPackages;
  networking.networkmanager.enable     = lib.mkForce false;

  # Home-Manager: baseline only, same shape as server-nix
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.bmag = {
      imports = [ ../../home/baseline.nix ];
    };
  };

  # Nightly auto-upgrade. WSL is only running while Windows is on, so the
  # systemd timer's Persistent=true default catches up on next WSL start
  # if 04:00 was missed.
  system.autoUpgrade = {
    enable = true;
    flake = "github:bmaglll/dotfiles#wsl-nix";
    flags = [ "--update-input" "nixpkgs" "-L" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };

  system.stateVersion = "25.11";
}
