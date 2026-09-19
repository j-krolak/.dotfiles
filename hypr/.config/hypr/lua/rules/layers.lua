-- The global "layers" animation (see core/animations.lua) smoothly
-- animates layer-shell surfaces resizing/appearing - that's what was
-- making the quickshell auto-hide bar look like it slides in and out
-- even though the QML itself no longer animates anything. This turns
-- animation off just for that one surface, without touching layer
-- animations anywhere else (rofi, notifications, etc.).
hl.layer_rule({
    match = { namespace = "quickshell" },
    no_anim = true,
})

-- The presenting overlay redraws on every cursor sample; animating it in
-- and out would fight with the ripples it draws.
hl.layer_rule({
    match = { namespace = "quickshell:present" },
    no_anim = true,
})

hl.layer_rule({
    match = { namespace = "quickshell:blur" },
    blur = true,
    ignore_alpha = 0.2,
})

-- Rofi (launched via ~/.local/bin/launch_rofi.sh) runs as its own
-- layer-shell surface under namespace "rofi" - same blur treatment as the
-- quickshell popups above, so the launcher matches the rest of the blurred
-- surfaces instead of sitting on a plain dark box.
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.2,
})
