pragma Singleton
import QtQuick

QtObject {
    // Void Command color palette
    readonly property color void_: "#06060C"
    readonly property color surface0: "#0A0A14"
    readonly property color surface1: "#10101E"
    readonly property color surface2: "#181828"
    readonly property color surface3: "#222236"
    readonly property color accent: "#8B6FC0"
    readonly property color accentDim: "#5C3F8F"
    readonly property color accentBright: "#A88AE0"
    readonly property color accentGlow: "#7C5CBF"
    readonly property color textPrimary: "#E0D4F0"
    readonly property color textSecondary: "#B8A0D6"
    readonly property color textDim: "#7A6890"
    readonly property color success: "#4ADE80"
    readonly property color warning: "#FBBF24"
    readonly property color danger: "#F87171"
    readonly property color info: "#60A5FA"

    // Typography
    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontLabel: 11
    readonly property int fontBody: 13
    readonly property int fontClock: 16
    readonly property int fontHeader: 22

    // Geometry
    readonly property int radiusPanel: 12
    readonly property int radiusPopup: 16
    readonly property int radiusInner: 8
    readonly property int blurRadius: 48

    // Animation
    readonly property int animDuration: 200
}
