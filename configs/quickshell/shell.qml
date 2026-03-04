import Quickshell
import Quickshell.Io
import QtQuick
import "bar" as Bar
import "launcher" as Launcher
import "notifications" as Notifications
import "powermenu" as PowerMenu
import "sidebar" as Sidebar
import "dock" as Dock
import "clipboard" as Clipboard
import "screenshot" as Screenshot
import "osd" as Osd

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

        function toggleGameMode(): void {
            ShellGlobals.toggleGameMode();
        }

        function showVolumeOsd(): void {
            osd.showVolume();
        }

        function showBrightnessOsd(): void {
            osd.showBrightness();
        }

        function toggleRecording(): void {
            ShellGlobals.toggleRecording();
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

    // Bottom dock
    Dock.Dock {
        id: dock
    }

    // Volume/Brightness OSD
    Osd.OsdPopup {
        id: osd
    }

    // Wallpaper crossfade overlay for scheme/wallpaper transitions
    SchemeTransition {
        id: schemeTransition
    }

    Connections {
        target: Theme
        function onSchemeTransitionRequested(oldWallpaper) {
            schemeTransition.start(oldWallpaper);
        }
    }
}
