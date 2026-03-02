{ config, pkgs, ... }:

{
  # AMD Phoenix APU - Hardware video acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Environment variables for Firefox VA-API support
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DRM_DEVICE = "/dev/dri/renderD128";
  };
}
