import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VoidCommand

Item {
    id: root

    // Extract unique resolutions from available modes
    function getResolutions(modes) {
        let seen = {};
        let result = [];
        for (let i = 0; i < modes.length; i++) {
            let key = modes[i].width + "x" + modes[i].height;
            if (!seen[key]) {
                seen[key] = true;
                result.push(key);
            }
        }
        return result;
    }

    // Get refresh rates available for a given resolution
    function getRefreshRates(modes, resolution) {
        let parts = resolution.split("x");
        let w = parseInt(parts[0]);
        let h = parseInt(parts[1]);
        let rates = [];
        for (let i = 0; i < modes.length; i++) {
            if (modes[i].width === w && modes[i].height === h)
                rates.push(modes[i].refreshRate.toFixed(2));
        }
        return rates;
    }

    StackLayout.onIsCurrentItemChanged: {
        if (StackLayout.isCurrentItem)
            DisplayManager.refresh();
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
                    text: "Display"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontHeader
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                VcButton {
                    text: "Refresh"
                    icon: "\uf021"
                    flat: true
                    onClicked: DisplayManager.refresh()
                }
            }

            Repeater {
                model: DisplayManager.monitors

                delegate: VcCard {
                    id: monitorCard
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true

                    headerIcon: "\uf108"
                    headerText: modelData.name + " — " + modelData.make + " " + modelData.model

                    property var availableModes: modelData.availableModes || []
                    property var resolutions: root.getResolutions(availableModes)
                    property string selectedRes: modelData.width + "x" + modelData.height
                    property var rates: root.getRefreshRates(availableModes, selectedRes)
                    property string selectedRate: modelData.refreshRate.toFixed(2)
                    property double selectedScale: modelData.scale
                    property int selectedTransform: modelData.transform
                    property bool initialized: false

                    // Modeline state
                    property string activeModeline: DisplayManager.modelines[modelData.name] || ""
                    property bool useModeline: activeModeline !== ""
                    property string generatedModeline: ""
                    property bool overclockExpanded: useModeline

                    Component.onCompleted: initialized = true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Current info
                        Text {
                            text: {
                                let info = "Current: " + monitorCard.selectedRes + " @ " + monitorCard.selectedRate + " Hz, "
                                      + monitorCard.selectedScale + "x scale";
                                if (monitorCard.useModeline)
                                    info += "  (custom modeline)";
                                return info;
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textSecondary
                        }

                        // Resolution
                        RowLayout {
                            spacing: 8
                            visible: !monitorCard.useModeline

                            Text {
                                text: "Resolution"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.textPrimary
                                Layout.preferredWidth: 100
                            }

                            ComboBox {
                                id: resCombo
                                Layout.preferredWidth: 200
                                model: monitorCard.resolutions
                                currentIndex: Math.max(0, monitorCard.resolutions.indexOf(monitorCard.selectedRes))

                                onCurrentValueChanged: {
                                    if (!monitorCard.initialized || !currentValue)
                                        return;
                                    monitorCard.selectedRes = currentValue;
                                    monitorCard.rates = root.getRefreshRates(monitorCard.availableModes, currentValue);
                                    if (monitorCard.rates.length > 0)
                                        monitorCard.selectedRate = monitorCard.rates[0];
                                }

                                background: Rectangle {
                                    color: Theme.surface1
                                    border.color: Theme.surface2
                                    border.width: 1
                                    radius: Theme.radiusSmall
                                }

                                contentItem: Text {
                                    text: resCombo.currentText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    color: Theme.textPrimary
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }

                                popup: Popup {
                                    y: resCombo.height
                                    width: resCombo.width
                                    padding: 2

                                    background: Rectangle {
                                        color: Theme.surface1
                                        border.color: Theme.surface2
                                        border.width: 1
                                        radius: Theme.radiusSmall
                                    }

                                    contentItem: ListView {
                                        implicitHeight: contentHeight
                                        model: resCombo.popup.visible ? resCombo.delegateModel : null
                                        clip: true
                                    }
                                }

                                delegate: ItemDelegate {
                                    width: resCombo.width
                                    height: 32

                                    contentItem: Text {
                                        text: modelData
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        color: resCombo.currentIndex === index ? Theme.accent : Theme.textPrimary
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: hovered ? Theme.surface2 : "transparent"
                                    }
                                }
                            }
                        }

                        // Refresh rate
                        RowLayout {
                            spacing: 8
                            visible: !monitorCard.useModeline

                            Text {
                                text: "Refresh Rate"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.textPrimary
                                Layout.preferredWidth: 100
                            }

                            ComboBox {
                                id: rateCombo
                                Layout.preferredWidth: 200
                                model: monitorCard.rates
                                currentIndex: Math.max(0, monitorCard.rates.indexOf(monitorCard.selectedRate))

                                onCurrentValueChanged: {
                                    if (monitorCard.initialized && currentValue)
                                        monitorCard.selectedRate = currentValue;
                                }

                                background: Rectangle {
                                    color: Theme.surface1
                                    border.color: Theme.surface2
                                    border.width: 1
                                    radius: Theme.radiusSmall
                                }

                                contentItem: Text {
                                    text: rateCombo.currentText + " Hz"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    color: Theme.textPrimary
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }

                                popup: Popup {
                                    y: rateCombo.height
                                    width: rateCombo.width
                                    padding: 2

                                    background: Rectangle {
                                        color: Theme.surface1
                                        border.color: Theme.surface2
                                        border.width: 1
                                        radius: Theme.radiusSmall
                                    }

                                    contentItem: ListView {
                                        implicitHeight: contentHeight
                                        model: rateCombo.popup.visible ? rateCombo.delegateModel : null
                                        clip: true
                                    }
                                }

                                delegate: ItemDelegate {
                                    width: rateCombo.width
                                    height: 32

                                    contentItem: Text {
                                        text: modelData + " Hz"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        color: rateCombo.currentIndex === index ? Theme.accent : Theme.textPrimary
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: hovered ? Theme.surface2 : "transparent"
                                    }
                                }
                            }
                        }

                        // --- Overclock / Custom Modeline section ---
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.surface2
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        RowLayout {
                            spacing: 8

                            Text {
                                text: "\uf0e7"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.warning
                            }

                            Text {
                                text: "Custom Refresh Rate"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            VcButton {
                                text: monitorCard.overclockExpanded ? "Collapse" : "Expand"
                                flat: true
                                onClicked: monitorCard.overclockExpanded = !monitorCard.overclockExpanded
                            }
                        }

                        ColumnLayout {
                            visible: monitorCard.overclockExpanded
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Generate a custom modeline via cvt to drive your monitor beyond its advertised refresh rates. Use reduced blanking for lower bandwidth (more likely to work)."
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textDim
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: "Target Rate"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    color: Theme.textPrimary
                                    Layout.preferredWidth: 100
                                }

                                Rectangle {
                                    Layout.preferredWidth: 80
                                    height: 36
                                    radius: Theme.radiusSmall
                                    color: Theme.surface1
                                    border.color: Theme.surface2
                                    border.width: 1

                                    TextInput {
                                        id: customRateInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        color: Theme.textPrimary
                                        text: "120"
                                        validator: IntValidator { bottom: 30; top: 500 }
                                        selectByMouse: true
                                    }
                                }

                                Text {
                                    text: "Hz"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    color: Theme.textSecondary
                                }

                                Item { width: 12 }

                                VcToggle {
                                    id: reducedBlankingToggle
                                    checked: true
                                    label: "Reduced blanking"
                                }
                            }

                            RowLayout {
                                spacing: 8

                                VcButton {
                                    text: "Generate"
                                    icon: "\uf1e0"
                                    flat: true
                                    onClicked: {
                                        let parts = monitorCard.selectedRes.split("x");
                                        let w = parseInt(parts[0]);
                                        let h = parseInt(parts[1]);
                                        let rate = parseInt(customRateInput.text);
                                        monitorCard.generatedModeline = DisplayManager.generateModeline(
                                            w, h, rate, reducedBlankingToggle.checked);
                                    }
                                }

                                VcButton {
                                    text: "Use Modeline"
                                    icon: "\uf00c"
                                    visible: monitorCard.generatedModeline !== ""
                                    onClicked: {
                                        DisplayManager.setMonitorModeline(monitorCard.modelData.name, monitorCard.generatedModeline);
                                    }
                                }

                                VcButton {
                                    text: "Remove Modeline"
                                    icon: "\uf00d"
                                    flat: true
                                    visible: monitorCard.useModeline
                                    onClicked: {
                                        DisplayManager.clearMonitorModeline(monitorCard.modelData.name);
                                        monitorCard.generatedModeline = "";
                                    }
                                }
                            }

                            // Generated modeline preview
                            Rectangle {
                                visible: monitorCard.generatedModeline !== ""
                                Layout.fillWidth: true
                                height: modelineText.implicitHeight + 16
                                radius: Theme.radiusSmall
                                color: Theme.void_
                                border.color: Theme.surface2
                                border.width: 1

                                Text {
                                    id: modelineText
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: "modeline " + monitorCard.generatedModeline
                                    font.family: "monospace"
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.textSecondary
                                    wrapMode: Text.WrapAnywhere
                                }
                            }

                            // Active modeline indicator
                            Rectangle {
                                visible: monitorCard.useModeline && monitorCard.generatedModeline === ""
                                Layout.fillWidth: true
                                height: activeModelineText.implicitHeight + 16
                                radius: Theme.radiusSmall
                                color: Theme.void_
                                border.color: Theme.accent
                                border.width: 1

                                Text {
                                    id: activeModelineText
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: "Active: modeline " + monitorCard.activeModeline
                                    font.family: "monospace"
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.accent
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }

                        // --- End overclock section ---
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.surface2
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        // Scale
                        RowLayout {
                            spacing: 8

                            Text {
                                text: "Scale"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.textPrimary
                                Layout.preferredWidth: 100
                            }

                            Row {
                                spacing: 6

                                property var scaleOptions: {
                                    let opts = [1.0, 1.25, 1.5, 2.0];
                                    let current = monitorCard.selectedScale;
                                    if (opts.indexOf(current) === -1)
                                        opts.unshift(current);
                                    return opts;
                                }

                                Repeater {
                                    model: parent.scaleOptions

                                    delegate: VcButton {
                                        required property var modelData
                                        text: modelData + "x"
                                        accent: monitorCard.selectedScale === modelData
                                        flat: monitorCard.selectedScale !== modelData
                                        onClicked: monitorCard.selectedScale = modelData
                                    }
                                }
                            }
                        }

                        // Transform
                        RowLayout {
                            spacing: 8

                            Text {
                                text: "Rotation"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.textPrimary
                                Layout.preferredWidth: 100
                            }

                            Row {
                                spacing: 6

                                Repeater {
                                    model: [
                                        { label: "Normal", value: 0 },
                                        { label: "90\u00b0", value: 1 },
                                        { label: "180\u00b0", value: 2 },
                                        { label: "270\u00b0", value: 3 }
                                    ]

                                    delegate: VcButton {
                                        required property var modelData
                                        text: modelData.label
                                        accent: monitorCard.selectedTransform === modelData.value
                                        flat: monitorCard.selectedTransform !== modelData.value
                                        onClicked: monitorCard.selectedTransform = modelData.value
                                    }
                                }
                            }
                        }

                        // VRR
                        RowLayout {
                            spacing: 8

                            Text {
                                text: "VRR"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                color: Theme.textPrimary
                                Layout.preferredWidth: 100
                            }

                            VcToggle {
                                checked: monitorCard.modelData.vrr
                                label: "Variable Refresh Rate"
                                onToggled: function(isChecked) {
                                    DisplayManager.setVrr(isChecked ? 1 : 0);
                                }
                            }
                        }

                        // Action buttons
                        RowLayout {
                            Layout.topMargin: 8
                            spacing: 8

                            VcButton {
                                text: "Apply"
                                icon: "\uf00c"
                                onClicked: {
                                    let pos = monitorCard.modelData.x + "x" + monitorCard.modelData.y;
                                    if (monitorCard.useModeline) {
                                        DisplayManager.applyModeline(
                                            monitorCard.modelData.name,
                                            monitorCard.activeModeline,
                                            pos,
                                            monitorCard.selectedScale
                                        );
                                    } else {
                                        DisplayManager.applyMonitor(
                                            monitorCard.modelData.name,
                                            monitorCard.selectedRes,
                                            parseFloat(monitorCard.selectedRate),
                                            pos,
                                            monitorCard.selectedScale
                                        );
                                    }
                                    if (monitorCard.selectedTransform !== monitorCard.modelData.transform)
                                        DisplayManager.setTransform(monitorCard.modelData.name, monitorCard.selectedTransform);
                                }
                            }

                            VcButton {
                                text: "Save"
                                icon: "\uf0c7"
                                flat: true
                                onClicked: DisplayManager.saveConfig()
                            }
                        }
                    }
                }
            }

            // Save result message
            Text {
                id: saveMsg
                visible: false
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.success

                Timer {
                    id: saveMsgTimer
                    interval: 3000
                    onTriggered: saveMsg.visible = false
                }

                Connections {
                    target: DisplayManager
                    function onSaveResult(success, message) {
                        saveMsg.text = message;
                        saveMsg.color = success ? Theme.success : Theme.danger;
                        saveMsg.visible = true;
                        saveMsgTimer.restart();
                    }
                }
            }
        }
    }
}
