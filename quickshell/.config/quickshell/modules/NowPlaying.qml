import QtQuick
import Quickshell.Services.Mpris

// Like waybar's "mpris" module: shows the current track from whatever
// media player is running (Spotify, mpv, browser tabs, ...) and lets you
// click to play/pause it. Split into two Text items (icon, title) rather
// than one - the icon needs its own larger size, which a single Text
// mixing both couldn't do per-glyph.
Item {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    visible: player !== null
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: root.player && root.player.isPlaying ? "⏸" : "⏵"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            leftPadding: Theme.modulePadding
            rightPadding: 4
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.player ? root.player.trackTitle : ""

            // Capped so a long track title can't grow wide enough to run
            // into the clock/calendar in the center of the bar - elide
            // only has any effect once there's an actual width limit for
            // it to enforce.
            width: Math.min(implicitWidth, 220)

            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            rightPadding: Theme.modulePadding
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.player && root.player.togglePlaying()
    }
}
