hl.config({
	input = {
		kb_layout     = "pl",
		kb_variant    = "",
		kb_model      = "",
		kb_rules      = "",

		accel_profile = "adaptive",

		follow_mouse  = 1,
		mouse_refocus = false,

		sensitivity   = 0, -- -1.0 - 1.0, 0 means no modification

		touchpad      = {
			natural_scroll          = true,
			scroll_factor           = 0.2,
			disable_while_typing    = false,
			middle_button_emulation = false,
		},
	},
})

hl.device({
	name = "kb066-mac-keyboard",
	kb_options = "altwin:swap_lalt_lwin",
})

hl.gesture({
	fingers   = 3,
	direction = "horizontal",
	action    = "workspace",
})
