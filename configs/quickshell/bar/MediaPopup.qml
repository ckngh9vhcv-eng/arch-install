import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import ".."

PanelWindow {
    id: popup

    property bool showing: false
    property real targetX: 0
    property int _gp: 3 * Theme.glowSpread

    anchors.top: true
    anchors.left: true
    implicitWidth: 320 + _gp * 2
    implicitHeight: contentCol.implicitHeight + 32 + _gp * 2
    visible: showing || hideAnim.running
    color: "transparent"
    focusable: true
    aboveWindows: true

    margins.top: 44 - _gp
    margins.left: Math.max(4, targetX) - _gp

    property var player: {
        var players = Mpris.players.values;
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var sink: Pipewire.defaultAudioSink

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                popup.showing = false;
                event.accepted = true;
            }
        }

        // Glow layers
        Rectangle {
            x: _gp - Theme.glowSpread * 3
            y: _gp - Theme.glowSpread * 3
            width: 320 + Theme.glowSpread * 6
            height: parent.height - _gp * 2 + Theme.glowSpread * 6
            radius: Theme.radiusPopup + Theme.glowSpread * 3
            color: "transparent"
            border.width: Theme.glowSpread * 3
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity * 0.34 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            x: _gp - Theme.glowSpread * 2
            y: _gp - Theme.glowSpread * 2
            width: 320 + Theme.glowSpread * 4
            height: parent.height - _gp * 2 + Theme.glowSpread * 4
            radius: Theme.radiusPopup + Theme.glowSpread * 2
            color: "transparent"
            border.width: Theme.glowSpread * 2
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity * 0.5 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            x: _gp - Theme.glowSpread
            y: _gp - Theme.glowSpread
            width: 320 + Theme.glowSpread * 2
            height: parent.height - _gp * 2 + Theme.glowSpread * 2
            radius: Theme.radiusPopup + Theme.glowSpread
            color: "transparent"
            border.width: Theme.glowSpread
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // Content wrapper at original dimensions
        Item {
            x: _gp
            y: _gp
            width: 320
            height: parent.height - _gp * 2

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusPopup
                color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.95)
                border.width: 1
                border.color: Theme.accentDim

                opacity: popup.showing ? 1.0 : 0.0
                scale: popup.showing ? 1.0 : 0.95
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation { id: hideAnim; duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        spacing: 12
                        Layout.fillWidth: true

                        // Large album art
                        Rectangle {
                            width: 120
                            height: 120
                            radius: Theme.radiusInner
                            color: Theme.surface3
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: player && player.trackArtUrl ? player.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(120, 120)
                                visible: source.toString() !== ""
                                opacity: status === Image.Ready ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            // Fallback icon
                            Text {
                                anchors.centerIn: parent
                                text: "\u{f001}"
                                font.family: Theme.fontFamily
                                font.pixelSize: 36
                                color: Theme.textDim
                                visible: !player || !player.trackArtUrl || player.trackArtUrl.toString() === ""
                            }
                        }

                        // Track info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: player ? (player.trackTitle || "No Track") : "No Player"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: player ? (player.trackArtist || "") : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }

                            Text {
                                text: player ? (player.trackAlbum || "") : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textDim
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }
                    }

                    // Playback controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        Text {
                            text: "\u{f04a}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            color: prevArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            visible: player !== null && player.canGoPrevious

                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (player) player.previous(); }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            property bool _bouncing: false

                            width: 40
                            height: 40
                            radius: 20
                            color: playArea.containsMouse ? Theme.accent : Theme.accentDim
                            scale: _bouncing ? 1.15 : (playArea.containsMouse ? 1.05 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Timer {
                                id: bounceTimer
                                interval: 150
                                onTriggered: parent._bouncing = false
                            }

                            Text {
                                anchors.centerIn: parent
                                text: player && player.playbackState === MprisPlaybackState.Playing ? "\u{f04c}" : "\u{f04b}"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    parent._bouncing = true;
                                    bounceTimer.restart();
                                    if (player) player.togglePlaying();
                                }
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: "\u{f04e}"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            color: nextArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            visible: player !== null && player.canGoNext

                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (player) player.next(); }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Progress bar with time labels
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: player !== null && player.lengthSupported && player.length > 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.surface3

                            property real progress: {
                                var _ = progressTick.tick;
                                if (!player || !player.lengthSupported || player.length <= 0) return 0;
                                return Math.max(0, Math.min(1, player.position / player.length));
                            }

                            Rectangle {
                                width: parent.progress * parent.width
                                height: parent.height
                                radius: 3
                                color: Theme.accent

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.Linear } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -4
                                anchors.bottomMargin: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(event) {
                                    if (player && player.canSeek && player.length > 0) {
                                        player.position = (event.x / parent.width) * player.length;
                                    }
                                }
                            }

                            Timer {
                                id: progressTick
                                property bool tick: false
                                interval: 1000
                                running: popup.showing && player !== null && player.playbackState === MprisPlaybackState.Playing
                                repeat: true
                                onTriggered: tick = !tick
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: {
                                    var _ = progressTick.tick;
                                    if (!player || !player.lengthSupported) return "0:00";
                                    var secs = Math.floor(player.position / 1000000);
                                    var m = Math.floor(secs / 60);
                                    var s = secs % 60;
                                    return m + ":" + s.toString().padStart(2, '0');
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textDim
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (!player || !player.lengthSupported || player.length <= 0) return "0:00";
                                    var secs = Math.floor(player.length / 1000000);
                                    var m = Math.floor(secs / 60);
                                    var s = secs % 60;
                                    return m + ":" + s.toString().padStart(2, '0');
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textDim
                            }
                        }
                    }

                    // Volume slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: {
                                if (!sink || !sink.audio) return "\u{f026}";
                                if (sink.audio.muted) return "\u{eee8}";
                                var vol = Math.round(sink.audio.volume * 100);
                                return vol > 66 ? "\u{f028}" : vol > 33 ? "\u{f027}" : "\u{f026}";
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            color: volMuteArea.containsMouse ? Theme.textPrimary : Theme.textSecondary

                            MouseArea {
                                id: volMuteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Volume track
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.surface3

                            Rectangle {
                                width: (sink && sink.audio && !sink.audio.muted) ? parent.width * Math.min(sink.audio.volume, 1.0) : 0
                                height: parent.height
                                radius: 2
                                color: sink && sink.audio && sink.audio.muted ? Theme.textDim : Theme.accent

                                Behavior on width { NumberAnimation { duration: 100 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(event) {
                                    if (sink && sink.audio) {
                                        sink.audio.volume = Math.max(0, Math.min(1.0, event.x / parent.width));
                                    }
                                }
                                onWheel: function(event) {
                                    if (!sink || !sink.audio) return;
                                    var delta = event.angleDelta.y > 0 ? 0.05 : -0.05;
                                    sink.audio.volume = Math.max(0, Math.min(1.0, sink.audio.volume + delta));
                                }
                            }
                        }

                        Text {
                            text: sink && sink.audio ? Math.round(sink.audio.volume * 100) + "%" : "--"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textDim
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }

    function toggle() { showing = !showing; }
    function show() { showing = true; }
    function hide() { showing = false; }
}
