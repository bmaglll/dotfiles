{ config, pkgs, inputs, ... }:

{
  imports =
    [
      # Shared config
      ../../baseline/configuration.nix
      # Hardware (generate on tower with: nixos-generate-config)
      ./hardware-configuration.nix
    ];

  # Hostname
  networking.hostName = "desk-nix";
}
