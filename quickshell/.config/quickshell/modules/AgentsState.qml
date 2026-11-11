pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// State behind the agents widget (Agents.qml in the bar, AgentsPanel.qml,
// its side panel), shared as a singleton for the same reason as BatteryState.
//
// Agent status is event-driven: herdr's socket API pushes
// pane.agent_status_changed, but only for explicitly subscribed panes, so
// this subscribes to every pane that currently hosts an agent and re-lists
// whenever an agent appears or a pane goes away. There is no polling timer;
// the only timer is a reconnect attempt while herdr isn't running.
//
// Usage numbers (plan limits, tokens, cost) are not live data and are
// fetched by AgentsPanel.qml only when the panel opens.
QtObject {
    id: root

    property bool visible: false

    Component.onCompleted: refresh()
    // Newest-first is not guaranteed by herdr; sorted for display below.
    property var agents: []

    readonly property int workingCount: agents.filter(a => a.agent_status === "working").length
    // "done" = finished while you weren't looking; herdr flips it back to idle
    // once you focus the agent.
    readonly property int doneCount: agents.filter(a => a.agent_status === "done").length
    readonly property int blockedCount: agents.filter(a => a.agent_status === "blocked").length

    // herdr accepts a single events.subscribe per connection (a second one
    // gets the connection dropped), so the subscription covers every pane
    // known at connect time and the socket is reconnected whenever the set
    // of agent panes changes.
    property string subscribedKey: ""
    readonly property string paneKey: agents.map(a => a.pane_id).sort().join(",")

    function subscribe() {
        subscribedKey = paneKey
        const subscriptions = [
            { type: "pane.agent_detected" },
            { type: "pane.closed" },
            { type: "pane.exited" }
        ].concat(agents.map(a => ({ type: "pane.agent_status_changed", pane_id: a.pane_id })))
        socket.write(JSON.stringify({
            id: "sub",
            method: "events.subscribe",
            params: { subscriptions: subscriptions }
        }) + "\n")
    }

    function syncSubscriptions() {
        if (socket.connected && paneKey !== subscribedKey) {
            socket.connected = false
            Qt.callLater(() => socket.connected = true)
        }
    }

    function refresh() {
        listProcess.running = true
    }

    property Timer debounce: Timer {
        interval: 150
        onTriggered: root.refresh()
    }

    property Timer reconnect: Timer {
        interval: 5000
        repeat: true
        running: !socket.connected
        onTriggered: socket.connected = true
    }

    property Process listProcess: Process {
        command: ["herdr", "agent", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.agents = JSON.parse(text).result.agents
                    root.syncSubscriptions()
                } catch (e) {}
            }
        }
    }

    property Process focusProcess: Process {}

    function focus(paneId) {
        focusProcess.command = ["herdr", "agent", "focus", paneId]
        focusProcess.running = true
    }

    property Socket socket: Socket {
        path: Quickshell.env("HOME") + "/.config/herdr/herdr.sock"
        connected: true

        onConnectedChanged: {
            if (connected) {
                root.subscribe()
                root.refresh()
            }
        }

        parser: SplitParser {
            // Acks carry "result"/"error"; everything else is an event.
            onRead: line => {
                if (!line.includes('"subscription_started"'))
                    root.debounce.restart()
            }
        }
    }
}
