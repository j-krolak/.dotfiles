pragma Singleton
import QtQuick

// Holds whether the full-screen wallpaper picker (WallpaperPickerOverview.qml)
// is open. It's only ever toggled from outside QML - the "qs ipc call
// wallpaper toggle" IPC target in that file, bound to a Hyprland keybind -
// but still lives in its own singleton rather than as a plain property on
// the window, matching CalendarState/TaskwarriorState's pattern for
// cross-window state.
QtObject {
    property bool visible: false
}
