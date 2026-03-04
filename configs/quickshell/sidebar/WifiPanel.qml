import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 8

    property bool expanded: true

    ListModel {
        id: networkModel
    }

    // Poll available networks
    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length === 0) return;
                // nmcli -t uses : as separator
                var parts = line.split(":");
                if (parts.length < 4) return;
                var ssid = parts[0];
                if (ssid.length === 0) return;
                // Deduplicate — skip if already in model
                for (var i = 0; i < networkModel.count; i++) {
                    if (networkModel.get(i).ssid === ssid) return;
                }
                networkModel.append({
                    ssid: ssid,
                    signal: parseInt(parts[1]) || 0,
                    security: parts[2] || "",
                    connected: parts[3] === "*"
                });
            }
        }
        onRunningChanged: {
            if (running) networkModel.clear();
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiScanProc.running = true
    }

    // Section header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "WI-FI NETWORKS"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.bold: true
            font.letterSpacing: 2
            color: Theme.textDim
            Layout.fillWidth: true
        }

        // Refresh button
        Text {
            text: "\u{f021}"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.textDim

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wifiScanProc.running = true
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

    // Network list
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: root.expanded

        Repeater {
            model: networkModel
            delegate: Rectangle {
                Layout.fillWidth: true
                height: passwordInput.visible ? 72 : 40
                radius: Theme.radiusInner
                color: model.connected
                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                       : mouseArea.containsMouse
                         ? Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.8)
                         : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.4)
                border.width: model.connected ? 1 : 0
                border.color: Theme.accentDim

                property bool showPassword: false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Signal strength icon
                        Text {
                            text: model.signal > 75 ? "\u{f1eb}" :
                                  model.signal > 50 ? "\u{f1eb}" :
                                  model.signal > 25 ? "\u{f1eb}" : "\u{f1eb}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: model.connected ? Theme.accent :
                                   model.signal > 50 ? Theme.textSecondary : Theme.textDim
                            opacity: Math.max(0.4, model.signal / 100)
                        }

                        // SSID
                        Text {
                            text: model.ssid
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: model.connected ? Theme.textPrimary : Theme.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Lock icon if secured
                        Text {
                            text: "\u{f023}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textDim
                            visible: model.security !== "" && model.security !== "--"
                        }

                        // Connected indicator
                        Text {
                            text: "\u{f00c}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.success
                            visible: model.connected
                        }
                    }

                    // Password input (shown when connecting to secured network)
                    RowLayout {
                        id: passwordInput
                        Layout.fillWidth: true
                        visible: showPassword
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            radius: 4
                            color: Theme.surface1
                            border.width: 1
                            border.color: Theme.accentDim

                            TextInput {
                                id: passField
                                anchors.fill: parent
                                anchors.margins: 4
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textPrimary
                                echoMode: TextInput.Password
                                clip: true

                                Keys.onReturnPressed: connectWithPassword()
                            }
                        }

                        Rectangle {
                            width: 50
                            height: 24
                            radius: 4
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "Join"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: connectWithPassword()
                            }
                        }
                    }
                }

                function connectWithPassword() {
                    wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", model.ssid, "password", passField.text];
                    wifiConnectProc.running = true;
                    showPassword = false;
                    passField.text = "";
                }

                Process {
                    id: wifiConnectProc
                    command: ["true"]
                }

                Process {
                    id: wifiDisconnectProc
                    command: ["nmcli", "connection", "down", model.ssid]
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.bottomMargin: passwordInput.visible ? 32 : 0
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (model.connected) {
                            wifiDisconnectProc.running = true;
                        } else if (model.security !== "" && model.security !== "--") {
                            showPassword = !showPassword;
                            if (showPassword) passField.forceActiveFocus();
                        } else {
                            wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", model.ssid];
                            wifiConnectProc.running = true;
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        // Empty state
        Text {
            visible: networkModel.count === 0
            text: "Scanning..."
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textDim
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
