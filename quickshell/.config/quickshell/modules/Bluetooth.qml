import QtQuick
import Quickshell.Bluetooth

// No waybar equivalent for this one - nothing showed Bluetooth status
// before. Click to power the adapter on/off.
StatusItem {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property int connectedCount: adapter
        ? adapter.devices.values.filter(d => d.connected).length
        : 0

    visible: adapter !== null

    tint: (adapter && adapter.enabled) ? Theme.barForeground : Theme.barMuted
    icon: (adapter && adapter.enabled) ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
    label: connectedCount > 0 ? String(connectedCount) : ""

    onClicked: {
        if (adapter)
            adapter.enabled = !adapter.enabled
    }
}
