import QtQuick
import Quickshell.Bluetooth

// No waybar equivalent for this one - nothing showed Bluetooth status
// before. Click to power the adapter on/off.
Text {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property int connectedCount: adapter
        ? adapter.devices.values.filter(d => d.connected).length
        : 0

    visible: adapter !== null

    color: (adapter && adapter.enabled) ? Theme.foreground : Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: {
        if (!adapter || !adapter.enabled)
            return "󰂲"
        return connectedCount > 0 ? "󰂱 " + connectedCount : "󰂯"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.adapter)
                root.adapter.enabled = !root.adapter.enabled
        }
    }
}
