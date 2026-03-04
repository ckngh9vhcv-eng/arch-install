import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

GridView {
    id: grid

    property string searchQuery: ""
    signal appLaunched()

    cellWidth: 140
    cellHeight: 110
    clip: true
    currentIndex: -1
    highlightFollowsCurrentItem: false
    keyNavigationEnabled: false

    model: {
        var apps = DesktopEntries.applications.values;
        if (searchQuery && searchQuery.length > 0) {
            var q = searchQuery.toLowerCase();
            return apps.filter(function(app) {
                return (app.name && app.name.toLowerCase().indexOf(q) !== -1) ||
                       (app.comment && app.comment.toLowerCase().indexOf(q) !== -1) ||
                       (app.genericName && app.genericName.toLowerCase().indexOf(q) !== -1);
            });
        }
        // Sort by frecency when no search query
        var sorted = apps.slice();
        sorted.sort(function(a, b) {
            var scoreA = AppFrequency.getScore(a.id);
            var scoreB = AppFrequency.getScore(b.id);
            if (scoreA !== scoreB) return scoreB - scoreA;
            return (a.name || "").localeCompare(b.name || "");
        });
        return sorted;
    }

    // Reset selection when search changes
    onModelChanged: currentIndex = -1

    // Context menu for pin/unpin
    property var contextTarget: null
    property bool contextMenuVisible: false
    property real contextMenuX: 0
    property real contextMenuY: 0

    Rectangle {
        id: contextMenu
        visible: grid.contextMenuVisible
        x: grid.contextMenuX
        y: grid.contextMenuY
        width: 140
        height: contextCol.implicitHeight + 12
        radius: 6
        color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.95)
        border.width: 1
        border.color: Theme.accentDim
        z: 100

        Column {
            id: contextCol
            anchors.fill: parent
            anchors.margins: 6

            Rectangle {
                width: parent.width
                height: 28
                radius: 4
                color: pinMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: grid.contextTarget && isFavorite(grid.contextTarget.id) ? "Unpin" : "Pin to favorites"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (grid.contextTarget) toggleFavorite(grid.contextTarget.id);
                        grid.contextMenuVisible = false;
                    }
                }
            }
        }
    }

    // Click outside context menu to close
    MouseArea {
        anchors.fill: parent
        visible: grid.contextMenuVisible
        z: 99
        onClicked: grid.contextMenuVisible = false
    }

    // Favorites support
    property var favorites: []

    function isFavorite(appId) {
        return favorites.indexOf(appId) !== -1;
    }

    function toggleFavorite(appId) {
        var idx = favorites.indexOf(appId);
        if (idx >= 0) {
            favorites.splice(idx, 1);
        } else {
            favorites.push(appId);
        }
        favorites = favorites.slice(); // trigger binding update
        saveFavorites();
    }

    function saveFavorites() {
        favFileView.setText(JSON.stringify(favorites));
    }

    FileView {
        id: favFileView
        path: Quickshell.env("HOME") + "/.local/share/quickshell/favorites.json"
        atomicWrites: true
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    grid.favorites = JSON.parse(content);
                } catch (e) {
                    grid.favorites = [];
                }
            }
        }
    }

    delegate: Item {
        width: grid.cellWidth
        height: grid.cellHeight

        required property var modelData
        required property int index

        Rectangle {
            id: appCard
            anchors.fill: parent
            anchors.margins: 4
            radius: Theme.radiusInner
            color: {
                if (grid.currentIndex === index)
                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3);
                if (cardMouse.containsMouse)
                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25);
                return "transparent";
            }
            border.width: grid.currentIndex === index ? 2 : (cardMouse.containsMouse ? 1 : 0)
            border.color: grid.currentIndex === index ? Theme.accentBright : Theme.accentGlow

            Column {
                anchors.centerIn: parent
                spacing: 6

                // App icon
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: {
                        if (modelData.icon && modelData.icon.length > 0)
                            return "image://icon/" + modelData.icon;
                        return "";
                    }
                    sourceSize.width: 48
                    sourceSize.height: 48
                    width: 48
                    height: 48
                    smooth: true
                    visible: modelData.icon && modelData.icon.length > 0
                }

                // Fallback icon text when no icon
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u{f015}"
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    color: Theme.textDim
                    visible: !modelData.icon || modelData.icon.length === 0
                }

                // App name
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.name || "Unknown"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                    width: appCard.width - 12
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function(event) {
                    if (event.button === Qt.RightButton) {
                        grid.contextTarget = modelData;
                        grid.contextMenuX = parent.x + event.x;
                        grid.contextMenuY = parent.y + event.y;
                        grid.contextMenuVisible = true;
                    } else {
                        AppFrequency.recordLaunch(modelData.id);
                        modelData.execute();
                        grid.appLaunched();
                    }
                }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Keyboard navigation
    function handleKey(event) {
        if (!model || model.length === 0) return false;

        var cols = Math.floor(width / cellWidth);
        if (cols < 1) cols = 1;

        if (event.key === Qt.Key_Right) {
            currentIndex = Math.min((currentIndex < 0 ? 0 : currentIndex + 1), model.length - 1);
            event.accepted = true;
            return true;
        } else if (event.key === Qt.Key_Left) {
            currentIndex = Math.max((currentIndex < 0 ? 0 : currentIndex - 1), 0);
            event.accepted = true;
            return true;
        } else if (event.key === Qt.Key_Down) {
            if (currentIndex < 0) {
                currentIndex = 0;
            } else {
                currentIndex = Math.min(currentIndex + cols, model.length - 1);
            }
            event.accepted = true;
            return true;
        } else if (event.key === Qt.Key_Up) {
            if (currentIndex < 0) {
                currentIndex = 0;
            } else {
                currentIndex = Math.max(currentIndex - cols, 0);
            }
            event.accepted = true;
            return true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentIndex >= 0 && currentIndex < model.length) {
                AppFrequency.recordLaunch(model[currentIndex].id);
                model[currentIndex].execute();
                appLaunched();
            } else {
                launchFirst();
            }
            event.accepted = true;
            return true;
        }
        return false;
    }

    // Launch first result on Enter
    function launchFirst() {
        if (model && model.length > 0) {
            AppFrequency.recordLaunch(model[0].id);
            model[0].execute();
            appLaunched();
        }
    }
}
