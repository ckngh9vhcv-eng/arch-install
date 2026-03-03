import QtQuick
import ".."

Rectangle {
    id: option

    property string icon: ""
    property string label: ""
    property color iconColor: Theme.textSecondary
    property bool needsConfirm: false
    property bool confirming: false
    signal clicked()

    width: 120
    height: 130
    radius: Theme.radiusPanel
    color: {
        if (confirming)
            return Qt.rgba(option.iconColor.r, option.iconColor.g, option.iconColor.b, 0.25);
        if (optionMouse.containsMouse)
            return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2);
        return Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.6);
    }
    border.width: confirming ? 2 : (optionMouse.containsMouse ? 1 : 0)
    border.color: confirming ? option.iconColor : Theme.accentGlow

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: option.icon
            font.family: Theme.fontFamily
            font.pixelSize: 36
            color: optionMouse.containsMouse || confirming ? Qt.lighter(option.iconColor, 1.4) : option.iconColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: confirming ? "Sure?" : option.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: confirming
            color: confirming ? option.iconColor : Theme.textPrimary
        }
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: option.confirming = false
    }

    MouseArea {
        id: optionMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!option.needsConfirm) {
                option.clicked();
                return;
            }
            if (option.confirming) {
                option.confirming = false;
                option.clicked();
            } else {
                option.confirming = true;
                confirmTimer.restart();
            }
        }
    }

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.width { NumberAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
}
