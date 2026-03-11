import QtQuick
import QtQuick.Layouts
import VoidCommand

Item {
    id: root

    property var fixResults: ({})
    property bool scanning: false

    function startScan() {
        let fixes = Catalog.fixes;
        let results = {};
        let script = "";

        for (let i = 0; i < fixes.length; i++) {
            let f = fixes[i];
            results[f.id] = "checking";
            script += f.detectCommand + " && echo 'VC:" + f.id + ":detected' || echo 'VC:" + f.id + ":clear'\n";
        }

        fixResults = results;
        scanning = true;
        TaskRunner.run(script);
    }

    Connections {
        target: TaskRunner
        enabled: root.scanning

        function onOutputLine(line) {
            if (!line.startsWith("VC:"))
                return;
            let parts = line.substring(3).split(":");
            if (parts.length < 2)
                return;
            let id = parts[0];
            let value = parts.slice(1).join(":").trim();
            let updated = Object.assign({}, root.fixResults);
            updated[id] = value;
            root.fixResults = updated;
        }

        function onFinished(exitCode) {
            root.scanning = false;
        }
    }

    StackLayout.onIsCurrentItemChanged: {
        if (StackLayout.isCurrentItem && !scanning)
            startScan();
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

            RowLayout {
                spacing: 12

                Text {
                    text: "Fixes"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontHeader
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                VcButton {
                    text: "Rescan"
                    icon: "\uf021"
                    flat: true
                    enabled: !root.scanning
                    onClicked: root.startScan()
                }
            }

            Repeater {
                model: Catalog.fixes

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: fixLayout.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.surface0
                    border.color: Theme.surface2
                    border.width: 1

                    property string status: root.fixResults[modelData.id] || "checking"

                    RowLayout {
                        id: fixLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 4
                            Layout.fillHeight: true
                            radius: 2
                            color: {
                                if (status === "fixed" || status === "clear") return Theme.success;
                                if (modelData.severity === "high") return Theme.danger;
                                if (modelData.severity === "medium") return Theme.warning;
                                return Theme.info;
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: modelData.name || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Text {
                                text: modelData.description || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textSecondary
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            visible: status === "checking"
                            text: "\uf110"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            color: Theme.textDim

                            RotationAnimation on rotation {
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: status === "checking"
                            }
                        }

                        Text {
                            visible: status === "clear" || status === "fixed"
                            text: status === "fixed" ? "\uf00c Fixed" : "\uf00c OK"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.success
                        }

                        VcButton {
                            visible: status === "detected"
                            text: "Apply Fix"
                            enabled: !root.scanning
                            onClicked: {
                                fixDialog.fixData = modelData;
                                fixDialog.open();
                            }
                        }
                    }
                }
            }
        }
    }

    FixDialog {
        id: fixDialog
        onFixApplied: function(fixId) {
            let updated = Object.assign({}, root.fixResults);
            updated[fixId] = "fixed";
            root.fixResults = updated;
        }
    }
}
