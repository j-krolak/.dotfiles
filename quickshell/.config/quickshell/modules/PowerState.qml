pragma Singleton
import QtQuick

// Same trick as BatteryState/CalendarState/TaskwarriorState: the bar widget
// (Battery.qml, on desktops with no battery) and the popup
// (PowerOverview.qml, its own top-level window under shell.qml's ShellRoot)
// are independent windows with no parent/child relationship, so a shared
// singleton is the simplest way for a click on one to toggle the other.
QtObject {
    id: root

    property bool visible: false
}
