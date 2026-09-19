pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Receiving end of hypr/lua/core/presenting.lua. That module emits Hyprland
// custom IPC events while presenting mode is on:
//
//   present,cursor <x> <y>          ~120Hz, global layout coordinates
//   present,click  <x> <y> <button> once per press, 272/273/274
//   present,mode   on|off
//
// PresentOverlay.qml (one per monitor) draws from this.
QtObject {
    id: root

    property bool active: false
    property real cursorX: 0
    property real cursorY: 0

    signal clicked(real x, real y, int button)

    // Presenting mode lives inside Hyprland, so quickshell can be restarted
    // mid-presentation and would otherwise never see the "mode on" it missed.
    // Cursor samples double as a heartbeat: they turn the overlay on, and their
    // absence turns it back off if Hyprland goes away mid-stream.
    readonly property Timer heartbeat: Timer {
        interval: 500
        onTriggered: root.active = false
    }

    readonly property Connections events: Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "custom")
                return

            const separator = event.data.indexOf(",")
            if (separator < 0 || event.data.substring(0, separator) !== "present")
                return

            const args = event.data.substring(separator + 1).split(" ")
            switch (args[0]) {
            case "cursor":
                root.cursorX = Number(args[1])
                root.cursorY = Number(args[2])
                root.active = true
                root.heartbeat.restart()
                break
            case "click":
                root.clicked(Number(args[1]), Number(args[2]), Number(args[3]))
                break
            case "mode":
                root.active = args[1] === "on"
                if (root.active)
                    root.heartbeat.restart()
                else
                    root.heartbeat.stop()
                break
            }
        }
    }
}
