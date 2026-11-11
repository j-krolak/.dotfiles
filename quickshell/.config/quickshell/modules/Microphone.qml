import QtQuick
import Quickshell.Services.Pipewire

// Like Volume.qml but for the default source: shows a mic icon, click to mute.
StatusItem {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: !source || !source.ready || source.audio.muted

    // Tracking the node tells Quickshell to keep its volume/mute state
    // (source.audio) actively bound instead of a one-off snapshot.
    PwObjectTracker {
        objects: root.source ? [root.source] : []
    }

    tint: muted ? Theme.barMuted : Theme.barForeground
    icon: muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"
    label: !source || !source.ready ? "--%" : source.audio.muted ? "muted" : Math.round(source.audio.volume * 100) + "%"

    onClicked: {
        if (source)
            source.audio.muted = !source.audio.muted
    }
    onWheel: e => {
        if (!source)
            return
        const step = e.angleDelta.y > 0 ? 0.05 : -0.05
        source.audio.volume = Math.max(0, Math.min(1, source.audio.volume + step))
    }
}
