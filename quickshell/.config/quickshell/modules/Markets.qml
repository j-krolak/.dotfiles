import QtQuick

// Bar entry for the markets panel (MarketsPanel.qml): a small trend arrow
// plus the first watched stock and its daily change, e.g. "NVDA -3.66%".
// Hidden until the first prices have arrived. Click opens the panel.
Item {
    id: root

    readonly property var quote: MarketsState.headline
    readonly property bool up: !!quote && (quote.change || 0) >= 0

    visible: !!quote
    implicitWidth: visible ? row.implicitWidth + Theme.modulePadding * 2 : 0
    implicitHeight: Theme.fontSize + 7

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.up ? "▲" : "▼"
            color: root.up ? "#30d158" : "#ff453a"
            opacity: 0.7
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 6
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.quote ? root.quote.symbol + " " + MarketsState.percent(root.quote.change) : ""
            color: Theme.barMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: MarketsState.visible = !MarketsState.visible
    }
}
