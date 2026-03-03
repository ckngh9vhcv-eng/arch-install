import QtQuick
import ".."

Rectangle {
    id: searchField

    property alias text: input.text
    signal accepted()

    width: 500
    height: 48
    radius: Theme.radiusInner
    color: Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.8)
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.accentGlow : Theme.accentDim

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        font.family: Theme.fontFamily
        font.pixelSize: 16
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: "#FFFFFF"
        clip: true

        onAccepted: searchField.accepted()
    }

    // Placeholder text
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "Search applications..."
        font.family: Theme.fontFamily
        font.pixelSize: 16
        color: Theme.textDim
        visible: input.text.length === 0
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    Behavior on border.color { ColorAnimation { duration: 150 } }
}
