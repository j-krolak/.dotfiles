import QtQuick
import Quickshell.Io

// Pending-task counter for Taskwarrior, refreshed on a timer via `task
// export` (same one-shot-process idea as SystemStats). Click to open the
// full overview (modules/TaskwarriorOverview.qml, its own window).
Text {
    id: root

    property int pendingCount: 0
    property int overdueCount: 0

    color: overdueCount > 0 ? Theme.urgent : Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: " " + pendingCount

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        // Process.running resets to false once the command exits, so
        // flipping it back to true here is what re-runs it every tick.
        onTriggered: taskProcess.running = true
    }

    Process {
        id: taskProcess
        command: ["task", "status:pending", "export"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const tasks = JSON.parse(text)
                    const now = new Date()

                    root.pendingCount = tasks.length
                    root.overdueCount = tasks.filter(t => {
                        if (!t.due) return false
                        // Taskwarrior exports dates as basic ISO
                        // ("20260829T220000Z") - insert the punctuation
                        // JS Date needs to parse it reliably.
                        const d = t.due
                        const due = new Date(d.slice(0, 4) + "-" + d.slice(4, 6) + "-" + d.slice(6, 8)
                            + "T" + d.slice(9, 11) + ":" + d.slice(11, 13) + ":" + d.slice(13, 15) + "Z")
                        return due < now
                    }).length
                } catch (e) {
                    root.pendingCount = 0
                    root.overdueCount = 0
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            TaskwarriorState.popupX = root.mapToItem(null, 0, root.height).x
            TaskwarriorState.visible = !TaskwarriorState.visible
        }
    }

    Connections {
        target: TaskwarriorState
        function onTasksChanged() { taskProcess.running = true }
    }
}
