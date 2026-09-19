import QtQuick
import Quickshell.Services.UPower

// Like waybar's "battery" module. Hides itself entirely on desktops
// that don't have a battery.
Text {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool charging: device && device.state === UPowerDeviceState.Charging
    // UPower reports this as a 0-1 fraction, not 0-100.
    readonly property real percent: device ? device.percentage * 100 : 0

    visible: device !== null && device.isLaptopBattery

    color: {
        if (charging) return Theme.good
        if (percent <= 15) return Theme.urgent
        return Theme.foreground
    }
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: device ? icon() + " " + Math.round(percent) + "%" : ""

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
        onClicked: BatteryState.visible = !BatteryState.visible
    }
}
