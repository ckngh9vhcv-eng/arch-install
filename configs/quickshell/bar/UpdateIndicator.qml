import QtQuick
import Quickshell.Io
import ".."

Row {
    id: root

    spacing: 2

    property int updateCount: 0
    property string updateList: ""
    property string tooltipText: "Checking for updates..."
    property bool _checking: false
    property var _buffer: []

    Text {
        id: iconText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        color: updateCount > 0 ? Theme.accent : Theme.textDim
        text: "\u{f0ab1}"

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 1500
            loops: Animation.Infinite
            running: root._checking
            onRunningChanged: {
                if (!running) iconText.rotation = 0;
            }
        }

        SequentialAnimation {
            id: colorPulse
            loops: Animation.Infinite
            running: root.updateCount > 0 && !root._checking

            ColorAnimation {
                target: iconText
                property: "color"
                from: Theme.accent; to: Theme.accentBright
                duration: 1500
                easing.type: Easing.InOutSine
            }
            ColorAnimation {
                target: iconText
                property: "color"
                from: Theme.accentBright; to: Theme.accent
                duration: 1500
                easing.type: Easing.InOutSine
            }

            onRunningChanged: {
                if (!running) {
                    iconText.color = Qt.binding(function() {
                        return root.updateCount > 0 ? Theme.accent : Theme.textDim;
                    });
                }
            }
        }
    }

    Text {
        id: countText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        color: updateCount > 0 ? Theme.accent : Theme.textDim
        text: updateCount > 0 ? " " + updateCount : ""
        visible: updateCount > 0

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "{ checkupdates 2>/dev/null; paru -Qua 2>/dev/null; }"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length > 0) root._buffer.push(line);
            }
        }
        onRunningChanged: {
            if (running) {
                root._checking = true;
                root._buffer = [];
            }
        }
        onExited: function(exitCode, exitStatus) {
            root._checking = false;
            var lines = root._buffer;
            root.updateCount = lines.length;
            if (lines.length === 0) {
                root.updateList = "";
                root.tooltipText = "System is up to date";
            } else {
                var shown = lines.slice(0, 20);
                root.updateList = shown.join("\n");
                root.tooltipText = lines.length + " update" + (lines.length !== 1 ? "s" : "") + " available\n" + root.updateList;
                if (lines.length > 20) {
                    root.tooltipText += "\n... and " + (lines.length - 20) + " more";
                }
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}
