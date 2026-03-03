pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var frequencyData: ({})
    property bool loaded: false

    property var fileView: FileView {
        path: "/home/mike/.local/share/quickshell/app_frequency.json"
        atomicWrites: true
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    root.frequencyData = JSON.parse(content);
                } catch (e) {
                    root.frequencyData = {};
                }
            }
            root.loaded = true;
        }
    }

    function save() {
        fileView.setText(JSON.stringify(frequencyData, null, 2));
    }

    function recordLaunch(appId) {
        if (!appId) return;
        if (!frequencyData[appId]) {
            frequencyData[appId] = { count: 0, lastUsed: 0 };
        }
        frequencyData[appId].count++;
        frequencyData[appId].lastUsed = Date.now();
        frequencyDataChanged();
        save();
    }

    function getScore(appId) {
        if (!appId || !frequencyData[appId]) return 0;
        var entry = frequencyData[appId];
        var now = Date.now();
        var age = now - entry.lastUsed;
        var dayMs = 86400000;
        var multiplier = 1;
        if (age < dayMs) multiplier = 4;
        else if (age < 7 * dayMs) multiplier = 2;
        return entry.count * multiplier;
    }

    function getTopApps(limit) {
        var entries = [];
        for (var appId in frequencyData) {
            entries.push({ id: appId, score: getScore(appId) });
        }
        entries.sort(function(a, b) { return b.score - a.score; });
        return entries.slice(0, limit || 8);
    }
}
