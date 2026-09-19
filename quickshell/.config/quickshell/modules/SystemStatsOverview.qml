import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Io
import Quickshell.Wayland

// Detail view for the bar's CPU/RAM/temp widget (SystemStats.qml), opened
// by clicking it. Same click-outside-to-close trick as Calendar.qml/
// TaskwarriorOverview.qml. Everything here is a plain, undiffed reading
// (free, df, /proc/loadavg, uptime) except the CPU percentage, which comes
// from SystemStatsState since only the bar widget's Timer keeps the two
// /proc/stat samples needed to diff it.
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

  visible: SystemStatsState.visible

  property string loadAvg: ""
  property real memTotalGiB: 0
  property real memUsedGiB: 0
  property real swapTotalGiB: 0
  property real swapUsedGiB: 0
  property string diskUsedStr: ""
  property string diskTotalStr: ""
  property string diskPercentStr: ""
  property string uptimeStr: ""
  property real tempC: 0
  property int coreCount: 0

  MouseArea {
    anchors.fill: parent
    onClicked: SystemStatsState.visible = false
  }

  function refresh() {
    detailProcess.running = true
  }

  onVisibleChanged: if (visible) refresh()

  Timer {
    interval: 5000
    running: SystemStatsState.visible
    repeat: true
    onTriggered: refresh()
  }

  Process {
    id: detailProcess
    command: ["sh", "-c",
      // Line 1: 1/5/15-minute load averages
      "awk '{print $1, $2, $3}' /proc/loadavg; " +
      // Line 2: total/used/available memory, in MiB
      "free -m | awk '/^Mem:/{print $2, $3, $7}'; " +
      // Line 3: total/used swap, in MiB (both 0 if there's no swap)
      "free -m | awk '/^Swap:/{print $2, $3}'; " +
      // Line 4: used/total/percent for the root filesystem
      "df -h / | awk 'NR==2{print $3, $2, $5}'; " +
      // Line 5: human-readable uptime
      "uptime -p; " +
      // Line 6: CPU temperature in millidegrees - same hwmon path as
      // SystemStats.qml, keep them in sync if it ever changes
      "cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || echo 0; " +
      // Line 7: logical core count
      "nproc"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")

        loadAvg = lines[0]

        const [memTotal, memUsed] = lines[1].split(" ").map(Number)
        memTotalGiB = memTotal / 1024
        memUsedGiB = memUsed / 1024

        const [swapTotal, swapUsed] = lines[2].split(" ").map(Number)
        swapTotalGiB = swapTotal / 1024
        swapUsedGiB = swapUsed / 1024

        const [diskUsed, diskTotal, diskPercent] = lines[3].split(" ")
        diskUsedStr = diskUsed
        diskTotalStr = diskTotal
        diskPercentStr = diskPercent

        uptimeStr = lines[4]
        tempC = Number(lines[5]) / 1000
        coreCount = Number(lines[6])
      }
    }
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 5
    // Opens directly under whichever icon was clicked (SystemStatsState.popupX,
    // set on click) instead of a fixed corner - clamped so it can't run off
    // the right edge when the icon sits near it.
    anchors.leftMargin: Math.max(Theme.barGap,
      Math.min(SystemStatsState.popupX, parent.width - width - Theme.barGap))
    width: 330
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
      spacing: 6

      Text {
        text: "System"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
      }

      Repeater {
        model: [
          { label: "CPU", value: SystemStatsState.cpuPercent.toFixed(0) + "% (" + coreCount + " cores)" },
          { label: "Load", value: loadAvg },
          { label: "Memory", value: memUsedGiB.toFixed(1) + " / " + memTotalGiB.toFixed(1) + " GiB" },
          { label: "Swap", value: swapUsedGiB.toFixed(1) + " / " + swapTotalGiB.toFixed(1) + " GiB", visible: swapTotalGiB > 0 },
          { label: "Disk (/)", value: diskUsedStr + " / " + diskTotalStr + " (" + diskPercentStr + ")" },
          { label: "Temp", value: tempC.toFixed(0) + "°C" },
          { label: "Uptime", value: uptimeStr },
        ]

        delegate: Row {
          required property var modelData
          visible: modelData.visible !== false
          width: layout.width

          Text {
            width: 70
            text: modelData.label
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Text {
            text: modelData.value
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }
        }
      }
    }
  }
}
