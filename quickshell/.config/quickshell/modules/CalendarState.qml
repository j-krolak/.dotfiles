pragma Singleton
import QtQuick

// The clock (inside Bar.qml's window) and the calendar popup (its own
// top-level window under shell.qml's ShellRoot) are two independent
// windows, so there's no parent/child relationship to pass a "toggle"
// through directly - a small shared singleton is the simplest way for
// one to tell the other to show/hide. Same trick as Theme, just for a
// bit of live state instead of constants.
QtObject {
    property bool visible: false
}
