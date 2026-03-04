import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: scheduleRoot
    spacing: 12
    visible: true

    // Mode selector row
    RowLayout {
        id: modeRow
        Layout.fillWidth: true
        spacing: 6

        component ModeButton: Rectangle {
            property string mode: ""
            property string label: ""

            Layout.fillWidth: true
            height: 28
            radius: Theme.radiusInner
            color: ShellGlobals.nightLightMode === mode
                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                   : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.6)
            border.width: 1
            border.color: ShellGlobals.nightLightMode === mode ? Theme.accent : Theme.accentDim

            Text {
                anchors.centerIn: parent
                text: label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: ShellGlobals.nightLightMode === mode ? Theme.textPrimary : Theme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ShellGlobals.nightLightMode = mode;
                    ShellGlobals.saveNightLight();
                    scheduleTimer.triggered();
                }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        ModeButton { mode: "manual"; label: "Manual" }
        ModeButton { mode: "sunset"; label: "Sunset" }
        ModeButton { mode: "schedule"; label: "Schedule" }
    }

    // Sunset info
    RowLayout {
        Layout.fillWidth: true
        visible: ShellGlobals.nightLightMode === "sunset" && ShellGlobals.locationLat !== 0
        spacing: 16

        Text {
            text: "\u{f185} " + sunriseTime
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.warning
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "\u{f186} " + sunsetTime
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.info
        }
    }

    // Schedule info
    RowLayout {
        Layout.fillWidth: true
        visible: ShellGlobals.nightLightMode === "schedule"
        spacing: 16

        Text {
            text: "\u{f186} On: " + ShellGlobals.nightLightOnTime
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.info
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "\u{f185} Off: " + ShellGlobals.nightLightOffTime
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.warning
        }
    }

    property string sunriseTime: ""
    property string sunsetTime: ""

    function timeToMinutes(timeStr) {
        var parts = timeStr.split(":");
        return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    }

    function checkSchedule() {
        if (ShellGlobals.nightLightMode === "manual") return;

        var now = new Date();
        var nowMinutes = now.getHours() * 60 + now.getMinutes();
        var onMinutes, offMinutes;

        if (ShellGlobals.nightLightMode === "sunset") {
            if (ShellGlobals.locationLat === 0) return;
            var sun = ShellGlobals.getSunTimes(ShellGlobals.locationLat, ShellGlobals.locationLon);
            sunriseTime = sun.sunrise;
            sunsetTime = sun.sunset;
            onMinutes = timeToMinutes(sun.sunset);
            offMinutes = timeToMinutes(sun.sunrise);
        } else {
            onMinutes = timeToMinutes(ShellGlobals.nightLightOnTime);
            offMinutes = timeToMinutes(ShellGlobals.nightLightOffTime);
        }

        // Determine if we should be in night light mode
        var shouldBeActive;
        if (onMinutes > offMinutes) {
            // Spans midnight (e.g., 20:00 to 06:00)
            shouldBeActive = (nowMinutes >= onMinutes || nowMinutes < offMinutes);
        } else {
            shouldBeActive = (nowMinutes >= onMinutes && nowMinutes < offMinutes);
        }

        if (shouldBeActive !== ShellGlobals.nightLightActive) {
            ShellGlobals.nightLightActive = shouldBeActive;
            if (shouldBeActive) {
                nightLightOnProc.command = ["hyprctl", "hyprsunset", "temperature",
                                            ShellGlobals.nightLightTemp.toString()];
                nightLightOnProc.running = true;
            } else {
                nightLightOffProc.running = true;
            }
        }
    }

    Process {
        id: nightLightOnProc
        command: ["true"]
    }

    Process {
        id: nightLightOffProc
        command: ["hyprctl", "hyprsunset", "identity"]
    }

    Timer {
        id: scheduleTimer
        interval: 60000
        running: ShellGlobals.nightLightMode !== "manual"
        repeat: true
        triggeredOnStart: true
        onTriggered: scheduleRoot.checkSchedule()
    }
}
