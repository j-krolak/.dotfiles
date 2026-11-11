import QtQuick
import QtQuick.Effects

// Bar module made of a WhiteSur symbolic icon plus an optional label. The
// icon SVGs are single-color, so they're tinted with `tint` to follow the
// same white/black switching as the text (see WallpaperTone.qml).
Item {
    id: root

    property string icon: ""
    // WhiteSur category folder the icon lives in (status/, actions/, ...).
    property string iconDir: "status"
    property string label: ""
    property color tint: Theme.barForeground
    readonly property int iconSize: 14
    // For modules that draw their own glyph on top (Battery.qml): hides the
    // SVG and reserves width for the custom drawing instead.
    property bool iconVisible: true
    property int extraWidth: 0

    signal clicked()
    signal wheel(var event)

    implicitWidth: row.implicitWidth + extraWidth + Theme.modulePadding * 2
    implicitHeight: Theme.fontSize + 7

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Item {
            width: root.iconSize
            height: root.iconSize
            visible: root.iconVisible
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: img
                anchors.fill: parent
                source: root.icon ? "file:///usr/share/icons/WhiteSur/" + (root.iconDir || "status") + "/symbolic/" + root.icon + ".svg" : ""
                sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: img
                brightness: 1.0
                colorization: 1.0
                colorizationColor: root.tint
            }
        }

        Text {
            visible: Theme.showStatusLabels && root.label.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: e => root.wheel(e)
    }
}
