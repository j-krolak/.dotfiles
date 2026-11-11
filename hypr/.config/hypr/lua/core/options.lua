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
    rounding = 12,
    rounding_power = 4,
    dim_inactive = true,
    dim_strength = 0.06,
    shadow = {
      enabled        = true,
      range          = 35,
      render_power   = 3,
      offset         = { 0, 12 },
      color          = "rgba(00000080)",
      color_inactive = "rgba(00000040)",
    },
    wobble = {
      enabled = true,
    },
    blur = {
      enabled           = true,
      size              = 4,
      passes            = 2,
      vibrancy          = 0.2,
      noise             = 0.02,
      brightness        = 1.0,
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
