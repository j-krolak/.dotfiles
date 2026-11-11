pragma Singleton
import QtQuick
import Quickshell.Io

// CPU / RAM / temp / disk readings for the widgets panel (Calendar.qml),
// sampled only while the panel is open.
//
// CPU usage can't be read directly - /proc/stat only has running totals since
// boot, so the percentage is the difference between two consecutive samples.
QtObject {
    id: root

    property real cpuPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real diskPercent: 0
    property real tempC: 0

    property real prevTotal: 0
    property real prevIdle: 0

    readonly property bool sampling: CalendarState.visible
    onSamplingChanged: if (sampling) { prevTotal = 0; prevIdle = 0 }

    readonly property Timer ticker: Timer {
        interval: 1500
        running: root.sampling
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProcess.running = true
    }

    readonly property Process statsProcess: Process {
        id: statsProcess
        command: ["sh", "-c",
            "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat; " +
            "free -m | awk '/^Mem:/{print $3, $2}'; " +
            // hwmon index is machine-specific
            "cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || echo 0; " +
            "df --output=pcent / | tail -1"
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

                const [used, all] = lines[1].split(" ").map(Number)
                root.memUsedGiB = used / 1024
                root.memTotalGiB = all / 1024
                root.tempC = Number(lines[2]) / 1000
                root.diskPercent = parseInt(lines[3])
            }
        }
    }
}
