import QtQuick
import Quickshell.Io
import ".."

Text {
    id: weatherInd

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    color: Theme.textSecondary
    visible: ShellGlobals.locationLat !== 0 && ShellGlobals.weatherApiKey.length > 0

    property string tempStr: ""
    property string weatherIcon: ""
    property string description: ""
    property string feelsLike: ""
    property string humidity: ""
    property string tooltipText: ""

    text: tempStr.length > 0 ? tempStr + " " + weatherIcon : ""

    function mapWeatherIcon(code) {
        if (code >= 200 && code < 300) return "\u{e31d}"; // thunderstorm
        if (code >= 300 && code < 400) return "\u{e319}"; // drizzle
        if (code >= 500 && code < 600) return "\u{e318}"; // rain
        if (code >= 600 && code < 700) return "\u{e31a}"; // snow
        if (code >= 700 && code < 800) return "\u{e313}"; // fog/mist
        if (code === 800) return "\u{e30d}";               // clear
        if (code === 801) return "\u{e302}";               // few clouds
        if (code >= 802) return "\u{e312}";                // clouds
        return "\u{e30d}";
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: fetchProc.running = true
    }

    Process {
        id: fetchProc
        command: ["curl", "-sf",
            "https://api.openweathermap.org/data/2.5/weather?lat=" + ShellGlobals.locationLat +
            "&lon=" + ShellGlobals.locationLon +
            "&appid=" + ShellGlobals.weatherApiKey +
            "&units=imperial"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var w = JSON.parse(data);
                    weatherInd.tempStr = Math.round(w.main.temp) + "\u00B0F";
                    weatherInd.weatherIcon = weatherInd.mapWeatherIcon(w.weather[0].id);
                    weatherInd.description = w.weather[0].description;
                    weatherInd.feelsLike = Math.round(w.main.feels_like) + "\u00B0F";
                    weatherInd.humidity = w.main.humidity + "%";
                    weatherInd.tooltipText = w.weather[0].description +
                        " | Feels like " + weatherInd.feelsLike +
                        " | Humidity " + weatherInd.humidity;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1800000  // 30 minutes
        running: weatherInd.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchProc.running = true
    }
}
