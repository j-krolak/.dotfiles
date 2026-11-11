pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// State behind the markets widget (Markets.qml in the bar, MarketsPanel.qml,
// its side panel). Prices come from scripts/markets.py, polled on a timer:
// slowly while only the bar entry is showing, faster while the panel is open.
QtObject {
    id: root

    property bool visible: false
    // "stocks" | "crypto" | "fx"
    property string tab: "stocks"
    // { updated, tabs: [{ id, label, type: "yahoo"|"fx", items: [...] }] }, from markets.json via the script.
    property var data: ({ tabs: [] })
    property bool loaded: false
    property bool failed: false

    readonly property var tabs: data.tabs
    readonly property var currentTab: tabs.find(t => t.id === tab) || tabs[0] || null
    readonly property var current: currentTab ? currentTab.items : []
    readonly property string kind: currentTab ? currentTab.type : "yahoo"
    // The bar shows the first item of the first tab, e.g. NVDA.
    readonly property var headline: tabs.length > 0 && tabs[0].items.length > 0 ? tabs[0].items[0] : null

    // The row that is expanded in the panel, and the chart range shown for it.
    // Longer ranges are fetched on demand; "default" is the sparkline's own
    // data (today for stocks/crypto, 30 days for currencies).
    property string expanded: ""
    property string range: "default"
    property var chart: ({ symbol: "", range: "", points: [] })
    readonly property var ranges: kind === "fx" ? ["1M", "3M", "1Y"] : ["1D", "1M", "1Y"]

    onTabChanged: expanded = ""

    function toggle(symbol) {
        expanded = expanded === symbol ? "" : symbol
        range = ranges[0]
    }

    function select(symbol, r) {
        range = r
        // The first range is already in the row's own data.
        if (r === ranges[0]) return
        chartProcess.running = false
        chartProcess.command = [script, "chart", symbol, r, kind]
        chartProcess.running = true
    }

    property Process chartProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.chart = JSON.parse(text) } catch (e) {}
            }
        }
    }

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/markets.py"
    property string editError: ""

    // Add or remove a symbol on the current tab (rewrites markets.json).
    function edit(action, symbol) {
        editError = ""
        editProcess.command = [script, "edit", action, tab, symbol]
        editProcess.running = true
    }

    // markets.json stores crypto without its "-USD" suffix.
    function remove(ticker) {
        const suffix = currentTab && currentTab.suffix ? currentTab.suffix : ""
        edit("remove", suffix && ticker.endsWith(suffix) ? ticker.slice(0, -suffix.length) : ticker)
    }

    property Process editProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    root.editError = r.ok ? "" : r.error
                    if (r.ok) root.refresh()
                } catch (e) {}
            }
        }
    }

    function refresh() {
        if (!process.running)
            process.running = true
    }

    Component.onCompleted: refresh()

    onVisibleChanged: {
        if (visible) refresh()
        else expanded = ""
    }

    property Timer poll: Timer {
        interval: root.visible ? 30000 : 120000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    property Process process: Process {
        command: [root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(text)
                    root.loaded = true
                    root.failed = false
                } catch (e) {
                    root.failed = true
                }
            }
        }
    }

    function format(price, currency) {
        const digits = price >= 1000 ? 0 : price >= 10 ? 2 : price >= 1 ? 3 : 4
        const n = price.toFixed(digits)
        return currency === "" ? n : currency === "USD" ? "$" + n : n + " " + currency
    }

    function percent(change) {
        if (change === null || change === undefined) return "–"
        return (change >= 0 ? "+" : "") + change.toFixed(2) + "%"
    }
}
