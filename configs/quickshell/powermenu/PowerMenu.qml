import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: powerMenu

    property bool showing: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: showing
    focusable: true
    aboveWindows: true
    color: "transparent"

    function toggle() {
        showing = !showing;
    }

    function show() {
        showing = true;
    }

    function hide() {
        showing = false;
        logoutOption.confirming = false;
        rebootOption.confirming = false;
        shutdownOption.confirming = false;
    }

    // Dark overlay
    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                powerMenu.hide();
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.82)

            MouseArea {
                anchors.fill: parent
                onClicked: powerMenu.hide()
            }

            // Center content
            Column {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "SYSTEM"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontHeader
                    font.bold: true
                    color: Theme.textPrimary
                    font.letterSpacing: 6
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    PowerOption {
                        icon: "\u{f033e}"
                        label: "Lock"
                        iconColor: Theme.info

                        onClicked: {
                            powerMenu.hide();
                            lockProc.running = true;
                        }

                        Process {
                            id: lockProc
                            command: ["hyprlock"]
                        }
                    }

                    PowerOption {
                        id: logoutOption
                        icon: "\u{f0343}"
                        label: "Logout"
                        iconColor: Theme.warning
                        needsConfirm: true

                        onClicked: {
                            powerMenu.hide();
                            logoutProc.running = true;
                        }

                        Process {
                            id: logoutProc
                            command: ["hyprctl", "dispatch", "exit"]
                        }
                    }

                    PowerOption {
                        id: rebootOption
                        icon: "\u{f0709}"
                        label: "Reboot"
                        iconColor: Theme.accent
                        needsConfirm: true

                        onClicked: {
                            powerMenu.hide();
                            rebootProc.running = true;
                        }

                        Process {
                            id: rebootProc
                            command: ["systemctl", "reboot"]
                        }
                    }

                    PowerOption {
                        id: shutdownOption
                        icon: "\u{f0425}"
                        label: "Shutdown"
                        iconColor: Theme.danger
                        needsConfirm: true

                        onClicked: {
                            powerMenu.hide();
                            shutdownProc.running = true;
                        }

                        Process {
                            id: shutdownProc
                            command: ["systemctl", "poweroff"]
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Press Escape to cancel"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textDim
                }
            }

            // Scale animation
            scale: powerMenu.showing ? 1.0 : 0.95
            opacity: powerMenu.showing ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        }
    }
}
