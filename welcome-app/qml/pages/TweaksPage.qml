import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    property var tweakStates: ({})
    property bool checking: false

    function loadStates() {
        let tweaks = Catalog.tweaks;
        let states = {};
        let script = "";

        for (let i = 0; i < tweaks.length; i++) {
            let t = tweaks[i];
            states[t.id] = undefined;
            if (t.type === "toggle") {
                script += t.checkCommand + " && echo 'VC:" + t.id + ":on' || echo 'VC:" + t.id + ":off'\n";
            } else if (t.type === "select") {
                script += "echo 'VC:" + t.id + ":'$(" + t.checkCommand + ")\n";
            }
        }

        tweakStates = states;
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
