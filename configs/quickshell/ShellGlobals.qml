pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool doNotDisturb: false
    property bool gameMode: false
    property bool recording: false
    property bool dockPinned: false

    onDoNotDisturbChanged: saveState()
    onDockPinnedChanged: saveState()
    property var favorites: []

    property var favoritesFile: FileView {
        path: root.homeDir + "/.local/share/quickshell/favorites.json"
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try { root.favorites = JSON.parse(content); }
                catch (e) { root.favorites = []; }
            }
        }
    }

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
        favorites = favorites.slice();
        favoritesFile.setText(JSON.stringify(favorites));
    }

    // Notification history (capped at 50)
    property ListModel notificationHistory: ListModel {}

    // Home directory for config paths
    readonly property string homeDir: Quickshell.env("HOME")

    // Location (shared by weather + night light sunset mode)
    property real locationLat: 0.0
    property real locationLon: 0.0
    property string locationCity: ""

    // Weather
    property string weatherApiKey: ""
    property bool weatherAutoDetect: false

    // Night light schedule
    property string nightLightMode: "manual"  // "manual" | "sunset" | "schedule"
    property bool nightLightActive: false
    property int nightLightTemp: 3500
    property string nightLightOnTime: "20:00"
    property string nightLightOffTime: "06:00"

    // Weather config FileView
    property var weatherConfigFile: FileView {
        path: root.homeDir + "/.local/share/quickshell/weather.json"
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    var cfg = JSON.parse(content);
                    if (cfg.lat !== undefined) root.locationLat = cfg.lat;
                    if (cfg.lon !== undefined) root.locationLon = cfg.lon;
                    if (cfg.city !== undefined) root.locationCity = cfg.city;
                    if (cfg.apiKey !== undefined) root.weatherApiKey = cfg.apiKey;
                    if (cfg.autoDetect !== undefined) root.weatherAutoDetect = cfg.autoDetect;
                    if (root.weatherAutoDetect && root.locationLat === 0.0 && root.locationLon === 0.0) {
                        geoDetectProc.running = true;
                    }
                } catch (e) {}
            }
        }
    }

    // Night light config FileView
    property var nightLightConfigFile: FileView {
        path: root.homeDir + "/.local/share/quickshell/nightlight.json"
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    var cfg = JSON.parse(content);
                    if (cfg.mode !== undefined) root.nightLightMode = cfg.mode;
                    if (cfg.temp !== undefined) root.nightLightTemp = cfg.temp;
                    if (cfg.onTime !== undefined) root.nightLightOnTime = cfg.onTime;
                    if (cfg.offTime !== undefined) root.nightLightOffTime = cfg.offTime;
                } catch (e) {}
            }
        }
    }

    // Geo-detect process (ip-api.com)
    property var geoDetectProc: Process {
        command: ["curl", "-sf", "http://ip-api.com/json/?fields=lat,lon,city"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var geo = JSON.parse(data);
                    if (geo.lat !== undefined) root.locationLat = geo.lat;
                    if (geo.lon !== undefined) root.locationLon = geo.lon;
                    if (geo.city !== undefined) root.locationCity = geo.city;
                    root.saveWeatherConfig();
                } catch (e) {}
            }
        }
    }

    // Save weather config
    function saveWeatherConfig() {
        var cfg = JSON.stringify({
            lat: locationLat,
            lon: locationLon,
            city: locationCity,
            apiKey: weatherApiKey,
            autoDetect: weatherAutoDetect
        }, null, 2);
        weatherConfigFile.setText(cfg);
    }

    // Save night light config
    function saveNightLight() {
        var cfg = JSON.stringify({
            mode: nightLightMode,
            temp: nightLightTemp,
            onTime: nightLightOnTime,
            offTime: nightLightOffTime
        }, null, 2);
        nightLightConfigFile.setText(cfg);
    }

    // Pure JS sunrise/sunset calculation
    // Based on NOAA solar position algorithm
    function getSunTimes(lat, lon) {
        var now = new Date();
        var start = new Date(now.getFullYear(), 0, 0);
        var diff = now - start;
        var oneDay = 1000 * 60 * 60 * 24;
        var dayOfYear = Math.floor(diff / oneDay);

        var zenith = 90.833;
        var D2R = Math.PI / 180;
        var R2D = 180 / Math.PI;

        // Longitude hour
        var lnHour = lon / 15;

        // Sunrise
        var tRise = dayOfYear + ((6 - lnHour) / 24);
        var MRise = (0.9856 * tRise) - 3.289;
        var LRise = MRise + (1.916 * Math.sin(MRise * D2R)) + (0.020 * Math.sin(2 * MRise * D2R)) + 282.634;
        LRise = ((LRise % 360) + 360) % 360;
        var RARise = R2D * Math.atan(0.91764 * Math.tan(LRise * D2R));
        RARise = ((RARise % 360) + 360) % 360;
        var LquadRise = Math.floor(LRise / 90) * 90;
        var RAquadRise = Math.floor(RARise / 90) * 90;
        RARise = RARise + (LquadRise - RAquadRise);
        RARise = RARise / 15;
        var sinDecRise = 0.39782 * Math.sin(LRise * D2R);
        var cosDecRise = Math.cos(Math.asin(sinDecRise));
        var cosHRise = (Math.cos(zenith * D2R) - (sinDecRise * Math.sin(lat * D2R))) / (cosDecRise * Math.cos(lat * D2R));
        var HRise = 360 - R2D * Math.acos(cosHRise);
        HRise = HRise / 15;
        var TRise = HRise + RARise - (0.06571 * tRise) - 6.622;
        var UTRise = ((TRise - lnHour) % 24 + 24) % 24;

        // Sunset
        var tSet = dayOfYear + ((18 - lnHour) / 24);
        var MSet = (0.9856 * tSet) - 3.289;
        var LSet = MSet + (1.916 * Math.sin(MSet * D2R)) + (0.020 * Math.sin(2 * MSet * D2R)) + 282.634;
        LSet = ((LSet % 360) + 360) % 360;
        var RASet = R2D * Math.atan(0.91764 * Math.tan(LSet * D2R));
        RASet = ((RASet % 360) + 360) % 360;
        var LquadSet = Math.floor(LSet / 90) * 90;
        var RAquadSet = Math.floor(RASet / 90) * 90;
        RASet = RASet + (LquadSet - RAquadSet);
        RASet = RASet / 15;
        var sinDecSet = 0.39782 * Math.sin(LSet * D2R);
        var cosDecSet = Math.cos(Math.asin(sinDecSet));
        var cosHSet = (Math.cos(zenith * D2R) - (sinDecSet * Math.sin(lat * D2R))) / (cosDecSet * Math.cos(lat * D2R));
        var HSet = R2D * Math.acos(cosHSet);
        HSet = HSet / 15;
        var TSet = HSet + RASet - (0.06571 * tSet) - 6.622;
        var UTSet = ((TSet - lnHour) % 24 + 24) % 24;

        // Convert to local timezone
        var tzOffset = -now.getTimezoneOffset() / 60;
        var sunriseHour = (UTRise + tzOffset) % 24;
        var sunsetHour = (UTSet + tzOffset) % 24;

        function pad(n) { return n < 10 ? "0" + n : "" + n; }

        return {
            sunrise: pad(Math.floor(sunriseHour)) + ":" + pad(Math.floor((sunriseHour % 1) * 60)),
            sunset: pad(Math.floor(sunsetHour)) + ":" + pad(Math.floor((sunsetHour % 1) * 60))
        };
    }

    function addNotificationToHistory(appName, summary, body, image) {
        notificationHistory.insert(0, {
            appName: appName || "Unknown",
            summary: summary || "",
            body: body || "",
            image: image ? image.toString() : "",
            timestamp: Date.now()
        });
        // Cap at 50 entries
        while (notificationHistory.count > 50) {
            notificationHistory.remove(notificationHistory.count - 1);
        }
    }

    function clearNotificationHistory() {
        notificationHistory.clear();
    }

    // === Shared Game Mode ===
    property var gameModeOnProc: Process {
        command: ["sh", "-c", "hyprctl keyword animations:enabled false && hyprctl keyword decoration:blur:enabled false && hyprctl keyword decoration:shadow:enabled false && hyprctl keyword decoration:dim_inactive false && hyprctl keyword decoration:rounding 0 && hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0"]
    }
    property var gameModeOffProc: Process {
        command: ["sh", "-c", "hyprctl keyword animations:enabled true && hyprctl keyword decoration:blur:enabled true && hyprctl keyword decoration:shadow:enabled true && hyprctl keyword decoration:dim_inactive true && hyprctl keyword decoration:rounding 10 && hyprctl keyword general:gaps_in 5 && hyprctl keyword general:gaps_out 10"]
    }

    function toggleGameMode() {
        gameMode = !gameMode;
        if (gameMode) {
            gameModeOnProc.running = true;
        } else {
            gameModeOffProc.running = true;
        }
        saveState();
    }

    // === Shared Recording ===
    property var recordStartProc: Process {
        command: ["sh", "-c", "mkdir -p ~/Videos/recordings && gpu-screen-recorder -w screen -f 60 -a default_output -o ~/Videos/recordings/recording_$(date +%Y%m%d_%H%M%S).mp4"]
    }
    property var recordStopProc: Process {
        command: ["pkill", "-f", "-SIGINT", "gpu-screen-recorder"]
    }

    function toggleRecording() {
        recording = !recording;
        if (recording) {
            recordStartProc.running = true;
        } else {
            recordStopProc.running = true;
        }
    }

    function stopRecording() {
        recording = false;
        recordStopProc.running = true;
    }

    // === State Persistence ===
    property var stateFile: FileView {
        path: root.homeDir + "/.local/share/quickshell/state.json"
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    var s = JSON.parse(content);
                    if (s.doNotDisturb !== undefined) root.doNotDisturb = s.doNotDisturb;
                    if (s.dockPinned !== undefined) root.dockPinned = s.dockPinned;
                    if (s.gameMode !== undefined) root.gameMode = s.gameMode;
                } catch (e) {}
            }
        }
    }

    function saveState() {
        var s = JSON.stringify({
            doNotDisturb: doNotDisturb,
            dockPinned: dockPinned,
            gameMode: gameMode
        }, null, 2);
        stateFile.setText(s);
    }
}
