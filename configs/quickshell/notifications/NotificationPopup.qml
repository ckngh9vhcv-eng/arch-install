import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."

Item {
    id: root

    // Group tracking: appName → array of notification refs
    property var notifGroups: ({})

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: function(notification) {
            notification.tracked = true;

            // Add to notification history (always, even DND)
            ShellGlobals.addNotificationToHistory(notification.appName, notification.summary, notification.body, notification.image);

            // Suppress popups in Do Not Disturb mode (still track them)
            if (ShellGlobals.doNotDisturb) return;

            var app = notification.appName || "Unknown";

            // Check for progress hint
            var progressValue = -1;
            if (notification.hints && notification.hints["value"] !== undefined) {
                progressValue = Math.max(0, Math.min(100, parseInt(notification.hints["value"])));
            }

            // Group logic
            if (!root.notifGroups[app]) {
                root.notifGroups[app] = [];
            }
            root.notifGroups[app].push(notification);

            // Check if group already exists in model
            var existingIdx = -1;
            for (var i = 0; i < notifModel.count; i++) {
                if (notifModel.get(i).appName === app) {
                    existingIdx = i;
                    break;
                }
            }

            if (existingIdx >= 0) {
                // Update existing group — replace with latest notification
                notifModel.set(existingIdx, {
                    notif: notification,
                    appName: app,
                    groupCount: root.notifGroups[app].length,
                    progressValue: progressValue
                });
            } else {
                // New group entry
                notifModel.insert(0, {
                    notif: notification,
                    appName: app,
                    groupCount: 1,
                    progressValue: progressValue
                });
            }

            // Auto-dismiss based on urgency (unless critical)
            if (notification.urgency !== NotificationUrgency.Critical) {
                var timeout = notification.urgency === NotificationUrgency.Low ? 5000 : 8000;
                dismissTimer.createObject(root, {
                    notifToExpire: notification,
                    notifApp: app,
                    interval: timeout
                });
            }
        }
    }

    // Remove a notification from its group and clean up if empty
    function removeFromGroup(app, notifId) {
        if (!notifGroups[app]) return;
        notifGroups[app] = notifGroups[app].filter(function(n) { return n.id !== notifId; });
        if (notifGroups[app].length === 0) {
            delete notifGroups[app];
            // Remove from model
            for (var i = 0; i < notifModel.count; i++) {
                if (notifModel.get(i).appName === app) {
                    notifModel.remove(i);
                    return;
                }
            }
        } else {
            // Update count in model
            for (var i = 0; i < notifModel.count; i++) {
                if (notifModel.get(i).appName === app) {
                    notifModel.set(i, {
                        notif: notifGroups[app][notifGroups[app].length - 1],
                        appName: app,
                        groupCount: notifGroups[app].length,
                        progressValue: notifModel.get(i).progressValue
                    });
                    return;
                }
            }
        }
    }

    // Dismiss all notifications in a group
    function dismissGroup(app) {
        if (!notifGroups[app]) return;
        var notifs = notifGroups[app].slice();
        for (var i = 0; i < notifs.length; i++) {
            notifs[i].dismiss();
        }
    }

    // Timer component for auto-dismiss
    Component {
        id: dismissTimer
        Timer {
            property var notifToExpire
            property string notifApp: ""
            running: true
            repeat: false
            onTriggered: {
                var nid = notifToExpire ? notifToExpire.id : -1;
                if (notifToExpire) notifToExpire.expire();
                // Fallback: remove from model directly in case onClosed doesn't fire
                if (nid >= 0 && notifApp.length > 0) {
                    root.removeFromGroup(notifApp, nid);
                }
                destroy();
            }
        }
    }

    ListModel {
        id: notifModel
    }

    // Notification cards positioned top-right — Loader destroys the layer surface
    // when empty so it doesn't steal clicks from windows underneath
    Loader {
        active: notifModel.count > 0
        sourceComponent: notifPanelComponent
    }

    Component {
        id: notifPanelComponent
        PanelWindow {
            anchors.top: true
            anchors.right: true
            implicitWidth: 380
            implicitHeight: notifColumn.implicitHeight + 20
            color: "transparent"
            focusable: false
            aboveWindows: true

            margins.top: 46
            margins.right: 10

            Column {
                id: notifColumn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.margins: 10
                spacing: 8

                Repeater {
                    model: notifModel

                Rectangle {
                    id: card
                    required property var notif
                    required property int index
                    required property string appName
                    required property int groupCount
                    required property int progressValue

                    property bool dismissing: false
                    property bool _entered: false
                    property int notifId: notif ? notif.id : -1

                    width: notifColumn.width
                    height: cardContent.implicitHeight + 24
                    radius: Theme.radiusPanel
                    color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.92)
                    border.width: 1
                    border.color: {
                        if (!notif) return Theme.accentDim;
                        switch (notif.urgency) {
                            case NotificationUrgency.Critical: return Theme.danger;
                            case NotificationUrgency.Low: return Theme.accentDim;
                            default: return Theme.accentGlow;
                        }
                    }

                    // Remove when notification is closed (with exit animation)
                    Connections {
                        target: notif
                        function onClosed() {
                            card.dismissing = true;
                            Qt.callLater(function() {
                                dismissRemoveTimer.start();
                            });
                        }
                    }

                    Timer {
                        id: dismissRemoveTimer
                        interval: Theme.animDuration
                        repeat: false
                        onTriggered: root.removeFromGroup(card.appName, card.notifId)
                    }

                    // Entry/exit animation targets
                    opacity: dismissing ? 0.0 : _entered ? 1.0 : 0.0
                    scale: dismissing ? 0.95 : _entered ? 1.0 : 0.95
                    x: dismissing ? 50 : _entered ? 0 : 30

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

                    // Entry animation
                    Component.onCompleted: {
                        _entered = true;
                    }

                    // Click notification body to invoke default action
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        z: 0
                        onClicked: {
                            if (!notif || !notif.actions) return;
                            var action = null;
                            for (var i = 0; i < notif.actions.length; i++) {
                                var a = notif.actions[i];
                                if (a.identifier === "default") { action = a; break; }
                            }
                            if (!action && notif.actions.length > 0) action = notif.actions[0];
                            if (action) {
                                action.invoke();
                                notif.dismiss();
                            }
                        }
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        // Header: app name (with group count) + close
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: {
                                    var label = notif ? notif.appName : "";
                                    if (groupCount > 1) label += " (" + groupCount + ")";
                                    return label;
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                font.bold: true
                                color: Theme.textDim
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "\u2715"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: closeMouse.containsMouse ? Theme.textPrimary : Theme.textDim

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (groupCount > 1) {
                                            root.dismissGroup(card.appName);
                                        } else if (notif) {
                                            notif.dismiss();
                                        }
                                    }
                                }
                            }
                        }

                        // Notification image
                        Image {
                            source: notif && notif.image ? notif.image : ""
                            visible: notif && notif.image && notif.image.toString() !== ""
                            Layout.fillWidth: true
                            Layout.maximumHeight: 120
                            fillMode: Image.PreserveAspectFit
                        }

                        // Summary
                        Text {
                            text: notif ? notif.summary : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                            color: Theme.textPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }

                        // Body
                        Text {
                            text: notif ? notif.body : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textSecondary
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            visible: notif && notif.body.length > 0
                        }

                        // Progress bar (from hints "value" key)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.surface3
                            visible: card.progressValue >= 0

                            Rectangle {
                                width: parent.width * (card.progressValue / 100)
                                height: parent.height
                                radius: 2
                                color: Theme.accent

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }
                        }

                        // Actions
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: notif && notif.actions && notif.actions.length > 0

                            Repeater {
                                model: notif ? notif.actions : []

                                Rectangle {
                                    required property var modelData
                                    width: actionText.implicitWidth + 16
                                    height: 26
                                    radius: 4
                                    color: actionMouse.containsMouse
                                           ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                                           : Qt.rgba(Theme.surface3.r, Theme.surface3.g, Theme.surface3.b, 0.8)

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: modelData.text || ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontLabel
                                        color: Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelData.invoke();
                                            if (notif) notif.dismiss();
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
}
