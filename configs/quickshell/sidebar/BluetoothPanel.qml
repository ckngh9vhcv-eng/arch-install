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

    // Poll paired devices
    Process {
        id: pairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length === 0) return;
                // Format: "Device XX:XX:XX:XX:XX:XX Name"
                var match = line.match(/^Device\s+([0-9A-F:]+)\s+(.+)$/i);
                if (!match) return;
                pairedModel.append({
                    mac: match[1],
                    name: match[2],
                    connected: false,
                    paired: true
                });
            }
        }
        onRunningChanged: {
            if (running) pairedModel.clear();
        }
        onExited: {
            // Check connection status for each device
            for (var i = 0; i < pairedModel.count; i++) {
                checkConnectionStatus(pairedModel.get(i).mac, i);
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

    // Scan: run bluetoothctl scan for 10s in background, then list discovered devices
    Process {
        id: scanProc
        command: ["sh", "-c", "timeout 10 bluetoothctl scan on > /dev/null 2>&1; bluetoothctl scan off > /dev/null 2>&1"]
        onExited: {
            root.scanning = false;
            availableScanProc.running = true;
        }
    }

    // List discovered devices, filtering out already-paired ones
    Process {
        id: availableScanProc
        command: ["sh", "-c", "comm -23 <(bluetoothctl devices | sort) <(bluetoothctl devices Paired | sort)"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length === 0) return;
                var match = line.match(/^Device\s+([0-9A-F:]+)\s+(.+)$/i);
                if (!match) return;
                for (var i = 0; i < availableModel.count; i++) {
                    if (availableModel.get(i).mac === match[1]) return;
                }
                availableModel.append({
                    mac: match[1],
                    name: match[2],
                    connected: false,
                    paired: false
                });
            }
        }
        onRunningChanged: {
            if (running) availableModel.clear();
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
