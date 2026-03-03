import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

Item {
    id: screenshotTool

    property bool showing: false

    function toggle() {
        if (showing) hide();
        else show();
    }

    function show() {
        showing = true;
    }

    function hide() {
        showing = false;
    }

    // Capture functions: set the pending mode, then defer destruction
    // to the next event loop tick so the calling MouseArea context
    // isn't destroyed mid-handler by the LazyLoader.
    property string pendingCapture: ""
    property int pendingDelay: 0

    function captureRegion() {
        pendingCapture = "region";
        teardownTimer.start();
    }

    function captureFullscreen() {
        pendingCapture = "full";
        teardownTimer.start();
    }

    function captureDelayed(seconds) {
        pendingCapture = "delayed";
        pendingDelay = seconds;
        teardownTimer.start();
    }

    // Step 1: Deferred teardown — destroys the PanelWindow safely
    // (fires on next event loop tick, after the click handler has returned)
    Timer {
        id: teardownTimer
        interval: 1
        repeat: false
        onTriggered: {
            screenshotTool.showing = false;  // LazyLoader destroys PanelWindow
            captureTimer.start();            // schedule capture after surface is gone
        }
    }

    // Step 2: Run the actual capture after the layer surface is unmapped
    Timer {
        id: captureTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (screenshotTool.pendingCapture === "region") {
                regionProc.running = true;
            } else if (screenshotTool.pendingCapture === "full") {
                fullProc.running = true;
            } else if (screenshotTool.pendingCapture === "delayed") {
                delayedTimer.interval = screenshotTool.pendingDelay * 1000;
                delayedTimer.start();
            }
            screenshotTool.pendingCapture = "";
        }
    }

    Timer {
        id: delayedTimer
        repeat: false
        onTriggered: fullProc.running = true
    }

    Process {
        id: regionProc
        command: ["hyprctl", "dispatch", "exec", "sh -c 'FILE=\"/tmp/screenshot-$(date +%s).png\" && grim -g \"$(slurp)\" \"$FILE\" && wl-copy < \"$FILE\" && notify-send \"Screenshot\" \"Region copied to clipboard\" -i \"$FILE\"'"]
    }

    Process {
        id: fullProc
        command: ["hyprctl", "dispatch", "exec", "sh -c 'FILE=\"/tmp/screenshot-$(date +%s).png\" && grim \"$FILE\" && wl-copy < \"$FILE\" && notify-send \"Screenshot\" \"Fullscreen copied to clipboard\" -i \"$FILE\"'"]
    }

    // LazyLoader: active=true creates the PanelWindow, active=false DESTROYS it
    // (guarantees the layer surface is fully unmapped before slurp grabs pointer)
    LazyLoader {
        id: windowLoader
        active: screenshotTool.showing

        PanelWindow {
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            visible: true
            focusable: true
            aboveWindows: true
            color: "transparent"

            FocusScope {
                anchors.fill: parent
                focus: true

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        screenshotTool.hide();
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.3)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: screenshotTool.hide()
                    }

                    // Center content panel
                    Rectangle {
                        anchors.centerIn: parent
                        width: 340
                        height: contentCol.height + 40
                        radius: Theme.radiusPopup
                        color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.95)
                        border.width: 1
                        border.color: Theme.accentDim

                        MouseArea { anchors.fill: parent }

                        Column {
                            id: contentCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 20
                            spacing: 12

                            // Title
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "SCREENSHOT"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontHeader
                                font.bold: true
                                font.letterSpacing: 4
                                color: Theme.textPrimary
                            }

                            // Region select button
                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: Theme.radiusInner
                                color: regionMouse.containsMouse
                                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                       : Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.6)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{f0a32}"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 20
                                        color: Theme.accent
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: "Region Select"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }

                                        Text {
                                            text: "click + drag"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontLabel
                                            color: Theme.textDim
                                        }
                                    }
                                }

                                MouseArea {
                                    id: regionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: screenshotTool.captureRegion()
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Full screen button
                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: Theme.radiusInner
                                color: fullMouse.containsMouse
                                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                       : Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.6)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{f00fd}"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 20
                                        color: Theme.accent
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: "Full Screen"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }

                                        Text {
                                            text: "instant"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontLabel
                                            color: Theme.textDim
                                        }
                                    }
                                }

                                MouseArea {
                                    id: fullMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: screenshotTool.captureFullscreen()
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Delay row
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Delay:"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.textSecondary
                                }

                                Repeater {
                                    model: [3, 5, 10]

                                    Rectangle {
                                        required property int modelData
                                        width: 52
                                        height: 32
                                        radius: Theme.radiusInner
                                        color: delayMouse.containsMouse
                                               ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                               : Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.6)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData + "s"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            color: Theme.textPrimary
                                        }

                                        MouseArea {
                                            id: delayMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: screenshotTool.captureDelayed(modelData)
                                        }

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }
                            }

                            // Escape hint
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Press Escape to cancel"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textDim
                                topPadding: 4
                            }
                        }
                    }
                }
            }
        }
    }
}
