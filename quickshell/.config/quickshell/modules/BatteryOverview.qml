import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower

// Battery details + power actions, opened by clicking the battery widget in
// the bar. Same click-outside-to-close trick as Calendar.qml /
// TaskwarriorOverview.qml: a full-screen invisible window with a MouseArea
// behind the actual card swallows the click that closes it.
PanelWindow {
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusiveZone: 0
  color: "transparent"
  // Same namespace Calendar.qml/TaskwarriorOverview.qml/SystemStatsOverview.qml
  // use - matched by a Hyprland layer rule that blurs it.
  Component.onCompleted: {
    if (this.WlrLayershell != null) {
      this.WlrLayershell.namespace = "quickshell:blur"
    }
  }

  visible: BatteryState.visible

  MouseArea {
    anchors.fill: parent
    onClicked: BatteryState.visible = false
  }

  readonly property UPowerDevice device: UPower.displayDevice
  readonly property bool charging: device && device.state === UPowerDeviceState.Charging
  readonly property real percent: device ? device.percentage * 100 : 0

  // Quickshell's own healthPercentage comes back unsupported on this
  // hardware/UPower combo (UPower.displayDevice is a synthetic aggregate
  // with no nativePath of its own, not the real BAT0) even though
  // `upower -i` reports a "capacity:" figure just fine for the actual
  // battery object. Shelling out to it directly is the simplest way to get
  // the same number, plus charge-cycles as a bonus stat - `upower -e` finds
  // the real battery_* object path first, since it isn't derivable from the
  // display device alone.
  property real fallbackHealthPercent: -1
  property int chargeCycles: -1

  Process {
    id: listDevicesProcess
    command: ["upower", "-e"]

    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.split("\n").find(l => l.includes("/battery_"))
        if (line) {
          upowerProcess.command = ["upower", "-i", line.trim()]
          upowerProcess.running = true
        }
      }
    }
  }

  Process {
    id: upowerProcess

    stdout: StdioCollector {
      onStreamFinished: {
        const capacityMatch = text.match(/^\s*capacity:\s*([\d.]+)%/m)
        fallbackHealthPercent = capacityMatch ? parseFloat(capacityMatch[1]) : -1
        const cyclesMatch = text.match(/^\s*charge-cycles:\s*(\d+)/m)
        chargeCycles = cyclesMatch ? parseInt(cyclesMatch[1]) : -1
      }
    }
  }

  readonly property bool healthKnown: (device && device.healthSupported) || fallbackHealthPercent >= 0
  readonly property real healthPercent: (device && device.healthSupported) ? device.healthPercentage : fallbackHealthPercent

  onVisibleChanged: if (visible) listDevicesProcess.running = true

  // UPower reports these in seconds, and leaves whichever one doesn't
  // apply to the current state at 0.
  function formatDuration(seconds) {
    if (!seconds || seconds <= 0) return ""
    const h = Math.floor(seconds / 3600)
    const m = Math.round((seconds % 3600) / 60)
    if (h > 0) return h + "h " + m + "m"
    return m + "m"
  }

  readonly property string timeText: {
    if (!device) return ""
    if (charging) {
      const t = formatDuration(device.timeToFull)
      return t ? t + " until full" : ""
    }
    const t = formatDuration(device.timeToEmpty)
    return t ? t + " remaining" : ""
  }

  // Reused for whichever power action is clicked - only one is ever in
  // flight at a time, and the popup closes immediately after anyway.
  Process {
    id: powerProcess
  }

  function hibernate() {
    powerProcess.command = ["systemctl", "hibernate"]
    powerProcess.running = true
    BatteryState.visible = false
  }

  function shutdown() {
    powerProcess.command = ["systemctl", "poweroff"]
    powerProcess.running = true
    BatteryState.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 5
    // Battery is always the last (rightmost) icon in the bar, so unlike
    // Taskwarrior/SystemStats this doesn't need to track a click-reported
    // popupX - it can just hug the screen's right edge directly, at the
    // same inset as the bar's own right-section pill.
    anchors.rightMargin: Theme.barGap
    width: Math.max(220, layout.implicitWidth + 24)
    height: layout.implicitHeight + 20
    radius: 10
    color: Theme.popupBackground

    // Swallows the click so it doesn't fall through to the full-screen
    // MouseArea behind the card and immediately close the popup.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: layout
      x: 12
      y: 10
      width: parent.width - 24
      spacing: 10

      // Icon (left) + stats (right), side by side.
      Row {
        spacing: 16

        // Vertical battery icon (body + terminal nub on top) with the
        // percentage drawn inside it, like a fuel gauge - fills from the
        // bottom up, same as how a real upright battery indicator reads.
        Column {
          spacing: 3
          anchors.top: parent.top

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 22
            height: 6
            radius: 2
            color: "white"
          }

          Rectangle {
            id: batteryBody
            width: 56
            height: 100
            radius: 8
            color: "transparent"
            border.color: "white"
            border.width: 2

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 5
              height: Math.max(0, (parent.height - 10) * (percent / 100))
              radius: 4
              color: charging ? Theme.good : (percent <= 15 ? Theme.urgent : Theme.accent)
            }

            Text {
              anchors.centerIn: parent
              text: device ? Math.round(percent) + "%" : "--"
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              font.bold: true
            }
          }
        }

        Column {
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter

          Text {
            visible: charging
            text: "Charging"
            color: Theme.good
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Text {
            visible: timeText.length > 0
            text: timeText
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          // energyCapacity is how much charge the battery can currently hold
          // at full charge, in Wh - not its original design capacity, which
          // Quickshell doesn't expose. healthPercentage is exactly that
          // ratio (current capacity / design capacity), so it's what
          // actually answers "how degraded is this battery" without needing
          // the raw design value.
          Text {
            visible: device && device.energyCapacity > 0
            text: device ? "Capacity: " + device.energyCapacity.toFixed(1) + " Wh" : ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Text {
            visible: healthKnown
            text: "Health: " + Math.round(healthPercent) + "% ("
              + Math.round(100 - healthPercent) + "% degraded)"
            color: healthPercent < 80 ? Theme.warning : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Text {
            visible: chargeCycles >= 0
            text: "Charge cycles: " + chargeCycles
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }
        }
      }

      Row {
        spacing: 8

        Rectangle {
          id: hibernateButton
          width: hibernateLabel.implicitWidth + 40
          height: 34
          radius: 8
          color: hibernateArea.containsMouse ? Theme.hoverBackground : "transparent"
          border.color: "#80ffffff"
          border.width: 1

          Text {
            id: hibernateLabel
            anchors.centerIn: parent
            text: "⏾  Hibernate"
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          MouseArea {
            id: hibernateArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hibernate()
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
}
