import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VoidCommand

Popup {
    id: root

    property var fixData: ({})
    property bool _finished: false
    property bool _success: false
    property int _cmdIndex: 0

    signal fixApplied(string fixId)

    anchors.centerIn: parent
    width: 520
    height: 420
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
        _cmdIndex = 0;
        terminal.clear();
    }

    function applyFix() {
        let cmds = fixData.fixCommands || [];
        if (cmds.length === 0) return;

        _cmdIndex = 0;
        runNextCommand();
    }

    function runNextCommand() {
        let cmds = fixData.fixCommands || [];
        if (_cmdIndex >= cmds.length) {
            _finished = true;
            _success = true;
            fixApplied(fixData.id);
            return;
        }

        TaskRunner.run(cmds[_cmdIndex]);
    }

    Connections {
        target: TaskRunner
        enabled: root.visible && !root._finished

        function onOutputLine(line) {
            terminal.appendLine(line);
        }

        function onFinished(exitCode) {
            if (exitCode !== 0) {
                root._finished = true;
                root._success = false;
                terminal.appendLine("Command failed with exit code " + exitCode);
                return;
            }

            root._cmdIndex++;
            root.runNextCommand();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        Text {
            text: fixData.name || "Fix"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontClock
            font.bold: true
            color: Theme.textPrimary
        }

        Text {
            text: fixData.description || ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Severity badge
        Rectangle {
            width: severityText.implicitWidth + 16
            height: 22
            radius: 11
            color: {
                if (fixData.severity === "high") return Theme.danger;
                if (fixData.severity === "medium") return Theme.warning;
                return Theme.info;
            }
            opacity: 0.2

            Text {
                id: severityText
                anchors.centerIn: parent
                text: (fixData.severity || "low").toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                font.bold: true
                color: {
                    if (fixData.severity === "high") return Theme.danger;
                    if (fixData.severity === "medium") return Theme.warning;
                    return Theme.info;
                }
            }
        }

        // Progress
        VcProgressBar {
            Layout.fillWidth: true
            value: TaskRunner.running ? -1 : (_finished ? 1.0 : 0.0)
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
            text: root._success ? "Fix applied successfully" : "Fix failed"
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
                text: "Apply Fix"
                enabled: !TaskRunner.running
                onClicked: root.applyFix()
            }

            VcButton {
                text: root._finished ? "Close" : "Cancel"
                flat: true
                onClicked: root.close()
            }
        }
    }
}
