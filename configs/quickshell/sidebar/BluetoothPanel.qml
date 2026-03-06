import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 8

    property bool expanded: true
    property bool scanning: false

    ListModel {
        id: pairedModel
    }

    ListModel {
        id: availableModel
    }

    property var _pendingPaired: []

    // Poll paired devices
    Process {
        id: pairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length === 0) return;
                var match = line.match(/^Device\s+([0-9A-F:]+)\s+(.+)$/i);
                if (!match) return;
                root._pendingPaired.push({ mac: match[1], name: match[2] });
            }
        }
        onRunningChanged: {
            if (running) root._pendingPaired = [];
        }
        onExited: {
            var pending = root._pendingPaired;
            var pendingMacs = pending.map(function(d) { return d.mac; });

            // Remove devices no longer paired
            for (var i = pairedModel.count - 1; i >= 0; i--) {
                if (pendingMacs.indexOf(pairedModel.get(i).mac) === -1)
                    pairedModel.remove(i);
            }
            // Add/update devices
            for (var j = 0; j < pending.length; j++) {
                var found = false;
                for (var k = 0; k < pairedModel.count; k++) {
                    if (pairedModel.get(k).mac === pending[j].mac) {
                        pairedModel.setProperty(k, "name", pending[j].name);
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    pairedModel.append({
                        mac: pending[j].mac,
                        name: pending[j].name,
                        connected: false,
                        paired: true
                    });
                }
            }
            // Check connection status for each device
            for (var ci = 0; ci < pairedModel.count; ci++) {
                checkConnectionStatus(pairedModel.get(ci).mac, ci);
            }
        }
    }

    function checkConnectionStatus(mac, index) {
        var proc = statusCheckComponent.createObject(root, { mac: mac, modelIndex: index });
        proc.running = true;
    }

    Component {
        id: statusCheckComponent
        Process {
            property string mac
            property int modelIndex
            command: ["sh", "-c", "bluetoothctl info " + mac + " | grep 'Connected: yes'"]
            onExited: {
                if (modelIndex < pairedModel.count) {
                    pairedModel.setProperty(modelIndex, "connected", exitCode === 0);
                }
                destroy();
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pairedProc.running = true
    }

    // Scan: bluetoothctl must stay interactive for discovery to work.
    // Send scan on, wait, then diff all devices vs paired to find available ones.
    Process {
        id: scanProc
        command: ["python3", "-c", `
import subprocess, time, re
ansi = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]|\x1b\[[0-9;]*[PK]')
proc = subprocess.Popen(['bluetoothctl'], stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
proc.stdin.write(b'scan on\n')
proc.stdin.flush()
time.sleep(8)
proc.stdin.write(b'devices\n')
proc.stdin.flush()
time.sleep(0.5)
proc.stdin.write(b'devices Paired\n')
proc.stdin.flush()
time.sleep(0.5)
proc.stdin.write(b'scan off\n')
proc.stdin.flush()
proc.stdin.write(b'quit\n')
proc.stdin.flush()
out, _ = proc.communicate(timeout=5)
raw = ansi.sub('', out.decode(errors='replace'))
lines = raw.split('\n')
all_devs = {}
paired_macs = set()
section = None
for line in lines:
    stripped = line.strip()
    if stripped.endswith('> devices') or stripped == 'devices':
        section = 'all'
        continue
    if stripped.endswith('> devices Paired') or stripped == 'devices Paired':
        section = 'paired'
        continue
    m = re.match(r'^Device\s+([0-9A-F:]{17})\s+(.+)', stripped, re.I)
    if section and m:
        mac, name = m.group(1), m.group(2)
        if section == 'all':
            all_devs[mac] = name
        elif section == 'paired':
            paired_macs.add(mac)
for mac, name in all_devs.items():
    if mac not in paired_macs:
        print(f'AVAILABLE|{mac}|{name}')
`]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (!line.startsWith("AVAILABLE|")) return;
                var parts = line.split("|");
                if (parts.length < 3) return;
                var mac = parts[1];
                var name = parts.slice(2).join("|");
                if (name.length === 0) name = mac;
                // Skip duplicates
                for (var j = 0; j < availableModel.count; j++) {
                    if (availableModel.get(j).mac === mac) return;
                }
                availableModel.append({
                    mac: mac,
                    name: name,
                    connected: false,
                    paired: false
                });
            }
        }
        onRunningChanged: {
            if (running) availableModel.clear();
        }
        onExited: {
            root.scanning = false;
        }
    }

    // Section header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "BLUETOOTH"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.bold: true
            font.letterSpacing: 2
            color: Theme.textDim
            Layout.fillWidth: true
        }

        // Scan button
        Text {
            text: root.scanning ? "\u{f110}" : "\u{f002}"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: root.scanning ? Theme.accent : Theme.textDim

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.scanning) {
                        root.scanning = true;
                        scanProc.running = true;
                    }
                }
            }
        }

        // Collapse toggle
        Text {
            text: root.expanded ? "\u{f078}" : "\u{f054}"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.textDim

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    // Device lists
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: root.expanded

        // Paired devices
        Repeater {
            model: pairedModel
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Theme.radiusInner
                color: model.connected
                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                       : btMouseArea.containsMouse
                         ? Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.8)
                         : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.4)
                border.width: model.connected ? 1 : 0
                border.color: Theme.accentDim

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Device icon
                    Text {
                        text: "\u{f294}"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: model.connected ? Theme.accent : Theme.textDim
                    }

                    // Device name
                    Text {
                        text: model.name
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: model.connected ? Theme.textPrimary : Theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Connected indicator
                    Text {
                        text: model.connected ? "Connected" : "Paired"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: model.connected ? Theme.success : Theme.textDim
                    }
                }

                Process {
                    id: btConnectProc
                    command: ["bluetoothctl", "connect", model.mac]
                }
                Process {
                    id: btDisconnectProc
                    command: ["bluetoothctl", "disconnect", model.mac]
                }

                MouseArea {
                    id: btMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (model.connected) {
                            btDisconnectProc.running = true;
                        } else {
                            btConnectProc.running = true;
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        // Available (unpaired) section header
        Text {
            visible: availableModel.count > 0
            text: "AVAILABLE"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
            color: Theme.textDim
            Layout.topMargin: 4
        }

        // Available devices
        Repeater {
            model: availableModel
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Theme.radiusInner
                color: availMouseArea.containsMouse
                       ? Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.8)
                       : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "\u{f294}"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.textDim
                    }

                    Text {
                        text: model.name
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Pair"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.accent
                    }
                }

                Process {
                    id: pairConnectProc
                    command: ["sh", "-c", "bluetoothctl pair " + model.mac + " && bluetoothctl connect " + model.mac]
                }

                MouseArea {
                    id: availMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: pairConnectProc.running = true
                }

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        // Empty state
        Text {
            visible: pairedModel.count === 0 && availableModel.count === 0
            text: "No devices"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textDim
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
