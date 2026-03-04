import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

Item {
    id: mediaRoot
    implicitWidth: controls.implicitWidth
    implicitHeight: controls.implicitHeight
    visible: player !== null

    signal clicked()

    property string tooltipText: trackInfoText.tooltipText
    property bool tooltipHovered: trackMouse.containsMouse || playIconMouse.containsMouse

    property var player: {
        var players = Mpris.players.values;
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    RowLayout {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        // Album art thumbnail
        Rectangle {
            width: 20
            height: 20
            radius: 4
            color: Theme.surface3
            clip: true
            visible: player !== null && player.trackArtUrl && player.trackArtUrl.toString() !== ""

            Image {
                anchors.fill: parent
                source: player ? player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(20, 20)
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }

        // Previous track
        Text {
            visible: player !== null && player.canGoPrevious
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: prevMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
            text: "\u{f04a}"

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (player) player.previous(); }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Play/pause icon with pulse animation
        Text {
            id: playIcon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: player && player.playbackState === MprisPlaybackState.Playing
                   ? Theme.textPrimary : Theme.accentGlow
            text: {
                if (!player) return "";
                return player.playbackState === MprisPlaybackState.Playing ? "\u25b6" : "\u23f8";
            }

            SequentialAnimation {
                id: pulseAnim
                loops: Animation.Infinite
                running: player !== null && player.playbackState === MprisPlaybackState.Playing

                NumberAnimation {
                    target: playIcon
                    property: "opacity"
                    from: 1.0; to: 0.5
                    duration: 1200
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: playIcon
                    property: "opacity"
                    from: 0.5; to: 1.0
                    duration: 1200
                    easing.type: Easing.InOutSine
                }

                onRunningChanged: {
                    if (!running) playIcon.opacity = 1.0;
                }
            }

            MouseArea {
                id: playIconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mediaRoot.clicked()
            }
        }

        // Track info
        Text {
            id: trackInfoText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.italic: true
            color: player && player.playbackState === MprisPlaybackState.Playing
                   ? Theme.textPrimary : Theme.accentGlow
            text: {
                if (!player) return "";
                var artist = player.trackArtist || "";
                var title = player.trackTitle || "";
                var label = artist ? (artist + " \u2014 " + title) : title;
                if (label.length > 40) label = label.substring(0, 37) + "...";
                return label;
            }
            elide: Text.ElideRight

            property string tooltipText: {
                if (!player) return "";
                var artist = player.trackArtist || "";
                var title = player.trackTitle || "";
                return artist ? (artist + " \u2014 " + title) : title;
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mediaRoot.clicked()
            }
        }

        // Next track
        Text {
            visible: player !== null && player.canGoNext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: nextMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
            text: "\u{f04e}"

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (player) player.next(); }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Progress bar — pinned to bottom of the bar area
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -8
        height: 2
        color: Theme.surface3
        visible: player !== null && player.lengthSupported && player.length > 0
        radius: 1

        property real progress: {
            var _ = _tick;
            if (!player || !player.lengthSupported || player.length <= 0) return 0;
            return Math.max(0, Math.min(1, player.position / player.length));
        }

        Rectangle {
            width: parent.progress * parent.width
            height: parent.height
            color: Theme.accent
            radius: 1

            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.Linear } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: function(event) {
                if (player && player.canSeek && player.length > 0) {
                    player.position = (event.x / parent.width) * player.length;
                }
            }
        }

        Timer {
            id: posTimer
            property bool tick: false
            interval: 1000
            running: player !== null && player.playbackState === MprisPlaybackState.Playing
            repeat: true
            onTriggered: tick = !tick
        }

        property real _tick: posTimer.tick ? 1 : 0
    }
}
