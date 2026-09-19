hl.config({
    debug = {
        suppress_errors = true,
    },

    general = {
        gaps_in       = 5,
        gaps_out      = 10,
        border_size   = 0,

        layout        = "dwindle",
        allow_tearing = false,

        col           = {
            active_border   = "#2a2b2c",
            inactive_border = "#2a2b2c",
        },
    },

    decoration = {
        inactive_opacity = 1,
        rounding = 14,
        blur = {
            enabled           = true,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = false,
        },
    },

    cursor = {
        inactive_timeout    = 3,
        no_hardware_cursors = 0,

    },

    dwindle = {
        preserve_split = true,
        -- NOTE: the old config also set `pseudotile = true`, but that key no
        -- longer exists in Hyprland 0.55's dwindle schema, so it's dropped here.
    },

    ecosystem = {
        no_update_news = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_splash_rendering = true,
        disable_hyprland_logo    = true,
    },
})
