import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VoidCommand

Item {
    id: root

    property var displayCategories: Catalog.appCategories

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

            Text {
                text: "Apps"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontHeader
                font.bold: true
                color: Theme.textPrimary
            }

            VcSearchBar {
                Layout.fillWidth: true
                onSearched: function(query) {
                    root.displayCategories = Catalog.filterApps(query);
                }
            }

            Repeater {
                model: root.displayCategories

                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 12

                    VcCategoryHeader {
                        icon: modelData.icon || ""
                        label: modelData.name || ""
                        count: modelData.apps ? modelData.apps.length : 0
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.fillWidth: true

                        Repeater {
                            model: modelData.apps || []

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: appLayout.implicitHeight + 24
                                radius: Theme.radius
                                color: Theme.surface0
                                border.color: Theme.surface2
                                border.width: 1

                                RowLayout {
                                    id: appLayout
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: 8

                                            Text {
                                                text: modelData.name || ""
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontBody
                                                font.bold: true
                                                color: Theme.textPrimary
                                            }

                                            Rectangle {
                                                visible: modelData.aur || false
                                                width: aurLabel.implicitWidth + 8
                                                height: 16
                                                radius: 4
                                                color: Theme.surface2

                                                Text {
                                                    id: aurLabel
                                                    anchors.centerIn: parent
                                                    text: "AUR"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    color: Theme.textDim
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.description || ""
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontLabel
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    VcButton {
                                        text: modelData.installed ? "Remove" : "Install"
                                        accent: !modelData.installed
                                        flat: modelData.installed
                                        enabled: !PackageManager.busy

                                        onClicked: {
                                            installDialog.packageName = modelData.package || "";
                                            installDialog.appName = modelData.name || "";
                                            installDialog.isRemove = modelData.installed || false;
                                            installDialog.open();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spacer between categories
                    Item { height: 4 }
                }
            }
        }
    }

    InstallDialog {
        id: installDialog
    }

    Connections {
        target: Catalog
        function onCatalogLoaded() {
            root.displayCategories = Catalog.appCategories;
        }
    }
}
