return {
	{
		name = "Screenshot area, frozen screen, to clipboard",
		keymap = "SUPER + SHIFT + S",
		action = hl.exec('~/.config/hypr/scripts/screenshot_area.sh --freeze')
	},
	{
		name = "Screenshot area, to clipboard",
		keymap = "ALT + S",
		action = hl.exec('~/.config/hypr/scripts/screenshot_area.sh')
	},
	{
		name = "Screenshot area with filename label, to clipboard",
		keymap = "ALT + SHIFT + S",
		action = hl.exec('~/.config/hypr/scripts/screenshot_annotated.sh')
	},
	{
		name = "Start screen recording",
		keymap = "ALT + SHIFT + V",
		action = hl.exec("~/.config/hypr/scripts/record_video.sh")
	},
	{
		name = "Start gif recording",
		keymap = "ALT + SHIFT + G",
		action = hl.exec("~/.config/hypr/scripts/record_gif.sh")
	},
	{
		name = "Stop recording",
		keymap = "ALT + SHIFT + E",
		action = hl.exec("~/.config/hypr/scripts/stop_recording.sh")
	},

	{
		name = "clipse",
		keymap = "SUPER + V",
		action = hl.exec("[float; size 622 652] kitty --class clipse -e clipse")
	}
}
