import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Transient notification toasts, replacing mako. A card per incoming
// notification that auto-dismisses, colored by urgency; the card going
// away only drops the toast, the notification itself stays in the
// history panel (NotificationsOverview.qml) until dismissed there.
// The DBus service itself lives in NotificationsState.qml.
PanelWindow {
  id: popup

  anchors {
    top: true
    right: true
  }
  margins {
    top: 12
    right: 12
  }
  exclusiveZone: 0
  color: "transparent"

  // Namespace matched by the hyprland layer rule that blurs behind the
  // toast cards, same as the bar and the other popups - see hypr's
  // rules/layers.lua.
  Component.onCompleted: {
    if (this.WlrLayershell != null) {
      this.WlrLayershell.namespace = "quickshell:blur"
    }
  }

  implicitWidth: 320
  implicitHeight: column.implicitHeight
  visible: NotificationsState.toasts.count > 0

  Column {
    id: column
    width: parent.width
    spacing: 6

    Repeater {
      model: NotificationsState.toasts

      delegate: Rectangle {
        id: card
        required property var notif
        required property int index

        width: column.width
        height: cardColumn.implicitHeight + 20
        radius: 8
        // The card body stops 3px short of the right edge so the accent
        // line below can sit beside it rather than under it - stacking
        // them doesn't work, popupBackground is translucent on purpose
        // (the compositor blurs what's behind) and the colour would show
        // straight through.
        color: "transparent"

        Rectangle {
          anchors.fill: parent
          anchors.rightMargin: 3
          topLeftRadius: parent.radius
          bottomLeftRadius: parent.radius
          color: Theme.popupBackground
        }

        // Urgency as a full-height line down the right edge rather than
        // an outline around the whole card - a stack of outlined cards
        // reads as noise, and the line sits on the screen-edge side.
        Rectangle {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 3
          topLeftRadius: 0
          bottomLeftRadius: 0
          topRightRadius: parent.radius
          bottomRightRadius: parent.radius
          color: NotificationsState.urgencyColor(card.notif)
        }

        Column {
          id: cardColumn
          x: 12
          y: 10
          width: parent.width - 24
          spacing: 2

          Text {
            text: card.notif.appName
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
          }

          Text {
            text: card.notif.summary
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            width: parent.width
            wrapMode: Text.WordWrap
          }

          Text {
            visible: text.length > 0
            text: card.notif.body
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
          }
        }

        // expireTimeout of 0 means "don't auto-expire" per the
        // notification spec; -1 (or unset) means "use a sane default".
        // Critical ones shouldn't time out at all (also per spec) - that's
        // what keeps the low-battery warning on screen until acknowledged.
        Timer {
          interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 5000
          running: card.notif.expireTimeout !== 0
            && card.notif.urgency !== NotificationUrgency.Critical
          onTriggered: NotificationsState.toasts.remove(card.index)
        }

        // The sending app (or a dismiss from the history panel) can close
        // it out from under us - stay in sync.
        Connections {
          target: card.notif
          function onClosed(reason) {
            NotificationsState.toasts.remove(card.index)
          }
        }

        // Click the toast to put it away without dismissing the
        // notification - it's still there in the panel afterwards.
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: NotificationsState.toasts.remove(card.index)
        }
      }
    }
  }
}
