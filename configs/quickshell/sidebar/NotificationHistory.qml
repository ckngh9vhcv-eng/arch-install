import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 8

    // Clear all button
    RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        Text {
            text: "Clear All"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: clearMouse.containsMouse ? Theme.textPrimary : Theme.textDim
            visible: ShellGlobals.notificationHistory.count > 0

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellGlobals.clearNotificationHistory()
            }
        }
    }

    // Empty state
    Text {
        visible: ShellGlobals.notificationHistory.count === 0
        text: "No notifications"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        color: Theme.textDim
        Layout.alignment: Qt.AlignHCenter
    }

    // Scrollable notification list
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: ShellGlobals.notificationHistory

        delegate: Rectangle {
            required property string appName
            required property string summary
            required property string body
            required property real timestamp
            required property int index

            width: ListView.view.width
            height: entryContent.implicitHeight + 12
            radius: Theme.radiusInner
            color: Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.6)

            ColumnLayout {
                id: entryContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: appName
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textDim
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: {
                            var diff = (Date.now() - timestamp) / 1000;
                            if (diff < 60) return "now";
                            if (diff < 3600) return Math.floor(diff / 60) + "m ago";
                            if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
                            return Math.floor(diff / 86400) + "d ago";
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textDim
                    }
                }

                Text {
                    text: summary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: body
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: body.length > 0
                }
            }
        }
    }
}
