import QtQuick
import Quickshell.Io
import ".."

Text {
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    color: Theme.textSecondary

    property string status: "\u{f6ff} ..."
    property string tooltipText: "Network: ..."
    property string connectionName: ""
    property string ipAddress: ""

    text: status

    Process {
        id: nmProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,IP4.ADDRESS", "device"]
        stdout: SplitParser {
            onRead: data => {
                var lines = data.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":");
                    if (parts.length >= 3 && parts[1] === "connected") {
                        if (parts[0] === "wifi") {
                            connectionName = parts[2];
                            status = "\u{f1eb} " + parts[2];
                            ipAddress = parts.length >= 4 ? parts[3].replace(/\/\d+$/, "") : "";
                            tooltipText = parts[2] + (ipAddress ? " — " + ipAddress : "");
                            return;
                        } else if (parts[0] === "ethernet") {
                            connectionName = parts[2];
                            status = "\u{f0200} Connected";
                            ipAddress = parts.length >= 4 ? parts[3].replace(/\/\d+$/, "") : "";
                            tooltipText = "Ethernet" + (ipAddress ? " — " + ipAddress : "");
                            return;
                        }
                    }
                }
                status = "\u{f071a} Disconnected";
                tooltipText = "Disconnected";
                connectionName = "";
                ipAddress = "";
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nmProc.running = true
    }
}
