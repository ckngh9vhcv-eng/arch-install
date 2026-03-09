import QtQuick
import VoidCommand

Rectangle {
    id: root

    property real value: -1  // 0-1 for determinate, < 0 for indeterminate

    implicitHeight: 4
    radius: 2
    color: Theme.surface2
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        radius: 2
        color: Theme.accent

        width: root.value >= 0 ? parent.width * root.value : parent.width * 0.3

        Behavior on width {
            enabled: root.value >= 0
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Indeterminate shimmer
        SequentialAnimation on x {
            running: root.value < 0
            loops: Animation.Infinite
            NumberAnimation {
                from: -fill.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }

        x: root.value >= 0 ? 0 : -fill.width
    }
}
