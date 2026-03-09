import QtQuick
import QtQuick.Layouts
import VoidCommand

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool accent: true
    property bool flat: false
    property bool enabled: true

    signal clicked()

    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 36
    radius: Theme.radiusSmall

    color: {
        if (!enabled) return Theme.surface2;
        if (flat) {
            if (mouseArea.pressed) return Theme.surface3;
            if (mouseArea.containsMouse) return Theme.surface2;
            return "transparent";
        }
        if (mouseArea.pressed) return Theme.accentDim;
        if (mouseArea.containsMouse) return Theme.accentBright;
        return Theme.accent;
    }

    scale: mouseArea.pressed ? 0.97 : 1.0

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: root.accent && !root.flat ? Theme.void_ : Theme.textPrimary
            opacity: root.enabled ? 1.0 : 0.5
        }

        Text {
            visible: root.text !== ""
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
            color: root.accent && !root.flat ? Theme.void_ : Theme.textPrimary
            opacity: root.enabled ? 1.0 : 0.5
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
