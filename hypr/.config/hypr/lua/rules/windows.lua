hl.window_rule({
	name  = "xdg-desktop-portal-gtk-float",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
})

hl.window_rule({
	name  = "picture-in-picture-float",
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
})

hl.window_rule({
	match = { float = true },
	border_size = 2,
	rounding = 20,
})

hl.window_rule({
	match = { pin = true },
	border_color = "#3994bc",
})
