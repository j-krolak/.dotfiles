import QtQuick

// Bar icon for the stopwatch. Shows just the icon while idle and the
// elapsed time once it has been started; click to open
// modules/StopwatchOverview.qml.
Text {
    id: root

    color: !StopwatchState.active ? Theme.foreground
        : StopwatchState.running ? Theme.accent
        : Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: "󱎫" + (StopwatchState.active ? " " + StopwatchState.format(StopwatchState.elapsedMs, false) : "")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            StopwatchState.popupX = root.mapToItem(null, 0, root.height).x
            StopwatchState.visible = !StopwatchState.visible
        }
    }
}
