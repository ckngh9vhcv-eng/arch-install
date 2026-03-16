import QtQuick
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: tile

    required property var windowData
    required property real cardWidth
    required property real cardHeight
    required property real screenWidth
    required property real screenHeight
    property string screenshotSource: ""
    property bool isFocused: false

    signal clicked()

    x: (windowData.at[0] / screenWidth) * cardWidth
    y: (windowData.at[1] / screenHeight) * cardHeight
    width: Math.max(48, (windowData.size[0] / screenWidth) * cardWidth)
    height: Math.max(36, (windowData.size[1] / screenHeight) * cardHeight)

    property var allApps: DesktopEntries.applications.values
    property string windowClass: (windowData.initialClass || windowData["class"] || "").toLowerCase()
    property var matchedApp: {
        var cls = windowClass;
        if (!cls) return null;
        for (var i = 0; i < allApps.length; i++) {
            var id = allApps[i].id.toLowerCase().replace(".desktop", "");
            if (id === cls) return allApps[i];
        }
        for (var i = 0; i < allApps.length; i++) {
            var id = allApps[i].id.toLowerCase().replace(".desktop", "");
            if (id.indexOf(cls) !== -1 || cls.indexOf(id) !== -1) return allApps[i];
        }
        return null;
    }

    property bool hasPreview: screenshotSource !== ""
    property bool hovered: tileMouse.containsMouse

    z: hovered ? 10 : 1

    // Hover lift
    transform: Translate { y: tile.hovered ? -2 : 0; Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }

    // Real drop shadow via GraphicalEffects
    DropShadow {
        anchors.fill: frame
        source: frame
        horizontalOffset: 2
        verticalOffset: tile.hovered ? 6 : 3
        radius: tile.hovered ? 16 : 8
        samples: 17
        color: Qt.rgba(0, 0, 0, tile.hovered ? 0.6 : 0.45)
        Behavior on verticalOffset { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // Hover glow
    Glow {
        visible: tile.hovered
        anchors.fill: frame
        source: frame
        radius: 8
        samples: 17
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
        opacity: tile.hovered ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Window frame
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 6
        clip: true
        color: Theme.surface0
        visible: true

        // Screenshot preview
        Image {
            visible: tile.hasPreview
            anchors.fill: parent
            source: tile.screenshotSource
            sourceClipRect: Qt.rect(
                tile.windowData.at[0],
                tile.windowData.at[1],
                tile.windowData.size[0],
                tile.windowData.size[1]
            )
            fillMode: Image.Stretch
            smooth: true
            cache: false
        }

        // Fallback: titlebar
        Rectangle {
            id: titleBar
            visible: !tile.hasPreview
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(16, parent.height * 0.2)
            color: Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.95)

            // Top rounded, bottom square
            radius: frame.radius
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // Window control dots
                Row {
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tile.width >= 60

                    Repeater {
                        model: [Theme.danger, Theme.warning, Theme.info]
                        Rectangle {
                            required property var modelData
                            width: Math.min(6, titleBar.height * 0.4)
                            height: width
                            radius: width / 2
                            color: modelData
                            opacity: 0.6
                        }
                    }
                }

                Image {
                    visible: tile.width >= 44
                    source: tile.matchedApp && tile.matchedApp.icon
                            ? "image://icon/" + tile.matchedApp.icon : ""
                    sourceSize.width: Math.min(10, titleBar.height - 4)
                    sourceSize.height: sourceSize.width
                    width: sourceSize.width
                    height: sourceSize.height
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: tile.width >= 80
                    text: windowData.title || tile.windowClass
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.min(8, titleBar.height - 5)
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    width: Math.max(0, tile.width - 56)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Fallback: body
        Rectangle {
            visible: !tile.hasPreview
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.95)

            Image {
                anchors.centerIn: parent
                source: tile.matchedApp && tile.matchedApp.icon
                        ? "image://icon/" + tile.matchedApp.icon : ""
                sourceSize.width: Math.min(48, Math.min(parent.width * 0.45, parent.height * 0.45))
                sourceSize.height: sourceSize.width
                width: sourceSize.width
                height: sourceSize.height
                smooth: true
                opacity: 0.15
                visible: parent.width >= 40 && parent.height >= 30
            }
        }

        // Focused window indicator (thin accent line at top)
        Rectangle {
            visible: tile.isFocused && !tile.hasPreview
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Theme.accent
            z: 5
        }

        // Hover overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b,
                           tile.hovered ? 0.12 : 0.0)
            z: 5
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Border
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            z: 6
            border.width: tile.hovered ? 1.5 : 0.5
            border.color: tile.hovered
                          ? Qt.rgba(Theme.accentBright.r, Theme.accentBright.g, Theme.accentBright.b, 0.7)
                          : Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.12)
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on border.width { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 10
        onClicked: tile.clicked()
    }
}
