import QtQuick
import Quickshell.Hyprland

// Mirrors waybar's "hyprland/workspaces" module in its simplest, classic
// form: one small dot per workspace, same size throughout, just colored
// differently for whichever one is active. Click a dot to switch to it.
// (Scroll-to-switch lives on the bar as a whole - see Bar.qml - not here,
// since scrolling over these tiny dots specifically isn't the point.)
Row {
    spacing: 4

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

            // The dot itself is tiny, so give the click/hover target a
            // bit more breathing room around it. A fixed size here (not
            // "parent.height") matters: the Row this sits in has no
            // explicit height of its own, so it takes its height from
            // its tallest child - binding back to "parent.height" would
            // make that circular and everything collapses to 0.
            implicitWidth: 16
            implicitHeight: Theme.fontSize + 6

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: width
                radius: width / 2
                color: wrapper.modelData.active ? Theme.accent
                    : hoverArea.containsMouse ? Theme.foreground
                    : Theme.muted
                // Inactive, unhovered dots fade out further still, so the
                // active one reads as clearly "the" workspace at a glance.
                opacity: wrapper.modelData.active || hoverArea.containsMouse ? 1 : 0.4
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
