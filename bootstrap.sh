#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

sudo pacman -S --needed - < packages/pacman.txt
command -v paru >/dev/null && paru -S --needed - < packages/aur.txt

# tmux.conf loads tpm from ~/.tmux, not ~/.config/tmux.
[ -d ~/.tmux/plugins/tpm ] || git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

stow --restow --target="$HOME" anki claude fastfetch fish herdr ghostty hypr nvim \
	quickshell rofi scripts tmux yazi

# voxtype/wayscriber/hyprpolkitagent left out: autostart.lua starts them, and
# their units want graphical-session.target, never reached without uwsm.
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now NetworkManager bluetooth

[ "$SHELL" = "$(command -v fish)" ] || chsh -s "$(command -v fish)"

cat <<'EOF'

Set by hand: va_driver + VA-API package, monitors.lua outputs,
Wallpapers (gitignored).
Then log in on TTY1.
EOF
