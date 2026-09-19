local bind = require("lua.core.bind")

---- laptop Fn media keys
local keymaps = {
	{
		name = "Volume up",
		keymap = "XF86AudioRaiseVolume",
		action = hl.exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
		opts = { repeating = true }
	},
	{
		name = "Volume down",
		keymap = "XF86AudioLowerVolume",
		action = hl.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
		opts = { repeating = true }
	},
	{
		name = "Mute",
		keymap = "XF86AudioMute",
		action = hl.exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
	},
	{
		name = "Mic mute",
		keymap = "XF86AudioMicMute",
		action = hl.exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
	},
	{
		name = "Brightness up",
		keymap = "XF86MonBrightnessUp",
		action = hl.exec("brightnessctl set +5%"),
		opts = { repeating = true }
	},
	{
		name = "Brightness down",
		keymap = "XF86MonBrightnessDown",
		action = hl.exec("brightnessctl set 5%-"),
		opts = { repeating = true }
	},
	{
		name = "Previous track",
		keymap = "ALT + CTRL + E",
		action = hl.exec("playerctl --player=spotify previous")
	},
	{
		name = "Next track",
		keymap = "ALT + CTRL + R",
		action = hl.exec("playerctl --player=spotify next")
	},
	{
		name = "Lock screen",
		keymap = "SUPER + L",
		action = hl.exec("loginctl lock-session && hyprctl dispatch dpms off")
	}
}


bind.extend(keymaps, bind.dual("Play/pause",
	"P", hl.exec("playerctl --player=spotify play-pause")))


return keymaps
