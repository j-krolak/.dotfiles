import QtQuick
import QtQuick.Effects
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Widgets side panel (like macOS Notification Center), opened by clicking
// the clock in the bar. It slides in from the right edge and holds a month
// calendar plus now-playing, audio, GitHub, system usage and stopwatch widgets below it. Plain JS Date math for the
// calendar - no QtQuick calendar widget ships here.
//
// The window covers the whole screen (invisibly, apart from the panel) so
// there's something to click "outside of": a MouseArea behind the panel
// closes it, and the panel has its own MouseArea to swallow clicks. The
// window stays visible until the slide-out animation finishes.
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
      this.WlrLayershell.namespace = "quickshell:widgets"
    }
  }

  visible: CalendarState.visible || panel.anchors.rightMargin > -panel.width


  // GitHub items via the gh CLI (already authenticated): issues assigned to
  // me, PRs waiting for my review, and my own open PRs. Refreshed whenever
  // the panel opens and every 5 minutes.
  property var ghData: ({ issues: [], reviews: [], prs: [] })
  property bool ghLoaded: false
  property string ghTab: "issues"
  // "" = all repos
  property string ghRepo: ""

  property bool ghMenuOpen: false

  // One repo filter for all tabs, listing every repo seen on any of them.
  readonly property var ghRepos: {
    const seen = []
    for (const key in ghData)
      for (const it of ghData[key])
        if (seen.indexOf(it.repository.nameWithOwner) < 0) seen.push(it.repository.nameWithOwner)
    return seen.sort()
  }
  readonly property string ghActiveRepo: ghRepos.indexOf(ghRepo) >= 0 ? ghRepo : ""

  function ghFiltered(key) {
    return ghData[key].filter(it => ghActiveRepo === "" || it.repository.nameWithOwner === ghActiveRepo)
  }
  readonly property var ghItems: ghFiltered(ghTab).slice(0, 6)

  readonly property var ghTabs: [
    { key: "issues", label: "Issues" },
    { key: "reviews", label: "Reviews" },
    { key: "prs", label: "My PRs" }
  ]

  function ghFetch(key, proc, text) {
    try {
      const d = Object.assign({}, ghData)
      d[key] = JSON.parse(text)
      ghData = d
      ghLoaded = true
    } catch (e) {}
  }

  Process {
    id: issuesProcess
    command: ["gh", "search", "issues", "--assignee", "@me", "--state", "open",
      "--sort", "updated", "--limit", "30", "--json", "title,url,number,repository"]
    stdout: StdioCollector { onStreamFinished: ghFetch("issues", issuesProcess, text) }
  }

  Process {
    id: reviewsProcess
    command: ["gh", "search", "prs", "--review-requested", "@me", "--state", "open",
      "--sort", "updated", "--limit", "30", "--json", "title,url,number,repository"]
    stdout: StdioCollector { onStreamFinished: ghFetch("reviews", reviewsProcess, text) }
  }

  Process {
    id: prsProcess
    command: ["gh", "search", "prs", "--author", "@me", "--state", "open",
      "--sort", "updated", "--limit", "30", "--json", "title,url,number,repository"]
    stdout: StdioCollector { onStreamFinished: ghFetch("prs", prsProcess, text) }
  }

  Process {
    id: openProcess
  }

  function refreshGithub() {
    for (const p of [issuesProcess, reviewsProcess, prsProcess])
      if (!p.running) p.running = true
  }

  Timer {
    interval: 300000
    running: true
    repeat: true
    onTriggered: refreshGithub()
  }


  // Only one popup open at a time.
  Connections {
    target: CalendarState
    function onVisibleChanged() {
      if (!CalendarState.visible) ghMenuOpen = false
      if (CalendarState.visible) {
        PopupManager.closeAll("Calendar")
        refreshGithub()
        now = new Date()
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
      }
    }
  }

  // Any click outside the panel closes it.
  MouseArea {
    anchors.fill: parent
    enabled: CalendarState.visible
    acceptedButtons: Qt.AllButtons
    onPressed: CalendarState.visible = false
  }

  property date now: new Date()
  property int viewYear: now.getFullYear()
  property int viewMonth: now.getMonth() // 0 = January

  readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  function daysInMonth(y, m) {
    return new Date(y, m + 1, 0).getDate()
  }

  // JS Date.getDay() is 0=Sunday..6=Saturday; shift so the grid starts
  // on Monday instead, like a normal wall calendar.
  function firstWeekdayIndex(y, m) {
    return (new Date(y, m, 1).getDay() + 6) % 7
  }

  function previousMonth() {
    if (viewMonth === 0) {
      viewMonth = 11
      viewYear -= 1
    } else {
      viewMonth -= 1
    }
  }

  function nextMonth() {
    if (viewMonth === 11) {
      viewMonth = 0
      viewYear += 1
    } else {
      viewMonth += 1
    }
  }

  // Slide-in panel: a frosted-glass container (the "quickshell:widgets"
  // layer rule blurs what's behind, a faint tint sits on top), holding the
  // widgets as dark glass cards.
  Item {
    id: panel
    width: 276 + padding * 2
    readonly property int padding: 10
    anchors.top: parent.top
    anchors.topMargin: Theme.barGap + 1
    // Height follows the widgets stack.
    height: widgetsColumn.implicitHeight + padding * 2
    // Anchored to the right edge and slid via its margin, not an absolute x:
    // the window's width is still 0 on the first frame after it maps, which
    // made the panel start from the left.
    anchors.right: parent.right
    anchors.rightMargin: CalendarState.visible ? Theme.barGap : -width

    Behavior on anchors.rightMargin {
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Barely-tinted glass: mostly the blur of what's behind. The layer rule
    // (hypr rules/layers.lua) has a low ignore_alpha so this faint tint still blurs.
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

  Rectangle {
    id: card
    width: parent.width
    height: layout.implicitHeight + 24
    radius: Theme.popupRadius
    color: Theme.popupGlass

    Column {
      id: layout
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10

      // header: Month YYYY      <  >
      Row {
        width: parent.width
        height: 24

        Text {
          width: parent.width - 56
          anchors.verticalCenter: parent.verticalCenter
          text: months[viewMonth] + " " + viewYear
          color: Theme.popupText
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize + 3
          font.bold: true
        }

        Text {
          text: "‹"
          width: 24
          height: parent.height
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Theme.popupText
          font.pixelSize: Theme.fontSize + 6
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: previousMonth() }
        }

        Text {
          text: "›"
          width: 24
          height: parent.height
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Theme.popupText
          font.pixelSize: Theme.fontSize + 6
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: nextMonth() }
        }
      }

      // weekday header
      Grid {
        width: parent.width
        columns: 7

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
          delegate: Text {
            required property string modelData
            width: layout.width / 7
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
          }
        }
      }

      // day grid - 6 weeks x 7 days is always enough to cover a month
      Grid {
        width: parent.width
        columns: 7

        Repeater {
          model: 42

          delegate: Item {
            required property int index

            readonly property int dayNumber: index - firstWeekdayIndex(viewYear, viewMonth) + 1
            readonly property bool inMonth: dayNumber >= 1 && dayNumber <= daysInMonth(viewYear, viewMonth)
            readonly property bool isToday: inMonth
              && viewYear === now.getFullYear()
              && viewMonth === now.getMonth()
              && dayNumber === now.getDate()

            width: layout.width / 7
            height: 24

            Rectangle {
              anchors.centerIn: parent
              width: 24
              height: 24
              radius: 12
              color: parent.isToday ? Theme.popupText : "transparent"
            }

            Text {
              anchors.centerIn: parent
              visible: parent.inMonth
              text: parent.dayNumber
              color: parent.isToday ? "#000000" : Theme.popupText
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.bold: parent.isToday
            }
          }
        }
      }
    }
  }

      // now playing widget (hidden when no player is running)
      Rectangle {
        id: music
        readonly property MprisPlayer player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

        visible: player !== null
        width: parent.width
        height: 96
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Row {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12

          Rectangle {
            width: 72
            height: 72
            radius: 8
            color: Theme.popupHover
            clip: true

            Image {
              anchors.fill: parent
              source: music.player ? music.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              text: "󰎆"
              visible: !(music.player && music.player.trackArtUrl !== "")
              color: Theme.popupMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize + 12
            }
          }

          Column {
            width: parent.width - 72 - 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              width: parent.width
              text: music.player ? music.player.trackTitle : ""
              color: Theme.popupText
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: music.player ? music.player.trackArtist : ""
              color: Theme.popupMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              elide: Text.ElideRight
            }

            Row {
              spacing: 14
              topPadding: 4

              Repeater {
                model: [
                  { glyph: "󰒮", act: "prev" },
                  { glyph: "", act: "toggle" },
                  { glyph: "󰒭", act: "next" }
                ]
                delegate: Text {
                  required property var modelData
                  text: modelData.act === "toggle"
                    ? (music.player && music.player.isPlaying ? "󰏤" : "󰐊")
                    : modelData.glyph
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize + 6

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (!music.player) return
                      if (parent.modelData.act === "prev") music.player.previous()
                      else if (parent.modelData.act === "next") music.player.next()
                      else music.player.togglePlaying()
                    }
                  }
                }
              }
            }
          }
        }
      }

      // audio: output + microphone volume
      Rectangle {
        id: audio
        readonly property PwNode sink: Pipewire.defaultAudioSink
        readonly property PwNode source: Pipewire.defaultAudioSource

        width: parent.width
        height: audioLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        // Keeps the nodes' volume/mute state live instead of a snapshot.
        PwObjectTracker {
          objects: [audio.sink, audio.source].filter(n => n)
        }

        Column {
          id: audioLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 10

          Repeater {
            model: [
              { node: audio.sink, icon: "󰕾", mutedIcon: "󰝟" },
              { node: audio.source, icon: "󰍬", mutedIcon: "󰍭" }
            ]

            delegate: Item {
              id: row
              required property var modelData
              readonly property var node: modelData.node
              readonly property bool ready: node !== null && node !== undefined && node.ready
              readonly property bool muted: !ready || node.audio.muted
              readonly property real vol: ready ? node.audio.volume : 0

              width: audioLayout.width
              height: 24
              opacity: ready ? 1 : 0.4

              Text {
                id: rowIcon
                width: 24
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: row.muted ? row.modelData.mutedIcon : row.modelData.icon
                color: row.muted ? Theme.popupMuted : Theme.popupText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4

                MouseArea {
                  anchors.fill: parent
                  enabled: row.ready
                  cursorShape: Qt.PointingHandCursor
                  onClicked: row.node.audio.muted = !row.node.audio.muted
                }
              }

              Item {
                id: slider
                anchors.left: rowIcon.right
                anchors.leftMargin: 8
                anchors.right: rowPct.left
                anchors.rightMargin: 8
                height: parent.height

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: 5
                  radius: 2.5
                  color: Theme.popupLine

                  Rectangle {
                    width: parent.width * Math.min(row.vol, 1)
                    height: parent.height
                    radius: parent.radius
                    color: row.muted ? Theme.popupMuted : Theme.popupText
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: row.ready
                  cursorShape: Qt.PointingHandCursor
                  function setFrom(x) {
                    row.node.audio.volume = Math.max(0, Math.min(1, x / width))
                  }
                  onPressed: mouse => setFrom(mouse.x)
                  onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
                  onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                    row.node.audio.volume = Math.max(0, Math.min(1, row.vol + step))
                  }
                }
              }

              Text {
                id: rowPct
                width: 34
                anchors.right: parent.right
                height: parent.height
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: row.ready ? Math.round(row.vol * 100) + "%" : "--"
                color: Theme.popupText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }
        }
      }

      // github: issues / review requests / my PRs
      Rectangle {
        width: parent.width
        height: ghLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: ghLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 6

          // repo filter dropdown
          Column {
            width: parent.width
            spacing: 2
            visible: ghRepos.length > 1

            Item {
              width: parent.width
              height: 22

              Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                opacity: ddArea.containsMouse ? 1 : 0.75

                Text {
                  text: ghActiveRepo === "" ? "All repos" : ghActiveRepo
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 1
                  font.bold: true
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: ghMenuOpen ? "▴" : "▾"
                  color: Theme.popupMuted
                  font.pixelSize: Theme.fontSize - 3
                }
              }

              MouseArea {
                id: ddArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ghMenuOpen = !ghMenuOpen
              }
            }

            Repeater {
              model: ghMenuOpen ? [""].concat(ghRepos) : []

              delegate: Rectangle {
                required property string modelData
                readonly property bool current: ghActiveRepo === modelData

                width: parent.width
                height: 24
                radius: 6
                color: optArea.containsMouse ? Theme.popupHover : "transparent"

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 8
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: parent.modelData === "" ? "All repos" : parent.modelData
                  color: parent.current ? Theme.popupText : Theme.popupMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 2
                  font.bold: parent.current
                  elide: Text.ElideRight
                }

                MouseArea {
                  id: optArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    ghRepo = parent.modelData
                    ghMenuOpen = false
                  }
                }
              }
            }
          }

          Row {
            spacing: 14

            Repeater {
              model: ghTabs

              delegate: Text {
                required property var modelData
                readonly property bool current: ghTab === modelData.key

                text: modelData.label + (ghLoaded ? " " + ghFiltered(modelData.key).length : "")
                color: current ? Theme.popupText : Theme.popupMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: current

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: ghTab = parent.modelData.key
                }
              }
            }
          }

          Text {
            visible: ghLoaded && ghItems.length === 0
            text: "Nothing here"
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Repeater {
            model: ghItems

            delegate: Item {
              required property var modelData
              width: ghLayout.width
              height: rowCol.implicitHeight + 6

              Rectangle {
                anchors.fill: parent
                radius: 6
                color: rowArea.containsMouse ? Theme.popupHover : "transparent"
              }

              Column {
                id: rowCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  width: parent.width
                  text: modelData.title
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 1
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.repository.nameWithOwner + " #" + modelData.number
                  color: Theme.popupMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 3
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  openProcess.command = ["xdg-open", modelData.url]
                  openProcess.running = true
                  CalendarState.visible = false
                }
              }
            }
          }
        }
      }

      // system usage
      Rectangle {
        width: parent.width
        height: sysLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: sysLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 8

          Repeater {
            model: [
              { label: "CPU", pct: SystemStatsState.cpuPercent,
                text: SystemStatsState.cpuPercent.toFixed(0) + "%  " + SystemStatsState.tempC.toFixed(0) + "°C" },
              { label: "RAM", pct: 100 * SystemStatsState.memUsedGiB / Math.max(SystemStatsState.memTotalGiB, 1),
                text: SystemStatsState.memUsedGiB.toFixed(1) + " / " + SystemStatsState.memTotalGiB.toFixed(0) + " GiB" },
              { label: "Disk", pct: SystemStatsState.diskPercent,
                text: SystemStatsState.diskPercent.toFixed(0) + "%" }
            ]

            delegate: Item {
              required property var modelData
              width: sysLayout.width
              height: 16

              Text {
                id: sysLabel
                width: 34
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: Theme.popupMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
              }

              Rectangle {
                id: sysTrack
                anchors.left: sysLabel.right
                anchors.right: sysValue.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 5
                radius: 2.5
                color: Theme.popupLine

                Rectangle {
                  width: parent.width * Math.min(Math.max(modelData.pct, 0), 100) / 100
                  height: parent.height
                  radius: parent.radius
                  color: modelData.pct >= 85 ? Theme.popupUrgent : Theme.popupText

                  Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                  }
                }
              }

              Text {
                id: sysValue
                width: 92
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: modelData.text
                color: Theme.popupText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }
        }
      }

      // stopwatch widget
      Rectangle {
        width: parent.width
        height: 56
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Row {
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 12
          spacing: 8

          Text {
            width: parent.width - 36 * 2 - 8 * 2
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: StopwatchState.format(StopwatchState.elapsedMs, true)
            color: StopwatchState.running ? Theme.popupText : Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 6
          }

          Repeater {
            model: [
              { glyph: "reset", act: "reset" },
              { glyph: "toggle", act: "toggle" }
            ]

            delegate: Item {
              required property var modelData
              readonly property bool isReset: modelData.act === "reset"

              width: 36
              height: parent.height
              opacity: isReset && !StopwatchState.active ? 0.35 : 1

              Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: btnArea.containsMouse ? Theme.popupLine : Theme.popupHover

                Text {
                  anchors.centerIn: parent
                  text: parent.parent.isReset ? "󰑐" : (StopwatchState.running ? "󰏤" : "󰐊")
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize + 3
                }
              }

              MouseArea {
                id: btnArea
                anchors.fill: parent
                enabled: !parent.isReset || StopwatchState.active
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.isReset ? StopwatchState.reset() : StopwatchState.toggle()
              }
            }
          }
        }
      }
    }
  }
}
