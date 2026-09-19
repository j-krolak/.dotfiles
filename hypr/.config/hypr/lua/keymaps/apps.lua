local vars         = require("lua.core.variables")
local programs     = vars.programs

local appLaunchers = {
	T = programs.terminal,
	Z = programs.browser,
	D = programs.files,
}

local keymaps      = {
	{
		name = "Terminal (alt)",
		keymap = "ALT + SHIFT + T",
		action = hl.exec(programs.terminal)
	},

	{
		name = "Color picker",
		keymap = "SUPER + P",
		action = hl.exec("hyprpicker -a")
	},
	{
		name = "App launcher",
		keymap = "ALT + W",
		action = hl.exec("~/.local/bin/launch_rofi.sh -show drun -show-icons")
	},

	{
		name = "Wallpaper picker",
		keymap = "SUPER + B",
		action = hl.exec("qs ipc call wallpaper toggle")
	},
	{
		name = "Restart quickshell",
		keymap = "SUPER + SHIFT + W",
		action = hl.exec("pkill -x quickshell; quickshell &")
	},

	{
		name = "Lock screen",
		keymap = "ALT + CTRL + L",
		action = hl.exec("pidof hyprlock || hyprlock")
	},
	{
		name = "Power menu",
		keymap = "ALT + CTRL + DELETE",
		action = hl.exec("~/.local/bin/powermenu.sh")
	},

}

for key, program in pairs(appLaunchers) do
	table.insert(keymaps, { name = "Launch " .. program, keymap = "SUPER + " .. key, action = hl.exec(program) })
end

return keymaps
