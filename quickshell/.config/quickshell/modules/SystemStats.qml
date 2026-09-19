import QtQuick
import Quickshell.Io

// Combines waybar's "cpu", "memory" and "temperature" modules into one
// widget, refreshed on a timer via a couple of shell one-liners.
//
// CPU usage can't be read directly - the kernel only exposes a running
// total of time spent in each state since boot (/proc/stat). To get a
// percentage we have to sample it twice and look at the *difference*,
// so we keep the previous sample around in prevTotal/prevIdle and diff
// against it every time the timer fires.
Text {
    id: root

    property real cpuPercent: 0
    property real memUsedGiB: 0
    property real tempC: 0

    property real prevTotal: 0
    property real prevIdle: 0

    // CPU% and RAM are still sampled below (the popup needs them - see
    // SystemStatsOverview.qml) but the bar itself only shows temperature,
    // to keep this pill from crowding out everything next to it.
    color: tempC >= 80 ? Theme.urgent : Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: "󰔏 " + tempC.toFixed(0) + "°C"

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        // Process.running resets to false once the command exits, so
        // flipping it back to true here is what re-runs it every tick.
        onTriggered: statsProcess.running = true
    }

    Process {
        id: statsProcess
        command: ["sh", "-c",
            // Line 1: total jiffies + idle jiffies from /proc/stat
            "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat; " +
            // Line 2: memory currently in use, in MiB
            "free -m | awk '/^Mem:/{print $3}'; " +
            // Line 3: CPU temperature in millidegrees (0 if unavailable -
            // adjust the hwmon path below to match your machine, same as
            // in waybar's config.jsonc)
            "cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || echo 0"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")

                const [total, idle] = lines[0].split(" ").map(Number)
                const deltaTotal = total - root.prevTotal
                const deltaIdle = idle - root.prevIdle
                if (root.prevTotal > 0 && deltaTotal > 0)
                    root.cpuPercent = 100 * (1 - deltaIdle / deltaTotal)
                root.prevTotal = total
                root.prevIdle = idle

                root.memUsedGiB = Number(lines[1]) / 1024
                root.tempC = Number(lines[2]) / 1000

                SystemStatsState.cpuPercent = root.cpuPercent
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SystemStatsState.popupX = root.mapToItem(null, 0, root.height).x
            SystemStatsState.visible = !SystemStatsState.visible
        }
    }
}
