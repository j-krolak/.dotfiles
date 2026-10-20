import QtQuick

// Double blue rule inside a popup card, like the border of a stele.
Item {
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        border.color: Theme.accent
        border.width: 1
        opacity: 0.8
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        color: "transparent"
        border.color: Theme.accent
        border.width: 1
        opacity: 0.35
    }
}
