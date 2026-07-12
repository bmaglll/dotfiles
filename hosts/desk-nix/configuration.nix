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

  # TODO: set on first install of this host. Pins on-disk state semantics to
  # the NixOS release this machine was initialized against. Whatever release
  # you install with (e.g. "26.05"), put here — do NOT copy 25.05 from lap-nix.
  # system.stateVersion = "26.05";
}
