local vars = require("lua.core.variables")

-- HDMI-A-1 stays pinned at a fixed 0x0 origin at all times so its global
-- coordinate space never shifts when eDP-1 is enabled/disabled (lid switch).
-- If HDMI moved (e.g. via position = "auto"), windows already tiled there
-- would keep their old global coordinates and end up misplaced.
hl.monitor({ output = vars.monitors.b, mode = "preferred@highrr", position = "0x0", scale = 1 })
hl.monitor({ output = vars.monitors.a, mode = "1920x1080@60", position = "auto-right", scale = 1 })

-- Lid switch handling lives in lua/core/lid.lua (delegates to scripts/lid.sh).
