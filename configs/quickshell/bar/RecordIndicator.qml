import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: root
    visible: ShellGlobals.recording
    implicitWidth: visible ? indicator.width + 8 : 0
    implicitHeight: parent.height

    RowLayout {
        id: indicator
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: dot
            width: 8
            height: 8
            radius: 4
            color: Theme.danger

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: ShellGlobals.recording
                NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        Text {
            text: "REC"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: Theme.danger
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ShellGlobals.recording = false;
            recordStopFromBar.running = true;
        }

        Process {
            id: recordStopFromBar
            command: ["pkill", "-SIGINT", "gpu-screen-rec"]
        }
    }
}
