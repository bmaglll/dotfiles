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
  boot.kernelParams = [ "resume_offset=39610368" "pcie_aspm.policy=performance" "amdgpu.sg_display=0" ];

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

  # Workaround for mt7921e hanging on resume ("PM: failed to restore async: error -110").
  # Reload the module after wake so wifi recovers without a manual reconnect.
  systemd.services.mt7921e-resume-fix = {
    description = "Reload mt7921e after resume (MT7922 suspend bug workaround)";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kmod}/bin/rmmod mt7921e || true; ${pkgs.kmod}/bin/modprobe mt7921e'";
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  environment.systemPackages = with pkgs; [
    libfprint
    iw
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
