{ config, pkgs, inputs, ... }:

{
  imports =
    [
      # Shared config
      ../../common/baseline.nix
      ../../common/desktop.nix
      # Hardware (generate on tower with: nixos-generate-config)
      ./hardware-configuration.nix
    ];

  # Hostname
  networking.hostName = "desk-nix";
}
