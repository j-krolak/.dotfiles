import QtQuick
import Quickshell.Services.Pipewire

// Like waybar's "pulseaudio" module: shows the default sink's volume,
// click to mute, scroll to adjust.
StatusItem {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !sink || !sink.ready || sink.audio.muted
    readonly property real vol: sink && sink.ready ? sink.audio.volume : 0

    // Tracking the node tells Quickshell to keep its volume/mute state
    // (sink.audio) actively bound instead of a one-off snapshot.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    tint: muted ? Theme.barMuted : Theme.barForeground
    icon: muted ? "audio-volume-muted-symbolic"
        : vol > 0.66 ? "audio-volume-high-symbolic"
        : vol > 0.33 ? "audio-volume-medium-symbolic"
        : "audio-volume-low-symbolic"
    label: !sink || !sink.ready ? "--%" : sink.audio.muted ? "muted" : Math.round(vol * 100) + "%"

    onClicked: {
        if (sink)
            sink.audio.muted = !sink.audio.muted
    }
    onWheel: e => {
        if (!sink)
            return
        const step = e.angleDelta.y > 0 ? 0.05 : -0.05
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step))
    }
}
