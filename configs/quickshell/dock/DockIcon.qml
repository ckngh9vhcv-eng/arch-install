import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: iconRoot

    required property var app
    property bool isRunning: false
    property bool isPinned: false
    property string clientAddress: ""

    signal leftClicked()
    signal rightClicked()

    width: 48
    height: 48

    scale: iconMouse.containsMouse ? 1.3 : 1.0
    transformOrigin: Item.Bottom
    z: iconMouse.containsMouse ? 10 : 0

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // Tooltip
    Rectangle {
        id: tooltip
        visible: iconMouse.containsMouse
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 8
        radius: 6
        color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.95)
        border.width: 1
        border.color: Theme.accentDim
        z: 100

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: iconRoot.app ? iconRoot.app.name : ""
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
        }
    }

    // Icon image
    Image {
        id: iconImage
        anchors.fill: parent
        source: iconRoot.app && iconRoot.app.icon ? "image://icon/" + iconRoot.app.icon : ""
        sourceSize.width: 48
        sourceSize.height: 48
        smooth: true
    }

    // Running indicator dot
    Rectangle {
        visible: iconRoot.isRunning
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 3
        width: 5
        height: 5
        radius: 2.5
        color: Theme.accent
    }

    MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                iconRoot.rightClicked();
            } else {
                iconRoot.leftClicked();
            }
        }
    }
}
