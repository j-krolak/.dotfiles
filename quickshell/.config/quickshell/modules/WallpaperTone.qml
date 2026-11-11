pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether the wallpaper behind the bar is light enough that the bar text
// should be black instead of white. Measured once at startup (from whatever
// awww is showing) and again each time the picker applies a new wallpaper -
// see WallpaperPickerOverview.qml's applyWallpaper().
Singleton {
    id: root

    property bool light: false

    // Mean luminance of the top 3/108 of the image, i.e. the strip under the
    // bar. "[0]" keeps animated gifs to their first frame.
    function analyze(path) {
        probe.command = ["sh", "-c", "magick \"$1[0]\" -colorspace Gray -resize '192x108!' -crop 192x3+0+0 +repage -format '%[fx:mean]' info:", "sh", path]
        probe.running = true
    }

    Component.onCompleted: current.running = true

    Process {
        id: current
        command: ["sh", "-c", "awww query | sed -n 's/.*image: //p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0)
                    root.analyze(p)
            }
        }
    }

    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text)
                if (!isNaN(v))
                    root.light = v > 0.5
            }
        }
    }
}
