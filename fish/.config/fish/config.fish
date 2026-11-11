set -gx EDITOR nvim
if set -q SSH_CONNECTION
    set -gx EDITOR vim
end
set -gx MANPAGER 'nvim +Man!'
set -gx TERM xterm-256color

# Qemu
set -gx SDL_VIDEODRIVER wayland

# Android sdk
set -gx ANDROID_HOME $HOME/Android/Sdk

# ROCM
set -gx ROCM_PATH /opt/rocm
set -gx HSA_OVERRIDE_GFX_VERSION 11.0.0

# pnpm
set -gx PNPM_HOME $HOME/.local/share/pnpm

# bun
set -gx BUN_INSTALL $HOME/.bun

# fish_add_path skips directories that don't exist and never duplicates entries.
fish_add_path -g /usr/local/bin $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin $HOME/.bend/bin $BUN_INSTALL/bin $PNPM_HOME
fish_add_path -ga $HOME/.npm-global/bin $PNPM_HOME/bin $HOME/MATLAB25/bin $HOME/.dotnet/tools

# TTY1 login starts Hyprland
if status is-login
    if test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
        exec start-hyprland
    end
end

if status is-interactive
    set -g fish_greeting

    alias gcc "gcc -Wall -Wextra -Wpedantic"
    alias remove-orphans "sudo pacman -Qdtq | sudo pacman -Rns -"
    alias governor "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

    alias v nvim

    alias g git
    alias gc "git commit -m"
    alias gst "git status"
    alias gd "git diff"
    alias lg lazygit

    alias dc "docker compose"

    starship init fish | source

    # Blank line between commands, but not before the first prompt. fish redraws the
    # prompt several times at startup, so a flag set inside fish_prompt is unreliable.
    function __mark_cmd_ran --on-event fish_postexec
        if string match -qr '^(clear|reset)(\s|$)' -- "$argv"
            set -e __cmd_ran
        else
            set -g __cmd_ran 1
        end
    end
    bind \cl 'set -e __cmd_ran; commandline -f clear-screen'
    functions -c fish_prompt __prompt_inner
    function fish_prompt
        set -q __cmd_ran; and echo
        __prompt_inner
    end

    zoxide init fish | source
    fnm env --use-on-cd --shell fish | source

    test -f /opt/miniconda3/etc/fish/conf.d/conda.fish; and source /opt/miniconda3/etc/fish/conf.d/conda.fish
end

