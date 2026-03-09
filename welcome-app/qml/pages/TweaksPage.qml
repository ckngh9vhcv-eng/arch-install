import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    property var tweakStates: ({})
    property var checkQueue: []
    property int checkIndex: -1
    property bool checking: false

    function loadStates() {
        let tweaks = Catalog.tweaks;
        let states = {};
        for (let i = 0; i < tweaks.length; i++)
            states[tweaks[i].id] = undefined;
        tweakStates = states;

        checkQueue = tweaks;
        checkIndex = 0;
        checking = true;
        runNextCheck();
    }

    function runNextCheck() {
        if (checkIndex >= checkQueue.length) {
            checking = false;
            return;
        }
        TaskRunner.run(checkQueue[checkIndex].checkCommand);
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
            if (root.checkIndex < 0 || root.checkIndex >= root.checkQueue.length)
                return;
            let tweak = root.checkQueue[root.checkIndex];
            if (tweak.type === "select")
                root.updateState(tweak.id, line.trim());
        }

        function onFinished(exitCode) {
            if (root.checkIndex < 0 || root.checkIndex >= root.checkQueue.length)
                return;

            let tweak = root.checkQueue[root.checkIndex];
            if (tweak.type === "toggle")
                root.updateState(tweak.id, exitCode === 0);

            root.checkIndex++;
            root.runNextCheck();
        }
    }

    Component.onCompleted: loadStates()

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
