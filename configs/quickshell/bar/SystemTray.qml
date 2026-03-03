import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import ".."

RowLayout {
    spacing: 8

    Repeater {
        model: SystemTray.items

        Image {
            required property SystemTrayItem modelData

            source: modelData.icon
            sourceSize.width: 18
            sourceSize.height: 18
            width: 18
            height: 18
            smooth: true

            opacity: itemMouse.containsMouse ? 1.0 : 0.7

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function(event) {
                    if (event.button === Qt.LeftButton) {
                        if (modelData.onlyMenu) {
                            modelData.display(parent, parent.width / 2, parent.height);
                        } else {
                            modelData.activate();
                        }
                    } else {
                        modelData.display(parent, parent.width / 2, parent.height);
                    }
                }
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
