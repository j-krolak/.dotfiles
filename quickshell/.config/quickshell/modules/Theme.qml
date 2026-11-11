pragma Singleton
import QtQuick

// A single place to tweak how the whole bar looks.
// Because this file starts with "pragma Singleton", every module can just
// write `Theme.foreground` etc. without creating an instance of it first -
// same idea as the built-in `Hyprland` / `Pipewire` singletons you'll see
// used in the other modules.
QtObject {
    // macOS-style: status modules show only their icon. Flip to bring back
    // the percentages / counts next to them.
    readonly property bool showStatusLabels: false
    readonly property color barBackground: "#00ffffff"
    readonly property color barForeground: WallpaperTone.light ? "#000000" : "#ffffff"
    readonly property color barMuted: WallpaperTone.light ? "#80000000" : "#99ffffff"
    // Status colors on the bar are deliberately the same as the text - colored ones blended into the wallpaper.
    readonly property color barUrgent: barForeground
    readonly property color barGood: barForeground
    readonly property color barAccent: barForeground
    readonly property color barWarning: barForeground
    // Shared look of the bar's popups: dark glass like the rofi launcher (blurred by
    // the "quickshell:blur" layer rule) with light text.
    readonly property color popupGlass: "#73000000"
    readonly property int popupRadius: 15
    readonly property color popupText: "#ffffff"
    readonly property color popupMuted: "#99ffffff"
    readonly property color popupLine: "#33ffffff"
    readonly property color popupHover: "#1affffff"
    readonly property color popupAccent: popupText
    readonly property color popupUrgent: popupText
    readonly property color popupGood: popupText
    readonly property color popupWarning: popupText
    readonly property color background: "#9913101a"
    // Popups (OSD, notifications, calendar) float over arbitrary desktop
    // content rather than sitting on their own bar, so they need to be
    // closer to opaque - background's 80% opacity let whatever was
    // behind (e.g. a blue-ish window) bleed through and wash out the
    // accent-colored bits inside.
    readonly property color popupBackground: "#6513101a"
    readonly property color foreground: "#f8f9f2"
    readonly property color accent: "#7aa2f7"
    // Blue of the Arch Linux logo glyph in the bar's left section.
    readonly property color archBlue: "#2196f3"
    // Faint outline around the bar's floating pills.
    readonly property color pillBorder: "#2e2f30"
    readonly property color muted: "#9399b2"
    readonly property color urgent: "#f38ba8"
    readonly property color warning: "#f9e2af"
    readonly property color good: "#a6e3a1"
    // Subtle highlight for hovering something that isn't already active,
    // e.g. an inactive workspace pill.
    readonly property color hoverBackground: "#1affffff"

    readonly property string fontFamily: "Inter"
    // Serif with full polytonic Greek coverage, for the classical elements.
    readonly property string serifFamily: "Noto Serif"
    readonly property int fontSize: 14

    readonly property int barHeight: 24
    // How many pixels stay on screen when the bar is "hidden", so there's
    // still something for the mouse to hover over to bring it back.
    // (2px hits a compositor rendering edge case and paints blank - 3px
    // is the thinnest that reliably shows up.)
    readonly property int peekHeight: 3
    // Each module's own Text already carries this as left/right padding
    // (for gutters when modules used to sit directly in the bar), and the
    // pill around a section adds it again on top of that - so the actual
    // gap you see on either side of a pill's content is 2x this value.
    readonly property int modulePadding: 5
    // Same idea as modulePadding, but for the pills' top/bottom.
    readonly property int modulePaddingY: 4
    // Gap between the bar's floating pills and the screen edges - same
    // value on top/left/right so the bar reads as evenly inset.
    readonly property int barGap: 8
}
