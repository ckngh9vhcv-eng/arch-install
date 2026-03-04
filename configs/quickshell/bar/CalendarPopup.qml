import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: popup

    property bool showing: false
    property real targetX: 0
    property int _gp: 3 * Theme.glowSpread

    anchors.top: true
    anchors.left: true
    implicitWidth: 280 + _gp * 2
    implicitHeight: contentCol.implicitHeight + 32 + _gp * 2
    visible: showing || calHideAnim.running
    color: "transparent"
    focusable: true
    aboveWindows: true

    margins.top: 44 - _gp
    margins.left: Math.max(4, targetX - 140) - _gp

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()
    property int todayDate: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    property int selectedDay: 0
    property string selectedDateKey: ""

    // Event data — empty map for now, future CalDAV will populate this
    // Format: { "2026-03-15": [{time: "10:00", summary: "Meeting"}, ...], ... }
    property var eventsByDate: ({})

    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay();
    }

    function prevMonth() {
        selectedDay = 0;
        selectedDateKey = "";
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear--;
        } else {
            displayMonth--;
        }
    }

    function nextMonth() {
        selectedDay = 0;
        selectedDateKey = "";
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear++;
        } else {
            displayMonth++;
        }
    }

    function monthName(m) {
        var names = ["January","February","March","April","May","June",
                     "July","August","September","October","November","December"];
        return names[m];
    }

    function pad2(n) { return n < 10 ? "0" + n : "" + n; }

    // Build 42-cell grid model (6 rows x 7 cols)
    property var calendarCells: {
        var cells = [];
        var totalDays = daysInMonth(displayMonth, displayYear);
        var startDay = firstDayOfMonth(displayMonth, displayYear);

        // Previous month trailing days
        var prevDays = displayMonth === 0 ? daysInMonth(11, displayYear - 1) : daysInMonth(displayMonth - 1, displayYear);
        var prevMonth = displayMonth === 0 ? 11 : displayMonth - 1;
        var prevYear = displayMonth === 0 ? displayYear - 1 : displayYear;
        for (var i = startDay - 1; i >= 0; i--) {
            var pd = prevDays - i;
            cells.push({ day: pd, current: false, today: false,
                         dateKey: prevYear + "-" + pad2(prevMonth + 1) + "-" + pad2(pd) });
        }

        // Current month days
        for (var d = 1; d <= totalDays; d++) {
            var isToday = (d === todayDate && displayMonth === todayMonth && displayYear === todayYear);
            cells.push({ day: d, current: true, today: isToday,
                         dateKey: displayYear + "-" + pad2(displayMonth + 1) + "-" + pad2(d) });
        }

        // Next month leading days
        var nextMonth = displayMonth === 11 ? 0 : displayMonth + 1;
        var nextYear = displayMonth === 11 ? displayYear + 1 : displayYear;
        var remaining = 42 - cells.length;
        for (var n = 1; n <= remaining; n++) {
            cells.push({ day: n, current: false, today: false,
                         dateKey: nextYear + "-" + pad2(nextMonth + 1) + "-" + pad2(n) });
        }

        return cells;
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                popup.showing = false;
                event.accepted = true;
            }
        }

        // Glow layers
        Rectangle {
            x: _gp - Theme.glowSpread * 3
            y: _gp - Theme.glowSpread * 3
            width: 280 + Theme.glowSpread * 6
            height: parent.height - _gp * 2 + Theme.glowSpread * 6
            radius: Theme.radiusPopup + Theme.glowSpread * 3
            color: "transparent"
            border.width: Theme.glowSpread * 3
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity * 0.34 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            x: _gp - Theme.glowSpread * 2
            y: _gp - Theme.glowSpread * 2
            width: 280 + Theme.glowSpread * 4
            height: parent.height - _gp * 2 + Theme.glowSpread * 4
            radius: Theme.radiusPopup + Theme.glowSpread * 2
            color: "transparent"
            border.width: Theme.glowSpread * 2
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity * 0.5 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            x: _gp - Theme.glowSpread
            y: _gp - Theme.glowSpread
            width: 280 + Theme.glowSpread * 2
            height: parent.height - _gp * 2 + Theme.glowSpread * 2
            radius: Theme.radiusPopup + Theme.glowSpread
            color: "transparent"
            border.width: Theme.glowSpread
            border.color: Theme.accentGlow
            opacity: popup.showing ? Theme.glowBaseOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // Content wrapper at original dimensions
        Item {
            x: _gp
            y: _gp
            width: 280
            height: parent.height - _gp * 2

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusPopup
                color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.95)
                border.width: 1
                border.color: Theme.accentDim

                opacity: popup.showing ? 1.0 : 0.0
                scale: popup.showing ? 1.0 : 0.95
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation { id: calHideAnim; duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Month/year header with nav
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "\u{f053}"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            color: prevMonthArea.containsMouse ? Theme.textPrimary : Theme.textSecondary

                            MouseArea {
                                id: prevMonthArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.prevMonth()
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: monthName(displayMonth) + " " + displayYear
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\u{f054}"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            color: nextMonthArea.containsMouse ? Theme.textPrimary : Theme.textSecondary

                            MouseArea {
                                id: nextMonthArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.nextMonth()
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Day-of-week header
                    Grid {
                        columns: 7
                        Layout.fillWidth: true
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: ["S","M","T","W","T","F","S"]

                            Text {
                                width: (contentCol.width - 32) / 7
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                font.bold: true
                                color: Theme.textDim
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Calendar grid
                    Grid {
                        columns: 7
                        Layout.fillWidth: true
                        columnSpacing: 0
                        rowSpacing: 2

                        Repeater {
                            model: calendarCells

                            Item {
                                width: (contentCol.width - 32) / 7
                                height: 34

                                property bool isSelected: modelData.current && modelData.day === popup.selectedDay
                                                         && popup.selectedDay > 0
                                property bool hasEvents: popup.eventsByDate[modelData.dateKey] !== undefined
                                                        && popup.eventsByDate[modelData.dateKey].length > 0

                                MouseArea {
                                    id: dayCellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.current ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (modelData.current) {
                                            popup.selectedDay = modelData.day;
                                            popup.selectedDateKey = modelData.dateKey;
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 2
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: modelData.today ? Theme.accent :
                                           (dayCellMouse.containsMouse && modelData.current
                                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                                            : "transparent")
                                    border.width: isSelected && !modelData.today ? 2 : 0
                                    border.color: Theme.accent

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 2 + (26 - height) / 2
                                    text: modelData.day
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontLabel
                                    color: modelData.today ? Theme.void_ :
                                           modelData.current ? Theme.textPrimary : Theme.textDim
                                    font.bold: modelData.today
                                }

                                // Event dot indicator
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 30
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: Theme.accent
                                    visible: hasEvents
                                }
                            }
                        }
                    }
                    // Event list for selected day
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: popup.selectedDay > 0
                                 && popup.eventsByDate[popup.selectedDateKey] !== undefined
                                 && popup.eventsByDate[popup.selectedDateKey].length > 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentDim
                            opacity: 0.5
                        }

                        Text {
                            text: "Events for " + monthName(displayMonth) + " " + popup.selectedDay
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.bold: true
                            color: Theme.textSecondary
                        }

                        Repeater {
                            model: popup.eventsByDate[popup.selectedDateKey] || []

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData.time || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.accent
                                    visible: text.length > 0
                                }

                                Text {
                                    text: modelData.summary || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            var now = new Date();
            todayDate = now.getDate();
            todayMonth = now.getMonth();
            todayYear = now.getFullYear();
            displayMonth = todayMonth;
            displayYear = todayYear;
            selectedDay = 0;
            selectedDateKey = "";
        }
    }

    function toggle() { showing = !showing; }
    function show() { showing = true; }
    function hide() { showing = false; }
}
