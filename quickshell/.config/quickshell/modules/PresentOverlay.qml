import QtQuick
import Quickshell
import Quickshell.Wayland

// The visible half of presenting mode (see PresentState.qml for the wiring):
// a ring trailing the cursor and a ripple at every click. One of these per
// monitor, instantiated from shell.qml.
//
// Two things make it safe to leave sitting on the Overlay layer: an empty
// input mask, so the compositor never routes a click here and everything
// underneath behaves exactly as it would without the overlay, and visible:false
// whenever presenting mode is off.
//
// Everything drawn here is inside the zoomed viewport, so it scales with
// cursor:zoom_factor - sizes below are what you see at 1x.
PanelWindow {
    id: overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Ignore (rather than exclusiveZone: 0, which forces the mode back to
    // Normal): the overlay has to cover the whole screen, bar included, or
    // every ripple lands offset by the bar's exclusive zone.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: PresentState.active

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:present"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    // Hyprland reports the cursor in global layout coordinates; this window
    // covers one monitor, so shift into that monitor's space.
    readonly property real cursorX: PresentState.cursorX - screen.x
    readonly property real cursorY: PresentState.cursorY - screen.y

    readonly property color leftColor: Theme.accent
    readonly property color rightColor: Theme.warning
    readonly property color middleColor: Theme.good

    function colorFor(button) {
        if (button === 273)
            return rightColor
        if (button === 274)
            return middleColor
        return leftColor
    }

    // Deliberately unanimated: this marks where the pointer *is*, so any easing
    // would put it somewhere the pointer isn't. Smoothness is the zoom camera's
    // job (cursor:zoom_detached_camera in core/options.lua), not the dot's.
    Rectangle {
        id: halo

        readonly property int size: 44

        width: size
        height: size
        radius: size / 2
        x: overlay.cursorX - size / 2
        y: overlay.cursorY - size / 2
        color: "transparent"
        border.width: 2
        border.color: overlay.leftColor
        opacity: 0.45
    }

    // A fixed pool rather than a model that grows and shrinks: clicks arrive
    // faster than an expanding ripple finishes, and reusing the oldest slot is
    // both cheaper and self-limiting. Eight is more overlapping ripples than
    // anyone can produce by clicking.
    property int nextSlot: 0

    Repeater {
        id: ripples
        model: 8

        delegate: Rectangle {
            id: ripple

            property real centerX: 0
            property real centerY: 0
            property real size: 10

            width: size
            height: size
            radius: size / 2
            x: centerX - size / 2
            y: centerY - size / 2
            color: Qt.rgba(border.color.r, border.color.g, border.color.b, 0.16)
            border.width: 3
            border.color: overlay.leftColor
            opacity: 0
            visible: opacity > 0

            function fire(px, py, tint) {
                centerX = px
                centerY = py
                border.color = tint
                expand.restart()
            }

            ParallelAnimation {
                id: expand

                NumberAnimation {
                    target: ripple
                    property: "size"
                    from: 12
                    to: 78
                    duration: 520
                    easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0
                        to: 0.85
                        duration: 70
                    }
                    NumberAnimation {
                        target: ripple
                        property: "opacity"
                        to: 0
                        duration: 450
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Connections {
        target: PresentState

        function onClicked(x, y, button) {
            const localX = x - overlay.screen.x
            const localY = y - overlay.screen.y
            // Clicks on another monitor still arrive here - every overlay sees
            // every event - so drop the ones outside this screen.
            if (localX < 0 || localY < 0 || localX > overlay.width || localY > overlay.height)
                return

            ripples.itemAt(overlay.nextSlot).fire(localX, localY, overlay.colorFor(button))
            overlay.nextSlot = (overlay.nextSlot + 1) % ripples.count
        }
    }
}
