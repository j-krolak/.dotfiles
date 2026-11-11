import QtQuick
import Quickshell

// Same idea as waybar's "clock" module, using Quickshell's built-in
// SystemClock so we don't have to manage our own Timer + Date. Click it
// to open the mini calendar (modules/Calendar.qml, its own window).
Text {
    color: Theme.barForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    height: Theme.fontSize + 7
    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd MMM d  HH:mm")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarState.visible = !CalendarState.visible
    }
}
