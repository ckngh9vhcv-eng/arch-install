import QtQuick
import QtQuick.Controls.Basic
import VoidCommand

Rectangle {
    id: root

    property alias text: textArea.text

    function appendLine(line) {
        textArea.text += line + "\n";
        flickable.contentY = Math.max(0, textArea.contentHeight - flickable.height);
    }

    function clear() {
        textArea.text = "";
    }

    color: Theme.void_
    border.color: Theme.surface2
    border.width: 1
    radius: Theme.radiusSmall
    clip: true

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: 8
        contentWidth: textArea.width
        contentHeight: textArea.contentHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        TextArea {
            id: textArea
            width: flickable.width
            readOnly: true
            wrapMode: TextArea.Wrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
            selectionColor: Theme.accent
            selectedTextColor: Theme.void_
            background: Item {}
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
