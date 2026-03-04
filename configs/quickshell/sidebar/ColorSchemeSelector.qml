import QtQuick
import QtQuick.Layouts
import ".."

GridLayout {
    columns: 4
    rowSpacing: 8
    columnSpacing: 8

    Repeater {
        model: Theme.schemeNames

        Rectangle {
            required property string modelData

            Layout.fillWidth: true
            height: 48
            radius: Theme.radiusInner

            property bool active: Theme.currentScheme === modelData
            property var scheme: Theme.schemes[modelData]

            color: active
                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                   : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.6)
            border.width: active ? 2 : 1
            border.color: active ? Theme.accent : Theme.accentDim

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                // Color dots row
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    Repeater {
                        model: scheme ? [scheme.accent, scheme.surface2, scheme.textPrimary] : []

                        Rectangle {
                            required property string modelData
                            width: 8
                            height: 8
                            radius: 4
                            color: modelData
                        }
                    }
                }

                // Scheme name
                Text {
                    Layout.fillWidth: true
                    text: Theme.schemeDisplayNames[modelData] || modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: active
                    color: active ? Theme.textPrimary : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!active) {
                        Theme.applyScheme(modelData);
                    }
                }
            }
        }
    }
}
