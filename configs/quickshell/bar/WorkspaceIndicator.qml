import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."

RowLayout {
    spacing: 6

    // Tooltip support
    property var barWindow
    property string tooltipText: {
        var ws = Hyprland.focusedWorkspace;
        return ws ? "Workspace " + ws.id : "";
    }

    Repeater {
        model: 9

        Rectangle {
            id: wsButton
            required property int index
            property int wsId: index + 1
            property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            property bool isActive: Hyprland.focusedWorkspace?.id === wsId
            property bool isOccupied: ws !== undefined

            width: isActive ? 18 : 12
            height: 12
            radius: 6

            color: isActive ? Theme.accent
                 : isOccupied ? Theme.textDim
                 : "transparent"

            border.width: isActive ? 0 : (isOccupied ? 0 : 1.5)
            border.color: Theme.textDim

            // Glow effect for active workspace
            Rectangle {
                visible: wsButton.isActive
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Theme.accentGlow.r, Theme.accentGlow.g, Theme.accentGlow.b, 0.5)
            }

            // Hover highlight
            opacity: mouseArea.containsMouse && !isActive ? 0.8 : 1.0

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsButton.wsId)
            }

            Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        }
    }
}
