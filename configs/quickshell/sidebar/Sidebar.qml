import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

Item {
    id: sidebarRoot

    property bool showing: false

    function toggle() {
        showing = !showing;
    }

    function show() {
        showing = true;
    }

    function hide() {
        showing = false;
    }

    // Click-outside backdrop (covers everything except sidebar)
    PanelWindow {
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        visible: sidebarRoot.showing
        focusable: false
        aboveWindows: true
        color: "transparent"

        margins.right: sidebar.implicitWidth

        MouseArea {
            anchors.fill: parent
            onClicked: sidebarRoot.hide()
        }
    }

    // Sidebar panel
    PanelWindow {
        id: sidebar

        property int _gp: 3 * Theme.glowSpread

        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        implicitWidth: 340 + _gp

        visible: sidebarRoot.showing
        focusable: true
        aboveWindows: true
        color: "transparent"

        FocusScope {
            anchors.fill: parent
            focus: true

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    sidebarRoot.hide();
                    event.accepted = true;
                }
            }

            // Left-edge glow strips
            Rectangle {
                x: 0
                y: 0
                width: sidebar._gp
                height: parent.height
                color: Theme.accentGlow
                opacity: sidebarRoot.showing ? Theme.glowBaseOpacity * 0.34 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                x: sidebar._gp / 3
                y: 0
                width: sidebar._gp * 2 / 3
                height: parent.height
                color: Theme.accentGlow
                opacity: sidebarRoot.showing ? Theme.glowBaseOpacity * 0.5 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                x: sidebar._gp * 2 / 3
                y: 0
                width: sidebar._gp / 3
                height: parent.height
                color: Theme.accentGlow
                opacity: sidebarRoot.showing ? Theme.glowBaseOpacity : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            // Background panel
            Rectangle {
                x: sidebar._gp
                y: 0
                width: 340
                height: parent.height
                color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.92)
                border.width: 1
                border.color: Theme.accentDim

                // Left glow line
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: 1
                    color: Theme.accentGlow
                    opacity: 0.4
                }

                ColumnLayout {
                    id: sidebarContent
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 48
                    spacing: 20

                    property int activeTab: 0

                    // Tab bar
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 24

                        // Dashboard tab
                        Item {
                            Layout.preferredWidth: dashLabel.implicitWidth
                            Layout.preferredHeight: dashLabel.implicitHeight + 6

                            Text {
                                id: dashLabel
                                text: "DASHBOARD"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontClock
                                font.bold: sidebarContent.activeTab === 0
                                font.letterSpacing: 4
                                color: sidebarContent.activeTab === 0 ? Theme.textPrimary : Theme.textDim
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                height: 2
                                color: Theme.accent
                                visible: sidebarContent.activeTab === 0
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sidebarContent.activeTab = 0
                            }
                        }

                        // Keybinds tab
                        Item {
                            Layout.preferredWidth: keybindsLabel.implicitWidth
                            Layout.preferredHeight: keybindsLabel.implicitHeight + 6

                            Text {
                                id: keybindsLabel
                                text: "KEYBINDS"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontClock
                                font.bold: sidebarContent.activeTab === 1
                                font.letterSpacing: 4
                                color: sidebarContent.activeTab === 1 ? Theme.textPrimary : Theme.textDim
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                height: 2
                                color: Theme.accent
                                visible: sidebarContent.activeTab === 1
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sidebarContent.activeTab = 1
                            }
                        }
                    }

                    // Dashboard content
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 20
                        visible: parent.activeTab === 0

                        // Uptime
                        Text {
                            id: uptimeText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textDim
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            visible: text.length > 0

                            property string uptimeStr: ""

                            Process {
                                id: uptimeProc
                                command: ["cat", "/proc/uptime"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        var secs = Math.floor(parseFloat(data.split(" ")[0]));
                                        var days = Math.floor(secs / 86400);
                                        var hours = Math.floor((secs % 86400) / 3600);
                                        var mins = Math.floor((secs % 3600) / 60);
                                        var parts = [];
                                        if (days > 0) parts.push(days + "d");
                                        if (hours > 0) parts.push(hours + "h");
                                        parts.push(mins + "m");
                                        uptimeText.text = "Up " + parts.join(" ");
                                    }
                                }
                            }

                            Timer {
                                interval: 60000
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: uptimeProc.running = true
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentDim
                            opacity: 0.5
                        }

                        // System stats section
                        Text {
                            text: "SYSTEM"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.bold: true
                            font.letterSpacing: 2
                            color: Theme.textDim
                        }

                        SystemStats {
                            Layout.fillWidth: true
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentDim
                            opacity: 0.5
                        }

                        // Quick settings section
                        Text {
                            text: "QUICK SETTINGS"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.bold: true
                            font.letterSpacing: 2
                            color: Theme.textDim
                        }

                        QuickSettings {
                            Layout.fillWidth: true
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentDim
                            opacity: 0.5
                        }

                        // Color scheme section
                        Text {
                            text: "COLOR SCHEME"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.bold: true
                            font.letterSpacing: 2
                            color: Theme.textDim
                        }

                        ColorSchemeSelector {
                            Layout.fillWidth: true
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentDim
                            opacity: 0.5
                        }

                        // Notification history section
                        Text {
                            text: "NOTIFICATIONS"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.bold: true
                            font.letterSpacing: 2
                            color: Theme.textDim
                        }

                        NotificationHistory {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }

                    // Keybinds content
                    KeybindReference {
                        visible: parent.activeTab === 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // Slide animation
        margins.right: sidebarRoot.showing ? 0 : -implicitWidth

        Behavior on margins.right {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
    }
}
