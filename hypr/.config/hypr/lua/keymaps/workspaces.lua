local vars     = require("lua.core.variables")
local bind     = require("lua.core.bind")
local monitors = vars.monitors

local keymaps  = {
	{
		name = "Add to scratchpad",
		keymap = "SUPER + C",
		action = hl.dsp.window.move({ workspace = "special:magic" }),
	},
	{
		name = "Toggle scratchpad",
		keymap = "SUPER + S",
		action = hl.dsp.workspace.toggle_special("magic"),
	},
	{
		name = "Next workspace",
		keymap = "CTRL + ALT + right",
		action = hl.dsp.focus({ workspace = "e+1" }),
	},
	{
		name = "Previous workspace",
		keymap = "CTRL + ALT + left",
		action = hl.dsp.focus({ workspace = "e-1" }),
	}
}


for i = 1, 8 do
	table.insert(keymaps,
		{ name = "Switch to workspace " .. i, keymap = "SUPER + " .. i, action = hl.dsp.focus({ workspace = i }) })

	-- moves window to workspace i without switching to it
	table.insert(keymaps, {
		name   = "Move window to workspace " .. i .. " (silent)",
		keymap = "ALT + SHIFT + " .. i,
		action = hl.dsp.window.move({ workspace = i }),
	})
end

-- same as above but mapped to non-matching workspace numbers (1->1, 2->3, 3->5, 4->7)
local altShiftTargets = { { 1, 1 }, { 2, 3 }, { 3, 5 }, { 4, 7 } }
for _, pair in ipairs(altShiftTargets) do
	table.insert(keymaps, {
		name   = "Move window to workspace " .. pair[2] .. " (silent)",
		keymap = "ALT + CTRL + " .. pair[1],
		action = hl.dsp.window.move({ workspace = pair[1], follow = false }),
	})
end

-- TODO: check it
bind.extend(keymaps, bind.dual(
	"Swap active workspaces between monitors",
	"BACKSLASH",
	hl.exec("hyprctl dispatch swapactiveworkspaces " .. monitors.a .. " " .. monitors.b)
))

table.insert(keymaps,
	{
		name = "Move window to monitor " .. monitors.a,
		keymap = "ALT + 1",
		action = hl.exec(
			"hyprctl dispatch movewindow mon:0")
	})
table.insert(keymaps,
	{
		name = "Move window to monitor " .. monitors.b,
		keymap = "ALT + 2",
		action = hl.exec(
			"hyprctl dispatch movewindow mon:1")
	})

-- swap keyboard focus to the other monitor
table.insert(keymaps, {
	name   = "Focus other monitor",
	keymap = "ALT + O",
	action = hl.exec("hyprctl dispatch focusmonitor " .. monitors.a .. " && hyprctl dispatch focusmonitor " .. monitors.b),
})
table.insert(keymaps, {
	name   = "Focus other monitor",
	keymap = "ALT + I",
	action = hl.exec("hyprctl dispatch focusmonitor " .. monitors.b .. " && hyprctl dispatch focusmonitor " .. monitors.a),
})

return keymaps
