import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    property string icon: ""
    property string label: ""
    property int count: -1

    implicitHeight: 28
    implicitWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: Theme.accent
        }

        Text {
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
            color: Theme.textSecondary
        }

        Rectangle {
            visible: root.count >= 0
            width: countText.implicitWidth + 12
            height: 20
            radius: 10
            color: Theme.surface2

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.count
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textDim
            }
        }
    }
}
