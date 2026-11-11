import QtQuick
import QtQuick.Effects
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Io

// Side panel with live prices, opened from the bar's markets entry
// (Markets.qml). Same construction as AgentsPanel.qml: a frosted glass
// container sliding in from the right with one dark glass card, here a
// tab switch (Stocks / Crypto / Currencies) above the price list.
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
      // So the add-symbol field can take typing.
      this.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
    }
  }

  visible: MarketsState.visible || panel.anchors.rightMargin > -panel.width

  // `qs ipc call markets toggle` - handy for a keybind.
  IpcHandler {
    target: "markets"
    function toggle(): void { MarketsState.visible = !MarketsState.visible }
  }

  Connections {
    target: MarketsState
    function onVisibleChanged() {
      if (MarketsState.visible)
        PopupManager.closeAll("Markets")
    }
  }

  // Any click outside the panel closes it.
  MouseArea {
    anchors.fill: parent
    enabled: MarketsState.visible
    acceptedButtons: Qt.AllButtons
    onPressed: MarketsState.visible = false
  }

  // The theme's popupGood/popupUrgent are plain white, which would make
  // gains and losses indistinguishable, so the charts bring their own.
  readonly property color gain: "#30d158"
  readonly property color loss: "#ff453a"


  Item {
    id: panel
    width: 276 + padding * 2
    readonly property int padding: 10
    anchors.top: parent.top
    anchors.topMargin: Theme.barGap + 1
    height: content.implicitHeight + padding * 2
    anchors.right: parent.right
    anchors.rightMargin: MarketsState.visible ? Theme.barGap : -width

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
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: panel.padding

      Rectangle {
        width: parent.width
        height: cardLayout.implicitHeight + 24
        radius: Theme.popupRadius
        color: Theme.popupGlass

        Column {
          id: cardLayout
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 8

          // tab switch
          Rectangle {
            width: parent.width
            height: 28
            radius: 8
            color: Theme.popupLine

            Row {
              anchors.fill: parent
              anchors.margins: 2

              Repeater {
                model: MarketsState.tabs

                Rectangle {
                  required property var modelData
                  readonly property bool selected: MarketsState.tab === modelData.id
                  width: parent.width / MarketsState.tabs.length
                  height: parent.height
                  radius: 6
                  color: selected ? Theme.popupHover : tabArea.containsMouse ? "#0dffffff" : "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.selected ? Theme.popupText : Theme.popupMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    font.bold: parent.selected
                  }

                  MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MarketsState.tab = modelData.id
                  }
                }
              }
            }
          }

          Text {
            visible: !MarketsState.loaded
            text: MarketsState.failed ? "Prices unavailable" : "Loading…"
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
          }

          Repeater {
            model: MarketsState.current

            Rectangle {
              id: row
              required property var modelData
              readonly property bool up: (modelData.change || 0) >= 0
              readonly property color tone: up ? win.gain : win.loss
              readonly property bool open: MarketsState.expanded === modelData.ticker
              // Points for the big chart: the row's own data for the first
              // range, otherwise whatever was fetched for the chosen one.
              readonly property var detailPoints: {
                if (MarketsState.range === MarketsState.ranges[0]) return modelData.spark || []
                const c = MarketsState.chart
                return c.symbol === modelData.ticker && c.range === MarketsState.range ? c.points : []
              }
              readonly property var detailTimes: {
                if (MarketsState.range === MarketsState.ranges[0]) return modelData.times || []
                const c = MarketsState.chart
                return c.symbol === modelData.ticker && c.range === MarketsState.range ? c.times || [] : []
              }
              width: cardLayout.width
              height: 52 + (open ? details.height + 8 : 0)
              radius: 10
              clip: true
              color: rowArea.containsMouse || open ? Theme.popupHover : "transparent"

              Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
              }

              Behavior on color {
                ColorAnimation { duration: 120 }
              }

              Column {
                x: 8
                y: (52 - height) / 2
                width: 78
                spacing: 2

                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: modelData.symbol
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize
                  font.bold: true
                }
                Text {
                  width: parent.width
                  text: modelData.name
                  elide: Text.ElideRight
                  color: Theme.popupMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 4
                }
              }

              Canvas {
                id: spark
                opacity: row.open ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }
                y: (52 - height) / 2
                x: 90
                width: parent.width - 90 - 84
                height: 34
                readonly property var points: modelData.spark || []
                readonly property color tone: row.tone
                onPointsChanged: requestPaint()
                onToneChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                  const ctx = getContext("2d")
                  ctx.reset()
                  const p = points
                  if (p.length < 2) return
                  const lo = Math.min.apply(null, p)
                  const hi = Math.max.apply(null, p)
                  const range = hi - lo || 1
                  const padY = 4
                  const padX = 4
                  const xs = i => padX + i / (p.length - 1) * (width - padX * 2)
                  const ys = v => height - padY - (v - lo) / range * (height - padY * 2)

                  const line = () => {
                    ctx.beginPath()
                    ctx.moveTo(xs(0), ys(p[0]))
                    for (let i = 1; i < p.length; i++) {
                      // Midpoint quadratics smooth the corners of the polyline.
                      const mx = (xs(i - 1) + xs(i)) / 2
                      const my = (ys(p[i - 1]) + ys(p[i])) / 2
                      ctx.quadraticCurveTo(xs(i - 1), ys(p[i - 1]), mx, my)
                    }
                    ctx.lineTo(xs(p.length - 1), ys(p[p.length - 1]))
                  }

                  // soft fill under the line
                  line()
                  ctx.lineTo(xs(p.length - 1), height)
                  ctx.lineTo(xs(0), height)
                  ctx.closePath()
                  const g = ctx.createLinearGradient(0, 0, 0, height)
                  g.addColorStop(0, Qt.rgba(tone.r, tone.g, tone.b, 0.28))
                  g.addColorStop(1, Qt.rgba(tone.r, tone.g, tone.b, 0))
                  ctx.fillStyle = g
                  ctx.fill()

                  line()
                  ctx.strokeStyle = tone
                  ctx.lineWidth = 1.6
                  ctx.lineJoin = "round"
                  ctx.lineCap = "round"
                  ctx.stroke()

                  // marker on the latest value
                  ctx.beginPath()
                  ctx.arc(xs(p.length - 1), ys(p[p.length - 1]), 2.4, 0, Math.PI * 2)
                  ctx.fillStyle = tone
                  ctx.fill()
                }
              }

              Column {
                anchors.right: parent.right
                anchors.rightMargin: 8
                y: (52 - height) / 2
                spacing: 3

                Text {
                  anchors.right: parent.right
                  text: MarketsState.format(modelData.price, modelData.currency)
                  color: Theme.popupText
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 1
                  font.bold: true
                }
                Rectangle {
                  anchors.right: parent.right
                  width: pct.implicitWidth + 10
                  height: pct.implicitHeight + 3
                  radius: height / 2
                  color: Qt.rgba(row.tone.r, row.tone.g, row.tone.b, 0.18)

                  Text {
                    id: pct
                    anchors.centerIn: parent
                    text: MarketsState.percent(modelData.change)
                    color: row.tone
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                    font.bold: true
                  }
                }
              }

              MouseArea {
                id: rowArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 52
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MarketsState.toggle(modelData.ticker)
              }

              // expanded details: range switch, bigger chart and stats
              Column {
                id: details
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 54
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8
                opacity: row.open ? 1 : 0

                Behavior on opacity {
                  NumberAnimation { duration: 180 }
                }

                Row {
                  spacing: 4

                  Repeater {
                    model: MarketsState.ranges

                    Rectangle {
                      required property string modelData
                      readonly property bool selected: MarketsState.range === modelData
                      width: rangeLabel.implicitWidth + 16
                      height: 20
                      radius: 10
                      color: selected ? Qt.rgba(row.tone.r, row.tone.g, row.tone.b, 0.22) : "transparent"

                      Text {
                        id: rangeLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: parent.selected ? row.tone : Theme.popupMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                        font.bold: true
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MarketsState.select(row.modelData.ticker, modelData)
                      }
                    }
                  }
                }

                Item {
                  width: parent.width
                  height: 96

                  Canvas {
                    id: big
                    anchors.fill: parent
                    readonly property var points: row.detailPoints
                    readonly property color tone: row.tone
                    // Index of the point under the cursor, -1 when not hovering.
                    property int hover: -1
                    property real cursorX: 0
                    property real cursorY: 0
                    onHoverChanged: requestPaint()
                    onPointsChanged: { hover = -1; requestPaint() }
                    onToneChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                      const ctx = getContext("2d")
                      ctx.reset()
                      const p = points
                      if (p.length < 2) return
                      const lo = Math.min.apply(null, p)
                      const hi = Math.max.apply(null, p)
                      const range = hi - lo || 1
                      const pad = 6
                      const xs = i => i / (p.length - 1) * width
                      const ys = v => height - pad - (v - lo) / range * (height - pad * 2)

                      // faint guides at the high and low
                      ctx.strokeStyle = "#22ffffff"
                      ctx.lineWidth = 1
                      ctx.setLineDash([3, 4])
                      for (const v of [lo, hi]) {
                        ctx.beginPath()
                        ctx.moveTo(0, Math.round(ys(v)) + 0.5)
                        ctx.lineTo(width, Math.round(ys(v)) + 0.5)
                        ctx.stroke()
                      }
                      ctx.setLineDash([])

                      const line = () => {
                        ctx.beginPath()
                        ctx.moveTo(xs(0), ys(p[0]))
                        for (let i = 1; i < p.length; i++) {
                          const mx = (xs(i - 1) + xs(i)) / 2
                          const my = (ys(p[i - 1]) + ys(p[i])) / 2
                          ctx.quadraticCurveTo(xs(i - 1), ys(p[i - 1]), mx, my)
                        }
                        ctx.lineTo(xs(p.length - 1), ys(p[p.length - 1]))
                      }

                      line()
                      ctx.lineTo(width, height)
                      ctx.lineTo(0, height)
                      ctx.closePath()
                      const g = ctx.createLinearGradient(0, 0, 0, height)
                      g.addColorStop(0, Qt.rgba(tone.r, tone.g, tone.b, 0.30))
                      g.addColorStop(1, Qt.rgba(tone.r, tone.g, tone.b, 0))
                      ctx.fillStyle = g
                      ctx.fill()

                      line()
                      ctx.strokeStyle = tone
                      ctx.lineWidth = 1.8
                      ctx.lineJoin = "round"
                      ctx.lineCap = "round"
                      ctx.stroke()

                      const h = hover >= 0 && hover < p.length ? hover : p.length - 1
                      if (hover >= 0) {
                        ctx.strokeStyle = "#66ffffff"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(Math.round(xs(h)) + 0.5, 0)
                        ctx.lineTo(Math.round(xs(h)) + 0.5, height)
                        ctx.stroke()
                      }
                      ctx.beginPath()
                      ctx.arc(xs(h), ys(p[h]), hover >= 0 ? 4 : 3, 0, Math.PI * 2)
                      ctx.fillStyle = tone
                      ctx.fill()
                      if (hover >= 0) {
                        ctx.lineWidth = 1.5
                        ctx.strokeStyle = "#ffffff"
                        ctx.stroke()
                      }
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => {
                      const n = big.points.length
                      if (n < 2) return
                      big.cursorX = mouse.x
                      big.cursorY = mouse.y
                      big.hover = Math.max(0, Math.min(n - 1, Math.round(mouse.x / width * (n - 1))))
                    }
                    onExited: big.hover = -1
                  }

                  // Value and time of the hovered point.
                  Rectangle {
                    id: tip
                    visible: big.hover >= 0 && big.hover < big.points.length
                    readonly property real px: big.points.length > 1 ? big.hover / (big.points.length - 1) * big.width : 0
                    x: Math.max(0, Math.min(big.width - width, big.cursorX - width / 2))
                    // Follows the cursor, sitting just above it.
                    y: big.cursorY - height - 14
                    width: tipColumn.implicitWidth + 14
                    height: tipColumn.implicitHeight + 8
                    radius: 8
                    color: "#e6141414"
                    border.width: 1
                    border.color: Theme.popupLine

                    Column {
                      id: tipColumn
                      anchors.centerIn: parent
                      spacing: 1

                      Text {
                        text: big.hover >= 0 && big.hover < big.points.length ? MarketsState.format(big.points[big.hover], row.modelData.currency) : ""
                        color: Theme.popupText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        font.bold: true
                      }
                      Text {
                        text: {
                          const t = big.hover >= 0 ? row.detailTimes[big.hover] : undefined
                          if (t === undefined) return ""
                          const d = new Date(t * 1000)
                          // Intraday ranges show the time, longer ones the date.
                          return MarketsState.range === "1D" && MarketsState.kind !== "fx"
                            ? Qt.formatTime(d, "HH:mm")
                            : Qt.formatDate(d, "d MMM yyyy")
                        }
                        color: Theme.popupMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                      }
                    }
                  }

                  Text {
                    visible: row.detailPoints.length < 2
                    anchors.centerIn: parent
                    text: "Loading…"
                    color: Theme.popupMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                  }
                }

                Grid {
                  width: parent.width
                  columns: 2
                  columnSpacing: 12
                  rowSpacing: 6

                  Repeater {
                    model: row.modelData.stats || []

                    Column {
                      required property var modelData
                      width: (details.width - 12) / 2
                      spacing: 1

                      Text {
                        text: modelData[0]
                        color: Theme.popupMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                      }
                      Text {
                        width: parent.width
                        text: modelData[1]
                        elide: Text.ElideRight
                        color: Theme.popupText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                      }
                    }
                  }
                }

                Text {
                  text: "Remove from list"
                  color: Theme.popupMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize - 4

                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      MarketsState.expanded = ""
                      MarketsState.remove(row.modelData.ticker)
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 28
            radius: 8
            color: "transparent"
            border.width: 1
            border.color: addInput.activeFocus ? Theme.popupMuted : Theme.popupLine

            TextInput {
              id: addInput
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              verticalAlignment: TextInput.AlignVCenter
              color: Theme.popupText
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              clip: true
              onAccepted: {
                if (text.trim() === "") return
                MarketsState.edit("add", text)
                text = ""
              }

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: addInput.text === "" && !addInput.activeFocus
                text: "+ Add symbol"
                color: Theme.popupMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
              }
            }
          }

          Text {
            visible: MarketsState.editError !== ""
            text: MarketsState.editError
            color: win.loss
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            leftPadding: 4
          }

          Text {
            visible: MarketsState.loaded
            text: "Updated " + Qt.formatTime(new Date(MarketsState.data.updated * 1000), "HH:mm")
              + (MarketsState.kind === "fx" ? " · daily ECB rates" : MarketsState.tab === "crypto" ? " · last 24h" : " · today")
            color: Theme.popupMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            leftPadding: 4
          }
        }
      }
    }
  }
}
