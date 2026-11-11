pragma Singleton
import QtQuick
import Quickshell

// Keeps at most one bar popup open: each popup window calls closeAll() with its
// own name when it opens, which closes all the others. Clicking outside already
// closes a popup (a full-screen MouseArea behind each card); the bar also calls
// it, since those windows do not cover the bar.
Singleton {
    id: root

    function closeAll(except) {
        if (except !== "Calendar") CalendarState.visible = false
        if (except !== "Agents") AgentsState.visible = false
        if (except !== "Markets") MarketsState.visible = false
        if (except !== "Battery") BatteryState.visible = false
        if (except !== "Notifications") NotificationsState.visible = false
        if (except !== "Power") PowerState.visible = false
        if (except !== "Wallpaper") WallpaperState.visible = false
    }
}
