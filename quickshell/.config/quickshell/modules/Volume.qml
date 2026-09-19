import QtQuick
import Quickshell.Services.Pipewire

// Like waybar's "pulseaudio" module: shows the default sink's volume,
// click to mute, scroll to adjust.
Text {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Tracking the node tells Quickshell to keep its volume/mute state
    // (sink.audio) actively bound instead of a one-off snapshot.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    color: (sink && sink.audio.muted) ? Theme.muted : Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: {
        if (!sink || !sink.ready)
            return "󰝟 --%"
        if (sink.audio.muted)
            return "󰝟 muted"
        return "󰕾 " + Math.round(sink.audio.volume * 100) + "%"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.sink)
                root.sink.audio.muted = !root.sink.audio.muted
        }
        onWheel: wheel => {
            if (!root.sink)
                return
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
        }
    }
}
