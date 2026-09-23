local vars = require("lua.core.variables")

-- HDMI-A-1 stays pinned at a fixed 0x0 origin at all times so its global
-- coordinate space never shifts when eDP-1 is enabled/disabled (lid switch).
-- If HDMI moved (e.g. via position = "auto"), windows already tiled there
-- would keep their old global coordinates and end up misplaced.
-- "preferred@highrr" wasn't valid Hyprland syntax - predefined mode keywords
-- (preferred/highres/highrr/maxwidth) can't be combined, only one at a time.
-- That invalid string silently fell back to the panel's EDID-preferred mode
-- (59.95Hz here) instead of the 75Hz this monitor actually supports.
-- "highrr" alone isn't right either - it picks the single highest refresh
-- rate in the whole mode list regardless of resolution (1024x768@75 on this
-- monitor). "highres" gets both: native resolution, at its best refresh rate.
hl.monitor({ output = vars.monitors.b, mode = "highres", position = "0x0", scale = 1 })

if not vars.single_monitor then
	hl.monitor({ output = vars.monitors.a, mode = "1920x1080@60", position = "auto-right", scale = 1 })
end

-- Lid switch handling lives in lua/core/lid.lua (delegates to scripts/lid.sh).
