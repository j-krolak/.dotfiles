import QtQuick
import Quickshell
import Quickshell.Io

// macOS-style recording indicator: a pulsing red dot, shown only while
// wf-recorder is running. Click to stop the recording.
Item {
    id: root

    property bool recording: false

    visible: recording
    implicitWidth: recording ? dot.width + Theme.modulePadding * 2 : 0
    implicitHeight: Theme.fontSize + 7

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProcess.running = true
    }

    Process {
        id: checkProcess
        command: ["pgrep", "-x", "wf-recorder"]
        // pgrep exits 0 when a match exists, 1 otherwise.
        onExited: code => root.recording = code === 0
    }

    Process {
        id: stopProcess
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/stop_recording.sh"]
    }

    Rectangle {
        id: dot
        anchors.centerIn: parent
        width: 9
        height: 9
        radius: width / 2
        color: "#ff453a"

        SequentialAnimation on opacity {
            running: root.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: stopProcess.running = true
    }
}
