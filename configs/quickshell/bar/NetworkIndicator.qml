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
    property string interfaceName: ""
    property real prevRxBytes: -1
    property real prevTxBytes: -1
    property real rxSpeed: 0
    property real txSpeed: 0
    property string baseTooltip: ""

    text: status

    Process {
        id: nmEditorProc
        command: ["nm-connection-editor"]
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nmEditorProc.running = true
    }

    onInterfaceNameChanged: {
        prevRxBytes = -1;
        prevTxBytes = -1;
        rxSpeed = 0;
        txSpeed = 0;
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
    }

    function updateTooltip() {
        if (baseTooltip === "") {
            tooltipText = "Network: ...";
            return;
        }
        if (interfaceName !== "" && (rxSpeed > 0 || txSpeed > 0)) {
            tooltipText = baseTooltip + "\n\u2193 " + formatSpeed(rxSpeed) + "  \u2191 " + formatSpeed(txSpeed);
        } else {
            tooltipText = baseTooltip;
        }
    }

    // Single shell command: outputs "TYPE:CONNECTION:DEVICE:IP" for the first connected interface
    Process {
        id: nmProc
        command: ["sh", "-c", "LINE=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device 2>/dev/null | grep -E '^(ethernet|wifi):connected:' | head -1); if [ -n \"$LINE\" ]; then DEV=$(echo \"$LINE\" | cut -d: -f4); IP=$(nmcli -t -f IP4.ADDRESS device show \"$DEV\" 2>/dev/null | head -1 | sed 's/.*://;s|/.*||'); echo \"$LINE:$IP\"; else echo 'disconnected'; fi"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line === "disconnected" || line === "") {
                    status = "\u{f071a} Disconnected";
                    baseTooltip = "";
                    tooltipText = "Disconnected";
                    connectionName = "";
                    ipAddress = "";
                    interfaceName = "";
                    return;
                }
                var parts = line.split(":");
                if (parts.length >= 4) {
                    var type = parts[0];
                    var conn = parts[2];
                    var dev = parts[3];
                    var ip = parts.length >= 5 ? parts[4] : "";
                    connectionName = conn;
                    interfaceName = dev;
                    ipAddress = ip;
                    if (type === "wifi") {
                        status = "\u{f1eb} " + conn;
                        baseTooltip = conn + (ip ? " \u2014 " + ip : "");
                    } else {
                        status = "\u{f0200} Connected";
                        baseTooltip = "Ethernet" + (ip ? " \u2014 " + ip : "");
                    }
                    updateTooltip();
                }
            }
        }
    }

    Process {
        id: speedProc
        property string iface: interfaceName
        command: ["sh", "-c", "cat /sys/class/net/" + iface + "/statistics/rx_bytes /sys/class/net/" + iface + "/statistics/tx_bytes 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var lines = data.trim().split("\n");
                if (lines.length >= 2) {
                    var rx = parseFloat(lines[0]);
                    var tx = parseFloat(lines[1]);
                    if (prevRxBytes >= 0 && prevTxBytes >= 0) {
                        rxSpeed = Math.max(0, (rx - prevRxBytes) / 3);
                        txSpeed = Math.max(0, (tx - prevTxBytes) / 3);
                        updateTooltip();
                    }
                    prevRxBytes = rx;
                    prevTxBytes = tx;
                }
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

    Timer {
        id: speedTimer
        interval: 3000
        running: interfaceName !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            speedProc.iface = interfaceName;
            speedProc.running = true;
        }
    }
}
