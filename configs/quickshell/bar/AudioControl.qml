import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import ".."

RowLayout {
    spacing: 4

    // Track the default sink so its properties become available
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var sink: Pipewire.defaultAudioSink

    // Tooltip support
    property string tooltipText: {
        if (!sink || !sink.audio) return "Audio unavailable";
        if (sink.audio.muted) return "Muted — " + (sink.description || "Unknown device");
        var vol = Math.round(sink.audio.volume * 100);
        return "Volume: " + vol + "% — " + (sink.description || "Unknown device");
    }

    Process {
        id: pavuProc
        command: ["pavucontrol"]
    }

    Text {
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        color: mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary

        scale: mouseArea.pressed ? 0.95 : mouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        text: {
            if (!sink || !sink.audio) return "\u{f026} --";
            if (sink.audio.muted) return "\u{eee8} Muted";
            var vol = Math.round(sink.audio.volume * 100);
            var icon = vol > 66 ? "\u{f028}" : vol > 33 ? "\u{f027}" : "\u{f026}";
            return icon + " " + vol + "%";
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: function(event) {
                if (event.button === Qt.RightButton) {
                    pavuProc.running = true;
                    return;
                }
                if (!sink || !sink.audio) return;
                if (event.button === Qt.LeftButton) {
                    sink.audio.muted = !sink.audio.muted;
                }
            }

            onWheel: function(event) {
                if (!sink || !sink.audio) return;
                var delta = event.angleDelta.y > 0 ? 0.05 : -0.05;
                sink.audio.volume = Math.max(0, Math.min(1.0, sink.audio.volume + delta));
            }
        }
    }
}
