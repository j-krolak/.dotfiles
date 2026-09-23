-- hl.exec_cmd() here runs immediately (unlike hl.dsp.exec_cmd(), which builds
-- a dispatcher for hl.bind()).
hl.on("hyprland.start", function()
    -- Make the Wayland session available to D-Bus, then expose Secret Service
    -- for browsers, Electron apps, and other libsecret clients.
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("voxtype daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("XDG_MENU_PREFIX=arch- kbuildsycoca6")
    hl.exec_cmd("sway-audio-idle-inhibit")
    hl.exec_cmd("wayscriber --daemon")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)
