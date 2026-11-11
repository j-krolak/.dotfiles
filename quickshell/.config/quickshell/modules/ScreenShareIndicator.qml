import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Screen sharing indicator: a solid dot with a ripple ring spreading out of
// it, shown while something is capturing the screen through the xdg portal
// (browser/Discord/OBS screen share). xdph exposes each capture as a
// "Video/Source" node named xdg-desktop-portal-hyprland, so it's matched by
// name to tell it apart from real cameras (also Video/Source). Hovering
// lists the apps receiving the stream.
Item {
    id: root

    readonly property var videoStreams: Pipewire.nodes.values.filter(n =>
        n.properties && n.properties["node.name"] === "xdg-desktop-portal-hyprland")
    readonly property bool sharing: videoStreams.length > 0
    readonly property color accent: "#0a84ff"

    // The consumer's node name is all PipeWire gives us ("zen-bin"), so
    // tidy it up into something readable ("Zen").
    readonly property var viewers: {
        const names = []
        for (const lg of Pipewire.linkGroups.values) {
            if (!lg.source || !lg.target || videoStreams.indexOf(lg.source) < 0)
                continue
            const p = lg.target.properties || {}
            const raw = p["application.name"] || p["node.name"] || ""
            const name = raw.replace(/[-_]bin$/, "")
            const pretty = name.charAt(0).toUpperCase() + name.slice(1)
            if (pretty && names.indexOf(pretty) < 0)
                names.push(pretty)
        }
        return names
    }

    visible: sharing
    implicitWidth: sharing ? 16 + Theme.modulePadding * 2 : 0
    implicitHeight: Theme.fontSize + 7

    // Node properties are only populated for tracked nodes.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Item {
        anchors.centerIn: parent
        width: 16
        height: 16

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: width / 2
            color: "transparent"
            border.width: 1.25
            border.color: root.accent

            SequentialAnimation {
                running: root.sharing
                loops: Animation.Infinite
                ParallelAnimation {
                    NumberAnimation { target: ring; property: "width"; from: 7; to: 16; duration: 1600; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "height"; from: 7; to: 16; duration: 1600; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "opacity"; from: 0.7; to: 0; duration: 1600; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 2000 }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: root.accent
            opacity: 0.85
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }

    PopupWindow {
        visible: hover.containsMouse && root.sharing
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        implicitWidth: tip.implicitWidth + 24
        implicitHeight: tip.implicitHeight + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#e6101015"

            Column {
                id: tip
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: "Screen sharing"
                    color: Theme.popupText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
                Text {
                    visible: root.viewers.length > 0
                    text: "with " + root.viewers.join(", ")
                    color: Theme.popupMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
