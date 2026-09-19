local bind = require("lua.core.bind")

local keymaps = {
	{
		name = "Close window",
		keymap = "ALT + Q",
		action = hl.dsp.window.close()
	},
	{
		name = "Close window",
		keymap = "ALT + F4",
		action = hl.dsp.window.close()
	},

	{
		name = "Toggle floating",
		keymap = "ALT + V",
		action = function()
			local w = hl.get_active_window()
			if w == nil then return end

			hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
			hl.dispatch(hl.dsp.window.resize({ x = 800, y = 500 }))
			hl.dispatch(hl.dsp.window.center())
		end
	},
	{
		name = "Toggle pin",
		keymap = "ALT + P",
		action = hl.dsp.window.pin({ action = "toggle" })
	},

	{
		name = "Toggle split (dwindle layout only)",
		keymap = "ALT + Y",
		action = hl.dsp.layout("togglesplit")
	},

	{
		name = "Focus left",
		keymap = "SUPER + SHITFT + H",
		action = hl.dsp.focus({ direction = "left" })
	},
	{
		name = "Focus right",
		keymap = "SUPER + SHIFT + L",
		action = function()
			hl.dsp.focus({ direction = "right" })
		end
	},
	{
		name = "Focus up",
		keymap = "SUPER + SHIFT + K",
		action = hl.dsp.focus({ direction = "up" })
	},
	{
		name = "Focus down",
		keymap = "SUPER + SHIFT + J",
		action = hl.dsp.focus({ direction = "down" })
	},

	{
		name = "Drag window",
		keymap = "ALT + mouse:272",
		action = hl.dsp.window.drag(),
		opts = { mouse = true }
	},
	{
		name = "Resize window",
		keymap = "ALT + mouse:273",
		action = hl.dsp.window.resize(),
		opts = { mouse = true }
	},
	{
		name = "Fullscreen",
		keymap = "SUPER + F",
		action = hl.dsp.window.fullscreen()
	},

}

-- TODO: make resing windows work
-- no typed hl.dsp helper for resizeactive yet
bind.extend(keymaps,
	bind.dual("Resize active window +40", "K", hl.dsp.window.resize({ x = 100, y = 40 }), { repeating = true }))
bind.extend(keymaps,
	bind.dual("Resize active window -40", "J", hl.dsp.window.resize({ x = -40, y = 0 }), { repeating = true }))

return keymaps
