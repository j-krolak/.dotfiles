import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland

// A small month-view calendar, opened by clicking the clock in the bar.
// No QtQuick module ships an actual calendar widget here, so this is
// just plain date math (JS Date) laid out in a 7-wide Grid - the same
// "no framework magic" spirit as the rest of the bar.
//
// The window covers the whole screen (invisibly, apart from the actual
// card) so there's something to click "outside of" - a MouseArea behind
// the card closes the calendar, and the card has its own MouseArea just
// to swallow clicks before they reach that one.
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

  visible: CalendarState.visible

  MouseArea {
    anchors.fill: parent
    onClicked: CalendarState.visible = false
  }

  readonly property date now: new Date()
  property int viewYear: now.getFullYear()
  property int viewMonth: now.getMonth() // 0 = January

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

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    // Bar's rendered pill height (~29px) plus a 10px gap to match the
    // spacing the user asked for between the popup and the bar.
    anchors.topMargin: 5
    width: 220
    height: layout.implicitHeight + 20
    radius: 10
    color: Theme.popupBackground

    // Swallows the click so it doesn't fall through to the full-screen
    // MouseArea behind the card and immediately close the calendar.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: layout
      x: 12
      y: 10
      width: parent.width - 24
      spacing: 8

      // header: <  Month YYYY  >
      Row {
        width: parent.width

        Text {
          text: "‹"
          width: 24
          horizontalAlignment: Text.AlignHCenter
          color: Theme.muted
          font.pixelSize: Theme.fontSize + 2
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: previousMonth() }
        }

        Text {
          width: parent.width - 48
          horizontalAlignment: Text.AlignHCenter
          text: new Date(viewYear, viewMonth, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy")
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.bold: true
        }

        Text {
          text: "›"
          width: 24
          horizontalAlignment: Text.AlignHCenter
          color: Theme.muted
          font.pixelSize: Theme.fontSize + 2
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
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
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
            height: 26

            Rectangle {
              anchors.centerIn: parent
              width: 22
              height: 22
              radius: 11
              color: parent.isToday ? Theme.accent : "transparent"
            }

            Text {
              anchors.centerIn: parent
              visible: parent.inMonth
              text: parent.dayNumber
              color: parent.isToday ? Theme.background : Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
            }
          }
        }
      }
    }
  }
}
