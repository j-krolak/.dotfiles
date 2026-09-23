import QtQuick
import Quickshell.Services.UPower

// Like waybar's "battery" module, but on a desktop with no battery this
// swaps to a plain power button instead of hiding - clicking it opens
// PowerOverview.qml (log out / shut down) rather than BatteryOverview.qml.
Text {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool hasBattery: device !== null && device.isLaptopBattery
    readonly property bool charging: device && device.state === UPowerDeviceState.Charging
    // UPower reports this as a 0-1 fraction, not 0-100.
    readonly property real percent: device ? device.percentage * 100 : 0

    visible: true

    color: {
        if (!hasBattery) return Theme.foreground
        if (charging) return Theme.good
        if (percent <= 15) return Theme.urgent
        return Theme.foreground
    }
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: hasBattery ? (icon() + " " + Math.round(percent) + "%") : "⏻"

    function icon() {
        if (charging) return "󰂄"
        if (percent > 90) return "󰁹"
        if (percent > 70) return "󰂀"
        if (percent > 40) return "󰁾"
        if (percent > 15) return "󰁻"
        return "󰁺"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.hasBattery) {
                BatteryState.visible = !BatteryState.visible
            } else {
                PowerState.visible = !PowerState.visible
            }
        }
    }
}
