pragma Singleton
import QtQuick

// Same trick as CalendarState: the bar widget (Taskwarrior.qml) and the
// overview popup (TaskwarriorOverview.qml, its own top-level window under
// shell.qml's ShellRoot) are independent windows with no parent/child
// relationship, so a shared singleton is the simplest way for a click on
// one to toggle the other.
QtObject {
    property bool visible: false
    // Screen-space x of the widget's bottom-left corner, so the popup
    // (a separate top-level window) can open directly below whichever
    // icon was actually clicked instead of at a fixed spot.
    property real popupX: 0

    // Fired by the overview after it marks a task done, so the bar
    // widget's pending count re-polls immediately instead of waiting
    // for its own 30s timer.
    signal tasksChanged()
}
