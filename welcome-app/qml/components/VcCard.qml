import QtQuick
import QtQuick.Layouts
import VoidCommand

Rectangle {
    id: root

    property string headerText: ""
    property string headerIcon: ""
    default property alias content: contentColumn.data

    color: Theme.surface0
    border.color: Theme.surface2
    border.width: 1
    radius: Theme.radius

    implicitHeight: mainLayout.implicitHeight + 24
    implicitWidth: 280

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            visible: root.headerText !== ""
            spacing: 8

            Text {
                visible: root.headerIcon !== ""
                text: root.headerIcon
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                color: Theme.accent
            }

            Text {
                text: root.headerText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: true
                color: Theme.textPrimary
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 4
        }
    }
}
