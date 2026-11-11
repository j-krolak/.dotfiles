import QtQuick

// One media glyph from the Nerd Font (Material Design set) - solid and
// closer to macOS's than the outlined WhiteSur ones.
Item {
    id: btn
    property string kind: "play"
    property bool enabledState: true
    property color tint: Theme.barForeground
    signal clicked()

    readonly property var glyphs: ({
        prev: 0xf04ae,
        play: 0xf040a,
        pause: 0xf03e4,
        next: 0xf04ad
    })

    width: 24
    height: Theme.fontSize + 7
    opacity: enabledState ? 1 : 0.4

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(btn.glyphs[btn.kind])
        color: btn.tint
        font.family: "MesloLGS Nerd Font"
        font.pixelSize: Theme.fontSize + 5
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (btn.enabledState) btn.clicked()
    }
}
