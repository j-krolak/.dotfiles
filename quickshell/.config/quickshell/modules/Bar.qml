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
      this.WlrLayershell.namespace = "quickshell:bar"
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
  readonly property int textCenterOffset: 0

  // Whether the mouse is actually over the bar right now - used below to
  // tell the difference between "hidden because you moved the mouse
  // away" and "hidden because the workspace-switch flash timed out".
  property bool hovering: false

  // Shared height for all three section pills below, so they read as a
  // matched set even though their contents (workspace dots vs. plain
  // text) aren't naturally the same height - tallest content plus a
  // little breathing room on top/bottom, same idea as the pills' width.
  readonly property int pillHeight: Math.max(leftPillRow.implicitHeight, rightPillRow.implicitHeight) + Theme.modulePaddingY * 2

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
    // Clicking empty bar space dismisses any open popup.
    onPressed: PopupManager.closeAll(null)
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
    color: bar.shown ? Theme.barBackground : bar.peekColor

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
        Item {
          anchors.verticalCenter: parent.verticalCenter
          width: leftPillRow.implicitWidth + Theme.modulePadding * 2
          height: bar.pillHeight

          Row {
            id: leftPillRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: bar.textCenterOffset
            spacing: 10

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "\uf303"
              color: Theme.barForeground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize + 2
              height: Theme.fontSize + 7
              verticalAlignment: Text.AlignVCenter
            }

            Text {
              id: appLabel
              anchors.verticalCenter: parent.verticalCenter
              // Hyprland's "activewindow>>class,title" event fires on every focus
              // change (empty when nothing is focused). toplevel.lastIpcObject is
              // only a snapshot refreshed on demand, so it lagged behind and
              // kept showing the previous window.
              property string cls: ""
              // "org.gnome.Nautilus" -> "Nautilus", "zen" -> "Zen"
              readonly property string appName: {
                const last = cls.split(".").pop()
                return last.length > 0 ? last.charAt(0).toUpperCase() + last.slice(1) : "Desktop"
              }
              text: appName

              // Terminal apps put spinner glyphs (✳, ⠋ ...) at the start of the title.
              // A fallback font draws them with different line metrics, which pushes
              // a shared line off-center, so they get their own fixed-height item
              // (titleIcon) and the rest of the title stays in the normal font.
              function setTitle(t) {
                const m = t.match(/^([\u2190-\u2BFF\u2800-\u28FF])\s*(.*)$/)
                titleIcon.text = m ? m[1] : ""
                windowTitle.text = m ? m[2] : t
              }

              Connections {
                target: Hyprland
                function onRawEvent(event) {
                  if (event.name === "activewindow") {
                    const i = event.data.indexOf(",")
                    appLabel.cls = i < 0 ? event.data : event.data.slice(0, i)
                    appLabel.setTitle(i < 0 ? "" : event.data.slice(i + 1))
                  } else if (event.name === "windowtitlev2") {
                    // "address,title" - keeps the title live (e.g. browser tab changes)
                    const j = event.data.indexOf(",")
                    if (Hyprland.activeToplevel && event.data.slice(0, j) === Hyprland.activeToplevel.address.replace("0x", ""))
                      appLabel.setTitle(event.data.slice(j + 1))
                  }
                }
              }

              Component.onCompleted: {
                const t = Hyprland.activeToplevel
                if (t && t.lastIpcObject && t.lastIpcObject["class"])
                  cls = t.lastIpcObject["class"]
              }
              color: Theme.barForeground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              font.bold: true
              height: Theme.fontSize + 7
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 200)
            }

            Text {
              id: titleIcon
              anchors.verticalCenter: parent.verticalCenter
              visible: text.length > 0
              color: Theme.barMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              height: Theme.fontSize + 7
              lineHeightMode: Text.FixedHeight
              lineHeight: height
              verticalAlignment: Text.AlignVCenter
            }

            Text {
              id: windowTitle
              anchors.verticalCenter: parent.verticalCenter
              visible: text.length > 0 && text !== appLabel.appName
              color: Theme.barMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              // Fixed height: fallback glyphs in a title (emoji, symbols) would
              // otherwise make this line taller and shift its text off-center.
              height: Theme.fontSize + 7
              lineHeightMode: Text.FixedHeight
              lineHeight: height
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 320)
            }
          }
        }
      }

      // modules-center
      Workspaces {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: bar.textCenterOffset
      }

      // modules-right
      Item {
        anchors.right: parent.right
        anchors.rightMargin: Theme.barGap
        anchors.verticalCenter: parent.verticalCenter
        width: rightPillRow.implicitWidth + Theme.modulePadding * 2
        height: bar.pillHeight

        Row {
          id: rightPillRow
          anchors.centerIn: parent
          anchors.verticalCenterOffset: bar.textCenterOffset
          spacing: 8

          RecordingIndicator {
            anchors.verticalCenter: parent.verticalCenter
          }

          ScreenShareIndicator {
            anchors.verticalCenter: parent.verticalCenter
          }

          Markets {
            anchors.verticalCenter: parent.verticalCenter
          }

          Agents {
            anchors.verticalCenter: parent.verticalCenter
          }

          Notifications {
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

          MediaControls {
            anchors.verticalCenter: parent.verticalCenter
          }

          ClockWidget {
            id: centerPillContent
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
