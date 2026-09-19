pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns the DBus notification service (nothing else is needed to "start"
// it - instantiating NotificationServer claims the name) plus the two
// views built on top of it, which live in separate top-level windows and
// so need a shared singleton to talk through:
//
//   NotificationPopups.qml    transient toasts, auto-dismissed
//   NotificationsOverview.qml the history panel, opened from the bar
//   Notifications.qml         the bar's bell + pending count
//
// Setting `tracked` on an incoming notification is what keeps it alive
// past the signal handler, and `server.trackedNotifications` then *is*
// the history - quickshell drops entries from it when a notification is
// closed, either by the sending app or by dismiss() from the panel.
QtObject {
    id: root

    property bool visible: false
    // Screen-space x of the bar widget's bottom-left corner, so the panel
    // (a separate top-level window) opens under the bell rather than at a
    // fixed spot. Same as TaskwarriorState.popupX.
    property real popupX: 0

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            notification.tracked = true
            root.arrivalTimes[notification.id] = new Date()
            root.pruneArrivalTimes()

            // keepOnReload replays everything still in the history when
            // the config reloads - those have been seen already, so they
            // go straight to the panel without popping a toast again.
            if (!notification.lastGeneration)
                root.toasts.append({ notif: notification })
        }
    }

    // Newest first - trackedNotifications keeps arrival order.
    readonly property var history: server.trackedNotifications.values.slice().reverse()
    readonly property int count: history.length
    readonly property bool hasCritical: history.some(n => n.urgency === NotificationUrgency.Critical)

    // Toasts are a separate queue from the history: a toast disappearing
    // on its timer must not close the notification behind it, otherwise
    // the panel would only ever show the last few seconds of activity.
    readonly property ListModel toasts: ListModel {}

    // The spec gives notifications no timestamp, so record arrival here,
    // keyed by id. Read once when a card is built, never re-evaluated.
    property var arrivalTimes: ({})

    function pruneArrivalTimes() {
        if (Object.keys(arrivalTimes).length <= 100) return
        const live = {}
        for (const n of server.trackedNotifications.values)
            live[n.id] = arrivalTimes[n.id]
        arrivalTimes = live
    }

    function timeOf(notification) {
        return arrivalTimes[notification.id] || new Date()
    }

    // dismiss() closes over DBus (so the sending app learns the user got
    // rid of it) and destroys the object, which removes it from the
    // history on its own.
    function dismissAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss()
    }

    function urgencyColor(notification) {
        if (notification.urgency === NotificationUrgency.Critical) return Theme.urgent
        if (notification.urgency === NotificationUrgency.Low) return Theme.muted
        return Theme.accent
    }

    function iconFor(notification) {
        if (notification.image !== "") return notification.image
        if (notification.appIcon !== "") return Quickshell.iconPath(notification.appIcon, true)
        return ""
    }
}
