import QtQuick
import Quickshell // for PanelWindow
import Quickshell.Io
import Quickshell.Services.Pipewire

// A small popup that flashes on screen for volume/brightness changes -
// filling in for swayosd, which is referenced in autostart.lua but isn't
// actually installed, so today those keys change nothing on screen.
//
// Anchoring only "bottom" (no left/right) is what centers this
// horizontally - that's just how wlr-layer-shell placement works when
// you don't anchor the perpendicular edges.
PanelWindow {
  id: osd

  anchors {
    bottom: true
  }
  margins.bottom: 40
  exclusiveZone: 0
  color: "transparent"

  implicitWidth: 220
  implicitHeight: 48

  property bool shown: false
  // "volume" or "brightness" - which one triggered the most recent flash.
  property string mode: "volume"

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: osd.shown = false
  }

  function flash(newMode) {
    mode = newMode
    shown = true
    hideTimer.restart()
  }

  // --- volume ----------------------------------------------------------
  readonly property PwNode sink: Pipewire.defaultAudioSink
  property bool muted: false
  property real volume: 0

  PwObjectTracker {
    objects: osd.sink ? [osd.sink] : []
  }

  Connections {
    target: osd.sink ? osd.sink.audio : null
    function onVolumeChanged() {
      osd.volume = osd.sink.audio.volume
      osd.flash("volume")
    }
    function onMutedChanged() {
      osd.muted = osd.sink.audio.muted
      osd.flash("volume")
    }
  }

  // --- brightness --------------------------------------------------------
  // No Quickshell service for backlight brightness, so watch the sysfs
  // file directly - the same file brightnessctl (used by the media
  // keybinds) writes to, so no keybind changes are needed.
  property real brightness: 0
  property real maxBrightness: 1

  FileView {
    path: "/sys/class/backlight/intel_backlight/brightness"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      osd.brightness = Number(text())
      osd.flash("brightness")
    }
  }

  FileView {
    path: "/sys/class/backlight/intel_backlight/max_brightness"
    onLoaded: osd.maxBrightness = Number(text())
  }

  readonly property real percent: mode === "volume"
    ? (muted ? 0 : volume * 100)
    : (maxBrightness > 0 ? (brightness / maxBrightness) * 100 : 0)

  visible: shown

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: Theme.popupBackground

    Row {
      anchors.centerIn: parent
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: osd.mode === "volume"
          ? (osd.muted ? "󰝟" : "󰕾")
          : "󰃟"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 4
      }

      Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 130
        height: 6
        radius: height / 2
        color: Theme.muted

        Rectangle {
          width: track.width * Math.max(0, Math.min(1, osd.percent / 100))
          height: track.height
          radius: track.radius
          color: Theme.accent
        }
      }
    }
  }
}
