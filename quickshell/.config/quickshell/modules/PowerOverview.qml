import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Io

// Power menu for desktops with no battery, opened by clicking the power
// button Battery.qml shows in their place. Same click-outside-to-close
// trick as BatteryOverview.qml/Calendar.qml/TaskwarriorOverview.qml: a
// full-screen invisible window with a MouseArea behind the actual card
// swallows the click that closes it.
PanelWindow {
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusiveZone: 0
  color: "transparent"
  // Same namespace Calendar.qml/TaskwarriorOverview.qml/BatteryOverview.qml
  // use - matched by a Hyprland layer rule that blurs it.
  Component.onCompleted: {
    if (this.WlrLayershell != null) {
      this.WlrLayershell.namespace = "quickshell:blur"
    }
  }

  visible: PowerState.visible

  MouseArea {
    anchors.fill: parent
    onClicked: PowerState.visible = false
  }

  // Reused for whichever power action is clicked - only one is ever in
  // flight at a time, and the popup closes immediately after anyway.
  Process {
    id: powerProcess
  }

  function logOut() {
    powerProcess.command = ["hyprctl", "dispatch", "exit"]
    powerProcess.running = true
    PowerState.visible = false
  }

  function shutdown() {
    powerProcess.command = ["systemctl", "poweroff"]
    powerProcess.running = true
    PowerState.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 5
    // Battery/power is always the last (rightmost) icon in the bar, so
    // like BatteryOverview.qml this doesn't need to track a click-reported
    // popupX - it can just hug the screen's right edge directly, at the
    // same inset as the bar's own right-section pill.
    anchors.rightMargin: Theme.barGap
    width: layout.implicitWidth + 24
    height: layout.implicitHeight + 20
    radius: 10
    color: Theme.popupBackground

    // Swallows the click so it doesn't fall through to the full-screen
    // MouseArea behind the card and immediately close the popup.
    MouseArea {
      anchors.fill: parent
    }

    Row {
      id: layout
      x: 12
      y: 10
      spacing: 8

      Rectangle {
        id: logOutButton
        width: logOutLabel.implicitWidth + 40
        height: 34
        radius: 8
        color: logOutArea.containsMouse ? Theme.hoverBackground : "transparent"
        border.color: "#80ffffff"
        border.width: 1

        Text {
          id: logOutLabel
          anchors.centerIn: parent
          text: "⏏  Log Out"
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 1
        }

        MouseArea {
          id: logOutArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: logOut()
        }
      }

      Rectangle {
        id: shutdownButton
        width: shutdownLabel.implicitWidth + 40
        height: 34
        radius: 8
        color: shutdownArea.containsMouse ? Theme.hoverBackground : "transparent"
        border.color: "#80ffffff"
        border.width: 1

        Text {
          id: shutdownLabel
          anchors.centerIn: parent
          text: "⏻  Shut Down"
          color: Theme.urgent
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 1
        }

        MouseArea {
          id: shutdownArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: shutdown()
        }
      }
    }
  }
}
