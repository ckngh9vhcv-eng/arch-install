import Quickshell
import Quickshell.Io
import QtQuick
import "bar" as Bar
import "launcher" as Launcher
import "notifications" as Notifications
import "powermenu" as PowerMenu
import "sidebar" as Sidebar
import "clipboard" as Clipboard
import "screenshot" as Screenshot

ShellRoot {
    // IPC handler for keybind integration
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            launcher.toggle();
        }

        function togglePower(): void {
            powerMenu.toggle();
        }

        function toggleSidebar(): void {
            sidebar.toggle();
        }

        function toggleClipboard(): void {
            clipboardManager.toggle();
        }

        function toggleScreenshot(): void {
            screenshotTool.toggle();
        }

        function cycleWallpaper(): void {
            Theme.cycleWallpaper();
        }
    }

    // Status bar on every screen
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar.Bar {
                onPowerClicked: powerMenu.show()
            }
        }
    }

    // App launcher overlay
    Launcher.Launcher {
        id: launcher
    }

    // Notification server
    Notifications.NotificationPopup {}

    // Power menu overlay
    PowerMenu.PowerMenu {
        id: powerMenu
    }

    // Screenshot tool overlay
    Screenshot.ScreenshotTool {
        id: screenshotTool
    }

    // Clipboard manager overlay
    Clipboard.ClipboardManager {
        id: clipboardManager
    }

    // Sidebar dashboard
    Sidebar.Sidebar {
        id: sidebar
    }
}
