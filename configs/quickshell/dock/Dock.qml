import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

Item {
    id: dockRoot

    property bool hovered: false
    property bool showing: ShellGlobals.dockPinned && hovered

    // ── Favorites — shared via ShellGlobals ──
    property var favorites: ShellGlobals.favorites

    // ── Hyprland client polling ──
    property var hyprClients: []

    Timer {
        id: clientPollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clientProc.running = true
    }

    Process {
        id: clientProc
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: function(data) {
                try { dockRoot.hyprClients = JSON.parse(data); }
                catch(e) { dockRoot.hyprClients = []; }
            }
        }
    }

    // ── Computed app lists ──
    property var allDesktopApps: DesktopEntries.applications.values

    property var pinnedApps: {
        var pinned = dockRoot.favorites || [];
        var apps = dockRoot.allDesktopApps;
        var clients = dockRoot.hyprClients;
        var result = [];
        for (var i = 0; i < pinned.length; i++) {
            var app = null;
            for (var j = 0; j < apps.length; j++) {
                if (apps[j].id === pinned[i]) { app = apps[j]; break; }
            }
            if (app) {
                var running = findClient(app, clients);
                result.push({ app: app, isRunning: !!running, address: running ? running.address : "" });
            }
        }
        return result;
    }

    property var runningOnlyApps: {
        var pinned = dockRoot.favorites || [];
        var clients = dockRoot.hyprClients;
        var apps = dockRoot.allDesktopApps;
        var result = [];
        var seen = {};
        for (var i = 0; i < clients.length; i++) {
            var c = clients[i];
            var cls = (c.initialClass || c["class"] || "").toLowerCase();
            if (!cls || seen[cls]) continue;
            // Skip if pinned
            var isPinned = false;
            for (var j = 0; j < pinned.length; j++) {
                if (pinned[j].toLowerCase().replace(".desktop", "").indexOf(cls) !== -1 ||
                    cls.indexOf(pinned[j].toLowerCase().replace(".desktop", "")) !== -1) {
                    isPinned = true; break;
                }
            }
            if (isPinned) continue;
            // Find matching desktop entry
            var app = matchClientToApp(cls, apps);
            if (app) {
                seen[cls] = true;
                result.push({ app: app, isRunning: true, address: c.address });
            }
        }
        return result;
    }

    function findClient(app, clients) {
        var appId = app.id.toLowerCase().replace(".desktop", "");
        for (var i = 0; i < clients.length; i++) {
            var cls = (clients[i].initialClass || clients[i]["class"] || "").toLowerCase();
            if (cls === appId || cls.indexOf(appId) !== -1 || appId.indexOf(cls) !== -1) {
                return clients[i];
            }
        }
        return null;
    }

    function matchClientToApp(cls, apps) {
        // Exact match first
        for (var i = 0; i < apps.length; i++) {
            var id = apps[i].id.toLowerCase().replace(".desktop", "");
            if (id === cls) return apps[i];
        }
        // Contains match
        for (var i = 0; i < apps.length; i++) {
            var id = apps[i].id.toLowerCase().replace(".desktop", "");
            if (id.indexOf(cls) !== -1 || cls.indexOf(id) !== -1) return apps[i];
        }
        return null;
    }

    // ── Hide timer ──
    Timer {
        id: hideTimer
        interval: 400
        onTriggered: dockRoot.hovered = false
    }

    // ── Dock panel ──
    PanelWindow {
        id: dockPanel
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 72
        exclusiveZone: 0
        focusable: false
        color: "transparent"

        margins.bottom: !ShellGlobals.dockPinned ? -dockPanel.implicitHeight
                      : dockRoot.showing ? 0
                      : -(dockPanel.implicitHeight - 6)

        Behavior on margins.bottom {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Full-area hover detection
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    hideTimer.stop();
                    dockRoot.hovered = true;
                } else {
                    hideTimer.restart();
                }
            }

            // Centered pill
            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                width: dockRow.implicitWidth + 24
                height: 60
                radius: height / 2
                color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.88)
                border.width: 1
                border.color: Theme.accentDim

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                // Top glow line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: parent.radius
                    anchors.rightMargin: parent.radius
                    height: 1
                    color: Theme.accentGlow
                    opacity: 0.3
                }

                // Content row
                Row {
                    id: dockRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Pinned apps
                    Repeater {
                        model: dockRoot.pinnedApps

                        DockIcon {
                            required property var modelData
                            app: modelData.app
                            isRunning: modelData.isRunning
                            isPinned: true
                            clientAddress: modelData.address

                            onLeftClicked: {
                                if (modelData.isRunning && modelData.address) {
                                    Hyprland.dispatch("focuswindow address:" + modelData.address);
                                } else {
                                    AppFrequency.recordLaunch(modelData.app.id);
                                    modelData.app.execute();
                                }
                            }
                            onRightClicked: ShellGlobals.toggleFavorite(modelData.app.id)
                        }
                    }

                    // Separator
                    Rectangle {
                        visible: dockRoot.pinnedApps.length > 0 && dockRoot.runningOnlyApps.length > 0
                        width: 1
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.accentDim
                        opacity: 0.5
                    }

                    // Running-only apps
                    Repeater {
                        model: dockRoot.runningOnlyApps

                        DockIcon {
                            required property var modelData
                            app: modelData.app
                            isRunning: true
                            isPinned: false
                            clientAddress: modelData.address

                            onLeftClicked: {
                                if (modelData.address) {
                                    Hyprland.dispatch("focuswindow address:" + modelData.address);
                                }
                            }
                            onRightClicked: ShellGlobals.toggleFavorite(modelData.app.id)
                        }
                    }
                }
            }
        }
    }
}
