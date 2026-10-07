#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

sudo pacman -S --needed - < packages/pacman.txt
command -v paru >/dev/null && paru -S --needed - < packages/aur.txt

# KEEP_ZSHRC stops the installer replacing the stowed ~/.zshrc; CHSH/RUNZSH
# keep it from grabbing the shell mid-script.
[ -d ~/.oh-my-zsh ] || KEEP_ZSHRC=yes CHSH=no RUNZSH=no \
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

omz=~/.oh-my-zsh/custom
[ -d "$omz/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k "$omz/themes/powerlevel10k"
[ -d "$omz/plugins/zsh-syntax-highlighting" ] || git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$omz/plugins/zsh-syntax-highlighting"
# tmux.conf loads tpm from ~/.tmux, not ~/.config/tmux.
[ -d ~/.tmux/plugins/tpm ] || git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

stow --restow --target="$HOME" anki claude fastfetch herdr hypr kitty nvim \
	quickshell rofi scripts tmux yazi zotero zsh

# voxtype/wayscriber/hyprpolkitagent left out: autostart.lua starts them, and
# their units want graphical-session.target, never reached without uwsm.
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now NetworkManager bluetooth

[ "$SHELL" = "$(command -v zsh)" ] || chsh -s "$(command -v zsh)"

cat <<'EOF'

Set by hand: va_driver + VA-API package, monitors.lua outputs,
Zotero profile dir name, wallpapers (gitignored).
Then log in on TTY1.
EOF
