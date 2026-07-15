-- Hyprland config (Lua). Migrated from hyprlang (deprecated since Hyprland 0.55).
-- See https://wiki.hypr.land/Configuring/Start/
-- Generated file lives at ~/.config/hypr/hyprland.lua (via Home-Manager extraConfig).

---------------------
---- VARIABLES ------
---------------------
local mainMod     = "SUPER"
local terminal    = "ghostty"
local fileManager = "nautilus"
local menu        = "wofi --show drun"

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 3,

        active_opacity   = 1.0,
        inactive_opacity = 0.8,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled           = true,
            size              = 10,
            passes            = 2,
            vibrancy          = 0.1696,
            new_optimizations = true,
        },
    },

    misc = {
        force_default_wallpaper = 1,    -- 0 or 1
        disable_hyprland_logo   = true,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 to 1.0

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.5,
        },
    },
})

-- Vertical slide for the special (magic) workspace
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "default", style = "slidevert" })

-- Touchpad gesture: 3-finger horizontal swipe changes workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Persistent workspace 1
hl.workspace_rule({ workspace = "1", persistent = true })

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("swaync")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("ghostty --class=ghostty.main -e tmux new-session -A -s Main")
end)

---------------------
---- KEYBINDINGS ----
---------------------

-- Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"))

-- Mute / mic mute
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- Volume (repeat on hold, limited to 140%)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })

-- Empty-workspace binds
hl.bind(mainMod .. " + Q",         hl.dsp.window.move({ workspace = "empty" }))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.move({ workspace = "empty", follow = false }))

-- Special (magic) workspace
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- Workspace cycling and monitor switching
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.workspace.move({ monitor = "+1" }))

-- Switch to / move window to workspaces 1-9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Clipboard history (Clipse via Ghostty)
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("ghostty --class=ghostty.clipse -e clipse"))

-- Core binds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty -e tmux new-session"))
hl.bind(mainMod .. " + W",      hl.dsp.window.close())
hl.bind("CTRL + ALT + escape",  hl.dsp.exit())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Z",      hl.dsp.window.float())
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd("pkill wofi || " .. menu))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("ghostty --class=ghostty.emoji -e bash ~/nixos-config/shell/emoji-picker.sh"))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))

-- Unifi camera dashboard
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("bash -lc ~/projects/personal/unifi-cams/unifi-dashboard.sh"))

-- Move window with SUPER + LMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

---------------------
---- WINDOW RULES ---
---------------------
-- Rules are evaluated top to bottom; last match wins.

-- Floating windows: orange border
hl.window_rule({ match = { float = true }, border_color = "rgba(ff9500ee)" })

-- Special workspace: purple border, transparency
hl.window_rule({ match = { workspace = "special:magic" }, border_color = "rgba(b388ffee)" })
hl.window_rule({ match = { workspace = "special:magic" }, opacity = "0.7" })

-- Floating on magic: orange overrides purple
hl.window_rule({ match = { float = true, workspace = "special:magic" }, border_color = "rgba(ff9500ee)" })

-- Picture-in-Picture: floating, pinned, bottom-right corner
hl.window_rule({
    match             = { title = "^Picture-in-Picture$" },
    float             = true,
    size              = { 480, 270 },
    move              = { "monitor_w-window_w-10", "35" },
    pin               = true,
    no_anim           = true,
    keep_aspect_ratio = true,
})

-- Clipse window via Ghostty
hl.window_rule({ match = { class = "(ghostty.clipse)" }, float = true, size = { 622, 600 } })

-- Emoji picker via Ghostty
hl.window_rule({ match = { class = "(ghostty.emoji)" }, float = true, size = { 622, 400 }, center = true })

-- Claude Code floating terminal
hl.window_rule({ match = { class = "(ghostty.claude)" }, float = true, size = { 900, 600 }, center = true })

-- Nautilus file manager: floating, centered
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, float = true, size = { 700, 500 }, center = true })

-- File picker dialogs (e.g. Chromium "Open File")
hl.window_rule({ match = { title = "^(Open File)$" }, float = true, size = { 700, 500 }, center = true })

-- Main tmux session in special workspace
hl.window_rule({ match = { class = "(ghostty.main)" }, workspace = "special:magic silent" })

-- Hyprland share picker / Discord / ProtonVPN
hl.window_rule({ match = { class = "^(hyprland-share-picker)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(discord)$" }, float = true, size = { 722, 600 } })
hl.window_rule({ match = { class = "^(protonvpn-app)$" }, float = true })

-- Unifi camera dashboard
hl.window_rule({ match = { title = "^(Camera Dashboard)$" }, float = true, center = true })

-- Polkit popup
hl.window_rule({ match = { class = "^(hyprpolkitagent)$" }, float = true, center = true })

-- Ghostty opacity
hl.window_rule({ match = { class = "^(ghostty)$" }, opacity = "0.9 1.0" })

--------------------
---- LAYER RULES ---
--------------------
hl.layer_rule({ match = { namespace = "quickshell" }, blur = true })
