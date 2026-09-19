if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
	exec start-hyprland
fi


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
