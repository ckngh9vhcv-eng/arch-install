import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: mixer
    spacing: 8

    property bool expanded: true

    ListModel {
        id: streamModel
    }

    function appIcon(name) {
        var lower = name.toLowerCase();
        if (lower.indexOf("firefox") !== -1) return "\u{f269}";
        if (lower.indexOf("chromium") !== -1 || lower.indexOf("chrome") !== -1) return "\u{f268}";
        if (lower.indexOf("discord") !== -1) return "\u{f392}";
        if (lower.indexOf("spotify") !== -1) return "\u{f1bc}";
        if (lower.indexOf("mpv") !== -1) return "\u{f144}";
        if (lower.indexOf("vlc") !== -1) return "\u{f144}";
        if (lower.indexOf("obs") !== -1) return "\u{f03d}";
        if (lower.indexOf("steam") !== -1) return "\u{f1b6}";
        return "\u{f028}";
    }

    // Incoming data buffer for reconciliation
    property var _pendingStreams: []

    // Poll script: extracts stream ID, app name, volume, mute status
    Process {
        id: pollProc
        command: ["sh", "-c", [
            "wpctl status 2>/dev/null | awk '",
            "/Audio/,/Video/ {",
            "  if (/Streams:/) f=1",
            "  else if (f && /^[[:space:]]+[0-9]+\\./) {",
            "    if (index($0, \">\") == 0) {",
            "      gsub(/^[[:space:]│*]+/, \"\")",
            "      match($0, /^([0-9]+)\\. +(.+)/, a)",
            "      if (a[1]) print a[1] \"|\" a[2]",
            "    }",
            "  }",
            "}' | while IFS='|' read -r id name; do",
            "  [ -z \"$id\" ] && continue",
            "  name=$(echo \"$name\" | sed 's/[[:space:]]*$//')",
            "  appname=$(wpctl inspect \"$id\" 2>/dev/null | grep -m1 'application.name' | sed 's/.*= \"//;s/\"//')",
            "  [ -z \"$appname\" ] && appname=\"$name\"",
            "  volline=$(wpctl get-volume \"$id\" 2>/dev/null)",
            "  vol=$(echo \"$volline\" | awk '{print $2}')",
            "  muted=0",
            "  echo \"$volline\" | grep -q MUTED && muted=1",
            "  echo \"$id|$appname|$vol|$muted\"",
            "done"
        ].join("\n")]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length < 4) return;
                mixer._pendingStreams.push({
                    streamId: parts[0],
                    appName: parts[1].trim(),
                    volume: parseFloat(parts[2]),
                    muted: parts[3] === "1"
                });
            }
        }
        onRunningChanged: {
            if (running) {
                mixer._pendingStreams = [];
            } else {
                mixer.reconcileStreams();
            }
        }
    }

    // Update model in-place: update existing, add new, remove stale
    function reconcileStreams() {
        var incoming = _pendingStreams;
        var seenIds = {};

        // Update existing or add new
        for (var i = 0; i < incoming.length; i++) {
            var s = incoming[i];
            seenIds[s.streamId] = true;
            var found = false;
            for (var j = 0; j < streamModel.count; j++) {
                if (streamModel.get(j).streamId === s.streamId) {
                    streamModel.setProperty(j, "appName", s.appName);
                    streamModel.setProperty(j, "volume", s.volume);
                    streamModel.setProperty(j, "muted", s.muted);
                    found = true;
                    break;
                }
            }
            if (!found) {
                streamModel.append(s);
            }
        }

        // Remove streams that no longer exist
        for (var k = streamModel.count - 1; k >= 0; k--) {
            if (!seenIds[streamModel.get(k).streamId]) {
                streamModel.remove(k);
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    // Section header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "APP MIXER"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.bold: true
            font.letterSpacing: 2
            color: Theme.textDim
            Layout.fillWidth: true
        }

        Text {
            text: "\u{f021}"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: refreshArea.containsMouse ? Theme.textPrimary : Theme.textDim

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pollProc.running = true
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            text: mixer.expanded ? "\u{f078}" : "\u{f054}"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: collapseArea.containsMouse ? Theme.textPrimary : Theme.textDim

            MouseArea {
                id: collapseArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mixer.expanded = !mixer.expanded
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Stream list
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: mixer.expanded

        // Empty state
        Text {
            text: "No audio streams"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textDim
            Layout.alignment: Qt.AlignHCenter
            visible: streamModel.count === 0
        }

        Repeater {
            model: streamModel

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: Theme.radiusInner
                color: model.muted
                       ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.1)
                       : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.4)
                border.width: 1
                border.color: model.muted ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.3) : Theme.accentDim

                property string sid: model.streamId
                property real vol: model.volume
                property bool isMuted: model.muted

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Top row: icon, name, percentage, mute
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: mixer.appIcon(model.appName)
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: isMuted ? Theme.danger : Theme.accent
                        }

                        Text {
                            text: model.appName
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: isMuted ? Theme.textDim : Theme.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Math.round(vol * 100) + "%"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textDim
                        }

                        Text {
                            text: isMuted ? "\u{eee8}" : "\u{f028}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: muteArea.containsMouse
                                   ? Theme.textPrimary
                                   : (isMuted ? Theme.danger : Theme.textSecondary)

                            MouseArea {
                                id: muteArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    muteProc.command = ["wpctl", "set-mute", sid, "toggle"];
                                    muteProc.running = true;
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Volume slider
                    Rectangle {
                        id: sliderTrack
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.surface3

                        Rectangle {
                            width: parent.width * Math.min(vol, 1.0)
                            height: parent.height
                            radius: 3
                            color: isMuted ? Theme.danger : Theme.accent

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }

                        Rectangle {
                            x: Math.min(vol, 1.0) * (parent.width - width)
                            y: (parent.height - height) / 2
                            width: 10
                            height: 10
                            radius: 5
                            color: sliderMouse.pressed ? Theme.accentBright : (isMuted ? Theme.danger : Theme.accent)
                            border.width: 1
                            border.color: Theme.accentGlow

                            Behavior on x { NumberAnimation { duration: sliderMouse.pressed ? 0 : 100 } }
                        }

                        MouseArea {
                            id: sliderMouse
                            anchors.fill: parent
                            anchors.topMargin: -6
                            anchors.bottomMargin: -6
                            cursorShape: Qt.PointingHandCursor

                            onPressed: function(event) {
                                setVolFromX(event.x);
                            }
                            onPositionChanged: function(event) {
                                if (pressed) setVolFromX(event.x);
                            }
                            onReleased: {
                                volSetProc.command = ["wpctl", "set-volume", sid, vol.toFixed(2)];
                                volSetProc.running = true;
                            }

                            function setVolFromX(x) {
                                var newVol = Math.max(0, Math.min(1.0, x / sliderTrack.width));
                                // Update model directly for instant visual feedback
                                streamModel.setProperty(index, "volume", newVol);
                            }
                        }
                    }
                }

                Process {
                    id: volSetProc
                    command: ["true"]
                }

                Process {
                    id: muteProc
                    command: ["true"]
                    onRunningChanged: {
                        if (!running) pollProc.running = true;
                    }
                }

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
            }
        }
    }
}
