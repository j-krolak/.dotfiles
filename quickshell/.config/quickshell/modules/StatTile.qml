import QtQuick

// Small number-over-caption tile used on the agents panel (AgentsPanel.qml).
Rectangle {
    id: tile

    property string value
    property string label

    height: 42
    radius: 9
    color: Theme.popupHover

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.value
            color: Theme.popupText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
        }
    }
}
