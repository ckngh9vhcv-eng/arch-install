import QtQuick
import VoidCommand

Item {
    id: root

    property bool checked: false
    property string label: ""
    property bool enabled: true

    signal toggled(bool checked)

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    Row {
        id: row
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: track
            width: 44
            height: 24
            radius: 12
            color: root.checked ? Theme.accent : Theme.surface2
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                id: knob
                width: 18
                height: 18
                radius: 9
                color: Theme.textPrimary
                y: 3
                x: root.checked ? track.width - width - 3 : 3

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.enabled) return;
                    root.checked = !root.checked;
                    root.toggled(root.checked);
                }
            }
        }

        Text {
            visible: root.label !== ""
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: Theme.textPrimary
            opacity: root.enabled ? 1.0 : 0.5
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
