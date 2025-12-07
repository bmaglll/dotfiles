{

    # variables
    "$mainMod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "nautilus";
    "$menu" = "wofi --show drun";  # change if you use something else (rofi, tofi, etc.)
    # windows
    general = {
      gaps_in = 5;
      gaps_out = 5;

      border_size = 2;

      # colors must be strings in Nix
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";

      resize_on_border = true;
      bindm = "SUPER,mouse:272,movewindow";

      allow_tearing = false;

      layout = "dwindle";
    };
    # window look
    decoration = {
      rounding = 3;

      active_opacity = 1.0;
      inactive_opacity = 0.8;

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
    	};

      blur = {
        enabled = true;
        size = 10;
        passes = 2;
        vibrancy = 0.1696;
	new_optimizations = true;
	noise = 0.1;
	ignore_opacity = true;
	contrast = 2;

      	};
    };
    # misc
    misc = {
      force_default_wallpaper = 1;   # 0 or 1
      disable_hyprland_logo = true;
    };

    # exec on startup
    exec-once = [
      "quickshell"
      "nm-applet --indicator"
      "clipse -listen"
      "playerctld daemon"
    ];

    # workspace rules
    workspace = [
      "1, persistent:true"
    ];

    # keyboard / mouse
    input = {
      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      kb_rules = "";

      follow_mouse = 1;

      sensitivity = 0; # -1.0 to 1.0

      touchpad = {
        natural_scroll = true;
      };
    };
    # touchpad
    gestures = {
      gesture = [
        "3, horizontal, workspace"
      ];

    };
    # keybindings
    bind = [
      # brightness
      ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

      # mute
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      # workspace binds
      "$mainMod, Q, movetoworkspace, empty"
      "$mainMod SHIFT, Q, movetoworkspacesilent, empty"
      # workspace switching
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"
      # Clipse pop-up with Ghostty
      "SUPER, V, exec, ghostty --class=ghostty.clipse -e clipse"
      # main Hyprland binds (now using ghostty + nautilus)
      "$mainMod, RETURN, exec, $terminal"
      "$mainMod, W, killactive,"
      "$mainMod, M, exit,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, Z, togglefloating,"
      "$mainMod, D, exec, $menu"
      "$mainMod, F, fullscreen, 1"
      "SUPER, L, exec, hyprlock"
      ];
    # repeat-on-hold audio binds
    binde = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
      ];
    # window rules
    windowrulev2 = [
      # Btop in kitty (if you still use this – otherwise you can delete)
      # "fullscreen, class:^(kitty)$, title:^(btop)$"
      # "float, class:^(kitty)$, title:^(btop)$"

      # Clipse window via Ghostty
      "float, class:(ghostty.clipse)"
      "size 622 600, class:(ghostty.clipse)"

      # Hyprland share picker / ProtonVPN
      "float, class:^(hyprland-share-picker)$"
      "center, class:^(hyprland-share-picker)$"
      "float, class:^(protonvpn-app)$"
      # OBS (uncomment if you want this behavior)
      # "float, class:^(com\\.obsproject\\.Studio)$"
      # "center, class:^(com\\.obsproject\\.Studio)$"
      ];
    layerrule = [
      "blur, quickshell"
      #"ignore_alpha 0.3,quickshell"
      #"noanim,quickshell"
      
    ];

}


