import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    spacing: 12

    // CPU usage
    property real cpuPercent: 0
    property real memPercent: 0
    property string memUsed: "0"
    property string memTotal: "0"
    property string diskUsed: "0"
    property string diskTotal: "0"
    property real diskPercent: 0
    property string homeUsed: "0"
    property string homeTotal: "0"
    property real homePercent: 0
    property string mediaUsed: "0"
    property string mediaTotal: "0"
    property real mediaPercent: 0
    property bool mediaMounted: false
    property real gpuPercent: 0
    property real gpuTemp: 0
    property real cpuTemp: 0

    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data);
                if (!isNaN(val)) cpuPercent = val;
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free -m | awk '/Mem:/ {printf \"%s %s %.1f\", $3, $2, $3/$2*100}'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length >= 3) {
                    memUsed = (parseFloat(parts[0]) / 1024).toFixed(1);
                    memTotal = (parseFloat(parts[1]) / 1024).toFixed(1);
                    memPercent = parseFloat(parts[2]);
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -h / | awk 'NR==2 {printf \"%s %s %s\", $3, $2, $5}'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length >= 3) {
                    diskUsed = parts[0];
                    diskTotal = parts[1];
                    diskPercent = parseFloat(parts[2]);
                }
            }
        }
    }

    Process {
        id: homeProc
        command: ["sh", "-c", "df -h /home | awk 'NR==2 {printf \"%s %s %s\", $3, $2, $5}'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length >= 3) {
                    homeUsed = parts[0];
                    homeTotal = parts[1];
                    homePercent = parseFloat(parts[2]);
                }
            }
        }
    }

    Process {
        id: mediaProc
        command: ["sh", "-c", "mountpoint -q /mnt/audiobooks && df -h /mnt/audiobooks | awk 'NR==2 {printf \"%s %s %s\", $3, $2, $5}' || echo 'UNMOUNTED'"]
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim();
                if (s === "UNMOUNTED") {
                    mediaMounted = false;
                } else {
                    var parts = s.split(" ");
                    if (parts.length >= 3) {
                        mediaMounted = true;
                        mediaUsed = parts[0];
                        mediaTotal = parts[1];
                        mediaPercent = parseFloat(parts[2]);
                    }
                }
            }
        }
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "radeontop -d - -l 1 2>/dev/null | head -1 | sed 's/.*gpu \\([0-9.]*\\)%.*/\\1/'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data);
                if (!isNaN(val)) gpuPercent = val;
            }
        }
    }

    Process {
        id: cpuTempProc
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*/; do [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"k10temp\" ] && cat \"$d/temp1_input\" && break; done"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data);
                if (!isNaN(val)) cpuTemp = val / 1000;
            }
        }
    }

    Process {
        id: gpuTempProc
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data);
                if (!isNaN(val)) gpuTemp = val / 1000;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            memProc.running = true;
            diskProc.running = true;
            homeProc.running = true;
            mediaProc.running = true;
            gpuProc.running = true;
            cpuTempProc.running = true;
            gpuTempProc.running = true;
        }
    }

    // CPU bar
    StatBar {
        label: "\u{f4bc} CPU"
        value: cpuPercent
        maxValue: 100
        displayText: cpuPercent.toFixed(1) + "%" + (cpuTemp > 0 ? "  " + cpuTemp.toFixed(0) + "°C" : "")
        barColor: cpuPercent > 80 ? Theme.danger : cpuPercent > 50 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
    }

    // Memory bar
    StatBar {
        label: "\u{f035b} RAM"
        value: memPercent
        maxValue: 100
        displayText: memUsed + " / " + memTotal + " GB"
        barColor: memPercent > 80 ? Theme.danger : memPercent > 60 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
    }

    // Root disk bar
    StatBar {
        label: "\u{f0a0} Root (/)"
        value: diskPercent
        maxValue: 100
        displayText: diskUsed + " / " + diskTotal
        barColor: diskPercent > 85 ? Theme.danger : diskPercent > 70 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
    }

    // Home disk bar
    StatBar {
        label: "\u{f0a0} Home (/home)"
        value: homePercent
        maxValue: 100
        displayText: homeUsed + " / " + homeTotal
        barColor: homePercent > 85 ? Theme.danger : homePercent > 70 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
    }

    // Media disk bar
    StatBar {
        label: "\u{f0a0} Media"
        value: mediaPercent
        maxValue: 100
        displayText: mediaMounted ? mediaUsed + " / " + mediaTotal : "Not mounted"
        barColor: mediaPercent > 85 ? Theme.danger : mediaPercent > 70 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
        visible: mediaMounted
    }

    // GPU bar
    StatBar {
        label: "\u{f035b} GPU"
        value: gpuPercent
        maxValue: 100
        displayText: gpuPercent.toFixed(1) + "%" + (gpuTemp > 0 ? "  " + gpuTemp.toFixed(0) + "°C" : "")
        barColor: gpuPercent > 85 ? Theme.danger : gpuPercent > 70 ? Theme.warning : Theme.accent
        Layout.fillWidth: true
    }

    // Stat bar component
    component StatBar: ColumnLayout {
        property string label
        property real value
        property real maxValue
        property string displayText
        property color barColor

        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textSecondary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: displayText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textDim
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.surface3

            Rectangle {
                width: parent.width * Math.min(value / maxValue, 1.0)
                height: parent.height
                radius: 3
                color: barColor

                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
}
