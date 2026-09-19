import Quickshell // for ShellRoot
import "modules"

// Quickshell only allows one top-level window per file, so once you need
// more than one (the bar, the volume/brightness OSD, notification
// popups, the calendar) they all live under a single ShellRoot here.
// Each one is a fully independent PanelWindow defined in modules/ - look
// there for the actual bar layout and behavior.
ShellRoot {
  // One Bar per connected monitor, instead of a single fixed one -
  // Variants re-creates its delegate for every entry in Quickshell.screens,
  // so plugging in (or unplugging) a second monitor adds/removes a bar
  // for it automatically.
  Variants {
    model: Quickshell.screens

    Bar {
      required property var modelData
      screen: modelData
    }
  }

  // Presenting mode's click ripples and cursor ring - one per monitor, same
  // as the bar. Hidden unless hypr/lua/core/presenting.lua says otherwise.
  Variants {
    model: Quickshell.screens

    PresentOverlay {
      required property var modelData
      screen: modelData
    }
  }

  Osd {}
  NotificationPopups {}
  Calendar {}
  TaskwarriorOverview {}
  SystemStatsOverview {}
  WallpaperPickerOverview {}
  BatteryOverview {}
  NotificationsOverview {}
}
