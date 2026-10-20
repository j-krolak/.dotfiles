import QtQuick
import Quickshell.Hyprland

// Mirrors waybar's "hyprland/workspaces" module in its simplest, classic
// form: one small Greek letter per workspace (α, β, γ, ...), colored
// differently for whichever one is active. Click a letter to switch to it.
// (Scroll-to-switch lives on the bar as a whole - see Bar.qml - not here,
// since scrolling over these letters specifically isn't the point.)
Row {
    spacing: 4

    readonly property var letters: ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ"]

    Repeater {
        // Hyprland.workspaces is a live list of HyprlandWorkspace objects,
        // kept in sync automatically over Hyprland's IPC socket. Special
        // workspaces (scratchpads, ...) are filtered out, same as waybar
        // does by default.
        model: Hyprland.workspaces.values.filter(w => !w.name.startsWith("special"))

        // Quickshell exposes each list item to the delegate as "modelData".
        delegate: Item {
            id: wrapper
            required property var modelData
            readonly property bool occupied: Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === modelData.id)

            // The letter is small, so give the click/hover target a
            // bit more breathing room around it. A fixed size here (not
            // "parent.height") matters: the Row this sits in has no
            // explicit height of its own, so it takes its height from
            // its tallest child - binding back to "parent.height" would
            // make that circular and everything collapses to 0.
            implicitWidth: 24
            implicitHeight: Theme.fontSize + 6

            Text {
                anchors.centerIn: parent
                text: wrapper.modelData.id >= 1 && wrapper.modelData.id <= letters.length
                    ? letters[wrapper.modelData.id - 1]
                    : wrapper.modelData.id
                font.family: Theme.serifFamily
                font.pixelSize: Theme.fontSize + 1
                color: wrapper.occupied ? Theme.foreground : Theme.muted
                opacity: wrapper.occupied || wrapper.modelData.active ? 1 : 0.8
            }

            Rectangle {
                visible: wrapper.modelData.active
                anchors.centerIn: parent
                width: 24
                height: 24
                color: "transparent"
                border.color: "#4a68b0"
                border.width: 1
                opacity: 1
            }

            Rectangle {
                visible: wrapper.modelData.active
                anchors.centerIn: parent
                width: 18
                height: 18
                color: "transparent"
                border.color: "#4a68b0"
                border.width: 1
                opacity: 0.7
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // Not wrapper.modelData.activate() - on this Hyprland build
                // (v0.55+, Lua-native config) the IPC dispatch endpoint only
                // accepts Lua expressions, not the classic "workspace <name>"
                // plain-text dispatcher string that activate() sends under
                // the hood, so it silently fails. Dispatch through the
                // hl.dsp.* namespace directly instead - see Bar.qml's
                // scroll-to-switch handler for the same workaround.
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wrapper.modelData.name}" })`)
            }
        }
    }
}
