import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import ".."

Item {
    id: cardRoot

    required property int wsId
    required property var windows
    required property real screenWidth
    required property real screenHeight
    required property bool isSelected
    required property string wallpaperSource
    property string screenshotSource: ""
    property int cardIndex: 0

    property bool isActive: Hyprland.focusedWorkspace?.id === wsId
    property bool isOccupied: windows.length > 0
    property bool isHovered: bgMouse.containsMouse
    property int focusedAddress: {
        // Find the focused window in this workspace
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].focusHistoryID === 0) return i;
        }
        return -1;
    }

    signal windowClicked(string address)
    signal backgroundClicked()

    // Staggered entrance
    property bool entranceReady: false
    property real entranceScale: entranceReady ? 1.0 : 0.92
    property real entranceOpacity: entranceReady ? 1.0 : 0.0

    Behavior on entranceScale {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    Behavior on entranceOpacity {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }

    scale: entranceScale
    opacity: entranceOpacity

    // Active/hover brightness
    property real cardBrightness: isActive ? 1.0 : (isHovered ? 0.9 : 0.75)
    Behavior on cardBrightness {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Drop shadow for the card
    DropShadow {
        anchors.fill: card
        source: card
        horizontalOffset: 0
        verticalOffset: cardRoot.isActive ? 4 : 2
        radius: cardRoot.isActive ? 20 : 10
        samples: 17
        color: Qt.rgba(0, 0, 0, cardRoot.isActive ? 0.5 : 0.3)
    }

    // Active glow
    Glow {
        visible: cardRoot.isActive
        anchors.fill: card
        source: card
        radius: 12
        samples: 17
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
    }

    // Main card
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        clip: true
        color: Theme.surface0

        // Wallpaper background (hidden when blurred version is shown)
        Image {
            id: wpImage
            anchors.fill: parent
            source: cardRoot.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: cardRoot.screenshotSource !== ""  // Only show sharp for active ws
        }

        // Blurred wallpaper for icon-mode cards
        Image {
            id: wpImageBlurSource
            anchors.fill: parent
            source: cardRoot.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: false  // Used as source for blur
        }

        FastBlur {
            anchors.fill: parent
            source: wpImageBlurSource
            radius: 32
            visible: cardRoot.screenshotSource === ""
        }

        // Dim overlay with brightness control
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 1.0 - cardRoot.cardBrightness)
            z: 1
        }

        // Top edge accent line for active workspace
        Rectangle {
            visible: cardRoot.isActive
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            z: 10
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.15; color: Theme.accent }
                GradientStop { position: 0.85; color: Theme.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Bottom edge subtle line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.1)
            z: 10
        }

        // Workspace number — bottom-right, subtle
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8
            width: wsNum.implicitWidth + 12
            height: wsNum.implicitHeight + 6
            radius: height / 2
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.5)
            border.width: 1
            border.color: cardRoot.isActive
                          ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                          : Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.15)
            z: 10

            Text {
                id: wsNum
                anchors.centerIn: parent
                text: cardRoot.wsId
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel - 1
                color: cardRoot.isActive ? Theme.accentBright : Theme.textDim
            }
        }

        // Window count badge — next to ws number
        Rectangle {
            visible: cardRoot.isOccupied
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8
            anchors.rightMargin: wsNum.implicitWidth + 28
            width: winCount.implicitWidth + 10
            height: winCount.implicitHeight + 4
            radius: height / 2
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.4)
            z: 10

            Text {
                id: winCount
                anchors.centerIn: parent
                text: cardRoot.windows.length + (cardRoot.windows.length === 1 ? " window" : " windows")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel - 2
                color: Theme.textDim
            }
        }

        // Empty workspace indicator
        Column {
            visible: !cardRoot.isOccupied
            anchors.centerIn: parent
            spacing: 6
            z: 5

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 2
                radius: 1
                color: Theme.textDim
                opacity: 0.25
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "empty"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel - 2
                font.letterSpacing: 2
                color: Theme.textDim
                opacity: 0.25
            }
        }

        // === Active workspace: screenshot-based window tiles ===
        Item {
            id: windowContainer
            visible: cardRoot.screenshotSource !== "" && cardRoot.isOccupied
            anchors.fill: parent
            clip: true
            z: 5

            Repeater {
                model: windowContainer.visible ? cardRoot.windows : []

                WindowTile {
                    required property var modelData
                    required property int index
                    windowData: modelData
                    cardWidth: windowContainer.width
                    cardHeight: windowContainer.height
                    screenWidth: cardRoot.screenWidth
                    screenHeight: cardRoot.screenHeight
                    screenshotSource: cardRoot.screenshotSource
                    isFocused: modelData.focusHistoryID === 0

                    onClicked: cardRoot.windowClicked(modelData.address)
                }
            }
        }

        // === Non-active workspaces: app icon grid ===
        Item {
            id: iconContainer
            visible: cardRoot.screenshotSource === "" && cardRoot.isOccupied
            anchors.fill: parent
            z: 5

            // Scale icons to card height
            property real iconSize: Math.min(Math.max(card.height * 0.45, 48), 96)

            Row {
                anchors.centerIn: parent
                spacing: iconContainer.iconSize * 0.4

                Repeater {
                    model: iconContainer.visible ? cardRoot.windows : []

                    Item {
                        id: iconDelegate
                        required property var modelData

                        property real sz: iconContainer.iconSize
                        width: sz * 1.4
                        height: sz + 24

                        property string winClass: (modelData.initialClass || modelData["class"] || "").toLowerCase()
                        property var matchedApp: {
                            var cls = iconDelegate.winClass;
                            if (!cls) return null;
                            var apps = DesktopEntries.applications.values;
                            for (var i = 0; i < apps.length; i++) {
                                var aid = apps[i].id.toLowerCase().replace(".desktop", "");
                                if (aid === cls) return apps[i];
                            }
                            for (var i = 0; i < apps.length; i++) {
                                var aid = apps[i].id.toLowerCase().replace(".desktop", "");
                                if (aid.indexOf(cls) !== -1 || cls.indexOf(aid) !== -1) return apps[i];
                            }
                            return null;
                        }
                        property string appName: matchedApp ? matchedApp.name : winClass
                        // Resolve icon: matched app icon, or fallback to class name
                        property string iconSource: {
                            if (matchedApp && matchedApp.icon)
                                return "image://icon/" + matchedApp.icon;
                            // Fallback: try class name directly as icon
                            if (winClass)
                                return "image://icon/" + winClass;
                            return "";
                        }

                        property bool iconHovered: iconMouse.containsMouse

                        // Icon background pill
                        Rectangle {
                            id: iconBg
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            width: iconDelegate.sz
                            height: iconDelegate.sz
                            radius: iconDelegate.sz * 0.28
                            color: iconDelegate.iconHovered
                                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                   : Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.5)
                            border.width: iconDelegate.iconHovered ? 1.5 : 0
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)

                            Image {
                                anchors.centerIn: parent
                                source: iconDelegate.iconSource
                                sourceSize.width: iconBg.width * 0.65
                                sourceSize.height: sourceSize.width
                                width: sourceSize.width
                                height: sourceSize.height
                                smooth: true
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: iconDelegate.iconHovered ? 1.08 : 1.0
                            transformOrigin: Item.Center
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        // App name
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: iconBg.bottom
                            anchors.topMargin: 6
                            width: parent.width + 16
                            text: iconDelegate.appName
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: iconDelegate.iconHovered ? Theme.textPrimary : Theme.textSecondary
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: iconMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardRoot.windowClicked(modelData.address)
                        }
                    }
                }
            }
        }

        // Border
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            z: 11
            border.width: cardRoot.isActive ? 1.5 : (cardRoot.isSelected ? 1.5 : cardRoot.isHovered ? 1 : 0.5)
            border.color: cardRoot.isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                        : cardRoot.isSelected ? Qt.rgba(Theme.accentBright.r, Theme.accentBright.g, Theme.accentBright.b, 0.5)
                        : cardRoot.isHovered ? Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.25)
                        : Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.08)
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on border.width { NumberAnimation { duration: 200 } }
        }

        // Background click
        MouseArea {
            id: bgMouse
            anchors.fill: parent
            z: 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cardRoot.backgroundClicked()
        }
    }
}
