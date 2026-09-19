pragma Singleton
import QtQuick

// Same visibility-toggle trick as CalendarState/TaskwarriorState, plus the
// live CPU percentage: that one needs two /proc/stat samples diffed against
// each other (see SystemStats.qml's Timer), so instead of re-deriving it in
// the popup too, the bar widget - which already samples it every tick -
// just publishes its latest value here for the popup to read.
QtObject {
    property bool visible: false
    property real cpuPercent: 0
    // Screen-space x of the widget's bottom-left corner, so the popup
    // (a separate top-level window) can open directly below whichever
    // icon was actually clicked instead of at a fixed spot.
    property real popupX: 0
}
