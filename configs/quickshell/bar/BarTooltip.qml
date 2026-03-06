import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: tooltip

    property string text: ""
    property real tipX: 0

    anchors.top: true
    anchors.left: true
    implicitWidth: tipLabel.implicitWidth + 20
    implicitHeight: tipLabel.implicitHeight + 12

    margins.top: 40
    margins.left: Math.max(4, tipX - implicitWidth / 2)

    color: "transparent"
    focusable: false
    aboveWindows: true

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.95)
        border.width: 1
        border.color: Theme.accentDim

        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: tooltip.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textPrimary
        }
    }
}
