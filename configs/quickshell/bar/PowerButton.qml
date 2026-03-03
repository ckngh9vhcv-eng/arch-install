import QtQuick
import ".."

Text {
    signal clicked()

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontClock
    color: mouseArea.containsMouse ? Theme.accentGlow : Theme.textSecondary
    text: "\u23fb"

    scale: mouseArea.pressed ? 0.95 : mouseArea.containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.clicked()
    }

    Behavior on color { ColorAnimation { duration: 150 } }
}
