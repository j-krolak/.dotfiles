pragma Singleton
import QtQuick

// Same trick as TaskwarriorState: the bar widget (Stopwatch.qml) and the
// popup (StopwatchOverview.qml) are independent windows, so the stopwatch
// lives in a shared singleton. Elapsed time is derived from an absolute
// start timestamp rather than incremented per tick, so a late tick can't
// make it drift.
QtObject {
    id: root

    property bool visible: false
    property real popupX: 0

    property bool running: false
    // Time banked from previous run segments, before the last resume.
    property real bankedMs: 0
    property real startMs: 0
    // Bumped by the ticker so `elapsedMs` re-evaluates.
    property real nowMs: Date.now()

    readonly property real elapsedMs: running ? bankedMs + (nowMs - startMs) : bankedMs
    readonly property bool active: running || bankedMs > 0

    function toggle() {
        if (running) {
            nowMs = Date.now()
            bankedMs += nowMs - startMs
            running = false
        } else {
            nowMs = Date.now()
            startMs = nowMs
            running = true
        }
    }

    function reset() {
        running = false
        bankedMs = 0
    }

    function format(ms, withCentis) {
        const total = Math.floor(ms / 10)
        const cs = total % 100
        const s = Math.floor(total / 100) % 60
        const m = Math.floor(total / 6000) % 60
        const h = Math.floor(total / 360000)
        const pad = n => String(n).padStart(2, "0")
        const base = (h > 0 ? h + ":" : "") + pad(m) + ":" + pad(s)
        return withCentis ? base + "." + pad(cs) : base
    }

    readonly property Timer ticker: Timer {
        interval: 50
        running: root.running
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }
}
