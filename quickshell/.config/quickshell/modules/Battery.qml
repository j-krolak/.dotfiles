import QtQuick
import Quickshell.Services.UPower

// Like waybar's "battery" module, but drawn like macOS's battery glyph
// (outlined body, proportional fill, small nub) instead of an icon - the
// icon-theme battery SVGs get busy at this size. On a desktop with no
// battery this swaps to a plain power button instead of hiding - clicking
// it opens PowerOverview.qml (log out / shut down) rather than
// BatteryOverview.qml.
StatusItem {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool hasBattery: device !== null && device.isLaptopBattery
    readonly property bool charging: device && device.state === UPowerDeviceState.Charging
    // UPower reports this as a 0-1 fraction, not 0-100.
    readonly property real percent: device ? device.percentage * 100 : 0
    readonly property bool low: hasBattery && !charging && percent <= 10

    visible: true
    icon: hasBattery ? "" : "system-shutdown-symbolic"
    label: hasBattery ? Math.round(percent) + "%" : ""
    tint: low ? Theme.urgent : charging ? Theme.good : Theme.barForeground
    iconVisible: !hasBattery
    extraWidth: hasBattery ? 24 : 0

    Item {
        visible: root.hasBattery
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: 22
        height: 11

        Rectangle {
            id: body
            width: 20
            height: parent.height
            radius: 3
            color: "transparent"
            border.color: root.low ? Theme.urgent : root.charging ? Theme.good : Theme.barMuted
            border.width: 1

            Rectangle {
                x: 2
                y: 2
                height: parent.height - 4
                width: Math.max(2, (parent.width - 4) * root.percent / 100)
                radius: 1.5
                color: root.low ? Theme.urgent : root.charging ? Theme.good : Theme.barForeground
            }
        }

        Rectangle {
            x: 20.5
            anchors.verticalCenter: parent.verticalCenter
            width: 1.5
            height: 4
            radius: 0.75
            color: Theme.barMuted
        }
    }

    onClicked: {
        if (hasBattery) {
            BatteryState.visible = !BatteryState.visible
        } else {
            PowerState.visible = !PowerState.visible
        }
    }
}
