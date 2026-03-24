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
      	};
    };
    # misc
    misc = {
      force_default_wallpaper = 1;   # 0 or 1
      disable_hyprland_logo = true;
    };

    # exec on startup
    exec-once = [
      "swaync"
      "quickshell"
      "nm-applet --indicator"
      "clipse -listen"
      "playerctld daemon"
      "ghostty --class=ghostty.main -e tmux new-session -A -s Main"
    ];

    # workspace rules
    workspace = [
      "1, persistent:true"
    ];

    # special workspace animation (vertical slide instead of horizontal)
    animation = [
      "specialWorkspace, 1, 4, default, slidevert"
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
	scroll_factor = 0.5;
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
      # screenshotting
      "$mainMod SHIFT, S, exec, hyprshot -m region --clipboard-only"
      # brightness
      ", XF86MonBrightnessUp, exec, brightnessctl s +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

      # mute
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      # workspace binds
      "$mainMod, Q, movetoworkspace, empty"
      "$mainMod SHIFT, Q, movetoworkspacesilent, empty"
      # special workspace
      "$mainMod, grave, togglespecialworkspace, magic"
      "$mainMod SHIFT, grave, movetoworkspacesilent, special:magic"
      # workspace cycling and monitor switching
      "$mainMod, Tab, workspace, e+1"
      "$mainMod SHIFT, Tab, movecurrentworkspacetomonitor, +1"
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
      "$mainMod, RETURN, exec, ghostty -e tmux new-session"
      "$mainMod, W, killactive,"
      "$mainMod, M, exit,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, Z, togglefloating,"
      "$mainMod, Space, exec, pkill wofi || $menu"
      "$mainMod, F, fullscreen, 1"
      "SUPER, L, exec, hyprlock"
      ];
    # lock on lid close
    bindl = [
      ", switch:Lid Switch, exec, pidof hyprlock || hyprlock"
    ];
    # repeat-on-hold audio binds
    binde = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
      ];
    # window rules
    windowrule = [
      # Floating windows: orange border
      "border_color rgba(ff9500ee), match:float 1"

      # Special workspace: purple border, transparency
      "border_color rgba(b388ffee), match:workspace special:magic"
      "opacity 0.7, match:workspace special:magic"

      # Floating on magic: orange overrides purple
      "border_color rgba(ff9500ee), match:float 1, match:workspace special:magic"

      # Picture-in-Picture: floating, pinned, bottom-right corner
      "float on, match:title ^Picture-in-Picture$"
      "size 480 270, match:title ^Picture-in-Picture$"
      "move (monitor_w-window_w-10) 35, match:title ^Picture-in-Picture$"
      "pin on, match:title ^Picture-in-Picture$"
      "no_anim on, match:title ^Picture-in-Picture$"
      "keep_aspect_ratio on, match:title ^Picture-in-Picture$"

      # Clipse window via Ghostty
      "float on, match:class (ghostty.clipse)"
      "size 622 600, match:class (ghostty.clipse)"

      # Claude Code floating terminal
      "float on, match:class (ghostty.claude)"
      "size 900 600, match:class (ghostty.claude)"
      "center on, match:class (ghostty.claude)"

      # Nautilus file manager: floating, centered
      "float on, match:class ^(org.gnome.Nautilus)$"
      "size 700 500, match:class ^(org.gnome.Nautilus)$"
      "center on, match:class ^(org.gnome.Nautilus)$"

      # File picker dialogs (e.g. Chromium "Open File")
      "float on, match:title ^(Open File)$"
      "size 700 500, match:title ^(Open File)$"
      "center on, match:title ^(Open File)$"

      # Main tmux session in special workspace
      "workspace special:magic silent, match:class (ghostty.main)"

      # Hyprland share picker / ProtonVPN / Discord
      "float on, match:class ^(hyprland-share-picker)$"
      "center on, match:class ^(hyprland-share-picker)$"
      "float on, match:class ^(discord)$"
      "size 722 600, match:class ^(discord)"
      "float on, match:class ^(protonvpn-app)$"

      # Polkit popup
      "float on, match:class ^(hyprpolkitagent)$"
      "center on, match:class ^(hyprpolkitagent)$"

      # Ghostty opacity
      "opacity 0.9 1.0, match:class ^(ghostty)$"
    ];
    layerrule = [
      "blur on, match:namespace quickshell"
    ];

}


