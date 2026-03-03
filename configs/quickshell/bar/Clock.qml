import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: clockRoot
    spacing: 0

    signal clicked()

    // Tooltip support
    property string tooltipText: {
        var now = new Date();
        var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
        var months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
        return days[now.getDay()] + ", " + months[now.getMonth()] + " " + now.getDate() + ", " + now.getFullYear();
    }

    Text {
        id: clockText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontClock
        font.bold: true
        color: Theme.textPrimary

        // Update every second
        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date();
                var hours = now.getHours();
                var ampm = hours >= 12 ? "PM" : "AM";
                hours = hours % 12;
                if (hours === 0) hours = 12;
                var mins = now.getMinutes().toString().padStart(2, '0');
                clockText.text = hours + ":" + mins + " " + ampm;
            }
        }

        scale: clockMouse.pressed ? 0.95 : clockMouse.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: clockRoot.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
}
