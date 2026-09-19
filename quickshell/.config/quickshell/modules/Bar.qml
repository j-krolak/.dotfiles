import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

// This is the quickshell equivalent of waybar's config.jsonc + style.css,
// split the same way: modules-left / modules-center / modules-right, each
// module implemented in its own small file alongside this one. Have a
// look there once this makes sense - each one is short and does one thing.
//
// On top of that, this bar auto-hides: it snaps out of the way and
// only a thin (usually invisible) sliver stays on screen, and hovering
// that sliver - i.e. the very top edge of the screen - snaps it back
// open instantly, no animation.
PanelWindow {
  id: bar

  anchors {
    top: true
    left: true
    right: true
  }

  // Reserve space for the bar so windows tile below it instead of
  // being covered by it.
  exclusiveZone: implicitHeight
  color: "transparent"

  // Minimal mode takes the whole screen. Dropping the window rather than
  // collapsing it to the peek strip also gives up the exclusive zone, so
  // windows reflow to full height, and avoids leaving the low-battery/urgent
  // tint stranded as a colored line across the top of a presentation.
  visible: !MinimalState.active
  // Same namespace the popups (Calendar.qml etc.) use - matched by a
  // Hyprland layer rule that blurs it. The rule matches on "quickshell" as
  // a substring, so this still also picks up the separate no_anim rule
  // that namespace gets (see hypr's rules/layers.lua) - needed to keep the
  // auto-hide reveal/hide instant instead of picking up the global layer
  // animation.
  Component.onCompleted: {
    if (this.WlrLayershell != null) {
      this.WlrLayershell.namespace = "quickshell:blur"
    }
  }

  // --- auto-hide -----------------------------------------------------
  property bool revealed: false

  // Stay open (ignore auto-hide) whenever the focused workspace has no
  // windows on it at all - there's nothing to cover up, so hiding the
  // bar would only cost a hover-to-reveal for no benefit. "windows" is
  // Hyprland's own live window count for the workspace (same field
  // `hyprctl workspaces -j` reports), kept in sync over the IPC socket.
  readonly property bool emptyWorkspace: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.windows === 0
  readonly property bool shown: true

  // The window itself shrinks down to a thin strip when hidden, instead
  // of the full bar height. (An earlier version tried to fake this by
  // pushing the window off-screen with a negative top margin, but
  // Hyprland's layer-shell just clamps negative margins to 0, so the
  // bar stayed fully visible - resizing implicitHeight is what actually
  // works.) No Behavior here on purpose - reveal/hide snaps instantly
  // instead of sliding.
  implicitHeight: shown ? pillHeight : Theme.peekHeight

  // Theme.fontFamily's line metrics are ascent-heavy (ascent 12.7px vs
  // descent 3.7px at this size), so vertically centering the raw Text
  // bounding box leaves visibly more room above the glyphs than below.
  // This nudges the visual center up to compensate.
  readonly property int textCenterOffset: -2

  // Whether the mouse is actually over the bar right now - used below to
  // tell the difference between "hidden because you moved the mouse
  // away" and "hidden because the workspace-switch flash timed out".
  property bool hovering: false

  // Shared height for all three section pills below, so they read as a
  // matched set even though their contents (workspace dots vs. plain
  // text) aren't naturally the same height - tallest content plus a
  // little breathing room on top/bottom, same idea as the pills' width.
  readonly property int pillHeight: Math.max(leftPillRow.implicitHeight, centerPillContent.implicitHeight, rightPillRow.implicitHeight) + Theme.modulePaddingY * 2

  // Small delay before hiding again so briefly crossing the bar while
  // moving the mouse elsewhere doesn't cause it to flicker shut. This is
  // just a debounce, not an animation - revealing is still instant.
  Timer {
    id: hideTimer
    interval: 400
    onTriggered: bar.revealed = false
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      bar.hovering = true
      hideTimer.stop()
      workspaceFlashTimer.stop()
      bar.revealed = true
    }
    onExited: {
      bar.hovering = false
      hideTimer.start()
    }

    // Scroll anywhere on the bar to step through workspaces, same as
    // GNOME/Ubuntu's top-panel workspace switcher. This MouseArea sits
    // underneath all the bar's modules (declared before the Rectangle
    // below), so none of their own click handlers are affected - a
    // module only intercepts the wheel event itself if it defines its
    // own onWheel, which none currently do. The relative offset
    // ("e+1"/"e-1") wraps around at the ends on its own. This Hyprland
    // build's IPC dispatch endpoint takes a Lua expression rather than
    // the classic "workspace e+1" plain-text dispatcher string - see
    // `hyprctl dispatch --help` / the hl.dsp.* namespace.
    onWheel: wheel => Hyprland.dispatch(`hl.dsp.focus({ workspace = "e${wheel.angleDelta.y > 0 ? "-1" : "+1"}" })`)
  }

  // Briefly reveal the bar whenever you switch workspaces, so you can
  // see where you landed without having to reach for the top edge.
  Timer {
    id: workspaceFlashTimer
    interval: 1200
    onTriggered: {
      if (!bar.hovering)
        bar.revealed = false
    }
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() {
      bar.revealed = true
      if (!bar.hovering)
        workspaceFlashTimer.restart()
    }
  }

  // While hidden there's normally no strip at all - it's just an
  // invisible hover target along the bottom edge. It only lights up to
  // flag something that needs attention:
  //   - red once the battery is low and not charging
  //   - yellow if a workspace has an urgent window (e.g. a notification)
  readonly property bool batteryLow: UPower.displayDevice
    && UPower.displayDevice.isLaptopBattery
    && UPower.displayDevice.state !== UPowerDeviceState.Charging
    && UPower.displayDevice.percentage * 100 <= 15
  readonly property bool hasUrgentWorkspace: Hyprland.workspaces.values.some(w => w.urgent)

  readonly property color peekColor: batteryLow ? Theme.urgent
    : hasUrgentWorkspace ? Theme.warning
    : "transparent"
  // ---------------------------------------------------------------------

  Rectangle {
    anchors.fill: parent
    clip: true
    // The bar itself has no background anymore - only the pill behind
    // each section does (below). Revealed still needs to win over
    // peekColor here, otherwise a low-battery/urgent hint bleeds through
    // as a full-width tint instead of just the thin peek strip.
    color: bar.shown ? "transparent" : bar.peekColor

    // The actual modules only need to be visible/interactive once the
    // bar has opened back up. No margin here on purpose - the window's
    // own height already matches the pills exactly (see implicitHeight
    // above), and the visual gap below them comes entirely from
    // Hyprland's own gaps_out, so it lines up with the gap between
    // windows (gaps_in) instead of stacking an extra one on top.
    Item {
      anchors.fill: parent
      opacity: bar.shown ? 1 : 0
      visible: opacity > 0

      // modules-left
      Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.barGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Pill behind the distro icon + workspace dots. NowPlaying
        // deliberately sits outside it (below) rather than being a third
        // child in here - a track title is unbounded in length and
        // wrapping it in the same chip would make the pill lurch wider
        // every time the song changes.
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          topLeftRadius: 0
          topRightRadius: 0
          bottomLeftRadius: height / 2
          bottomRightRadius: height / 2
          color: Theme.background
          border.color: Theme.pillBorder
          border.width: 0
          width: leftPillRow.implicitWidth + Theme.modulePadding * 2
          height: bar.pillHeight

          Row {
            id: leftPillRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: bar.textCenterOffset
            spacing: 4

                    Workspaces {
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        NowPlaying {
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: bar.textCenterOffset
        }
      }

      // modules-center
      Rectangle {
        anchors.centerIn: parent
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: height / 2
        bottomRightRadius: height / 2
        color: Theme.background
        border.color: Theme.pillBorder
        border.width: 0
        width: centerPillContent.implicitWidth + Theme.modulePadding * 2
        height: bar.pillHeight

        ClockWidget {
          id: centerPillContent
          anchors.centerIn: parent
          anchors.verticalCenterOffset: bar.textCenterOffset
        }
      }

      // modules-right
      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Theme.barGap
        anchors.verticalCenter: parent.verticalCenter
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: height / 2
        bottomRightRadius: height / 2
        color: Theme.background
        border.color: Theme.pillBorder
        border.width: 0
        width: rightPillRow.implicitWidth + Theme.modulePadding * 2
        height: bar.pillHeight

        Row {
          id: rightPillRow
          anchors.centerIn: parent
          anchors.verticalCenterOffset: bar.textCenterOffset
          spacing: 4

          Taskwarrior {
            anchors.verticalCenter: parent.verticalCenter
          }

          Notifications {
            anchors.verticalCenter: parent.verticalCenter
          }

          SystemStats {
            anchors.verticalCenter: parent.verticalCenter
          }

          Volume {
            anchors.verticalCenter: parent.verticalCenter
          }

          Microphone {
            anchors.verticalCenter: parent.verticalCenter
          }

          NetworkStatus {
            anchors.verticalCenter: parent.verticalCenter
          }

          Bluetooth {
            anchors.verticalCenter: parent.verticalCenter
          }

          Battery {
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
