import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: bar

    property var modelData
    screen: modelData
    signal powerClicked()

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 36

    color: "transparent"

    // Popup state — only one at a time
    property string activePopup: ""

    function togglePopup(name) {
        if (activePopup === name) {
            activePopup = "";
        } else {
            activePopup = name;
        }
        mediaPopup.showing = (activePopup === "media");
        calendarPopup.showing = (activePopup === "calendar");
    }

    function closePopups() {
        activePopup = "";
        mediaPopup.showing = false;
        calendarPopup.showing = false;
    }

    // Tooltip state
    property string tooltipText: ""
    property real tooltipX: 0
    property bool tooltipHovered: false

    Timer {
        id: tooltipDelay
        interval: 500
        repeat: false
        onTriggered: {
            if (bar.tooltipHovered) {
                barTooltip.text = bar.tooltipText;
                barTooltip.tipX = bar.tooltipX;
            }
        }
    }

    function showTooltip(text, globalX) {
        tooltipText = text;
        tooltipX = globalX;
        tooltipHovered = true;
        tooltipDelay.restart();
    }

    function hideTooltip() {
        tooltipHovered = false;
        tooltipDelay.stop();
        barTooltip.text = "";
    }

    BarTooltip {
        id: barTooltip
    }

    MediaPopup {
        id: mediaPopup
        targetX: mediaPlayer.x + 12
    }

    CalendarPopup {
        id: calendarPopup
        targetX: clock.x + clock.width / 2 + 12
    }

    // Blurred background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.75)
        border.width: 0

        // Bottom glow line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.accentDim
            opacity: 0.3
        }
    }

    // Bar content
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Left section: workspaces + media
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 8

            WorkspaceIndicator {}

            BarSeparator {}

            MediaPlayer {
                id: mediaPlayer
                onClicked: bar.togglePopup("media")
                onTooltipHoveredChanged: {
                    if (tooltipHovered && tooltipText.length > 0) {
                        bar.showTooltip(tooltipText, mediaPlayer.mapToItem(null, mediaPlayer.width / 2, 0).x);
                    } else {
                        bar.hideTooltip();
                    }
                }
            }
        }

        // Center: clock
        Item { Layout.fillWidth: true }

        Clock {
            id: clock
            onClicked: bar.togglePopup("calendar")
        }

        Item { Layout.fillWidth: true }

        // Right section: audio, network, bluetooth, tray, power
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            AudioControl {}

            BarSeparator {}

            NetworkIndicator {}

            BarSeparator {}

            BluetoothIndicator {}

            BarSeparator {}

            UpdateIndicator {}

            BarSeparator {}

            SystemTray {}

            BarSeparator {}

            PowerButton {
                onClicked: bar.powerClicked()
            }
        }
    }
}
