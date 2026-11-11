import QtQuick

// Bell + pending count for the bar. Goes muted and countless when there's
// nothing waiting; click to open the history panel
// (modules/NotificationsOverview.qml, its own window).
StatusItem {
    id: root

    readonly property int count: NotificationsState.count

    tint: {
        if (count === 0) return Theme.barMuted
        if (NotificationsState.hasCritical) return Theme.barUrgent
        return Theme.barAccent
    }
    icon: count > 0 ? "notification-new-symbolic" : "notification-symbolic"
    label: count > 0 ? String(count) : ""

    onClicked: {
        NotificationsState.popupX = root.mapToItem(null, 0, root.height).x
        NotificationsState.visible = !NotificationsState.visible
    }
}
