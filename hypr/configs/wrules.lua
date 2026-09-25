--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
  match = { class = "^(rofi)$" },
  stay_focused = true
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Swaync
hl.layer_rule({
    name = "blur-swaync-cc",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.5
})

hl.layer_rule({
    name = "blur-swaync-notif",
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0.5
})

-- Spotify
hl.window_rule({
    name  = "spotify-special-ws",
    match = { class = "spotify" },
    workspace = "special:music silent",
})
