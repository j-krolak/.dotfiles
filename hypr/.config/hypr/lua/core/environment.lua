hl.env("GTK_THEME", "Fluent-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_DEBUG", "portals")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", require("lua.core.variables").va_driver)

-- "arch-" confirmed correct: /etc/xdg/menus/arch-applications.menu exists,
-- no plasma- menu on this system (the old config set this twice, conflicting).
hl.env("XDG_MENU_PREFIX", "arch-")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark"))
hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Fluent-Dark"))
