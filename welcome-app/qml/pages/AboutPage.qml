import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: Math.min(parent.width - 48, 500)

        // Logo text
        Text {
            text: "VOID COMMAND"
            font.family: Theme.fontFamily
            font.pixelSize: 42
            font.bold: true
            color: Theme.accent
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "A custom Arch Linux desktop experience"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: Theme.textSecondary
            Layout.alignment: Qt.AlignHCenter
        }

        // Info card
        VcCard {
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                columnSpacing: 20
                rowSpacing: 8
                Layout.fillWidth: true

                Text {
                    text: "Version"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textDim
                }
                Text {
                    text: "1.0.0"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textPrimary
                }

                Text {
                    text: "Desktop"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textDim
                }
                Text {
                    text: "Hyprland + Quickshell"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textPrimary
                }

                Text {
                    text: "Theme"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textDim
                }
                Text {
                    text: Theme.schemeDisplayNames[Theme.currentScheme] || Theme.currentScheme
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.accent
                }

                Text {
                    text: "Kernel"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textDim
                }
                Text {
                    text: SystemInfo.kernelVersion
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textPrimary
                }

                Text {
                    text: "Boot"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textDim
                }
                Text {
                    text: SystemInfo.bootMode
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textPrimary
                }
            }
        }

        // Links
        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            VcButton {
                text: "GitHub"
                icon: "\uf09b"
                flat: true
                onClicked: Qt.openUrlExternally("https://github.com/ckngh9vhcv-eng/arch-install")
            }

            VcButton {
                text: "Report Issue"
                icon: "\uf188"
                flat: true
                onClicked: Qt.openUrlExternally("https://github.com/ckngh9vhcv-eng/arch-install/issues")
            }
        }

        // Credits
        Text {
            text: "Built with Qt6, Hyprland, and Quickshell"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textDim
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
        }
    }
}
