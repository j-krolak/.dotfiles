import QtQuick
import QtQuick.Effects
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Io

// Side panel for the coding agents, opened from the bar's agents entry
// (Agents.qml). Same look as the date/widgets panel (Calendar.qml): a frosted
// glass container sliding in from the right, holding dark glass cards - here
// one for the agents themselves and one each for Claude Code and OpenCode
// usage. The usage numbers are fetched once per open (scripts/ai-usage.py),
// not on a timer.
PanelWindow {
  id: win

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
      this.WlrLayershell.namespace = "quickshell:widgets"
    }
  }

  visible: AgentsState.visible || panel.anchors.rightMargin > -panel.width

  // `qs ipc call agents toggle` - handy for a keybind.
  IpcHandler {
    target: "agents"
    function toggle(): void { AgentsState.visible = !AgentsState.visible }
  }

  property var usage: null

  Connections {
    target: AgentsState
    function onVisibleChanged() {
      if (AgentsState.visible) {
        PopupManager.closeAll("Agents")
        win.usage = null
        AgentsState.refresh()
        usageProcess.running = true
      }
    }
  }

  Process {
    id: usageProcess
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/ai-usage.py"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { win.usage = JSON.parse(text) } catch (e) {}
      }
    }
  }

  function tokens(n) {
    if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
    if (n >= 1e3) return Math.round(n / 1e3) + "k"
    return String(n)
  }

  function resetsIn(iso) {
    const s = (new Date(iso).getTime() - Date.now()) / 1000
    if (!(s > 0)) return ""
    const d = Math.floor(s / 86400)
    const h = Math.floor((s % 86400) / 3600)
    const m = Math.round((s % 3600) / 60)
    return "resets in " + (d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m")
  }

  function resetsAt(iso) {
    const d = new Date(iso)
    if (isNaN(d.getTime())) return ""
    const sameDay = d.toDateString() === new Date().toDateString()
    return sameDay ? "at " + Qt.formatTime(d, "HH:mm") : Qt.formatDateTime(d, "ddd HH:mm")
  }

  function project(cwd) {
    return cwd ? cwd.split("/").filter(p => p).pop() : ""
  }

  readonly property var sortedAgents: AgentsState.agents.slice().sort((a, b) => {
    const rank = s => s === "blocked" ? 0 : s === "working" ? 1 : 2
    return rank(a.agent_status) - rank(b.agent_status)
  }).slice(0, 8)

  // Any click outside the panel closes it.
  MouseArea {
    anchors.fill: parent
    enabled: AgentsState.visible
    acceptedButtons: Qt.AllButtons
    onPressed: AgentsState.visible = false
  }

  component Heading: Text {
    color: Theme.popupMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 2
    font.bold: true
    font.capitalization: Font.AllUppercase
  }

  component Line: Text {
    color: Theme.popupText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    elide: Text.ElideRight
  }

  component Limit: Column {
    id: limit
    property string label
    property var info
    readonly property color tone: info.percent >= 85 ? Theme.popupUrgent : Theme.popupText

    spacing: 7

    Item {
      width: parent.width
      height: pct.implicitHeight

      Text {
        id: pct
        text: Math.round(limit.info.percent) + "%"
        color: limit.tone
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 8
        font.bold: true
      }
      Text {
        anchors.left: pct.right
        anchors.leftMargin: 8
        anchors.baseline: pct.baseline
        text: limit.label
        color: Theme.popupMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
      }
      Column {
        anchors.right: parent.right
        anchors.verticalCenter: pct.verticalCenter
        spacing: 1

        Text {
          anchors.right: parent.right
          text: win.resetsIn(limit.info.resets_at)
          color: Theme.popupText
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 2
        }
        Text {
          anchors.right: parent.right
          text: win.resetsAt(limit.info.resets_at)
          color: Theme.popupMuted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 3
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 10
      radius: 5
      color: Theme.popupLine

      Rectangle {
        width: Math.max(height, parent.width * Math.min(1, limit.info.percent / 100))
        height: parent.height
        radius: parent.radius
        color: limit.tone

        Behavior on width {
          NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
      }
    }

    Item {
      width: parent.width
      height: usedText.implicitHeight

      Text {
        id: usedText
        text: Math.round(limit.info.percent) + "% used"
        color: Theme.popupMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 3
      }
      Text {
        anchors.right: parent.right
        text: Math.max(0, 100 - Math.round(limit.info.percent)) + "% left"
        color: Theme.popupMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 3
      }
    }
  }

  // Slide-in panel, same construction as Calendar.qml's.
  Item {
    id: panel
    width: 276 + padding * 2
    readonly property int padding: 10
    anchors.top: parent.top
    anchors.topMargin: Theme.barGap + 1
    height: widgetsColumn.implicitHeight + padding * 2
    anchors.right: parent.right
    anchors.rightMargin: AgentsState.visible ? Theme.barGap : -width

    Behavior on anchors.rightMargin {
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
      id: glass
      anchors.fill: parent
      radius: Theme.popupRadius
      color: "#0dffffff"
      visible: false
    }

    MultiEffect {
      anchors.fill: glass
      source: glass
      shadowEnabled: true
      shadowColor: "black"
      shadowOpacity: 0.35
      shadowBlur: 1.0
      shadowVerticalOffset: 4
    }

    // Swallows clicks so they don't reach the close-on-click MouseArea.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: widgetsColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: panel.padding
      spacing: Theme.barGap

      // agents
      Rectangle {
        width: parent.width
        height: agentsLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: agentsLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 6

          Heading {
            text: "Agents · " + AgentsState.workingCount + " working"
              + (AgentsState.blockedCount > 0 ? " · " + AgentsState.blockedCount + " blocked" : "")
          }

          Repeater {
            model: win.sortedAgents

            Rectangle {
              required property var modelData
              width: agentsLayout.width
              height: 40
              radius: 8
              color: rowArea.containsMouse ? Theme.popupHover : "transparent"

              Rectangle {
                id: statusDot
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                readonly property bool working: modelData.agent_status === "working"
                readonly property bool blocked: modelData.agent_status === "blocked"
                color: working || blocked ? Theme.popupText : "transparent"
                border.width: 1.25
                border.color: working || blocked ? Theme.popupText : Theme.popupMuted

                SequentialAnimation on opacity {
                  running: statusDot.working || statusDot.blocked
                  loops: Animation.Infinite
                  onRunningChanged: if (!running) statusDot.opacity = 1
                  NumberAnimation { to: 0.35; duration: statusDot.blocked ? 450 : 900; easing.type: Easing.InOutSine }
                  NumberAnimation { to: 1; duration: statusDot.blocked ? 450 : 900; easing.type: Easing.InOutSine }
                }
              }

              Column {
                anchors.left: statusDot.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Line {
                  width: parent.width
                  text: modelData.terminal_title_stripped || modelData.agent
                }
                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: win.project(modelData.cwd) + " · " + modelData.agent_status
                  color: Theme.popupMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 3
                }
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  AgentsState.focus(modelData.pane_id)
                  AgentsState.visible = false
                }
              }
            }
          }
        }
      }

      // Claude Code usage
      Rectangle {
        width: parent.width
        height: claudeLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: claudeLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 8

          Item {
            width: parent.width
            height: claudeHeading.implicitHeight

            Heading { id: claudeHeading; text: "Claude Code" }
            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              visible: !!win.usage && !!win.usage.claude.limits.plan
              text: win.usage && win.usage.claude.limits.plan ? win.usage.claude.limits.plan.toUpperCase() : ""
              color: Theme.popupMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 3
              font.bold: true
            }
          }

          Text {
            visible: !win.usage
            text: "Loading…"
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Limit {
            width: parent.width
            visible: !!win.usage && !!win.usage.claude.limits.five_hour
            label: "5-hour session"
            info: win.usage && win.usage.claude.limits.five_hour || ({ percent: 0, resets_at: "" })
          }

          Limit {
            width: parent.width
            visible: !!win.usage && !!win.usage.claude.limits.seven_day
            label: "Weekly"
            info: win.usage && win.usage.claude.limits.seven_day || ({ percent: 0, resets_at: "" })
          }

          Text {
            visible: !!win.usage && win.usage.claude.limits.error !== undefined
            text: win.usage && win.usage.claude.limits.retry_in ? "Rate limited · retry in " + Math.ceil(win.usage.claude.limits.retry_in / 60) + " min" : "Limits unavailable"
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
          }

          Row {
            visible: !!win.usage
            width: parent.width
            spacing: 8

            StatTile {
              width: (parent.width - 8) / 2
              value: win.usage ? win.tokens(win.usage.claude.tokens.today) : ""
              label: "tokens today"
            }
            StatTile {
              width: (parent.width - 8) / 2
              value: win.usage ? win.tokens(win.usage.claude.tokens.week) : ""
              label: "tokens this week"
            }
          }
        }
      }

      // OpenCode usage
      Rectangle {
        width: parent.width
        height: openLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: openLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 6

          Heading { text: "OpenCode" }

          Line {
            width: parent.width
            text: win.usage ? "Today · " + win.tokens(win.usage.opencode.today.tokens)
              + " tokens · $" + win.usage.opencode.today.cost.toFixed(2) : "Loading…"
          }
          Line {
            width: parent.width
            visible: !!win.usage
            text: win.usage ? "Week · " + win.tokens(win.usage.opencode.week.tokens)
              + " tokens · $" + win.usage.opencode.week.cost.toFixed(2) : ""
            color: Theme.popupMuted
          }
        }
      }
    }
  }
}
