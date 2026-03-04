import QtQuick
import Quickshell.Io
import ".."

Text {
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    color: Theme.info

    property string status: "\u{f294}"
    property string tooltipText: "No device connected"
    property string deviceName: ""

    text: status

    Process {
        id: bluemanProc
        command: ["blueman-manager"]
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: bluemanProc.running = true
    }

    Process {
        id: btProc
        command: ["bluetoothctl", "info"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("not available") !== -1) {
                    status = "\u{f294}";
                    color = Theme.textDim;
                    tooltipText = "Bluetooth unavailable";
                    deviceName = "";
                } else if (data.indexOf("Name:") !== -1) {
                    var match = data.match(/Name:\s*(.+)/);
                    if (match) {
                        deviceName = match[1];
                        status = "\u{f294} " + match[1];
                        color = Theme.info;
                        tooltipText = match[1];
                    }
                } else {
                    status = "\u{f294}";
                    color = Theme.textSecondary;
                    tooltipText = "No device connected";
                    deviceName = "";
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }
}
