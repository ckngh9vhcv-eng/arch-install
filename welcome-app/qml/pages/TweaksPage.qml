import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    property var tweakStates: ({})
    property bool checking: false
    property bool applying: false
    property bool pacmanBusy: false
    property string pacmanStatus: ""

    function loadStates() {
        let tweaks = Catalog.tweaks;
        let script = "";

        // Only reset states on first load (when empty)
        if (Object.keys(tweakStates).length === 0) {
            let states = {"parallel-downloads": undefined, "reflector-timer": undefined};
            for (let i = 0; i < tweaks.length; i++)
                states[tweaks[i].id] = undefined;
            tweakStates = states;
        }

        for (let i = 0; i < tweaks.length; i++) {
            let t = tweaks[i];
            if (t.type === "toggle") {
                script += t.checkCommand + " && echo 'VC:" + t.id + ":on' || echo 'VC:" + t.id + ":off'\n";
            } else if (t.type === "select") {
                script += "echo 'VC:" + t.id + ":'$(" + t.checkCommand + ")\n";
            }
        }

        script += "PVAL=$(grep -E '^ParallelDownloads' /etc/pacman.conf 2>/dev/null | grep -oE '[0-9]+'); [ -z \"$PVAL\" ] && PVAL=1; echo \"VC:parallel-downloads:$PVAL\"\n";
        script += "systemctl is-active --quiet reflector.timer && echo 'VC:reflector-timer:on' || echo 'VC:reflector-timer:off'\n";

        checking = true;
        TaskRunner.run(script);
    }

    function updateState(id, value) {
        let updated = Object.assign({}, tweakStates);
        updated[id] = value;
        tweakStates = updated;
    }

    Connections {
        target: TaskRunner
        enabled: root.checking

        function onOutputLine(line) {
            if (!line.startsWith("VC:"))
                return;
            let parts = line.substring(3).split(":");
            if (parts.length < 2)
                return;
            let id = parts[0];
            let value = parts.slice(1).join(":").trim();
            if (value === "on")
                root.updateState(id, true);
            else if (value === "off")
                root.updateState(id, false);
            else
                root.updateState(id, value);
        }

        function onFinished(exitCode) {
            root.checking = false;
        }
    }

    Connections {
        target: TaskRunner
        enabled: root.applying

        function onRunningChanged() {
            if (!TaskRunner.running) {
                root.applying = false;
                root.loadStates();
            }
        }
    }

    function runPacmanAction(command) {
        pacmanTerminal.clear();
        pacmanStatus = "";
        pacmanBusy = true;
        TaskRunner.run(command);
    }

    Connections {
        target: TaskRunner
        enabled: root.pacmanBusy

        function onOutputLine(line) {
            pacmanTerminal.appendLine(line);
        }

        function onFinished(exitCode) {
            root.pacmanBusy = false;
            root.pacmanStatus = exitCode === 0 ? "success" : "failed";
            root.loadStates();
        }
    }

    StackLayout.onIsCurrentItemChanged: {
        if (StackLayout.isCurrentItem && !checking)
            loadStates();
    }

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
            spacing: 16

            Text {
                text: "Tweaks"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontHeader
                font.bold: true
                color: Theme.textPrimary
            }

            // --- Pacman Section ---
            Text {
                text: "Pacman"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontClock
                font.bold: true
                color: Theme.accent
                Layout.topMargin: 8
            }

            // Pacman Settings card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: pacmanSettingsLayout.implicitHeight + 24
                radius: Theme.radius
                color: Theme.surface0
                border.color: Theme.surface2
                border.width: 1

                ColumnLayout {
                    id: pacmanSettingsLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Parallel Downloads
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Parallel Downloads"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Text {
                                text: "Number of packages to download simultaneously"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textSecondary
                            }
                        }

                        Row {
                            spacing: 4

                            Repeater {
                                model: ["1", "3", "5", "10"]

                                delegate: VcButton {
                                    required property string modelData
                                    text: modelData
                                    accent: root.tweakStates["parallel-downloads"] === modelData
                                    flat: root.tweakStates["parallel-downloads"] !== modelData
                                    enabled: !TaskRunner.running

                                    onClicked: {
                                        TaskRunner.run("pkexec sed -i -E 's/^#?ParallelDownloads.*/ParallelDownloads = " + modelData + "/' /etc/pacman.conf");
                                        root.updateState("parallel-downloads", modelData);
                                        root.applying = true;
                                    }
                                }
                            }
                        }
                    }

                    // Reflector Timer
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Auto-rank Mirrors"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Text {
                                text: "Periodically re-rank mirrors via reflector timer"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textSecondary
                            }
                        }

                        VcToggle {
                            checked: root.tweakStates["reflector-timer"] === true
                            enabled: !TaskRunner.running && root.tweakStates["reflector-timer"] !== undefined

                            onToggled: function(isChecked) {
                                let cmd = isChecked
                                    ? "pkexec bash -c 'pacman -S --noconfirm --needed reflector && systemctl enable --now reflector.timer'"
                                    : "pkexec systemctl disable --now reflector.timer";
                                TaskRunner.enqueue(cmd);
                                root.updateState("reflector-timer", isChecked);
                                root.applying = true;
                            }
                        }
                    }
                }
            }

            // Pacman Maintenance card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: pacmanActionsLayout.implicitHeight + 24
                radius: Theme.radius
                color: Theme.surface0
                border.color: Theme.surface2
                border.width: 1

                ColumnLayout {
                    id: pacmanActionsLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "Maintenance"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        VcButton {
                            text: "Re-rank Mirrors"
                            enabled: !TaskRunner.running
                            onClicked: root.runPacmanAction(
                                "pkexec bash -c '" +
                                "pacman -S --noconfirm --needed cachyos-rate-mirrors 2>/dev/null || pacman -S --noconfirm --needed reflector 2>/dev/null || true; " +
                                "if command -v cachyos-rate-mirrors >/dev/null 2>&1; then cachyos-rate-mirrors; " +
                                "elif command -v reflector >/dev/null 2>&1; then reflector --latest 10 --sort rate --fastest 5 --save /etc/pacman.d/mirrorlist; " +
                                "else echo No mirror ranking tool could be installed; exit 1; fi'"
                            )
                        }

                        VcButton {
                            text: "Refresh Keyring"
                            flat: true
                            enabled: !TaskRunner.running
                            onClicked: root.runPacmanAction(
                                "pkexec bash -c 'pacman-key --init && pacman-key --populate archlinux cachyos'"
                            )
                        }

                        VcButton {
                            text: "Clear Cache"
                            flat: true
                            enabled: !TaskRunner.running
                            onClicked: root.runPacmanAction(
                                "pkexec bash -c 'if command -v paccache >/dev/null 2>&1; then paccache -rk2; else echo paccache not found - install pacman-contrib; exit 1; fi'"
                            )
                        }

                        VcButton {
                            text: "Remove Lock"
                            flat: true
                            enabled: !TaskRunner.running
                            onClicked: root.runPacmanAction(
                                "pkexec bash -c 'if [ -f /var/lib/pacman/db.lck ]; then rm /var/lib/pacman/db.lck && echo Lock file removed; else echo No lock file present; fi'"
                            )
                        }

                        VcButton {
                            text: "Force DB Sync"
                            flat: true
                            enabled: !TaskRunner.running
                            onClicked: root.runPacmanAction("pkexec pacman -Syy --noconfirm")
                        }
                    }
                }
            }

            // Terminal output for pacman actions
            VcTerminalOutput {
                id: pacmanTerminal
                Layout.fillWidth: true
                implicitHeight: 200
                visible: root.pacmanBusy || pacmanTerminal.text.length > 0
            }

            // Status text after pacman action completes
            Text {
                visible: root.pacmanStatus !== ""
                text: root.pacmanStatus === "success" ? "✓ Completed successfully" : "✗ Operation failed"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: root.pacmanStatus === "success" ? Theme.success : Theme.danger
            }

            // --- Services Section ---
            Text {
                text: "Services"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontClock
                font.bold: true
                color: Theme.accent
                Layout.topMargin: 16
            }

            Repeater {
                model: Catalog.tweaks

                delegate: Rectangle {
                    id: tweakCard
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: tweakLayout.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.surface0
                    border.color: Theme.surface2
                    border.width: 1

                    RowLayout {
                        id: tweakLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: tweakCard.modelData.name || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Text {
                                text: tweakCard.modelData.description || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textSecondary
                            }
                        }

                        Loader {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            active: tweakCard.modelData.type === "toggle"
                            sourceComponent: VcToggle {
                                checked: root.tweakStates[tweakCard.modelData.id] === true
                                enabled: !TaskRunner.running && root.tweakStates[tweakCard.modelData.id] !== undefined

                                onToggled: function(isChecked) {
                                    let cmds = isChecked
                                        ? tweakCard.modelData.enableCommands
                                        : tweakCard.modelData.disableCommands;
                                    for (let i = 0; i < cmds.length; i++)
                                        TaskRunner.enqueue(cmds[i]);
                                    root.updateState(tweakCard.modelData.id, isChecked);
                                    root.applying = true;
                                }
                            }
                        }

                        Loader {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            active: tweakCard.modelData.type === "select"
                            sourceComponent: Row {
                                spacing: 6

                                Repeater {
                                    model: tweakCard.modelData.options || []

                                    delegate: VcButton {
                                        required property string modelData
                                        text: modelData
                                        accent: root.tweakStates[tweakCard.modelData.id] === modelData
                                        flat: root.tweakStates[tweakCard.modelData.id] !== modelData
                                        enabled: !TaskRunner.running

                                        onClicked: {
                                            let cmd = tweakCard.modelData.selectCommand.replace("%OPTION%", modelData);
                                            TaskRunner.run(cmd);
                                            root.updateState(tweakCard.modelData.id, modelData);
                                            root.applying = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
