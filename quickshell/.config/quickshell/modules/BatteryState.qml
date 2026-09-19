pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

// Same trick as CalendarState/TaskwarriorState: the bar widget
// (Battery.qml) and the popup (BatteryOverview.qml, its own top-level
// window under shell.qml's ShellRoot) are independent windows with no
// parent/child relationship, so a shared singleton is the simplest way for
// a click on one to toggle the other.
//
// The low-battery warning lives here rather than in Battery.qml because
// the bar is instantiated once per monitor - it would fire one
// notification per screen from there.
QtObject {
    id: root

    property bool visible: false

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool discharging: device !== null
        && device.isLaptopBattery
        && device.state !== UPowerDeviceState.Charging
    // UPower reports this as a 0-1 fraction, not 0-100.
    readonly property real percent: device ? device.percentage * 100 : 0

    // onCriticalChanged only runs on an actual transition, so this fires
    // once on the way down; plugging in and unplugging re-arms it.
    readonly property bool critical: discharging && percent <= 10
    onCriticalChanged: if (critical) lowBatteryNotify.running = true

    // Goes out over DBus and comes straight back into our own
    // notification server (NotificationsState.qml), so it shows up as a
    // toast and stays in the history panel like anything else.
    readonly property Process lowBatteryNotify: Process {
        command: ["notify-send", "-u", "critical", "-a", "Battery",
            "Battery low", Math.round(root.percent) + "% left - plug in the charger"]
    }
}
