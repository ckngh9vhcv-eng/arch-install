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
            ShellGlobals.gameMode = !ShellGlobals.gameMode;
            if (ShellGlobals.gameMode) {
                gameModeOnProc.running = true;
            } else {
                gameModeOffProc.running = true;
            }
        }

        function showVolumeOsd(): void {
            osd.showVolume();
        }

        function showBrightnessOsd(): void {
            osd.showBrightness();
        }

        function toggleRecording(): void {
            ShellGlobals.recording = !ShellGlobals.recording;
            if (ShellGlobals.recording) {
                recordStartProc.running = true;
            } else {
                recordStopProc.running = true;
            }
        }
    }

    // Game mode processes
    Process {
        id: gameModeOnProc
        command: ["sh", "-c", "hyprctl keyword animations:enabled false && hyprctl keyword decoration:blur:enabled false && hyprctl keyword decoration:shadow:enabled false && hyprctl keyword decoration:dim_inactive false && hyprctl keyword decoration:rounding 0 && hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0"]
    }
    Process {
        id: gameModeOffProc
        command: ["sh", "-c", "hyprctl keyword animations:enabled true && hyprctl keyword decoration:blur:enabled true && hyprctl keyword decoration:shadow:enabled true && hyprctl keyword decoration:dim_inactive true && hyprctl keyword decoration:rounding 10 && hyprctl keyword general:gaps_in 5 && hyprctl keyword general:gaps_out 10"]
    }

    // Recording processes
    Process {
        id: recordStartProc
        command: ["sh", "-c", "mkdir -p ~/Videos/recordings && gpu-screen-recorder -w screen -f 60 -a default_output -o ~/Videos/recordings/recording_$(date +%Y%m%d_%H%M%S).mp4"]
    }
    Process {
        id: recordStopProc
        command: ["pkill", "-SIGINT", "gpu-screen-rec"]
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

    // Volume/Brightness OSD
    Osd.OsdPopup {
        id: osd
    }
}
