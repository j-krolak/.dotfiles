import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland

// Notification history, opened by clicking the bell in the bar. Same
// click-outside-to-close trick as Calendar.qml: a full-screen invisible
// window with a MouseArea behind the actual card swallows the click that
// closes it. The list is NotificationsState.history, which quickshell
// keeps in sync - a notification closed by its app disappears here too.
PanelWindow {
  id: overview

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusiveZone: 0
  color: "transparent"

  Component.onCompleted: {
    if (this.WlrLayershell != null) {
      this.WlrLayershell.namespace = "quickshell:blur"
    }
  }

  visible: NotificationsState.visible

  readonly property var items: NotificationsState.history

  MouseArea {
    anchors.fill: parent
    onClicked: NotificationsState.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 5
    // Opens directly under the bell (NotificationsState.popupX, set on
    // click), clamped so it can't run off the right edge.
    anchors.leftMargin: Math.max(Theme.barGap,
      Math.min(NotificationsState.popupX, parent.width - width - Theme.barGap))
    width: 360
    height: layout.implicitHeight + 20
    radius: 10
    color: Theme.popupBackground

    // Swallows the click so it doesn't fall through to the full-screen
    // MouseArea behind the card and immediately close the panel.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: layout
      x: 12
      y: 10
      width: parent.width - 24
      spacing: 8

      Item {
        width: parent.width
        height: title.implicitHeight

        Text {
          id: title
          text: "Notifications" + (overview.items.length > 0 ? " (" + overview.items.length + ")" : "")
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.bold: true
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: title.verticalCenter
          visible: overview.items.length > 0
          text: "Clear all"
          color: clearArea.containsMouse ? Theme.urgent : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 2

          MouseArea {
            id: clearArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationsState.dismissAll()
          }
        }
      }

      Text {
        visible: overview.items.length === 0
        text: "Nothing new"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
      }

      // Caps the panel instead of letting a busy day grow it past the
      // screen; contentHeight drives whether it actually scrolls.
      Flickable {
        width: parent.width
        height: Math.min(list.implicitHeight, 420)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: list
          width: parent.width
          spacing: 6

          Repeater {
            model: overview.items

            delegate: Rectangle {
              id: row
              required property var modelData

              width: list.width
              height: rowContent.implicitHeight + 16
              radius: 8
              color: rowArea.containsMouse ? Theme.hoverBackground : "transparent"

              // Same accent line as the toasts (NotificationPopups.qml),
              // on the right edge rather than an outline.
              Rectangle {
                width: 3
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                topLeftRadius: 0
                bottomLeftRadius: 0
                topRightRadius: parent.radius
                bottomRightRadius: parent.radius
                color: NotificationsState.urgencyColor(row.modelData)
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.modelData.dismiss()
              }

              Row {
                id: rowContent
                x: 12
                y: 8
                width: parent.width - 24
                spacing: 8

                Image {
                  id: icon
                  visible: source != ""
                  source: NotificationsState.iconFor(row.modelData)
                  sourceSize.width: 24
                  sourceSize.height: 24
                  width: 24
                  height: 24
                  fillMode: Image.PreserveAspectFit
                }

                Column {
                  width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
                  spacing: 1

                  Item {
                    width: parent.width
                    height: appName.implicitHeight

                    Text {
                      id: appName
                      text: row.modelData.appName
                      color: Theme.muted
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontSize - 3
                    }

                    Text {
                      anchors.right: parent.right
                      text: Qt.formatDateTime(NotificationsState.timeOf(row.modelData), "HH:mm")
                      color: Theme.muted
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontSize - 3
                    }
                  }

                  Text {
                    width: parent.width
                    text: row.modelData.summary
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }

                  Text {
                    visible: text.length > 0
                    width: parent.width
                    text: row.modelData.body
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
