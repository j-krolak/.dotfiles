import QtQuick
import Quickshell.Networking

// Like waybar's "network" module, simplified down to overall
// connectivity rather than per-interface details.
Text {
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    text: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full: return "󰤨 online"
        case NetworkConnectivity.Limited: return "󰤟 limited"
        case NetworkConnectivity.Portal: return "󰤫 portal"
        case NetworkConnectivity.None: return "󰤭 offline"
        default: return "󰤮 ..."
        }
    }
}
