import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Io
import Quickshell.Wayland 

// Read-only list of pending Taskwarrior tasks, opened by clicking the
// Taskwarrior widget in the bar. Same click-outside-to-close trick as
// Calendar.qml: a full-screen invisible window with a MouseArea behind
// the actual card swallows the click that closes it.
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

  visible: TaskwarriorState.visible

  property var tasks: []

  MouseArea {
    anchors.fill: parent
    onClicked: TaskwarriorState.visible = false
  }

  // Taskwarrior exports dates as basic ISO ("20260829T220000Z") - insert
  // the punctuation JS Date needs to parse it reliably.
  function parseDue(due) {
    return new Date(due.slice(0, 4) + "-" + due.slice(4, 6) + "-" + due.slice(6, 8)
      + "T" + due.slice(9, 11) + ":" + due.slice(11, 13) + ":" + due.slice(13, 15) + "Z")
  }

  function refresh() {
    taskProcess.running = true
  }

  // Pick up any changes made from the CLI (or ticked off elsewhere)
  // right when the popup opens, on top of the periodic refresh below.
  onVisibleChanged: if (visible) refresh()

  Timer {
    interval: 15000
    running: TaskwarriorState.visible
    repeat: true
    onTriggered: refresh()
  }

  Process {
    id: taskProcess
    command: ["task", "status:pending", "export"]

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text)
          parsed.sort((a, b) => b.urgency - a.urgency)
          tasks = parsed
        } catch (e) {
          tasks = []
        }
      }
    }
  }

  // Marks whichever task's uuid is written into `command` as done. Reused
  // sequentially across clicks (checkboxes are disabled while it's
  // running, see below) rather than spawning one Process per task.
  Process {
    id: doneProcess

    onExited: {
      refresh()
      TaskwarriorState.tasksChanged()
    }
  }

  function markDone(uuid) {
    doneProcess.command = ["task", uuid, "done"]
    doneProcess.running = true
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 5
    // Opens directly under whichever icon was clicked (TaskwarriorState.popupX,
    // set on click) instead of a fixed corner - clamped so it can't run off
    // the right edge when the icon sits near it.
    anchors.leftMargin: Math.max(Theme.barGap,
      Math.min(TaskwarriorState.popupX, parent.width - width - Theme.barGap))
    width: 300
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
      spacing: 8

      Text {
        text: "Tasks (" + tasks.length + " pending)"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
      }

      Text {
        visible: tasks.length === 0
        text: "Nothing pending"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
      }

      Repeater {
        model: tasks

        delegate: Row {
          id: item
          required property var modelData

          readonly property bool hasDue: modelData.due !== undefined
          readonly property date dueDate: hasDue ? parseDue(modelData.due) : new Date()
          readonly property bool overdue: hasDue && dueDate < new Date()

          width: layout.width
          spacing: 8

          // Checkbox: click to mark this task done. Disabled (and shown
          // as a spinner-ish dim state) while a done request for any
          // task is in flight, since doneProcess is reused sequentially.
          Rectangle {
            id: checkbox
            width: 12
            height: 12
            radius: 3
            y: 2
            color: checkArea.pressed ? Theme.good : "transparent"
            border.color: doneProcess.running ? Theme.muted : Theme.good
            border.width: 1.5
            opacity: doneProcess.running ? 0.4 : 1

            MouseArea {
              id: checkArea
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              enabled: !doneProcess.running
              onClicked: markDone(item.modelData.uuid)
            }
          }

          Column {
            width: parent.width - checkbox.width - parent.spacing
            spacing: 1

            Text {
              width: parent.width
              text: item.modelData.description
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              wrapMode: Text.WordWrap
            }

            Row {
              spacing: 6

              Text {
                visible: item.modelData.priority !== undefined
                text: item.modelData.priority || ""
                color: item.modelData.priority === "H" ? Theme.urgent
                  : item.modelData.priority === "M" ? Theme.warning
                  : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                font.bold: true
              }

              Text {
                visible: item.modelData.project !== undefined
                text: item.modelData.project || ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
              }

              Text {
                visible: item.hasDue
                text: Qt.formatDateTime(item.dueDate, "MMM d")
                color: item.overdue ? Theme.urgent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
              }
            }
          }
        }
      }
    }
  }
}
