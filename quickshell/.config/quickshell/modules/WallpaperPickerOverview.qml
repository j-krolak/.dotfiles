import QtQuick
import Quickshell // for PanelWindow, Quickshell.shellDir
import Quickshell.Io

// Full-screen wallpaper picker: a fan of skewed (parallelogram) thumbnails,
// all sheared the same way, with a wider one - the current selection -
// among them. There's no bar icon for this one - it's only reachable via
// the "qs ipc call wallpaper toggle" IPC target below, bound to a Hyprland
// keybind (see keymaps/apps.lua). Same click-outside-to-close trick as
// Calendar.qml / TaskwarriorOverview.qml, except here the "card" covers
// the whole screen instead of floating under a widget, so the outer
// MouseArea just sits behind the thumbnail row.
//
// Wallpapers live in modules-relative "wallpapers/" (a sibling of this
// file's directory) rather than anywhere under ~/.config/hypr, so the
// picker doesn't depend on some other tool's directory layout - copy
// whatever images you want offered in here.
PanelWindow {
  id: root

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusiveZone: 0
  color: "transparent"
  // Layer-shell surfaces don't get keyboard input by default - needed for
  // the arrow-key/Enter/Escape navigation below to actually reach us.
  focusable: true

  visible: WallpaperState.visible

  readonly property string wallpaperDir: Quickshell.shellDir + "/wallpapers"
  property var wallpapers: []
  // Index of the current selection - wider than the rest, and what
  // Enter applies. Moved with the left/right arrow keys.
  property int centerIndex: 0

  readonly property int cardHeight: 380
  readonly property int sideCardWidth: 150
  readonly property int centerCardWidth: 280
  // Horizontal offset between a card's top and bottom edge - what turns
  // its rectangle into a parallelogram. Every card shears the same way
  // (only width sets the selection apart), rather than mirroring left vs
  // right into a fan.
  readonly property int shearPx: 70
  readonly property real shearFactor: shearPx / cardHeight

  MouseArea {
    anchors.fill: parent
    onClicked: WallpaperState.visible = false
  }

  Item {
    id: keyHandler
    anchors.fill: parent
    focus: true

    Keys.onLeftPressed: root.centerIndex = Math.max(0, root.centerIndex - 1)
    Keys.onRightPressed: root.centerIndex = Math.min(root.wallpapers.length - 1, root.centerIndex + 1)
    Keys.onEscapePressed: WallpaperState.visible = false
    Keys.onReturnPressed: root.applyCurrent()
    Keys.onEnterPressed: root.applyCurrent()
  }

  function applyCurrent() {
    if (wallpapers.length > 0)
      applyWallpaper(wallpapers[centerIndex])
  }

  // Staged results from listProcess/queryProcess below - kept out of
  // `wallpapers`/`centerIndex` until both are in, so the fan never briefly
  // renders with the wrong (fallback) card selected before snapping to the
  // right one a moment later.
  property var _pendingWallpapers: null
  property string _pendingCurrentName: ""
  property bool _pendingQueryDone: false

  function refresh() {
    _pendingWallpapers = null
    _pendingQueryDone = false
    listProcess.running = true
    queryProcess.running = true
  }

  onVisibleChanged: if (visible) {
    refresh()
    keyHandler.forceActiveFocus()
  }

  function _applyPendingIfReady() {
    if (_pendingWallpapers === null || !_pendingQueryDone) return
    wallpapers = _pendingWallpapers
    const index = wallpapers.findIndex(p => p.split("/").pop() === _pendingCurrentName)
    centerIndex = index >= 0 ? index : Math.floor((wallpapers.length - 1) / 2)
    Qt.callLater(scrollToCenter)
  }

  // Lists files directly under wallpaperDir and keeps only image
  // extensions - simpler than pulling in Qt.labs.folderlistmodel just for
  // this one lookup.
  Process {
    id: listProcess
    command: ["find", wallpaperDir, "-maxdepth", "1", "-type", "f"]

    stdout: StdioCollector {
      onStreamFinished: {
        _pendingWallpapers = text.split("\n")
          .filter(p => /\.(jpe?g|png|webp|gif|bmp)$/i.test(p))
          .sort()
        _applyPendingIfReady()
      }
    }
  }

  // Asks awww which image is currently on screen, so opening the picker
  // starts hovered/selected on that one instead of always the middle card.
  // Runs in parallel with listProcess above rather than after it, so the
  // two roughly-equal-cost process spawns overlap instead of stacking.
  Process {
    id: queryProcess
    command: ["awww", "query"]

    stdout: StdioCollector {
      onStreamFinished: {
        // One line per output, e.g. ": eDP-1: 1920x1080, scale: 1,
        // currently displaying: image: /path/to/file" - just take the
        // first monitor's image.
        const match = text.match(/currently displaying: image: (.+)/)
        // Compare filenames, not full paths: wallpaperDir is built from
        // Quickshell.shellDir, which resolves through the ~/.config/quickshell
        // symlink, while awww reports the canonicalized real path - same
        // file, two different strings.
        _pendingCurrentName = match ? match[1].trim().split("/").pop() : ""
        _pendingQueryDone = true
        _applyPendingIfReady()
      }
    }
  }

  // Reused sequentially across clicks - only one wallpaper change is ever
  // in flight at a time.
  Process {
    id: applyProcess
  }

  function applyWallpaper(path) {
    applyProcess.command = ["awww", "img", path, "--transition-type", "random"]
    applyProcess.running = true
    WallpaperState.visible = false
  }

  // Keeps the selected card scrolled into the middle of the viewport as
  // centerIndex changes - card widths aren't uniform (the selection is
  // wider), so this reads actual delegate geometry rather than doing the
  // width*index math a plain uniform-grid scrollToIndex could get away with.
  function scrollToCenter() {
    const item = repeater.itemAt(centerIndex)
    if (!item) return
    const targetX = item.x + item.width / 2 - flick.width / 2
    flick.contentX = Math.max(0, Math.min(targetX, Math.max(0, flick.contentWidth - flick.width)))
  }

  onCenterIndexChanged: Qt.callLater(scrollToCenter)

  Text {
    anchors.centerIn: parent
    visible: wallpapers.length === 0
    text: "No images in " + wallpaperDir
    color: Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
  }

  // Horizontally scrollable when there are more thumbnails than fit -
  // capped to the screen width and centered when everything already fits.
  Flickable {
    id: flick
    anchors.centerIn: parent
    visible: wallpapers.length > 0
    width: Math.min(row.implicitWidth, parent.width - 160)
    height: root.cardHeight
    contentWidth: row.implicitWidth
    contentHeight: root.cardHeight
    // No clip: the picker is already the full (transparent) screen, so
    // there's nothing for an off-center sheared card to spill onto - but
    // clipping it here would slice straight through its diagonal edge,
    // leaving a jagged partial parallelogram instead of its real shape.
    boundsBehavior: Flickable.StopAtBounds

    Behavior on contentX {
      NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    Row {
      id: row
      spacing: 20

      Repeater {
        id: repeater
        model: wallpapers

        delegate: Item {
          id: card
          required property string modelData
          required property int index

          readonly property bool isCenter: index === root.centerIndex

          width: isCenter ? root.centerCardWidth : root.sideCardWidth
          height: root.cardHeight
          z: isCenter ? 2 : (thumbArea.containsMouse ? 1 : 0)
          scale: thumbArea.containsMouse ? 1.05 : 1

          Behavior on scale {
            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
          }
          Behavior on width {
            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
          }

          Rectangle {
            id: frame
            anchors.fill: parent
            clip: true
            color: "black"

            transform: Matrix4x4 {
              matrix: Qt.matrix4x4(
                1, root.shearFactor, 0, 0,
                0, 1,                0, 0,
                0, 0,                1, 0,
                0, 0,                0, 1)
            }

            // Counter-sheared so the photo itself reads upright - only the
            // clip boundary (this item's rectangle, sheared by the parent
            // transform above) ends up a parallelogram. Oversized
            // horizontally so the crop still fully covers the parent's
            // clip region once the shear is undone.
            Image {
              anchors.centerIn: parent
              width: parent.width + 2 * root.shearPx
              height: parent.height
              source: "file://" + card.modelData
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              // Fixed, not bound to width/height: those animate (selecting
              // a card resizes it via Behavior on width above), and a
              // moving sourceSize forces Qt to re-decode the image from
              // disk on every frame of that animation - each decode is
              // async, so the image blanks out mid-transition. Sized for
              // the largest a card ever gets (the selected/center width);
              // PreserveAspectCrop scales the one decoded texture down for
              // narrower cards for free.
              sourceSize.width: root.centerCardWidth + 2 * root.shearPx
              sourceSize.height: root.cardHeight

              transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                  1, -root.shearFactor, 0, 0,
                  0, 1,                 0, 0,
                  0, 0,                 1, 0,
                  0, 0,                 0, 1)
              }
            }

            // Border drawn as its own layer, after (on top of) the image -
            // frame's own border would otherwise be painted first and then
            // fully covered by the opaque, deliberately-oversized Image.
            Rectangle {
              anchors.fill: parent
              color: "transparent"
              border.color: thumbArea.containsMouse || card.isCenter ? Theme.accent : Theme.pillBorder
              border.width: thumbArea.containsMouse || card.isCenter ? 3 : 1.5
            }
          }

          MouseArea {
            id: thumbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.centerIndex = card.index
              applyWallpaper(card.modelData)
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      WallpaperState.visible = !WallpaperState.visible
    }
  }
}
