pragma Singleton
import QtQuick

QtObject {
    id: root

    // --- Mutable color properties (animated on scheme change) ---
    property color void_: "#06060C"
    property color surface0: "#0A0A14"
    property color surface1: "#10101E"
    property color surface2: "#181828"
    property color surface3: "#222236"

    property color accent: "#8B6FC0"
    property color accentDim: "#5C3F8F"
    property color accentBright: "#A88AE0"
    property color accentGlow: "#7C5CBF"

    property color textPrimary: "#E0D4F0"
    property color textSecondary: "#B8A0D6"
    property color textDim: "#7A6890"

    // Semantic (constant across schemes)
    readonly property color success: "#4ADE80"
    readonly property color warning: "#FBBF24"
    readonly property color danger: "#F87171"
    readonly property color info: "#60A5FA"

    // --- Typography ---
    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontLabel: 11
    readonly property int fontBody: 13
    readonly property int fontClock: 16
    readonly property int fontHeader: 22
    readonly property int fontTitle: 28

    // --- Geometry ---
    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int animDuration: 200

    // --- Scheme data ---
    property string currentScheme: "void-command"

    property var schemes: ({
        "void-command": {
            void_: "#06060C", surface0: "#0A0A14", surface1: "#10101E",
            surface2: "#181828", surface3: "#222236",
            accent: "#8B6FC0", accentDim: "#5C3F8F", accentBright: "#A88AE0", accentGlow: "#7C5CBF",
            textPrimary: "#E0D4F0", textSecondary: "#B8A0D6", textDim: "#7A6890"
        },
        "ember": {
            void_: "#0C0606", surface0: "#140A0A", surface1: "#1E1010",
            surface2: "#281818", surface3: "#362222",
            accent: "#C06F6F", accentDim: "#8F3F3F", accentBright: "#E08A8A", accentGlow: "#BF5C5C",
            textPrimary: "#F0D4D4", textSecondary: "#D6A0A0", textDim: "#906868"
        },
        "ocean": {
            void_: "#06090C", surface0: "#0A0E14", surface1: "#10161E",
            surface2: "#182028", surface3: "#222E36",
            accent: "#6F9DC0", accentDim: "#3F6F8F", accentBright: "#8AB8E0", accentGlow: "#5C8FBF",
            textPrimary: "#D4E4F0", textSecondary: "#A0BCD6", textDim: "#687A90"
        },
        "verdant": {
            void_: "#060C08", surface0: "#0A140D", surface1: "#101E15",
            surface2: "#182820", surface3: "#22362B",
            accent: "#6FC08B", accentDim: "#3F8F5C", accentBright: "#8AE0A8", accentGlow: "#5CBF7C",
            textPrimary: "#D4F0DF", textSecondary: "#A0D6B8", textDim: "#68907A"
        },
        "frost": {
            void_: "#060C0C", surface0: "#0A1414", surface1: "#101E1E",
            surface2: "#182828", surface3: "#223636",
            accent: "#6FC0C0", accentDim: "#3F8F8F", accentBright: "#8AE0E0", accentGlow: "#5CBFBF",
            textPrimary: "#D4F0F0", textSecondary: "#A0D6D6", textDim: "#689090"
        },
        "solar": {
            void_: "#0C0A06", surface0: "#140F0A", surface1: "#1E1810",
            surface2: "#282218", surface3: "#363022",
            accent: "#C0A86F", accentDim: "#8F7A3F", accentBright: "#E0C88A", accentGlow: "#BF9A5C",
            textPrimary: "#F0E8D4", textSecondary: "#D6C4A0", textDim: "#908068"
        },
        "nord": {
            void_: "#1a1e26", surface0: "#2E3440", surface1: "#3B4252",
            surface2: "#434C5E", surface3: "#4C566A",
            accent: "#88C0D0", accentDim: "#5E81AC", accentBright: "#8FBCBB", accentGlow: "#81A1C1",
            textPrimary: "#ECEFF4", textSecondary: "#D8DEE9", textDim: "#7B88A1"
        },
        "tokyo-night": {
            void_: "#16161e", surface0: "#1a1b26", surface1: "#1f2335",
            surface2: "#292e42", surface3: "#3b4261",
            accent: "#bb9af7", accentDim: "#9d7cd8", accentBright: "#c0caf5", accentGlow: "#7aa2f7",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textDim: "#565f89"
        }
    })

    readonly property var schemeNames: [
        "void-command", "ember", "ocean", "verdant",
        "frost", "solar", "nord", "tokyo-night"
    ]

    readonly property var schemeDisplayNames: ({
        "void-command": "Void Command",
        "ember": "Ember",
        "ocean": "Ocean",
        "verdant": "Verdant",
        "frost": "Frost",
        "solar": "Solar",
        "nord": "Nord",
        "tokyo-night": "Tokyo Night"
    })

    function applyScheme(name) {
        let s = schemes[name];
        if (!s) return;

        currentScheme = name;
        void_ = s.void_;
        surface0 = s.surface0;
        surface1 = s.surface1;
        surface2 = s.surface2;
        surface3 = s.surface3;
        accent = s.accent;
        accentDim = s.accentDim;
        accentBright = s.accentBright;
        accentGlow = s.accentGlow;
        textPrimary = s.textPrimary;
        textSecondary = s.textSecondary;
        textDim = s.textDim;
    }

    // Watch for theme changes from Quickshell
    property var _conn: Connections {
        target: ThemeWatcher
        function onSchemeChanged(scheme) {
            root.applyScheme(scheme);
        }
    }

    Component.onCompleted: {
        applyScheme(ThemeWatcher.currentScheme);
    }

    // --- Color animations ---
    Behavior on void_ { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on surface0 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on surface1 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on surface2 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on surface3 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on accent { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on accentDim { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on accentBright { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on accentGlow { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on textPrimary { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on textSecondary { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on textDim { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
}
