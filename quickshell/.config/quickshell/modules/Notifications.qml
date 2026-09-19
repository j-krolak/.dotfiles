import QtQuick

// Bell + pending count for the bar. Goes muted and countless when there's
// nothing waiting; click to open the history panel
// (modules/NotificationsOverview.qml, its own window).
Text {
    id: root

    readonly property int count: NotificationsState.count

    color: {
        if (count === 0) return Theme.muted
        if (NotificationsState.hasCritical) return Theme.urgent
        return Theme.accent
    }
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: count > 0 ? "󰂚 " + count : "󰂜"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationsState.popupX = root.mapToItem(null, 0, root.height).x
            NotificationsState.visible = !NotificationsState.visible
        }
    }
}
