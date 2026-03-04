import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

GridView {
    id: grid

    property string searchQuery: ""
    property var _matchData: ({})
    signal appLaunched()
    signal searchWeb()

    // Fuzzy match: returns { score, indices } or null
    function fuzzyScore(query, target) {
        if (!query || !target) return null;
        var q = query.toLowerCase();
        var t = target.toLowerCase();
        var qi = 0, indices = [], lastMatch = -1, score = 0;
        var consecutive = 0;

        for (var ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                indices.push(ti);
                // Consecutive bonus
                if (lastMatch === ti - 1) {
                    consecutive++;
                    score += 5 * consecutive;
                } else {
                    consecutive = 0;
                    // Gap penalty
                    if (lastMatch >= 0) score -= (ti - lastMatch - 1);
                }
                // Start of string bonus
                if (ti === 0) score += 10;
                // Word boundary bonus
                if (ti > 0 && " -._".indexOf(t[ti - 1]) !== -1) score += 8;
                lastMatch = ti;
                qi++;
            }
        }
        if (qi < q.length) return null; // not all query chars matched

        // Exact substring bonus
        if (t.indexOf(q) !== -1) score += 50;

        return { score: score, indices: indices };
    }

    // Wrap matched characters in highlight tags
    function highlightName(name, appId) {
        if (!name) return "Unknown";
        if (!searchQuery || searchQuery.length === 0) return name;
        var data = _matchData[appId];
        if (!data || data.length === 0) return name;

        var result = "";
        var inHighlight = false;
        for (var i = 0; i < name.length; i++) {
            var ch = name[i].replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            if (data.indexOf(i) !== -1) {
                if (!inHighlight) {
                    result += "<font color='" + Theme.accentBright + "'>";
                    inHighlight = true;
                }
                result += ch;
            } else {
                if (inHighlight) {
                    result += "</font>";
                    inHighlight = false;
                }
                result += ch;
            }
        }
        if (inHighlight) result += "</font>";
        return result;
    }

    cellWidth: 140
    cellHeight: 110
    clip: true
    currentIndex: -1
    highlightFollowsCurrentItem: false
    keyNavigationEnabled: false

    model: {
        var apps = DesktopEntries.applications.values;
        if (searchQuery && searchQuery.length > 0) {
            var matchData = {};
            var scored = [];
            for (var i = 0; i < apps.length; i++) {
                var app = apps[i];
                var best = null;
                var bestIndices = [];
                // Check name (+10 field bonus), genericName, comment
                var fields = [
                    { text: app.name, bonus: 10 },
                    { text: app.genericName, bonus: 0 },
                    { text: app.comment, bonus: 0 }
                ];
                for (var f = 0; f < fields.length; f++) {
                    var result = fuzzyScore(searchQuery, fields[f].text);
                    if (result) {
                        var total = result.score + fields[f].bonus;
                        if (!best || total > best) {
                            best = total;
                            // Only store indices for name field matches
                            bestIndices = (f === 0) ? result.indices : [];
                        }
                    }
                }
                if (best !== null) {
                    scored.push({ app: app, score: best });
                    if (bestIndices.length > 0) matchData[app.id] = bestIndices;
                }
            }
            scored.sort(function(a, b) {
                if (a.score !== b.score) return b.score - a.score;
                var fa = AppFrequency.getScore(a.app.id);
                var fb = AppFrequency.getScore(b.app.id);
                if (fa !== fb) return fb - fa;
                return (a.app.name || "").localeCompare(b.app.name || "");
            });
            _matchData = matchData;
            var result = [];
            for (var j = 0; j < scored.length; j++) result.push(scored[j].app);
            return result;
        }
        _matchData = {};
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
                    text: grid.contextTarget && isFavorite(grid.contextTarget.id) ? "Unpin from Dock" : "Pin to Dock"
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

    // Favorites — delegated to ShellGlobals singleton
    property var favorites: ShellGlobals.favorites

    function isFavorite(appId) {
        return ShellGlobals.isFavorite(appId);
    }

    function toggleFavorite(appId) {
        ShellGlobals.toggleFavorite(appId);
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
                    text: grid.highlightName(modelData.name, modelData.id)
                    textFormat: grid.searchQuery.length > 0 ? Text.StyledText : Text.PlainText
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
                        var pos = cardMouse.mapToItem(grid, event.x, event.y);
                        grid.contextMenuX = pos.x;
                        grid.contextMenuY = pos.y;
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
        if (!model || model.length === 0) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                searchWeb();
                event.accepted = true;
                return true;
            }
            return false;
        }

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
