import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: transitionOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Below windows so apps aren't obscured, but covers hyprpaper restart
    aboveWindows: false
    exclusionMode: ExclusionMode.Ignore
    visible: false
    color: "transparent"

    property string oldWallpaper: ""
    property bool transitioning: false

    function start(wallpaperPath) {
        if (transitioning) {
            // Reset mid-transition: snap overlay back to opaque with new source
            fadeOut.stop();
            delayTimer.stop();
        }
        oldWallpaper = wallpaperPath;
        wallpaperImage.opacity = 1.0;
        visible = true;
        transitioning = true;
        delayTimer.start();
    }

    // Delay before fading out — gives hyprpaper time to restart underneath
    Timer {
        id: delayTimer
        interval: 800
        repeat: false
        onTriggered: fadeOut.start()
    }

    // Fade-out animation
    NumberAnimation {
        id: fadeOut
        target: wallpaperImage
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: 600
        easing.type: Easing.OutCubic
        onFinished: {
            transitionOverlay.visible = false;
            transitionOverlay.transitioning = false;
        }
    }

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: transitionOverlay.oldWallpaper ? "file://" + transitionOverlay.oldWallpaper : ""
        fillMode: Image.PreserveAspectCrop
        opacity: 1.0
    }
}
