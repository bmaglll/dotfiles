{ config, pkgs, inputs, ... }:

{
  imports =
    [
      # Shared config
      ../../common/configuration.nix
      # Hardware
      ./hardware-configuration.nix
      ./laptop_gpu.nix
      # Framework 13 Laptop Flake
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ];

  # Hostname
  networking.hostName = "lap-nix";

  # Laptop power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Fingerprint authentication
  services.fprintd.enable = true;

  environment.systemPackages = with pkgs; [
    libfprint
  ];

  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    greetd = {
      fprintAuth = true;
    };
    hyprlock = {
      fprintAuth = true;
      text = ''
        auth       sufficient   pam_fprintd.so
        auth       include      login
        account    include      login
        password   include      login
        session    include      login
      '';
    };
  };
}
