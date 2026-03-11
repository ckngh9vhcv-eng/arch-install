import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VoidCommand

Popup {
    id: root

    property string packageName: ""
    property string appName: ""
    property bool isRemove: false
    property bool isFlatpak: false
    property bool _finished: false
    property bool _success: false

    anchors.centerIn: parent
    width: 520
    height: 400
    modal: true
    closePolicy: Popup.CloseOnEscape

    background: Rectangle {
        color: Theme.surface1
        border.color: Theme.surface3
        border.width: 1
        radius: Theme.radius
    }

    onOpened: {
        _finished = false;
        _success = false;
        terminal.clear();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        Text {
            text: root.isRemove ? "Remove " + root.appName : "Install " + root.appName
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontClock
            font.bold: true
            color: Theme.textPrimary
        }

        Text {
            text: "Package: " + root.packageName
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textDim
        }

        // Progress
        VcProgressBar {
            Layout.fillWidth: true
            value: PackageManager.busy ? -1 : (_finished ? 1.0 : 0.0)
        }

        // Terminal output
        VcTerminalOutput {
            id: terminal
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Status
        Text {
            visible: root._finished
            text: root._success ? "Completed successfully" : "Operation failed"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            color: root._success ? Theme.success : Theme.danger
        }

        // Actions
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignRight

            VcButton {
                visible: !root._finished
                text: root.isRemove ? "Remove" : "Install"
                enabled: !PackageManager.busy
                onClicked: {
                    if (root.isFlatpak) {
                        if (root.isRemove)
                            PackageManager.removeFlatpak(root.packageName);
                        else
                            PackageManager.installFlatpak(root.packageName);
                    } else {
                        if (root.isRemove)
                            PackageManager.remove([root.packageName]);
                        else
                            PackageManager.install([root.packageName]);
                    }
                }
            }

            VcButton {
                text: root._finished ? "Close" : "Cancel"
                flat: true
                onClicked: root.close()
            }
        }
    }

    Connections {
        target: PackageManager

        function onOutputLine(line) {
            if (root.visible)
                terminal.appendLine(line);
        }

        function onInstallFinished(success) {
            if (root.visible) {
                root._finished = true;
                root._success = success;
            }
        }
    }
}
