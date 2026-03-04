import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

Item {
    id: root

    property bool showing: false
    property string icon: "\u{f028}"
    property real value: 0.0
    property bool muted: false

    function showVolume() {
        volumeProc.running = true;
    }

    function showBrightness() {
        brightnessProc.running = true;
    }

    // Read current volume
    Process {
        id: volumeProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                // Output: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                var line = data.trim();
                root.muted = line.indexOf("[MUTED]") !== -1;
                var match = line.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    root.value = parseFloat(match[1]);
                }
                if (root.muted) {
                    root.icon = "\u{eee8}";
                } else if (root.value > 0.66) {
                    root.icon = "\u{f028}";
                } else if (root.value > 0.33) {
                    root.icon = "\u{f027}";
                } else if (root.value > 0) {
                    root.icon = "\u{f026}";
                } else {
                    root.icon = "\u{eee8}";
                }
                root.showing = true;
                hideTimer.restart();
            }
        }
    }

    // Read current brightness
    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                var pct = parseInt(data.trim());
                if (!isNaN(pct)) {
                    root.value = pct / 100.0;
                    root.muted = false;
                    root.icon = "\u{f185}";
                    root.showing = true;
                    hideTimer.restart();
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.showing = false
    }

    PanelWindow {
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 80

        visible: root.showing || fadeOut.running
        focusable: false
        aboveWindows: true
        color: "transparent"

        // OSD container — centered at bottom
        Item {
            anchors.fill: parent

            Rectangle {
                id: osdBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                width: 240
                height: 48
                radius: 24
                color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.92)
                border.width: 1
                border.color: Theme.accentDim

                opacity: root.showing ? 1.0 : 0.0
                scale: root.showing ? 1.0 : 0.9

                Behavior on opacity {
                    NumberAnimation {
                        id: fadeOut
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Icon
                    Text {
                        text: root.icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: root.muted ? Theme.danger : Theme.accent
                    }

                    // Progress bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.surface3

                        Rectangle {
                            width: parent.width * Math.min(root.value, 1.0)
                            height: parent.height
                            radius: 3
                            color: root.muted ? Theme.danger : Theme.accent

                            Behavior on width {
                                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Percentage
                    Text {
                        text: Math.round(root.value * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        font.bold: true
                        color: root.muted ? Theme.danger : Theme.textPrimary
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
