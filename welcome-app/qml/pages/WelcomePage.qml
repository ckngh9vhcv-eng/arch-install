import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            anchors.topMargin: 24
            spacing: 20

            // Hero
            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: "Welcome to Void Command"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Your Arch Linux desktop is ready. Here's what's under the hood."
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // System info grid
            GridLayout {
                columns: 3
                columnSpacing: 12
                rowSpacing: 12
                Layout.fillWidth: true

                VcCard {
                    headerIcon: "\uf2db"
                    headerText: "CPU"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.cpuModel
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                VcCard {
                    headerIcon: "\uf26c"
                    headerText: "GPU"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.gpuModel
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Driver: " + SystemInfo.gpuDriver
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textDim
                    }
                }

                VcCard {
                    headerIcon: "\uf538"
                    headerText: "Memory"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.ramTotal
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                    }
                }

                VcCard {
                    headerIcon: "\uf17c"
                    headerText: "Kernel"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.kernelVersion
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                    }
                }

                VcCard {
                    headerIcon: "\uf108"
                    headerText: "Hostname"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.hostname
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                    }
                }

                VcCard {
                    headerIcon: "\uf017"
                    headerText: "Uptime"
                    Layout.fillWidth: true

                    Text {
                        text: SystemInfo.uptime
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.textSecondary
                    }
                }
            }

            // Quick actions
            Text {
                text: "Get Started"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontHeader
                font.bold: true
                color: Theme.textPrimary
                Layout.topMargin: 8
            }

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                VcButton {
                    text: "Browse Apps"
                    icon: "\uf1b2"
                    onClicked: window.currentPage = 1
                }

                VcButton {
                    text: "Check for Fixes"
                    icon: "\uf0ad"
                    onClicked: window.currentPage = 2
                }

                VcButton {
                    text: "System Tweaks"
                    icon: "\uf1de"
                    onClicked: window.currentPage = 3
                }
            }
        }
    }
}
