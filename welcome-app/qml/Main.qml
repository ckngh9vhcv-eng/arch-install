import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VoidCommand

ApplicationWindow {
    id: window
    width: 960
    height: 660
    visible: true
    title: "Void Command"
    color: Theme.void_

    property int currentPage: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // --- Sidebar ---
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: Theme.surface0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                // Branding
                Text {
                    text: "VOID COMMAND"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontClock
                    font.bold: true
                    color: Theme.accent
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 16
                    Layout.topMargin: 8
                }

                Repeater {
                    model: [
                        { icon: "\uf015", label: "Welcome", page: 0 },
                        { icon: "\uf1b2", label: "Apps", page: 1 },
                        { icon: "\uf0ad", label: "Fixes", page: 2 },
                        { icon: "\uf1de", label: "Tweaks", page: 3 },
                        { icon: "\uf05a", label: "About", page: 4 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSmall
                        color: window.currentPage === modelData.page
                               ? Theme.surface2
                               : navMouse.containsMouse ? Theme.surface1 : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: window.currentPage === modelData.page
                                       ? Theme.accent : Theme.textSecondary
                            }

                            Text {
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: window.currentPage === modelData.page
                                       ? Theme.textPrimary : Theme.textSecondary
                            }

                            Item { Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentPage = modelData.page
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Helper name badge
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: Theme.radiusSmall
                    color: Theme.surface1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf49e  " + PackageManager.helperName
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textDim
                    }
                }
            }
        }

        // --- Sidebar separator ---
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.surface2
        }

        // --- Content area ---
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.currentPage

            WelcomePage {}
            AppsPage {}
            FixesPage {}
            TweaksPage {}
            AboutPage {}
        }
    }
}
