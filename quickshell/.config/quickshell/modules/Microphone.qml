import QtQuick
import Quickshell.Services.Pipewire

// Like Volume.qml but for the default source: shows a mic icon, click to mute.
Text {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource

    // Tracking the node tells Quickshell to keep its volume/mute state
    // (source.audio) actively bound instead of a one-off snapshot.
    PwObjectTracker {
        objects: root.source ? [root.source] : []
    }

    color: (source && source.audio.muted) ? Theme.muted : Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: {
        if (!source || !source.ready)
            return "󰍭 --%"
        if (source.audio.muted)
            return "󰍭 muted"
        return "󰍬 " + Math.round(source.audio.volume * 100) + "%"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.source)
                root.source.audio.muted = !root.source.audio.muted
        }
        onWheel: wheel => {
            if (!root.source)
                return
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.source.audio.volume = Math.max(0, Math.min(1, root.source.audio.volume + step))
        }
    }
}
