local minimal    = require("lua.core.minimal")
local presenting = require("lua.core.presenting")
local zoom       = require("lua.core.zoom")

return {
	{
		name = "Toggle minimal mode (no bar, wider gaps)",
		keymap = "SUPER + SHIFT + Z",
		action = function() minimal.toggle() end
	},
	{
		name = "Toggle presenting mode (cursor ring, click ripples)",
		keymap = "SUPER + SHIFT + P",
		action = function() presenting.toggle() end
	},
	{
		name = "Zoom in (hold)",
		keymap = "SUPER + EQUAL",
		action = function() zoom.hold(1) end,
		on_release = function() zoom.release() end
	},
	{
		name = "Zoom out (hold)",
		keymap = "SUPER + MINUS",
		action = function() zoom.hold(-1) end,
		on_release = function() zoom.release() end
	},
	{
		name = "Reset zoom",
		keymap = "SUPER + 0",
		action = function() zoom.reset() end
	},
}
