import QtQuick
import QtQuick.Layouts
import ".."

Flickable {
    id: root
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: content
        width: root.width
        spacing: 16

        component KeyCategory: ColumnLayout {
            property string title

            spacing: 6

            Text {
                text: title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                font.bold: true
                font.letterSpacing: 2
                color: Theme.textDim
            }
        }

        component KeyRow: RowLayout {
            property string keys
            property string action

            spacing: 8

            Rectangle {
                color: Theme.accentDim
                radius: 4
                implicitWidth: keyText.implicitWidth + 12
                implicitHeight: keyText.implicitHeight + 6

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: keys
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.textPrimary
                }
            }

            Text {
                text: action
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textSecondary
            }
        }

        // Apps
        KeyCategory {
            title: "APPS"
            KeyRow { keys: "SUPER + Space"; action: "Launcher" }
            KeyRow { keys: "SUPER + B"; action: "Browser" }
            KeyRow { keys: "SUPER + T"; action: "Terminal" }
            KeyRow { keys: "SUPER + F"; action: "Files" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Windows
        KeyCategory {
            title: "WINDOWS"
            KeyRow { keys: "SUPER + Q"; action: "Close" }
            KeyRow { keys: "SUPER + W"; action: "Float" }
            KeyRow { keys: "SUPER + P"; action: "Fullscreen" }
            KeyRow { keys: "SUPER + SHIFT + P"; action: "Fake Fullscreen" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Focus
        KeyCategory {
            title: "FOCUS"
            KeyRow { keys: "SUPER + Arrows"; action: "Move Focus" }
            KeyRow { keys: "SUPER + SHIFT + Arrows"; action: "Move Window" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Workspaces
        KeyCategory {
            title: "WORKSPACES"
            KeyRow { keys: "SUPER + 1-9"; action: "Switch" }
            KeyRow { keys: "SUPER + SHIFT + 1-9"; action: "Move To" }
            KeyRow { keys: "SUPER + Scroll"; action: "Cycle" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Tools
        KeyCategory {
            title: "TOOLS"
            KeyRow { keys: "SUPER + D"; action: "Sidebar" }
            KeyRow { keys: "SUPER + V"; action: "Clipboard" }
            KeyRow { keys: "SUPER + SHIFT + S"; action: "Screenshot" }
            KeyRow { keys: "SUPER + G"; action: "Game Mode" }
            KeyRow { keys: "SUPER + R"; action: "Record Screen" }
            KeyRow { keys: "SUPER + N"; action: "Cycle Wallpaper" }
            KeyRow { keys: "SUPER + L"; action: "Lock" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Zoom
        KeyCategory {
            title: "ZOOM"
            KeyRow { keys: "SUPER + ="; action: "Zoom In" }
            KeyRow { keys: "SUPER + -"; action: "Zoom Out" }
            KeyRow { keys: "SUPER + 0"; action: "Reset Zoom" }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDim; opacity: 0.3 }

        // Media
        KeyCategory {
            title: "MEDIA"
            KeyRow { keys: "Play/Pause"; action: "Toggle Playback" }
            KeyRow { keys: "Next"; action: "Next Track" }
            KeyRow { keys: "Prev"; action: "Previous Track" }
            KeyRow { keys: "Stop"; action: "Stop Playback" }
        }

        // Bottom padding
        Item { Layout.preferredHeight: 8 }
    }
}
