{
  auth = {
      pam = {
        enabled = true; # Corresponds to raw 'pam:enabled'
      };
      fingerprint = {
        enabled = true; # Corresponds to raw 'fingerprint:enabled'
        ready_message = "Scan Finger"; # Corresponds to raw 'fingerprint:ready_message'
      };
    };

  background = {
    monitor = "eDP-1";
    path = "/home/bmag/nixos-config/wallpapers/c691.jpg";
    blur_passes = 2;
    blur_size = 3;
  };
  label = [
    {
      monitor = "eDP-1";
      # Bold time at the top
      text = "<b>$TIME</b>";
      color = "rgba(255, 255, 255, 1.0)";
      font_size = 28;
      font_family = "JetBrainsMono Nerd Font";
      position = "0, 40";
      halign = "center";
      valign = "top";
    }
    {
      monitor = "eDP-1";
      # Bold fail reason under the input field, red
      text = "<b>$FAIL</b>";
      color = "rgba(204, 34, 34, 1.0)";
      font_size = 20;
      font_family = "JetBrainsMono Nerd Font";
      position = "0, 60";  # under the center input field
      halign = "center";
      valign = "center";
    }
  ];

  # Transparent password field, only ***** over the background
  input-field = {
    monitor = "eDP-1";
    size = "400, 90";

    # Kill the visible box
    outline_thickness = 0;
    outer_color = "rgba(255, 0, 0, 0.0)";
    inner_color = "rgba(255, 255, 255, 0.0)";
    check_color = "rgba(0, 0, 0, 0)";
    fail_color  = "rgba(0, 0, 0, 0)";
    capslock_color = "rgba(0, 0, 0, 0)";
    numlock_color = "rgba(0, 0, 0, 0)";

    # White text / dots on top of wallpaper
    font_color = "rgba(255, 255, 255, 1.0)";
    font_family = "JetBrainsMono Nerd Font";

    # Use ***** instead of round dots
    dots_text_format = "*";
    dots_size = 0.75;
    dots_center = true;

    fade_on_empty = false;
    placeholder_text = "";

    hide_input = false;

    rounding = 0;

    position = "0, 0";
    halign = "center";
    valign = "center";
  };
}

