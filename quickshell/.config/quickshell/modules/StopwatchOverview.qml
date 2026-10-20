import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland

// Stopwatch popup, opened by clicking Stopwatch.qml in the bar. Same
// click-outside-to-close trick as TaskwarriorOverview.qml.
PanelWindow {
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

  visible: StopwatchState.visible

  MouseArea {
    anchors.fill: parent
    onClicked: StopwatchState.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 5
    anchors.leftMargin: Math.max(Theme.barGap,
      Math.min(StopwatchState.popupX, parent.width - width - Theme.barGap))
    width: 240
    height: layout.implicitHeight + 24
    radius: 2
    color: Theme.popupBackground

    GreekFrame {}

    // Swallows the click so it doesn't fall through and close the popup.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: layout
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: StopwatchState.format(StopwatchState.elapsedMs, true)
        color: StopwatchState.running ? Theme.foreground : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 15
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Rectangle {
          width: 100
          height: 34
          radius: 0
          color: toggleArea.containsMouse ? Theme.hoverBackground : "transparent"
          border.color: "#80ffffff"
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: StopwatchState.running ? "󰏤  Pause" : (StopwatchState.active ? "󰐊  Resume" : "󰐊  Start")
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: StopwatchState.toggle()
          }
        }

        Rectangle {
          width: 100
          height: 34
          radius: 0
          opacity: StopwatchState.active ? 1 : 0.4
          color: resetArea.containsMouse ? Theme.hoverBackground : "transparent"
          border.color: "#80ffffff"
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰜺  Reset"
            color: Theme.urgent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          MouseArea {
            id: resetArea
            anchors.fill: parent
            enabled: StopwatchState.active
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: StopwatchState.reset()
          }
        }
      }
    }
  }
}
