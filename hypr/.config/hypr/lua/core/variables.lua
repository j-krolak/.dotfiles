-- Shared constants used across modules.
-- require("lua.core.variables") to pull these in - never rely on globals,
-- since each require() runs in its own scope.

return {
  -- Per machine: iHD on Intel, radeonsi on AMD, nvidia on NVIDIA.
  va_driver = "radeonsi",

  -- Per machine: true on the desktop (single external monitor, no laptop
  -- panel), false on the laptop (eDP-1 + external HDMI monitor).
  single_monitor = true,

  monitors = {
    a = "eDP-1",
    b = "HDMI-A-1",
  },

  programs = {
    terminal = "kitty",
    browser  = "zen-browser",
    editor   = "code",
    files    = "dolphin",
    music    = "spotify",
  },
}
