{ config, pkgs, inputs, ... }:

{
  imports =
    [
      # Shared config
      ../../common/baseline.nix
      ../../common/desktop.nix
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
  # Uses powerManagement.resumeCommands because it fires on both suspend and hibernation
  # resume; an earlier attempt with a `post-resume.target`-bound service silently never ran
  # because that target does not exist in systemd.
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/rmmod mt7921e || true
    ${pkgs.kmod}/bin/modprobe mt7921e
  '';

  # DOIO 4-key macropad raw-HID access for VIA/Vial remapping without root.
  # First rule: current qmkbuilder VIA firmware (feed:6060).
  # Second rule: Vial firmware (matches Vial's serial), in case we flash it.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="feed", ATTRS{idProduct}=="6060", MODE="0660", GROUP="users", TAG+="uaccess"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    libfprint
    iw
    remmina
    vial
    codex
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

  # Pins on-disk state semantics to the release this machine was initialized
  # against. Preserving the previously-inherited value from common/desktop.nix
  # so behavior does not change. Do not bump without reading the release notes.
  system.stateVersion = "25.05";
}
