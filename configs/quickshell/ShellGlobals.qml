pragma Singleton
import QtQuick

QtObject {
    property bool doNotDisturb: false

    // Notification history (capped at 50)
    property ListModel notificationHistory: ListModel {}

    function addNotificationToHistory(appName, summary, body, image) {
        notificationHistory.insert(0, {
            appName: appName || "Unknown",
            summary: summary || "",
            body: body || "",
            image: image ? image.toString() : "",
            timestamp: Date.now()
        });
        // Cap at 50 entries
        while (notificationHistory.count > 50) {
            notificationHistory.remove(notificationHistory.count - 1);
        }
    }

    function clearNotificationHistory() {
        notificationHistory.clear();
    }
}
