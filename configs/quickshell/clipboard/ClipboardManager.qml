import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: clipboardManager

    property bool showing: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: showing
    focusable: true
    aboveWindows: true
    color: "transparent"

    function toggle() {
        if (showing) hide();
        else show();
    }

    function show() {
        clipModel.clear();
        searchInput.text = "";
        showing = true;
        listProc.running = true;
        searchInput.forceActiveFocus();
    }

    function hide() {
        showing = false;
    }

    function selectEntry(id) {
        decodeProc.clipId = id;
        decodeProc.running = true;
        hide();
    }

    function deleteEntry(id, index) {
        deleteProc.clipId = id;
        deleteProc.deleteIndex = index;
        deleteProc.running = true;
    }

    function clearAll() {
        wipeProc.running = true;
        clipModel.clear();
    }

    ListModel {
        id: clipModel
    }

    // Load clipboard history
    Process {
        id: listProc
        command: ["sh", "-c", "cliphist -db-path ~/.local/share/cliphist/db list"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim().length === 0) return;
                var tabIdx = line.indexOf("\t");
                if (tabIdx === -1) return;
                var id = line.substring(0, tabIdx).trim();
                var preview = line.substring(tabIdx + 1).trim();
                // Skip binary/image entries
                if (preview.startsWith("[[ binary data")) return;
                clipModel.append({ clipId: id, clipText: preview });
            }
        }
    }

    // Decode and copy selected entry
    Process {
        id: decodeProc
        property string clipId: ""
        command: ["sh", "-c", "echo '" + clipId + "' | cliphist -db-path ~/.local/share/cliphist/db decode | wl-copy"]
    }

    // Delete a single entry
    Process {
        id: deleteProc
        property string clipId: ""
        property int deleteIndex: -1
        command: ["sh", "-c", "echo '" + clipId + "' | cliphist -db-path ~/.local/share/cliphist/db delete"]
        onExited: function(exitCode, exitStatus) {
            if (deleteIndex >= 0 && deleteIndex < clipModel.count) {
                clipModel.remove(deleteIndex);
            }
        }
    }

    // Wipe all history
    Process {
        id: wipeProc
        command: ["sh", "-c", "cliphist -db-path ~/.local/share/cliphist/db wipe"]
    }

    // Dark overlay backdrop
    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                clipboardManager.hide();
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.void_.r, Theme.void_.g, Theme.void_.b, 0.75)

            MouseArea {
                anchors.fill: parent
                onClicked: clipboardManager.hide()
            }

            // Center content panel
            Rectangle {
                anchors.centerIn: parent
                width: 650
                height: 580
                radius: Theme.radiusPopup
                color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.92)
                border.width: 1
                border.color: Theme.accentDim

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Header row
                    Row {
                        width: parent.width
                        height: 32

                        Text {
                            text: "CLIPBOARD"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeader
                            font.bold: true
                            font.letterSpacing: 4
                            color: Theme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: parent.width - clearBtn.width - 120; height: 1 }

                        Rectangle {
                            id: clearBtn
                            width: clearText.width + 24
                            height: 28
                            radius: Theme.radiusInner
                            color: clearMouse.containsMouse
                                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.3)
                                   : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear All"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.danger
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipboardManager.clearAll()
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Search field
                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: Theme.radiusInner
                        color: Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.8)
                        border.width: searchInput.activeFocus ? 2 : 1
                        border.color: searchInput.activeFocus ? Theme.accentGlow : Theme.accentDim

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            selectionColor: Theme.accent
                            selectedTextColor: "#FFFFFF"
                            clip: true
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Filter clipboard..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.textDim
                            visible: searchInput.text.length === 0
                        }

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    // Clip list
                    ListView {
                        id: clipList
                        width: parent.width
                        height: parent.height - 32 - 42 - 24
                        clip: true
                        model: clipModel
                        spacing: 2

                        delegate: Rectangle {
                            id: clipDelegate
                            required property int index
                            required property string clipId
                            required property string clipText

                            property bool matchesFilter: {
                                if (searchInput.text.length === 0) return true;
                                return clipText.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1;
                            }

                            width: clipList.width
                            height: matchesFilter ? 44 : 0
                            visible: matchesFilter
                            radius: Theme.radiusInner
                            color: entryMouse.containsMouse
                                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                   : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 8

                                // Preview text
                                Text {
                                    width: parent.width - deleteBtn.width - 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: clipDelegate.clipText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Delete button
                                Rectangle {
                                    id: deleteBtn
                                    width: 28
                                    height: 28
                                    radius: Theme.radiusInner
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: delMouse.containsMouse
                                           ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.3)
                                           : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u{f0156}"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: delMouse.containsMouse ? Theme.danger : Theme.textDim
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clipboardManager.deleteEntry(clipDelegate.clipId, clipDelegate.index)
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                anchors.rightMargin: 36
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipboardManager.selectEntry(clipDelegate.clipId)
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                // Scale animation
                scale: clipboardManager.showing ? 1.0 : 0.95
                opacity: clipboardManager.showing ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
