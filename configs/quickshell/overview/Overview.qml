import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import ".."

PanelWindow {
    id: overview

    property bool showing: false
    property var hyprClients: []
    property int selectedIndex: -1
    property string screenshotPath: ""
    property int capturedWsId: 0

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: showing
    focusable: true
    aboveWindows: true
    color: "transparent"

    property string wallpaperPath: {
        var wps = Theme.currentWallpapers;
        var idx = Theme.currentWallpaperIndex;
        if (wps.length > 0 && idx < wps.length) {
            return "file://" + Quickshell.env("HOME") + "/wallpapers/" + wps[idx];
        }
        return "";
    }

    function toggle() {
        if (showing) hide();
        else show();
    }

    function show() {
        selectedIndex = -1;
        capturedWsId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0;
        screenshotProc.running = true;
    }

    function hide() {
        showing = false;
        // Reset entrance states
        for (var i = 0; i < cardRepeater.count; i++) {
            var item = cardRepeater.itemAt(i);
            if (item) item.entranceReady = false;
        }
    }

    function activateWorkspace(wsId) {
        Hyprland.dispatch("workspace " + wsId);
        hide();
    }

    function activateWindow(address) {
        Hyprland.dispatch("focuswindow address:" + address);
        hide();
    }

    function windowsForWorkspace(wsId) {
        var result = [];
        for (var i = 0; i < hyprClients.length; i++) {
            var c = hyprClients[i];
            if (c.workspace && c.workspace.id === wsId && !c.hidden && c.mapped !== false) {
                result.push(c);
            }
        }
        return result;
    }

    // Staggered entrance
    property int entranceIndex: 0
    Timer {
        id: entranceTimer
        interval: 40
        repeat: true
        onTriggered: {
            if (overview.entranceIndex < cardRepeater.count) {
                var item = cardRepeater.itemAt(overview.entranceIndex);
                if (item) item.entranceReady = true;
                overview.entranceIndex++;
            } else {
                entranceTimer.stop();
                overview.entranceIndex = 0;
            }
        }
    }

    Process {
        id: screenshotProc
        command: ["grim", "/tmp/qs-overview-capture.png"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                overview.screenshotPath = "file:///tmp/qs-overview-capture.png?" + Date.now();
            } else {
                overview.screenshotPath = "";
            }
            clientProc.running = true;
        }
    }

    Process {
        id: clientProc
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: function(data) {
                try { overview.hyprClients = JSON.parse(data); }
                catch(e) { overview.hyprClients = []; }
                overview.showing = true;
                overview.entranceIndex = 0;
                entranceTimer.start();
            }
        }
    }

    property real screenW: width > 0 ? width : 1920
    property real screenH: height > 0 ? height : 1080

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                overview.hide();
                event.accepted = true;
                return;
            }

            var idx = overview.selectedIndex;
            if (event.key === Qt.Key_Up) {
                idx = idx <= 0 ? 0 : idx - 1;
            } else if (event.key === Qt.Key_Down) {
                idx = idx < 0 ? 0 : Math.min(idx + 1, workspaceModel.count - 1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (idx >= 0 && idx < workspaceModel.count) {
                    overview.activateWorkspace(workspaceModel.get(idx).wsId);
                }
                event.accepted = true;
                return;
            } else {
                return;
            }

            overview.selectedIndex = idx;
            event.accepted = true;
        }

        // Wallpaper backdrop
        Image {
            id: backdropImage
            anchors.fill: parent
            source: overview.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: false  // Hidden — used as source for blur
        }

        // Blurred wallpaper
        FastBlur {
            anchors.fill: backdropImage
            source: backdropImage
            radius: 48
        }

        // Dim + color wash over blurred wallpaper
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.5)
        }

        // Subtle accent gradient in center
        RadialGradient {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.8
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.04) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: overview.hide()
        }

        ListModel {
            id: workspaceModel
        }

        onVisibleChanged: {
            if (!visible) return;
            rebuildModel();
        }

        function rebuildModel() {
            workspaceModel.clear();
            var activeId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
            for (var ws = 1; ws <= 9; ws++) {
                var wins = overview.windowsForWorkspace(ws);
                if (wins.length > 0 || ws === activeId) {
                    workspaceModel.append({ wsId: ws, isEmpty: wins.length === 0 });
                }
            }
        }

        Item {
            id: contentContainer
            anchors.centerIn: parent
            width: parent.width * 0.82
            height: parent.height * 0.88

            scale: overview.showing ? 1.0 : 0.9
            opacity: overview.showing ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: 14
                width: parent.width

                Repeater {
                    id: cardRepeater
                    model: workspaceModel

                    WorkspaceCard {
                        required property int index
                        required property var model

                        width: contentContainer.width
                        height: model.isEmpty
                                ? 48
                                : Math.min(
                                    (contentContainer.height - (workspaceModel.count - 1) * 14) / workspaceModel.count,
                                    contentContainer.width * (9/16)
                                  )

                        wsId: model.wsId
                        windows: overview.windowsForWorkspace(model.wsId)
                        screenWidth: overview.screenW
                        screenHeight: overview.screenH
                        isSelected: overview.selectedIndex === index
                        wallpaperSource: overview.wallpaperPath
                        screenshotSource: model.wsId === overview.capturedWsId
                                          ? overview.screenshotPath : ""
                        cardIndex: index

                        onWindowClicked: function(address) {
                            overview.activateWindow(address);
                        }
                        onBackgroundClicked: {
                            overview.activateWorkspace(wsId);
                        }
                    }
                }
            }
        }
    }
}
