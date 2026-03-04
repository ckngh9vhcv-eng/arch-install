import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import ".."

ColumnLayout {
    spacing: 16

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var sink: Pipewire.defaultAudioSink

    // Volume slider
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "\u{f028} Volume"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                color: Theme.textSecondary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: sink && sink.audio ? Math.round(sink.audio.volume * 100) + "%" : "--"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                color: Theme.textDim
            }
        }

        // Volume bar (draggable)
        Rectangle {
            id: volumeTrack
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Theme.surface3

            Rectangle {
                width: sink && sink.audio ? parent.width * Math.min(sink.audio.volume, 1.0) : 0
                height: parent.height
                radius: 4
                color: Theme.accent

                Behavior on width { NumberAnimation { duration: 100 } }
            }

            // Knob handle
            Rectangle {
                x: (sink && sink.audio ? Math.min(sink.audio.volume, 1.0) : 0) * (parent.width - width)
                y: (parent.height - height) / 2
                width: 14
                height: 14
                radius: 7
                color: volumeMouse.pressed ? Theme.accentBright : Theme.accent
                border.width: 2
                border.color: Theme.accentGlow

                Behavior on x { NumberAnimation { duration: volumeMouse.pressed ? 0 : 100 } }
            }

            MouseArea {
                id: volumeMouse
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                cursorShape: Qt.PointingHandCursor

                onPressed: function(event) {
                    setVolumeFromX(event.x);
                }
                onPositionChanged: function(event) {
                    if (pressed) setVolumeFromX(event.x);
                }

                function setVolumeFromX(x) {
                    if (sink && sink.audio) {
                        sink.audio.volume = Math.max(0, Math.min(1.0, x / volumeTrack.width));
                    }
                }
            }
        }

        // Mute toggle
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Theme.radiusInner
            color: sink && sink.audio && sink.audio.muted
                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2)
                   : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.6)
            border.width: 1
            border.color: sink && sink.audio && sink.audio.muted ? Theme.danger : Theme.accentDim

            Text {
                anchors.centerIn: parent
                text: sink && sink.audio && sink.audio.muted ? "\u{eee8} Muted" : "\u{f028} Unmuted"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
                }
            }
        }
    }

    // Toggle buttons grid
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        ToggleButton {
            Layout.fillWidth: true
            icon: "\u{f0eb}"
            label: ShellGlobals.nightLightMode === "manual" ? "Night Light"
                 : ShellGlobals.nightLightMode === "sunset" ? "Night Light (Sunset)"
                 : "Night Light (Sched)"
            active: ShellGlobals.nightLightActive

            onToggled: {
                if (ShellGlobals.nightLightMode === "manual") {
                    ShellGlobals.nightLightActive = !ShellGlobals.nightLightActive;
                    if (ShellGlobals.nightLightActive) {
                        nightLightOnProc.running = true;
                    } else {
                        nightLightOffProc.running = true;
                    }
                }
            }

            Process {
                id: nightLightOnProc
                command: ["hyprctl", "hyprsunset", "temperature", ShellGlobals.nightLightTemp.toString()]
            }
            Process {
                id: nightLightOffProc
                command: ["hyprctl", "hyprsunset", "identity"]
            }
        }

        ToggleButton {
            id: wifiToggle
            Layout.fillWidth: true
            icon: "\u{f1eb}"
            label: "Wi-Fi"
            active: wifiActive

            property bool wifiActive: true

            onToggled: {
                wifiActive = !wifiActive;
                wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiActive ? "on" : "off"];
                wifiToggleProc.running = true;
            }

            Process {
                id: wifiPollProc
                command: ["nmcli", "radio", "wifi"]
                stdout: SplitParser {
                    onRead: data => {
                        wifiToggle.wifiActive = data.trim() === "enabled";
                    }
                }
            }

            Process {
                id: wifiToggleProc
                command: ["true"]
            }

            Timer {
                interval: 5000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: wifiPollProc.running = true
            }
        }

        ToggleButton {
            id: btToggle
            Layout.fillWidth: true
            icon: "\u{f294}"
            label: "Bluetooth"
            active: btActive

            property bool btActive: true

            onToggled: {
                btActive = !btActive;
                btToggleProc.command = ["bluetoothctl", "power", btActive ? "on" : "off"];
                btToggleProc.running = true;
            }

            Process {
                id: btPollProc
                command: ["sh", "-c", "bluetoothctl show | grep Powered | awk '{print $2}'"]
                stdout: SplitParser {
                    onRead: data => {
                        btToggle.btActive = data.trim() === "yes";
                    }
                }
            }

            Process {
                id: btToggleProc
                command: ["true"]
            }

            Timer {
                interval: 5000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: btPollProc.running = true
            }
        }

        ToggleButton {
            Layout.fillWidth: true
            icon: "\u{f1f6}"
            label: "Do Not Disturb"
            active: ShellGlobals.doNotDisturb

            onToggled: {
                ShellGlobals.doNotDisturb = !ShellGlobals.doNotDisturb;
            }
        }

        ToggleButton {
            Layout.fillWidth: true
            icon: "\u{f11b}"
            label: "Game Mode"
            active: ShellGlobals.gameMode
            activeColor: Theme.warning

            onToggled: {
                ShellGlobals.gameMode = !ShellGlobals.gameMode;
                if (ShellGlobals.gameMode) {
                    gameModeOnProc.running = true;
                } else {
                    gameModeOffProc.running = true;
                }
            }

            Process {
                id: gameModeOnProc
                command: ["sh", "-c", "hyprctl keyword animations:enabled false && hyprctl keyword decoration:blur:enabled false && hyprctl keyword decoration:shadow:enabled false && hyprctl keyword decoration:dim_inactive false && hyprctl keyword decoration:rounding 0 && hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0"]
            }
            Process {
                id: gameModeOffProc
                command: ["sh", "-c", "hyprctl keyword animations:enabled true && hyprctl keyword decoration:blur:enabled true && hyprctl keyword decoration:shadow:enabled true && hyprctl keyword decoration:dim_inactive true && hyprctl keyword decoration:rounding 10 && hyprctl keyword general:gaps_in 5 && hyprctl keyword general:gaps_out 10"]
            }
        }

        ToggleButton {
            id: powerToggle
            Layout.fillWidth: true
            icon: powerProfile === "performance" ? "\u{f0e7}" :
                  powerProfile === "power-saver" ? "\u{f06c}" : "\u{f24e}"
            label: powerProfile === "performance" ? "Performance" :
                   powerProfile === "power-saver" ? "Power Saver" : "Balanced"
            active: powerProfile !== "balanced"
            activeColor: powerProfile === "performance" ? Theme.warning : Theme.success

            property string powerProfile: "balanced"

            onToggled: {
                var next = powerProfile === "balanced" ? "performance" :
                           powerProfile === "performance" ? "power-saver" : "balanced";
                powerSetProc.command = ["powerprofilesctl", "set", next];
                powerSetProc.running = true;
            }

            Process {
                id: powerPollProc
                command: ["powerprofilesctl", "get"]
                stdout: SplitParser {
                    onRead: data => {
                        var p = data.trim();
                        if (p.length > 0) powerToggle.powerProfile = p;
                    }
                }
            }

            Process {
                id: powerSetProc
                command: ["true"]
                onRunningChanged: {
                    if (!running) powerPollProc.running = true;
                }
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: powerPollProc.running = true
            }
        }

        ToggleButton {
            Layout.fillWidth: true
            icon: "\u{f111}"
            label: "Record"
            active: ShellGlobals.recording
            activeColor: Theme.danger

            onToggled: {
                ShellGlobals.recording = !ShellGlobals.recording;
                if (ShellGlobals.recording) {
                    recordStartProc.running = true;
                } else {
                    recordStopProc.running = true;
                }
            }

            Process {
                id: recordStartProc
                command: ["sh", "-c", "mkdir -p ~/Videos/recordings && gpu-screen-recorder -w screen -f 60 -a default_output -o ~/Videos/recordings/recording_$(date +%Y%m%d_%H%M%S).mp4"]
            }
            Process {
                id: recordStopProc
                command: ["pkill", "-SIGINT", "gpu-screen-rec"]
            }
        }
    }

    NightLightSchedule {
        Layout.fillWidth: true
    }

    // Toggle button component
    component ToggleButton: Rectangle {
        property string icon: ""
        property string label: ""
        property bool active: false
        property bool _pulsing: false
        property color activeColor: Theme.accent
        signal toggled()

        height: 56
        radius: Theme.radiusInner
        color: active
               ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.2)
               : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.6)
        border.width: 1
        border.color: _pulsing ? Theme.accentBright : (active ? Qt.lighter(activeColor, 1.2) : Theme.accentDim)

        scale: _pulsing ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Timer {
            id: pulseTimer
            interval: 150
            onTriggered: _pulsing = false
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                text: icon
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: active ? Qt.lighter(activeColor, 1.3) : Theme.textDim
            }

            Text {
                text: label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: active ? Theme.textPrimary : Theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                _pulsing = true;
                pulseTimer.restart();
                toggled();
            }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
