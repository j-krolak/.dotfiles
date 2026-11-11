import QtQuick

// Bar entry for the coding agents herdr is running: a little robot head,
// coloured by state and with no text for the simple ones:
//   working  - white, antenna pulses, slides open to show the session title
//   blocked  - orange, faster pulse, title in orange: an agent waits on your answer
//   done     - green: an agent finished and you haven't looked at it yet
//   idle     - dim
// Hidden when there are no agents. Click opens AgentsPanel.qml.
Item {
    id: root

    readonly property bool working: AgentsState.workingCount > 0
    // herdr's "blocked" = an agent is sitting on an approval/question prompt
    // and waiting for an answer. It beats "working", which beats "done"
    // (finished and not looked at yet), for what the bar shows.
    readonly property bool blocked: AgentsState.blockedCount > 0
    readonly property bool done: AgentsState.doneCount > 0
    readonly property string mode: blocked ? "blocked" : working ? "working" : done ? "done" : "idle"
    readonly property bool active: mode !== "idle"
    readonly property int activeCount: blocked ? AgentsState.blockedCount : working ? AgentsState.workingCount : AgentsState.doneCount
    readonly property color attention: "#ff9f0a"
    readonly property color finished: "#30d158"
    readonly property var current: AgentsState.agents.find(a => a.agent_status === (blocked ? "blocked" : "working"))
    readonly property string title: current ? (current.terminal_title_stripped || current.agent) : ""
    readonly property int padding: 0

    visible: AgentsState.agents.length > 0
    implicitWidth: visible ? pill.width + Theme.modulePadding * 2 : 0
    implicitHeight: Theme.fontSize + 7

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: 22
        radius: height / 2
        color: "transparent"

        // Starts at the robot and grows by the slid-out part.
        width: root.padding * 2 + star.width + slide.width + (slide.width > 0 ? row.spacing : 0)
        clip: true

        Behavior on width {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Row {
            id: row
            x: root.padding
            height: parent.height
            spacing: 6

            // Little robot head. While an agent works the antenna light pulses
            // and the eyes blink; still and dim when idle.
            Item {
                id: star
                anchors.verticalCenter: parent.verticalCenter
                // Same footprint as the other bar icons (StatusItem.iconSize).
                width: 14
                height: 14
                readonly property color tone: root.blocked ? root.attention : root.working ? Theme.barForeground : root.done ? root.finished : Theme.barMuted

                // Drawn on a 16px grid, scaled down to the icon size.
                Item {
                    width: 16
                    height: 16
                    scale: 14 / 16
                    transformOrigin: Item.TopLeft

                    // antenna
                    Rectangle {
                        x: 7.25
                        y: 2.5
                        width: 1.5
                        height: 2.5
                        color: star.tone
                    }
                    Rectangle {
                        id: bulb
                        x: 6
                        y: 0.5
                        width: 4
                        height: 4
                        radius: 2
                        color: star.tone

                        SequentialAnimation on opacity {
                            running: root.blocked || root.working
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) bulb.opacity = 1
                            NumberAnimation { to: 0.25; duration: root.blocked ? 320 : 650; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: root.blocked ? 320 : 650; easing.type: Easing.InOutSine }
                        }
                    }

                    // ears
                    Rectangle { x: 0; y: 8.5; width: 1.5; height: 3.5; radius: 0.75; color: star.tone }
                    Rectangle { x: 14.5; y: 8.5; width: 1.5; height: 3.5; radius: 0.75; color: star.tone }

                    // head
                    Rectangle {
                        x: 2
                        y: 5
                        width: 12
                        height: 10
                        radius: 3.5
                        color: "transparent"
                        border.width: 1.5
                        border.color: star.tone

                        Row {
                            anchors.centerIn: parent
                            spacing: 2.5

                            Repeater {
                                model: 2

                                Rectangle {
                                    id: eye
                                    width: 2.2
                                    height: 2.2
                                    radius: 1.1
                                    color: star.tone
                                    transformOrigin: Item.Center

                                    SequentialAnimation on scale {
                                        running: root.working
                                        loops: Animation.Infinite
                                        onRunningChanged: if (!running) eye.scale = 1
                                        PauseAnimation { duration: 1800 }
                                        NumberAnimation { to: 0.1; duration: 90 }
                                        NumberAnimation { to: 1; duration: 120 }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: slide
                anchors.verticalCenter: parent.verticalCenter
                height: label.implicitHeight
                clip: true
                width: root.blocked || root.working ? Math.min(label.implicitWidth, 170) : 0

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    // Keep the last title while collapsing instead of blanking mid-slide.
                    property string shown: ""
                    text: shown + (root.activeCount > 1 ? "  +" + (root.activeCount - 1) : "")
                    color: root.blocked ? root.attention : Theme.barForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 170)

                    Connections {
                        target: root
                        function onTitleChanged() {
                            if (root.title !== "")
                                label.shown = root.title
                        }
                    }
                    Component.onCompleted: shown = root.title
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: AgentsState.visible = !AgentsState.visible
    }
}
