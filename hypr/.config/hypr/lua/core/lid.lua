hl.bind("switch:on:Lid Switch", hl.exec("~/.config/hypr/scripts/lid.sh close"),
	{ locked = true })
hl.bind("switch:off:Lid Switch", hl.exec("~/.config/hypr/scripts/lid.sh open"),
	{ locked = true })
