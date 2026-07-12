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

  networking.hostName = "wsl-nix";

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
    users.bmag.imports = [ ../../home/baseline.nix ];
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
