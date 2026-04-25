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

  # Open port for UniFi Protect webhook listener
  networking.firewall.allowedTCPPorts = [ 9999 ];

  # Hibernate resume
  boot.resumeDevice = "/dev/disk/by-uuid/51e79868-d770-4c23-ba7d-f9754f95bc41";
  boot.kernelParams = [ "resume_offset=39610368" "pcie_aspm.policy=performance" ];

  # Lid close triggers suspend-then-hibernate
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };

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
    };
  };
}
