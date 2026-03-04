import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: launcher

    property bool showing: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: showing
    focusable: true
    aboveWindows: true
    color: "transparent"

    function toggle() {
        if (showing) hide();
        else show();
    }

    function show() {
        showing = true;
        searchField.clear();
        searchField.focusInput();
    }

    function hide() {
        showing = false;
    }

    function isUrl(text) {
        if (text.indexOf("http://") === 0 || text.indexOf("https://") === 0)
            return true;
        return /^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}/.test(text);
    }

    function getSearchUrl(text) {
        if (text.indexOf("http://") === 0 || text.indexOf("https://") === 0)
            return text;
        if (isUrl(text))
            return "https://" + text;
        return "https://duckduckgo.com/?q=" + encodeURIComponent(text);
    }

    function openWebSearch() {
        Qt.openUrlExternally(getSearchUrl(searchField.text));
        hide();
    }

    // Dark overlay backdrop
    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (appGrid.contextMenuVisible) {
                    appGrid.contextMenuVisible = false;
                } else {
                    launcher.hide();
                }
                event.accepted = true;
                return;
            }
            // Forward arrow keys and Enter to AppGrid
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                appGrid.handleKey(event);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.75)

            // Close on background click
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (appGrid.contextMenuVisible) {
                        appGrid.contextMenuVisible = false;
                    } else {
                        launcher.hide();
                    }
                }
            }

            // Center content panel
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.65, 900)
                height: Math.min(parent.height * 0.7, 650)
                radius: Theme.radiusPopup
                color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.92)
                border.width: 1
                border.color: Theme.accentDim

                // Prevent clicks from closing
                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // Search bar
                    SearchField {
                        id: searchField
                        anchors.horizontalCenter: parent.horizontalCenter
                        onAccepted: {
                            if (appGrid.count > 0)
                                appGrid.launchFirst();
                            else if (searchField.text.length > 0)
                                launcher.openWebSearch();
                        }
                    }

                    // Favorites row — visible only when search is empty
                    Row {
                        id: favRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        visible: searchField.text.length === 0
                        height: visible ? 56 : 0

                        property var favApps: {
                            // Build favorites list: pinned first, then top frecency
                            var pinned = appGrid.favorites || [];
                            var allApps = DesktopEntries.applications.values;
                            var result = [];
                            var seen = {};

                            // Add pinned favorites first
                            for (var i = 0; i < pinned.length && result.length < 8; i++) {
                                var app = allApps.find(function(a) { return a.id === pinned[i]; });
                                if (app) {
                                    result.push(app);
                                    seen[pinned[i]] = true;
                                }
                            }

                            // Fill remaining from frecency
                            var top = AppFrequency.getTopApps(8);
                            for (var j = 0; j < top.length && result.length < 8; j++) {
                                if (!seen[top[j].id] && top[j].score > 0) {
                                    var frecApp = allApps.find(function(a) { return a.id === top[j].id; });
                                    if (frecApp) {
                                        result.push(frecApp);
                                        seen[top[j].id] = true;
                                    }
                                }
                            }

                            return result;
                        }

                        Repeater {
                            model: favRow.favApps

                            Rectangle {
                                required property var modelData
                                width: 48
                                height: 48
                                radius: Theme.radiusInner
                                color: favMouse.containsMouse
                                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                       : "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                    sourceSize.width: 36
                                    sourceSize.height: 36
                                    width: 36
                                    height: 36
                                    smooth: true
                                }

                                MouseArea {
                                    id: favMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AppFrequency.recordLaunch(modelData.id);
                                        modelData.execute();
                                        launcher.hide();
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    // App grid
                    AppGrid {
                        id: appGrid
                        width: parent.width
                        height: parent.height - searchField.height
                               - (favRow.visible ? favRow.height + 16 : 0)
                               - (webFallback.visible ? webFallback.height + 16 : 0)
                               - 16
                        searchQuery: searchField.text
                        onAppLaunched: launcher.hide()
                        onSearchWeb: launcher.openWebSearch()
                    }

                    // Web search / URL fallback row
                    Rectangle {
                        id: webFallback
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 36
                        radius: Theme.radiusInner
                        visible: searchField.text.length > 0
                        color: webFallbackMouse.containsMouse
                               ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                               : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: launcher.isUrl(searchField.text)
                                  ? "Open " + searchField.text
                                  : "Search DuckDuckGo for '" + searchField.text + "'"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.accentBright
                            elide: Text.ElideRight
                            width: parent.width - 24
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: webFallbackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: launcher.openWebSearch()
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Scale animation
                scale: launcher.showing ? 1.0 : 0.95
                opacity: launcher.showing ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
