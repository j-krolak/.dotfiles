import QtQuick
import Quickshell.Networking

// Like waybar's "network" module, simplified down to overall
// connectivity rather than per-interface details.
StatusItem {
    icon: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full: return "network-wireless-signal-excellent-symbolic"
        case NetworkConnectivity.Limited: return "network-wireless-signal-weak-symbolic"
        case NetworkConnectivity.Portal: return "network-wireless-signal-ok-symbolic"
        case NetworkConnectivity.None: return "network-wireless-offline-symbolic"
        default: return "network-wireless-acquiring-symbolic"
        }
    }
    label: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Limited: return "limited"
        case NetworkConnectivity.Portal: return "portal"
        case NetworkConnectivity.None: return "offline"
        default: return ""
        }
    }
}
