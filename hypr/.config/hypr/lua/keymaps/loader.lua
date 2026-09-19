-- Collects keymap specs from lua/keymaps/*, binds them all, and writes a
-- cheatsheet file browsable via rofi (SUPER + /), grouped under section
-- headers and styled with the same theme as the app launcher (ALT + W).

local bind = require("lua.core.bind")

local sections = {
	{ label = "Apps",        keymaps = require("lua.keymaps.apps") },
	{ label = "Windows",     keymaps = require("lua.keymaps.windows") },
	{ label = "Workspaces",  keymaps = require("lua.keymaps.workspaces") },
	{ label = "Media",       keymaps = require("lua.keymaps.media") },
	{ label = "Voxtype",     keymaps = require("lua.keymaps.voxtype") },
	{ label = "Screenshots", keymaps = require("lua.keymaps.screenshots") },
	{ label = "Modes",       keymaps = require("lua.keymaps.modes") },
	{ label = "Wayscriber",  keymaps = require("lua.keymaps.wayscriber") },
}

local entries = {}
for _, section in ipairs(sections) do
	bind.extend(entries, section.keymaps)
end

local cheatsheetPath = os.getenv("HOME") .. "/.cache/hypr/keymaps_cheatsheet.txt"
local rofiTheme = os.getenv("HOME") .. "/.config/rofi/launchers/type-1/rofi-style.rasi"
table.insert(sections, {
	label = "Help",
	keymaps = {
		{
			name   = "Show this cheatsheet",
			keymap = "SUPER + SLASH",
			action = hl.exec(
				"rofi -dmenu -markup-rows -p 'Keymaps' -i"
				.. " -theme " .. rofiTheme
				.. " -theme-str 'window {width: 780px;} listview {lines: 16;}'"
				.. " < " .. cheatsheetPath
			),
		},
	},
})
bind.extend(entries, sections[#sections].keymaps)

local seenAt = {}
for _, e in ipairs(entries) do
	if seenAt[e.keymap] then
		error(("keymap collision on %q: %q and %q"):format(e.keymap, seenAt[e.keymap], e.name))
	end
	seenAt[e.keymap] = e.name
end

for _, e in ipairs(entries) do
	hl.bind(e.keymap, e.action, e.opts)
	-- A keymap may also act on release (held-down actions, e.g. the zoom
	-- ramp). That's a second Hyprland bind on the same combo, but still one
	-- entry here - it isn't a separate thing to look up in the cheatsheet,
	-- and the collision check above should still see the combo only once.
	if e.on_release then
		hl.bind(e.keymap, e.on_release, { release = true })
	end
end

os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hypr")
local f = io.open(cheatsheetPath, "w")
if f then
	for _, section in ipairs(sections) do
		f:write(string.format("<span weight='bold' foreground='#7aa2f7'>%s</span>\n", section.label:upper()))
		for _, e in ipairs(section.keymaps) do
			f:write(string.format(
				"<b>%-22s</b>  <span alpha='75%%'>%s</span>\n",
				e.keymap, e.name
			))
		end
	end
	f:close()
end
