import QtQuick
import Quickshell.Io
import ".."

Text {
    id: indicator

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody

    property string profile: "balanced"
    property string tooltipText: "Power: balanced"

    text: profile === "performance" ? "\u{f0e7}" :
          profile === "power-saver" ? "\u{f06c}" : "\u{f24e}"

    color: profile === "performance" ? Theme.warning :
           profile === "power-saver" ? Theme.success : Theme.textSecondary

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var next = profile === "balanced" ? "performance" :
                       profile === "performance" ? "power-saver" : "balanced";
            setProc.command = ["powerprofilesctl", "set", next];
            setProc.running = true;
        }
    }

    Process {
        id: pollProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim();
                if (p.length > 0) {
                    indicator.profile = p;
                    indicator.tooltipText = "Power: " + p;
                }
            }
        }
    }

    Process {
        id: setProc
        command: ["true"]
        onRunningChanged: {
            if (!running) pollProc.running = true;
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }
}
