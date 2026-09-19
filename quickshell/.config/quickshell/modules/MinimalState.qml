pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Receiving end of hypr/lua/core/minimal.lua, which emits one Hyprland custom
// IPC event: "minimal,mode on|off". Bar.qml watches `active` to hide itself.
//
// Nothing else lives here - the cursor ring and click ripples belong to
// presenting mode, which has its own state in PresentState.qml.
QtObject {
    id: root

    property bool active: false

    readonly property Connections events: Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "custom")
                return

            const separator = event.data.indexOf(",")
            if (separator < 0 || event.data.substring(0, separator) !== "minimal")
                return

            const args = event.data.substring(separator + 1).split(" ")
            if (args[0] === "mode")
                root.active = args[1] === "on"
        }
    }
}
