import QtQuick
import Quickshell.Services.Mpris

// Previous / play-pause / next for whatever player is running, like the
// media buttons in macOS's menu bar. Only shown while a player exists.
// WhiteSur only ships outlined media icons, so the solid macOS-style
// glyphs come from the Nerd Font instead (see MediaButton.qml).
Row {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    visible: player !== null
    spacing: 2

    MediaButton {
        kind: "prev"
        enabledState: root.player && root.player.canGoPrevious
        onClicked: root.player.previous()
    }

    MediaButton {
        kind: root.player && root.player.isPlaying ? "pause" : "play"
        onClicked: root.player.togglePlaying()
    }

    MediaButton {
        kind: "next"
        enabledState: root.player && root.player.canGoNext
        onClicked: root.player.next()
    }
}
