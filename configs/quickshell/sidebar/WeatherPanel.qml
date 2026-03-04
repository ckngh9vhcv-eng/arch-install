import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

ColumnLayout {
    id: weatherPanel
    spacing: 12
    visible: ShellGlobals.weatherApiKey.length > 0

    property string currentTemp: "--"
    property string currentIcon: ""
    property string currentDesc: ""
    property string feelsLike: "--"
    property string humidity: "--"
    property string windSpeed: "--"
    property string windDir: ""
    property var forecast: []

    function mapWeatherIcon(code) {
        if (code >= 200 && code < 300) return "\u{e31d}";
        if (code >= 300 && code < 400) return "\u{e319}";
        if (code >= 500 && code < 600) return "\u{e318}";
        if (code >= 600 && code < 700) return "\u{e31a}";
        if (code >= 700 && code < 800) return "\u{e313}";
        if (code === 800) return "\u{e30d}";
        if (code === 801) return "\u{e302}";
        if (code >= 802) return "\u{e312}";
        return "\u{e30d}";
    }

    function windDirection(deg) {
        var dirs = ["N","NE","E","SE","S","SW","W","NW"];
        return dirs[Math.round(deg / 45) % 8];
    }

    function dayName(timestamp) {
        var d = new Date(timestamp * 1000);
        return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d.getDay()];
    }

    // Current weather fetch
    Process {
        id: currentProc
        command: ["curl", "-sf",
            "https://api.openweathermap.org/data/2.5/weather?lat=" + ShellGlobals.locationLat +
            "&lon=" + ShellGlobals.locationLon +
            "&appid=" + ShellGlobals.weatherApiKey +
            "&units=imperial"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var w = JSON.parse(data);
                    weatherPanel.currentTemp = Math.round(w.main.temp) + "\u00B0F";
                    weatherPanel.currentIcon = weatherPanel.mapWeatherIcon(w.weather[0].id);
                    weatherPanel.currentDesc = w.weather[0].description;
                    weatherPanel.feelsLike = Math.round(w.main.feels_like) + "\u00B0F";
                    weatherPanel.humidity = w.main.humidity + "%";
                    weatherPanel.windSpeed = Math.round(w.wind.speed) + " mph";
                    weatherPanel.windDir = weatherPanel.windDirection(w.wind.deg || 0);
                } catch (e) {}
            }
        }
    }

    // Forecast fetch
    Process {
        id: forecastProc
        command: ["curl", "-sf",
            "https://api.openweathermap.org/data/2.5/forecast?lat=" + ShellGlobals.locationLat +
            "&lon=" + ShellGlobals.locationLon +
            "&appid=" + ShellGlobals.weatherApiKey +
            "&units=imperial&cnt=40"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var f = JSON.parse(data);
                    var dailyMap = {};
                    for (var i = 0; i < f.list.length; i++) {
                        var item = f.list[i];
                        var d = new Date(item.dt * 1000);
                        var key = d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate();
                        if (!dailyMap[key]) {
                            dailyMap[key] = {
                                dt: item.dt,
                                high: item.main.temp_max,
                                low: item.main.temp_min,
                                icon: item.weather[0].id
                            };
                        } else {
                            if (item.main.temp_max > dailyMap[key].high) dailyMap[key].high = item.main.temp_max;
                            if (item.main.temp_min < dailyMap[key].low) dailyMap[key].low = item.main.temp_min;
                        }
                    }
                    var days = Object.keys(dailyMap).sort();
                    var result = [];
                    for (var j = 0; j < Math.min(days.length, 5); j++) {
                        var dd = dailyMap[days[j]];
                        result.push({
                            day: weatherPanel.dayName(dd.dt),
                            icon: weatherPanel.mapWeatherIcon(dd.icon),
                            high: Math.round(dd.high),
                            low: Math.round(dd.low)
                        });
                    }
                    weatherPanel.forecast = result;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1800000  // 30 minutes
        running: weatherPanel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentProc.running = true;
            forecastProc.running = true;
        }
    }

    // Current weather display
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
            text: currentIcon
            font.family: Theme.fontFamily
            font.pixelSize: 36
            color: Theme.accent
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: currentTemp
                font.family: Theme.fontFamily
                font.pixelSize: 24
                font.bold: true
                color: Theme.textPrimary
            }

            Text {
                text: ShellGlobals.locationCity.length > 0 ? ShellGlobals.locationCity : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textDim
                visible: text.length > 0
            }

            Text {
                text: currentDesc
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textSecondary
                visible: text.length > 0
            }
        }
    }

    // Detail grid
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 4
        columnSpacing: 16

        Text {
            text: "\u{f2c9} Feels like"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
        }
        Text {
            text: feelsLike
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textPrimary
        }

        Text {
            text: "\u{f043} Humidity"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
        }
        Text {
            text: humidity
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textPrimary
        }

        Text {
            text: "\u{f72e} Wind"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
        }
        Text {
            text: windSpeed + (windDir.length > 0 ? " " + windDir : "")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textPrimary
        }
    }

    // 5-day forecast
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: forecast.length > 0

        Repeater {
            model: forecast.length

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                property var dayData: forecast[index] || {}

                Text {
                    text: dayData.day || ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.bold: index === 0
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: dayData.icon || ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    color: Theme.accent
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: (dayData.high !== undefined ? dayData.high + "\u00B0" : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: (dayData.low !== undefined ? dayData.low + "\u00B0" : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textDim
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
