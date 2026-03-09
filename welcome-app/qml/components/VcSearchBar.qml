import QtQuick
import QtQuick.Controls.Basic
import VoidCommand

Rectangle {
    id: root

    property alias text: input.text
    signal searched(string query)

    implicitHeight: 40
    radius: Theme.radiusSmall
    color: Theme.surface1
    border.color: input.activeFocus ? Theme.accent : Theme.surface3
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            text: "\uf002"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }

        TextField {
            id: input
            width: parent.width - 32
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: Theme.textPrimary
            placeholderText: "Search..."
            placeholderTextColor: Theme.textDim
            background: Item {}

            onTextChanged: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 300
        onTriggered: root.searched(input.text)
    }
}
