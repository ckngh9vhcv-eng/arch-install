pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Home directory (portable — no hardcoded paths)
    readonly property string homeDir: Quickshell.env("HOME")

    // --- Mutable color properties (defaults = Void Command) ---
    property color void_: "#06060C"
    Behavior on void_ { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color surface0: "#0A0A14"
    Behavior on surface0 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color surface1: "#10101E"
    Behavior on surface1 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color surface2: "#181828"
    Behavior on surface2 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color surface3: "#222236"
    Behavior on surface3 { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color accent: "#8B6FC0"
    Behavior on accent { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color accentDim: "#5C3F8F"
    Behavior on accentDim { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color accentBright: "#A88AE0"
    Behavior on accentBright { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color accentGlow: "#7C5CBF"
    Behavior on accentGlow { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color textPrimary: "#E0D4F0"
    Behavior on textPrimary { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color textSecondary: "#B8A0D6"
    Behavior on textSecondary { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color textDim: "#7A6890"
    Behavior on textDim { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    property color success: "#4ADE80"
    property color warning: "#FBBF24"
    property color danger: "#F87171"
    property color info: "#60A5FA"

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
    readonly property int glowSpread: 12
    readonly property real glowBaseOpacity: 0.08

    // Animation
    readonly property int animDuration: 200

    // --- Transition signal ---
    signal schemeTransitionRequested(string oldWallpaper)

    // --- Color scheme switching ---
    property string currentScheme: "void-command"
    property var currentWallpapers: []
    property int currentWallpaperIndex: 0
    property var wallpaperIndices: ({})
    property var _pendingWallpapers: []

    property var schemeNames: [
        "void-command", "ember", "ocean", "verdant",
        "frost", "solar", "nord", "tokyo-night", "auto"
    ]

    property var schemeDisplayNames: ({
        "void-command": "Void Command",
        "ember": "Ember",
        "ocean": "Ocean",
        "verdant": "Verdant",
        "frost": "Frost",
        "solar": "Solar",
        "nord": "Nord",
        "tokyo-night": "Tokyo Night",
        "auto": "Wallpaper (Auto)"
    })

    // Note: "auto" entry is a fallback — the real icon theme is selected
    // dynamically from the generated primary hue. See _iconThemeForHue().
    property var schemeIconThemes: ({
        "void-command": "Tela-circle-purple-dark",
        "ember": "Tela-circle-red-dark",
        "ocean": "Tela-circle-blue-dark",
        "verdant": "Tela-circle-green-dark",
        "frost": "Tela-circle-grey-dark",
        "solar": "Tela-circle-orange-dark",
        "nord": "Tela-circle-nord-dark",
        "tokyo-night": "Tela-circle-dracula-dark",
        "auto": "Tela-circle-grey-dark"
    })

    property var schemes: ({
        "void-command": {
            void_: "#06060C", surface0: "#0A0A14", surface1: "#10101E",
            surface2: "#181828", surface3: "#222236",
            accent: "#8B6FC0", accentDim: "#5C3F8F", accentBright: "#A88AE0", accentGlow: "#7C5CBF",
            textPrimary: "#E0D4F0", textSecondary: "#B8A0D6", textDim: "#7A6890",
            wallpaper: "void-command.png",
            selectionBg: "#2A1F3D",
            ansi: {
                color0: "#06060C", color8: "#2A1F3D",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#B8A0D6", color15: "#E0D4F0"
            },
            qtHighlight: "#5c478c",
            starship: {
                g1: "#1E1529", g2: "#2D2040", g3: "#3D2B5A",
                g4: "#7C5CBF", g5: "#503D6B", g6: "#3B2D50",
                fg1: "#B8A0D6", fg2: "#D4C4E9", fgDark: "#1E1529"
            }
        },
        "ember": {
            void_: "#0C0606", surface0: "#140A0A", surface1: "#1E1010",
            surface2: "#281818", surface3: "#362222",
            accent: "#C06F6F", accentDim: "#8F3F3F", accentBright: "#E08A8A", accentGlow: "#BF5C5C",
            textPrimary: "#F0D4D4", textSecondary: "#D6A0A0", textDim: "#906868",
            wallpaper: "ember.png",
            selectionBg: "#3D1F1F",
            ansi: {
                color0: "#0C0606", color8: "#3D1F1F",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#C06F6F", color13: "#D6A0A0",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#D6A0A0", color15: "#F0D4D4"
            },
            qtHighlight: "#8c4747",
            starship: {
                g1: "#291515", g2: "#402020", g3: "#5A2B2B",
                g4: "#BF5C5C", g5: "#6B3D3D", g6: "#502D2D",
                fg1: "#D6A0A0", fg2: "#E9C4C4", fgDark: "#291515"
            }
        },
        "ocean": {
            void_: "#06090C", surface0: "#0A0E14", surface1: "#10161E",
            surface2: "#182028", surface3: "#222E36",
            accent: "#6F9DC0", accentDim: "#3F6F8F", accentBright: "#8AB8E0", accentGlow: "#5C8FBF",
            textPrimary: "#D4E4F0", textSecondary: "#A0BCD6", textDim: "#687A90",
            wallpaper: "ocean.jpg",
            selectionBg: "#1F2D3D",
            ansi: {
                color0: "#06090C", color8: "#1F2D3D",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6F9DC0", color12: "#8AB8E0",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#A0BCD6", color15: "#D4E4F0"
            },
            qtHighlight: "#47708c",
            starship: {
                g1: "#152029", g2: "#203040", g3: "#2B405A",
                g4: "#5C8FBF", g5: "#3D566B", g6: "#2D4050",
                fg1: "#A0BCD6", fg2: "#C4D8E9", fgDark: "#152029"
            }
        },
        "verdant": {
            void_: "#060C08", surface0: "#0A140D", surface1: "#101E15",
            surface2: "#182820", surface3: "#22362B",
            accent: "#6FC08B", accentDim: "#3F8F5C", accentBright: "#8AE0A8", accentGlow: "#5CBF7C",
            textPrimary: "#D4F0DF", textSecondary: "#A0D6B8", textDim: "#68907A",
            wallpaper: "verdant.png",
            selectionBg: "#1F3D2A",
            ansi: {
                color0: "#060C08", color8: "#1F3D2A",
                color1: "#CC4444", color9: "#E06666",
                color2: "#6FC08B", color10: "#8AE0A8",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#A0D6B8", color15: "#D4F0DF"
            },
            qtHighlight: "#478c5c",
            starship: {
                g1: "#152920", g2: "#204030", g3: "#2B5A40",
                g4: "#5CBF7C", g5: "#3D6B50", g6: "#2D5040",
                fg1: "#A0D6B8", fg2: "#C4E9D4", fgDark: "#152920"
            }
        },
        "frost": {
            void_: "#060C0C", surface0: "#0A1414", surface1: "#101E1E",
            surface2: "#182828", surface3: "#223636",
            accent: "#6FC0C0", accentDim: "#3F8F8F", accentBright: "#8AE0E0", accentGlow: "#5CBFBF",
            textPrimary: "#D4F0F0", textSecondary: "#A0D6D6", textDim: "#689090",
            wallpaper: "frost.png",
            selectionBg: "#1F3D3D",
            ansi: {
                color0: "#060C0C", color8: "#1F3D3D",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#6FC0C0", color14: "#8AE0E0",
                color7: "#A0D6D6", color15: "#D4F0F0"
            },
            qtHighlight: "#478c8c",
            starship: {
                g1: "#152929", g2: "#204040", g3: "#2B5A5A",
                g4: "#5CBFBF", g5: "#3D6B6B", g6: "#2D5050",
                fg1: "#A0D6D6", fg2: "#C4E9E9", fgDark: "#152929"
            }
        },
        "solar": {
            void_: "#0C0A06", surface0: "#140F0A", surface1: "#1E1810",
            surface2: "#282218", surface3: "#363022",
            accent: "#C0A86F", accentDim: "#8F7A3F", accentBright: "#E0C88A", accentGlow: "#BF9A5C",
            textPrimary: "#F0E8D4", textSecondary: "#D6C4A0", textDim: "#908068",
            wallpaper: "solar.jpg",
            selectionBg: "#3D351F",
            ansi: {
                color0: "#0C0A06", color8: "#3D351F",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#C0A86F", color11: "#E0C88A",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#D6C4A0", color15: "#F0E8D4"
            },
            qtHighlight: "#8c7a47",
            starship: {
                g1: "#292015", g2: "#403520", g3: "#5A4A2B",
                g4: "#BF9A5C", g5: "#6B5A3D", g6: "#50452D",
                fg1: "#D6C4A0", fg2: "#E9DCC4", fgDark: "#292015"
            }
        },
        "nord": {
            void_: "#1a1e26", surface0: "#2E3440", surface1: "#3B4252",
            surface2: "#434C5E", surface3: "#4C566A",
            accent: "#88C0D0", accentDim: "#5E81AC", accentBright: "#8FBCBB", accentGlow: "#81A1C1",
            textPrimary: "#ECEFF4", textSecondary: "#D8DEE9", textDim: "#7B88A1",
            wallpaper: "nord.jpg",
            selectionBg: "#3B4252",
            ansi: {
                color0: "#2E3440", color8: "#4C566A",
                color1: "#BF616A", color9: "#D08770",
                color2: "#A3BE8C", color10: "#A3BE8C",
                color3: "#EBCB8B", color11: "#EBCB8B",
                color4: "#5E81AC", color12: "#81A1C1",
                color5: "#B48EAD", color13: "#B48EAD",
                color6: "#88C0D0", color14: "#8FBCBB",
                color7: "#D8DEE9", color15: "#ECEFF4"
            },
            qtHighlight: "#5e81ac",
            starship: {
                g1: "#242933", g2: "#2E3440", g3: "#3B4252",
                g4: "#81A1C1", g5: "#4C566A", g6: "#3B4252",
                fg1: "#D8DEE9", fg2: "#ECEFF4", fgDark: "#2E3440"
            }
        },
        "tokyo-night": {
            void_: "#16161e", surface0: "#1a1b26", surface1: "#1f2335",
            surface2: "#292e42", surface3: "#3b4261",
            accent: "#bb9af7", accentDim: "#9d7cd8", accentBright: "#c0caf5", accentGlow: "#7aa2f7",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textDim: "#565f89",
            wallpaper: "tokyo-night.jpg",
            selectionBg: "#33467c",
            ansi: {
                color0: "#1a1b26", color8: "#414868",
                color1: "#f7768e", color9: "#f7768e",
                color2: "#9ece6a", color10: "#9ece6a",
                color3: "#e0af68", color11: "#e0af68",
                color4: "#7aa2f7", color12: "#7aa2f7",
                color5: "#bb9af7", color13: "#bb9af7",
                color6: "#7dcfff", color14: "#7dcfff",
                color7: "#a9b1d6", color15: "#c0caf5"
            },
            qtHighlight: "#9d7cd8",
            starship: {
                g1: "#16161e", g2: "#1a1b26", g3: "#292e42",
                g4: "#7aa2f7", g5: "#3b4261", g6: "#292e42",
                fg1: "#a9b1d6", fg2: "#c0caf5", fgDark: "#1a1b26"
            }
        },
        // Auto scheme — populated by matugen from the current wallpaper.
        // The values below are a neutral Void Command-like fallback that only
        // shows up before the first matugen run (cold start, no cache).
        "auto": {
            void_: "#06060C", surface0: "#0A0A14", surface1: "#10101E",
            surface2: "#181828", surface3: "#222236",
            accent: "#8B6FC0", accentDim: "#5C3F8F", accentBright: "#A88AE0", accentGlow: "#7C5CBF",
            textPrimary: "#E0D4F0", textSecondary: "#B8A0D6", textDim: "#7A6890",
            wallpaper: "auto/_test.png",
            selectionBg: "#2A1F3D",
            ansi: {
                color0: "#06060C", color8: "#2A1F3D",
                color1: "#CC4444", color9: "#E06666",
                color2: "#44AA77", color10: "#66CC99",
                color3: "#CCAA44", color11: "#EEBB66",
                color4: "#6688CC", color12: "#88AAEE",
                color5: "#8B6FC0", color13: "#B8A0D6",
                color6: "#44AAAA", color14: "#66CCCC",
                color7: "#B8A0D6", color15: "#E0D4F0"
            },
            qtHighlight: "#5c478c",
            starship: {
                g1: "#1E1529", g2: "#2D2040", g3: "#3D2B5A",
                g4: "#7C5CBF", g5: "#503D6B", g6: "#3B2D50",
                fg1: "#B8A0D6", fg2: "#D4C4E9", fgDark: "#1E1529"
            }
        }
    })

    // --- Persistence ---
    property var schemeFileView: FileView {
        path: root.homeDir + "/.local/share/quickshell/color-scheme.json"
        atomicWrites: true
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try {
                    var data = JSON.parse(content);
                    if (data.wallpaperIndices) {
                        root.wallpaperIndices = data.wallpaperIndices;
                    }
                    if (data.scheme && root.schemes[data.scheme]) {
                        root.applyScheme(data.scheme, true);
                        return;
                    }
                } catch (e) {}
            }
            root.applyScheme("void-command", true);
        }
    }

    function saveScheme() {
        schemeFileView.setText(JSON.stringify({
            scheme: currentScheme,
            wallpaperIndices: wallpaperIndices
        }, null, 2));
    }

    // --- App config FileViews ---
    property var gtkCss3FileView: FileView {
        path: root.homeDir + "/.config/gtk-3.0/gtk.css"
        atomicWrites: true
    }
    property var gtkCss4FileView: FileView {
        path: root.homeDir + "/.config/gtk-4.0/gtk.css"
        atomicWrites: true
    }
    property var kittyFileView: FileView {
        path: root.homeDir + "/.config/kitty/kitty.conf"
        atomicWrites: true
    }
    property var hyprlockFileView: FileView {
        path: root.homeDir + "/.config/hypr/hyprlock.conf"
        atomicWrites: true
    }
    property var hyprpaperFileView: FileView {
        path: root.homeDir + "/.config/hypr/hyprpaper.conf"
        atomicWrites: true
    }
    property var starshipFileView: FileView {
        path: root.homeDir + "/.config/starship.toml"
        atomicWrites: true
    }
    property var qt6ctFileView: FileView {
        path: root.homeDir + "/.config/qt6ct/colors/VoidCommand.conf"
        atomicWrites: true
    }
    property var fastfetchFileView: FileView {
        path: root.homeDir + "/.config/fastfetch/config.jsonc"
        atomicWrites: true
    }
    property var vesktopCssFileView: FileView {
        path: root.homeDir + "/.config/vesktop/settings/quickCss.css"
        atomicWrites: true
    }

    // --- Processes for live reload ---
    property var kittyReloadProc: Process {
        command: ["sh", "-c", "kill -SIGUSR1 $(pgrep kitty) 2>/dev/null"]
    }
    property var hyprpaperRestartProc: Process {
        command: ["sh", "-c", "killall hyprpaper 2>/dev/null; sleep 0.3; setsid -f hyprpaper </dev/null >/dev/null 2>&1"]
    }
    property var hyprBorderProc: Process {
        // command set dynamically in updateAppConfigs
    }
    property var iconThemeProc: Process {
        // command set dynamically in updateAppConfigs
    }

    // --- Matugen (dynamic wallpaper-based palette) ---
    property string _matugenStdout: ""
    property string _pendingAutoWallpaperFile: ""
    property var _matugenCache: ({})

    property var matugenProc: Process {
        // command set dynamically in _runMatugen()
        stdout: SplitParser {
            onRead: data => { root._matugenStdout += data }
        }
        onExited: (code, status) => {
            if (code !== 0 || root._matugenStdout.length === 0) {
                console.warn("matugen failed (code=" + code + "), keeping previous palette");
                root._matugenStdout = "";
                return;
            }
            try {
                var mtg = JSON.parse(root._matugenStdout);
                var wpFile = root._pendingAutoWallpaperFile;
                var scheme = root._buildSchemeFromMatugen(mtg, wpFile);
                root._matugenCache[wpFile] = scheme;
                root._persistMatugenCache();
                root._applyAutoScheme(scheme, wpFile);
            } catch (e) {
                console.warn("matugen JSON parse failed: " + e);
            }
            root._matugenStdout = "";
        }
    }

    property var matugenCacheFileView: FileView {
        path: root.homeDir + "/.cache/void-command/matugen-cache.json"
        atomicWrites: true
        onLoaded: {
            var content = text();
            if (content && content.length > 0) {
                try { root._matugenCache = JSON.parse(content); } catch (e) {}
            }
        }
    }

    // --- Wallpaper discovery ---
    property var wallpaperDiscoverProc: Process {
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.length > 0) {
                    // Auto wallpapers live in a subfolder; preserve the
                    // "auto/" prefix so path composition works downstream.
                    if (line.indexOf("auto/") === 0) {
                        root._pendingWallpapers.push(line);
                    } else {
                        var parts = line.split("/");
                        root._pendingWallpapers.push(parts[parts.length - 1]);
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            var files = root._pendingWallpapers;
            if (files.length === 0) {
                var s = root.schemes[root.currentScheme];
                if (s) {
                    root.currentWallpapers = [s.wallpaper];
                    root.currentWallpaperIndex = 0;
                }
            } else {
                files.sort((a, b) => root._wallpaperSortKey(a) - root._wallpaperSortKey(b));
                root.currentWallpapers = files;
                var idx = root.wallpaperIndices[root.currentScheme] || 0;
                if (idx >= files.length) idx = 0;
                root.currentWallpaperIndex = idx;
            }
            root._applyCurrentWallpaper();
        }
    }

    function discoverWallpapers(schemeName) {
        wallpaperDiscoverProc.running = false;
        root._pendingWallpapers = [];
        var dir = root.homeDir + "/wallpapers/";
        if (schemeName === "auto") {
            // Auto scheme: list every image in ~/wallpapers/auto/ and store
            // entries as "auto/<filename>" so path composition downstream
            // (hyprpaper/hyprlock) works unchanged.
            wallpaperDiscoverProc.command = ["sh", "-c",
                "cd " + dir + " 2>/dev/null && " +
                "ls -1 auto/*.png auto/*.jpg auto/*.jpeg auto/*.webp 2>/dev/null | sort"
            ];
        } else {
            wallpaperDiscoverProc.command = ["sh", "-c",
                "ls -1 " + dir + schemeName + ".png " +
                dir + schemeName + ".jpg " +
                dir + schemeName + "-[0-9]*.png " +
                dir + schemeName + "-[0-9]*.jpg 2>/dev/null"
            ];
        }
        wallpaperDiscoverProc.running = true;
    }

    function _applyCurrentWallpaper() {
        if (root.currentWallpapers.length === 0) return;
        var wallpaperFile = root.currentWallpapers[root.currentWallpaperIndex];

        if (root.currentScheme === "auto") {
            // Auto scheme: generate (or recall from cache) the palette, then
            // apply colors and write all downstream configs in one coherent pass.
            var cached = root._matugenCache[wallpaperFile];
            if (cached) {
                root._applyAutoScheme(cached, wallpaperFile);
            } else {
                root._runMatugen(wallpaperFile);
            }
            return;
        }

        var s = root.schemes[root.currentScheme];
        if (!s) return;
        hyprpaperFileView.setText(generateHyprpaperConf(wallpaperFile));
        hyprlockFileView.setText(generateHyprlockConf(s, wallpaperFile));
        hyprpaperRestartProc.running = true;
    }

    function cycleWallpaper() {
        if (root.currentWallpapers.length <= 1) return;
        // Emit transition signal with current wallpaper before cycling
        var oldWp = root.homeDir + "/wallpapers/" + root.currentWallpapers[root.currentWallpaperIndex];
        schemeTransitionRequested(oldWp);
        root.currentWallpaperIndex = (root.currentWallpaperIndex + 1) % root.currentWallpapers.length;
        var indices = root.wallpaperIndices;
        indices[root.currentScheme] = root.currentWallpaperIndex;
        root.wallpaperIndices = indices;
        saveScheme();
        _applyCurrentWallpaper();
    }

    function _wallpaperSortKey(filename) {
        var base = filename.replace(/\.[^.]+$/, "");
        if (base === root.currentScheme) return 0;
        var suffix = base.substring(root.currentScheme.length);
        var match = suffix.match(/^-(\d+)$/);
        return match ? parseInt(match[1]) : 0;
    }

    // --- Apply scheme ---
    function applyScheme(name, skipSave) {
        var s = schemes[name];
        if (!s) return;

        // Emit transition signal with current wallpaper before changing anything
        if (!skipSave && root.currentWallpapers.length > 0) {
            var oldWp = root.homeDir + "/wallpapers/" + root.currentWallpapers[root.currentWallpaperIndex];
            schemeTransitionRequested(oldWp);
        }

        currentScheme = name;

        // Auto scheme short-circuit: don't apply static placeholder colors or
        // generate configs here — wait until matugen (or the cache) provides
        // the real palette in _applyCurrentWallpaper()/_applyAutoScheme().
        if (name === "auto") {
            if (!skipSave) saveScheme();
            discoverWallpapers(name);
            return;
        }

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

        if (!skipSave) {
            saveScheme();
        }

        updateAppConfigs(s);
        discoverWallpapers(name);
    }

    // --- Update external app configs ---
    function updateAppConfigs(s) {
        gtkCss3FileView.setText(generateGtkCss(3, s));
        gtkCss4FileView.setText(generateGtkCss(4, s));
        kittyFileView.setText(generateKittyConf(s));
        starshipFileView.setText(generateStarshipToml(s));
        qt6ctFileView.setText(generateQt6ctColors(s));
        fastfetchFileView.setText(generateFastfetchConfig(s));
        vesktopCssFileView.setText(generateVesktopCss(s));

        // Kitty live reload
        kittyReloadProc.running = true;

        // Hyprland border colors
        hyprBorderProc.command = ["sh", "-c",
            "hyprctl keyword general:col.active_border 'rgb(" + s.accent.substring(1) + ")' && " +
            "hyprctl keyword general:col.inactive_border 'rgb(" + s.surface1.substring(1) + ")'"
        ];
        hyprBorderProc.running = true;

        // Icon theme
        var iconTheme = root.schemeIconThemes[root.currentScheme] || "Tela-circle-purple-dark";
        iconThemeProc.command = ["sh", "-c",
            "gsettings set org.gnome.desktop.interface icon-theme '" + iconTheme + "' && " +
            "sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=" + iconTheme + "/' ~/.config/gtk-3.0/settings.ini"
        ];
        iconThemeProc.running = true;
    }

    // --- Matugen: dynamic palette generation from wallpaper ---

    // Spawn matugen and stream its JSON output into _matugenStdout.
    // Uses: scheme-vibrant (punchy accents), --prefer saturation (pick the
    // most vivid source color), --contrast 0.3 (slightly crisper text),
    // --dry-run (no side effects — we consume JSON only).
    function _runMatugen(wallpaperFile) {
        var wp = root.homeDir + "/wallpapers/" + wallpaperFile;
        root._matugenStdout = "";
        root._pendingAutoWallpaperFile = wallpaperFile;
        matugenProc.running = false;
        matugenProc.command = ["sh", "-c",
            "matugen image '" + wp + "' --json hex --mode dark " +
            "--dry-run --quiet --prefer saturation --type scheme-vibrant " +
            "--contrast 0.3 | tr -d '\\n'"
        ];
        matugenProc.running = true;
    }

    // Apply a generated auto scheme: replace schemes.auto, animate color
    // properties, regenerate all downstream configs, write hyprpaper/hyprlock,
    // and hue-match the icon theme.
    function _applyAutoScheme(scheme, wallpaperFile) {
        // Stash in the schemes map so persistence + general code paths work.
        var schemesCopy = root.schemes;
        schemesCopy["auto"] = scheme;
        root.schemes = schemesCopy;

        // Animated color properties (Behavior on color handles the fade).
        root.void_ = scheme.void_;
        root.surface0 = scheme.surface0;
        root.surface1 = scheme.surface1;
        root.surface2 = scheme.surface2;
        root.surface3 = scheme.surface3;
        root.accent = scheme.accent;
        root.accentDim = scheme.accentDim;
        root.accentBright = scheme.accentBright;
        root.accentGlow = scheme.accentGlow;
        root.textPrimary = scheme.textPrimary;
        root.textSecondary = scheme.textSecondary;
        root.textDim = scheme.textDim;

        // Hue-match the icon theme based on generated primary.
        var iconTheme = root._iconThemeForColor(scheme.accent);
        var iconThemes = root.schemeIconThemes;
        iconThemes["auto"] = iconTheme;
        root.schemeIconThemes = iconThemes;

        updateAppConfigs(scheme);
        hyprpaperFileView.setText(generateHyprpaperConf(wallpaperFile));
        hyprlockFileView.setText(generateHyprlockConf(scheme, wallpaperFile));
        hyprpaperRestartProc.running = true;
    }

    // Persist the matugen palette cache to ~/.cache/void-command/.
    function _persistMatugenCache() {
        matugenCacheFileView.setText(JSON.stringify(root._matugenCache, null, 2));
    }

    // Build a full Void Command scheme object from a matugen JSON payload.
    // Maps M3 roles → VC slots with an eye toward the deep-black aesthetic.
    function _buildSchemeFromMatugen(mtg, wallpaperFile) {
        var c = mtg.colors;
        var p = mtg.palettes;
        function role(name) { return c[name].dark.color; }
        function tone(palette, t) { return p[palette][String(t)].color; }

        // Surface ladder — pull from M3 container tones. The deepest "void_"
        // slot uses neutral tone 5 (near-black with wallpaper-tinted hue) to
        // preserve the signature black-black backdrop under every palette.
        var void_ = tone("neutral", 5);
        var surface0 = role("surface_container_lowest");
        var surface1 = role("surface_container_low");
        var surface2 = role("surface_container");
        var surface3 = role("surface_container_high");

        // Accent family from the primary palette's tonal ladder.
        // tone 90 ≈ bright, tone 70 ≈ glow, tone 40 ≈ dim.
        var accent = role("primary");                   // M3-clamped for dark mode
        var accentDim = tone("primary", 40);
        var accentBright = tone("primary", 90);
        var accentGlow = tone("primary", 70);

        // Text ladder from M3 semantic on_surface roles.
        var textPrimary = role("on_surface");
        var textSecondary = role("on_surface_variant");
        var textDim = role("outline");

        // Selection bg: primary container — keeps the accent feel on selected text.
        var selectionBg = role("primary_container");

        // Qt highlight: a slightly-darker accent for button highlights.
        var qtHighlight = tone("primary", 35);

        // Harmonized ANSI: use M3 semantic palettes where they exist (error for
        // red, primary for magenta, tertiary for cyan) and pick fixed-hue
        // anchors from matched tones for green/yellow/blue so terminal output
        // stays legible regardless of wallpaper hue.
        var ansi = root._harmonizedAnsi(mtg);

        // Starship gradient: walk up the primary tonal ladder for a smooth
        // left-to-right color gradient in the prompt segments.
        var starship = {
            g1: tone("neutral", 10),
            g2: tone("primary", 15),
            g3: tone("primary", 25),
            g4: tone("primary", 50),
            g5: tone("primary", 30),
            g6: tone("primary", 20),
            fg1: role("on_surface_variant"),
            fg2: role("on_surface"),
            fgDark: tone("neutral", 10)
        };

        return {
            void_: void_,
            surface0: surface0,
            surface1: surface1,
            surface2: surface2,
            surface3: surface3,
            accent: accent,
            accentDim: accentDim,
            accentBright: accentBright,
            accentGlow: accentGlow,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textDim: textDim,
            wallpaper: wallpaperFile,
            selectionBg: selectionBg,
            ansi: ansi,
            qtHighlight: qtHighlight,
            starship: starship
        };
    }

    // Harmonized ANSI derivation.
    //
    // Strategy: use M3's semantic palettes for the slots that match (error →
    // red, primary → magenta, tertiary → cyan) and derive green/yellow/blue
    // from the primary palette's saturation/lightness profile at fixed hue
    // anchors. This keeps terminal output legible under any wallpaper while
    // harmonizing saturation across all 16 slots.
    function _harmonizedAnsi(mtg) {
        var c = mtg.colors;
        var p = mtg.palettes;
        function role(name) { return c[name].dark.color; }
        function tone(pal, t) { return p[pal][String(t)].color; }

        // Profile the primary at tone 70 to lift saturation/lightness for derived hues.
        var primaryMid = tone("primary", 70);
        var prof = root._hexToHsl(primaryMid);
        // Clamp S/L into a readable band so the derived colors don't fight the surface.
        var sNorm = Math.max(0.55, Math.min(0.80, prof[1]));
        var lNorm = Math.max(0.60, Math.min(0.72, prof[2]));
        var sBright = Math.min(0.88, sNorm + 0.08);
        var lBright = Math.min(0.80, lNorm + 0.08);

        function hue(deg, bright) {
            return root._hslToHex(deg, bright ? sBright : sNorm, bright ? lBright : lNorm);
        }

        return {
            // Blacks
            color0: role("surface"),
            color8: role("surface_container_high"),
            // Reds — M3 error (calibrated for dark mode contrast)
            color1: tone("error", 50),
            color9: role("error"),
            // Greens — fixed hue 140°, primary profile
            color2: hue(140, false),
            color10: hue(140, true),
            // Yellows — fixed hue 48°
            color3: hue(48, false),
            color11: hue(48, true),
            // Blues — fixed hue 212°
            color4: hue(212, false),
            color12: hue(212, true),
            // Magenta — the main accent
            color5: role("primary"),
            color13: tone("primary", 80),
            // Cyans — from tertiary
            color6: role("tertiary"),
            color14: tone("tertiary", 80),
            // Whites
            color7: role("on_surface_variant"),
            color15: role("on_surface")
        };
    }

    // Hex (#rrggbb) → [h (0-360), s (0-1), l (0-1)]
    function _hexToHsl(hex) {
        var r = parseInt(hex.substring(1, 3), 16) / 255;
        var g = parseInt(hex.substring(3, 5), 16) / 255;
        var b = parseInt(hex.substring(5, 7), 16) / 255;
        var max = Math.max(r, g, b), min = Math.min(r, g, b);
        var h = 0, s = 0, l = (max + min) / 2;
        if (max !== min) {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h *= 60;
        }
        return [h, s, l];
    }

    // HSL → hex (#rrggbb)
    function _hslToHex(h, s, l) {
        h = ((h % 360) + 360) % 360 / 360;
        s = Math.max(0, Math.min(1, s));
        l = Math.max(0, Math.min(1, l));
        function hue2rgb(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        }
        var r, g, b;
        if (s === 0) {
            r = g = b = l;
        } else {
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var pp = 2 * l - q;
            r = hue2rgb(pp, q, h + 1/3);
            g = hue2rgb(pp, q, h);
            b = hue2rgb(pp, q, h - 1/3);
        }
        function toHex(x) {
            var v = Math.round(x * 255).toString(16);
            return v.length === 1 ? "0" + v : v;
        }
        return "#" + toHex(r) + toHex(g) + toHex(b);
    }

    // Map a generated primary color to the nearest Tela-circle-<color>-dark
    // icon theme by hue angle (with a grey fallback for desaturated colors).
    function _iconThemeForColor(hex) {
        var hsl = root._hexToHsl(hex);
        var h = hsl[0], s = hsl[1];
        if (s < 0.15) return "Tela-circle-grey-dark";
        if (h < 20 || h >= 340) return "Tela-circle-red-dark";
        if (h < 45)  return "Tela-circle-orange-dark";
        if (h < 70)  return "Tela-circle-yellow-dark";
        if (h < 165) return "Tela-circle-green-dark";
        if (h < 200) return "Tela-circle-nord-dark";   // teal/cyan range
        if (h < 255) return "Tela-circle-blue-dark";
        if (h < 305) return "Tela-circle-purple-dark";
        return "Tela-circle-pink-dark";
    }

    // --- Config generators ---

    function generateKittyConf(s) {
        var a = s.ansi;
        return "font_family      FiraCode Nerd Font\n\
font_size        12\n\
scrollback_lines 10000\n\
enable_audio_bell false\n\
window_padding_width 4\n\
confirm_os_window_close 0\n\
background_opacity 0.85\n\
\n\
# Color scheme\n\
background  " + s.void_ + "\n\
foreground  " + s.textPrimary + "\n\
cursor      " + s.accent + "\n\
cursor_text_color " + s.void_ + "\n\
selection_background " + s.selectionBg + "\n\
selection_foreground " + s.textPrimary + "\n\
url_color   " + s.accent + "\n\
\n\
# Tab bar\n\
tab_bar_style powerline\n\
active_tab_background " + s.accent + "\n\
active_tab_foreground " + s.void_ + "\n\
inactive_tab_background " + s.surface1 + "\n\
inactive_tab_foreground " + s.textSecondary + "\n\
\n\
# ANSI colors\n\
color0  " + a.color0 + "\n\
color8  " + a.color8 + "\n\
color1  " + a.color1 + "\n\
color9  " + a.color9 + "\n\
color2  " + a.color2 + "\n\
color10 " + a.color10 + "\n\
color3  " + a.color3 + "\n\
color11 " + a.color11 + "\n\
color4  " + a.color4 + "\n\
color12 " + a.color12 + "\n\
color5  " + a.color5 + "\n\
color13 " + a.color13 + "\n\
color6  " + a.color6 + "\n\
color14 " + a.color14 + "\n\
color7  " + a.color7 + "\n\
color15 " + a.color15 + "\n";
    }

    function generateHyprlockConf(s, wallpaperFile) {
        function toRgba(hex, alpha) {
            var r = parseInt(hex.substring(1,3), 16);
            var g = parseInt(hex.substring(3,5), 16);
            var b = parseInt(hex.substring(5,7), 16);
            return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
        }
        var wp = root.homeDir + "/wallpapers/" + wallpaperFile;
        return "background {\n\
    monitor =\n\
    path = " + wp + "\n\
    blur_passes = 4\n\
    blur_size = 5\n\
    brightness = 0.85\n\
    contrast = 0.95\n\
}\n\
\n\
# Clock\n\
label {\n\
    monitor =\n\
    text = cmd[update:1000] echo \"$(date +%H:%M)\"\n\
    font_size = 80\n\
    font_family = FiraCode Nerd Font\n\
    color = " + toRgba(s.textPrimary, "1.0") + "\n\
    position = 0, 200\n\
    halign = center\n\
    valign = center\n\
}\n\
\n\
# Date\n\
label {\n\
    monitor =\n\
    text = cmd[update:60000] echo \"$(date '+%A, %B %d')\"\n\
    font_size = 18\n\
    font_family = FiraCode Nerd Font\n\
    color = " + toRgba(s.textSecondary, "1.0") + "\n\
    position = 0, 130\n\
    halign = center\n\
    valign = center\n\
}\n\
\n\
# Password input\n\
input-field {\n\
    monitor =\n\
    size = 300, 50\n\
    outline_thickness = 2\n\
    dots_size = 0.25\n\
    dots_spacing = 0.3\n\
    dots_center = true\n\
    dots_rounding = -1\n\
    outer_color = " + toRgba(s.accent, "0.6") + "\n\
    inner_color = " + toRgba(s.surface1, "0.85") + "\n\
    font_color = " + toRgba(s.textPrimary, "1.0") + "\n\
    fade_on_empty = true\n\
    placeholder_text = <i>Enter password...</i>\n\
    hide_input = false\n\
    rounding = 12\n\
    check_color = " + toRgba(s.accent, "1.0") + "\n\
    fail_color = rgba(204, 34, 34, 0.8)\n\
    fail_text = <i>Authentication failed</i>\n\
    position = 0, -20\n\
    halign = center\n\
    valign = center\n\
}\n";
    }

    function generateHyprpaperConf(wallpaperFile) {
        var wp = root.homeDir + "/wallpapers/" + wallpaperFile;
        return "wallpaper {\n\
    monitor =\n\
    path = " + wp + "\n\
    fit_mode = cover\n\
}\n\
splash = false\n";
    }

    function generateStarshipToml(s) {
        var st = s.starship;
        return 'command_timeout = 5000\n\
\n\
format = """[](#' + st.g1.substring(1) + ')\\\n\
$python\\\n\
$username\\\n\
[](bg:#' + st.g2.substring(1) + ' fg:#' + st.g1.substring(1) + ')\\\n\
$directory\\\n\
[](fg:#' + st.g2.substring(1) + ' bg:#' + st.g3.substring(1) + ')\\\n\
$git_branch\\\n\
$git_status\\\n\
[](fg:#' + st.g3.substring(1) + ' bg:#' + st.g4.substring(1) + ')\\\n\
$c\\\n\
$golang\\\n\
$nodejs\\\n\
$rust\\\n\
$nix_shell\\\n\
[](fg:#' + st.g4.substring(1) + ' bg:#' + st.g5.substring(1) + ')\\\n\
$docker_context\\\n\
[](fg:#' + st.g5.substring(1) + ' bg:#' + st.g6.substring(1) + ')\\\n\
$cmd_duration\\\n\
$time\\\n\
[ ](fg:#' + st.g6.substring(1) + ')"""\n\
\n\
[username]\n\
show_always = true\n\
style_user = "bg:#' + st.g1.substring(1) + ' fg:#' + st.fg1.substring(1) + '"\n\
style_root = "bg:#' + st.g1.substring(1) + ' fg:#FF6B6B"\n\
format = "[ $user ]($style)"\n\
\n\
[directory]\n\
style = "bg:#' + st.g2.substring(1) + ' fg:#' + st.fg2.substring(1) + '"\n\
format = "[ $path ]($style)"\n\
truncation_length = 3\n\
truncation_symbol = ".../"\n\
\n\
[directory.substitutions]\n\
Documents = "\u{f0219} "\n\
Downloads = "\u{f01da} "\n\
Music = "\u{f075a} "\n\
Pictures = "\u{f021f} "\n\
\n\
[git_branch]\n\
symbol = ""\n\
style = "bg:#' + st.g3.substring(1) + ' fg:#' + st.fg2.substring(1) + '"\n\
format = "[ $symbol $branch ]($style)"\n\
\n\
[git_status]\n\
style = "bg:#' + st.g3.substring(1) + ' fg:#' + st.fg2.substring(1) + '"\n\
format = "[$all_status$ahead_behind ]($style)"\n\
\n\
[c]\n\
symbol = "\u{e61e} "\n\
style = "bg:#' + st.g4.substring(1) + ' fg:#' + st.fgDark.substring(1) + '"\n\
format = "[ $symbol($version) ]($style)"\n\
\n\
[golang]\n\
symbol = "\u{e626} "\n\
style = "bg:#' + st.g4.substring(1) + ' fg:#' + st.fgDark.substring(1) + '"\n\
format = "[ $symbol($version) ]($style)"\n\
\n\
[nodejs]\n\
symbol = ""\n\
style = "bg:#' + st.g4.substring(1) + ' fg:#' + st.fgDark.substring(1) + '"\n\
format = "[ $symbol ($version) ]($style)"\n\
\n\
[rust]\n\
symbol = ""\n\
style = "bg:#' + st.g4.substring(1) + ' fg:#' + st.fgDark.substring(1) + '"\n\
format = "[ $symbol ($version) ]($style)"\n\
\n\
[nix_shell]\n\
symbol = "\u{2744}"\n\
style = "bg:#' + st.g4.substring(1) + ' fg:#' + st.fgDark.substring(1) + '"\n\
format = "[ $symbol $state ]($style)"\n\
\n\
[python]\n\
style = "bg:#' + st.g1.substring(1) + ' fg:#' + st.fg1.substring(1) + '"\n\
format = "[($virtualenv )]($style)"\n\
\n\
[docker_context]\n\
symbol = "\u{f308} "\n\
style = "bg:#' + st.g5.substring(1) + ' fg:#' + st.fg2.substring(1) + '"\n\
format = "[ $symbol $context ]($style)"\n\
\n\
[cmd_duration]\n\
min_time = 2000\n\
style = "bg:#' + st.g6.substring(1) + ' fg:#' + st.fg1.substring(1) + '"\n\
format = "[ \u{f251}$duration ]($style)"\n\
\n\
[time]\n\
disabled = false\n\
time_format = "%R"\n\
style = "bg:#' + st.g6.substring(1) + ' fg:#' + st.fg1.substring(1) + '"\n\
format = "[ $time ]($style)"\n';
    }

    function generateGtkCss(version, s) {
        var header = version === 3
            ? "/* Void Command GTK3 Theme Override */\n"
            : "/* Void Command GTK4 Theme Override */\n";
        var comment = "/* Palette: " + root.currentScheme + "\n\
 *   void: " + s.void_ + "  surface0: " + s.surface0 + "  surface1: " + s.surface1 + "\n\
 *   surface2: " + s.surface2 + "  surface3: " + s.surface3 + "\n\
 *   accent: " + s.accent + "  accentDim: " + s.accentDim + "  accentBright: " + s.accentBright + "\n\
 *   textPrimary: " + s.textPrimary + "  textSecondary: " + s.textSecondary + "  textDim: " + s.textDim + "\n\
 */\n\n";

        var bgSection;
        if (version === 3) {
            bgSection = "/* === Backgrounds === */\n\
.background {\n\
    background-color: " + s.surface0 + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        } else {
            bgSection = "/* === Backgrounds === */\n\
window, window.background {\n\
    background-color: " + s.surface0 + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        }

        var headerbar = "headerbar, .titlebar {\n\
    background-color: " + s.void_ + ";\n\
    border-bottom: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
headerbar:backdrop, .titlebar:backdrop {\n\
    background-color: " + s.void_ + ";\n\
    color: " + s.textDim + ";\n\
}\n\n";

        var views;
        if (version === 3) {
            views = ".view, iconview, treeview.view {\n\
    background-color: " + s.surface1 + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        } else {
            views = ".view, columnview, listview, gridview {\n\
    background-color: " + s.surface1 + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        }

        var textview = "textview text {\n\
    background-color: " + s.surface1 + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";

        var textviewBorder = version === 3 ? "textview border {\n\
    background-color: " + s.surface2 + ";\n\
}\n\n" : "";

        var sidebar;
        if (version === 3) {
            sidebar = "placessidebar, .sidebar {\n\
    background-color: " + s.surface0 + ";\n\
    color: " + s.textSecondary + ";\n\
}\n\
\n\
placessidebar row:selected {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        } else {
            sidebar = ".navigation-sidebar {\n\
    background-color: " + s.surface0 + ";\n\
    color: " + s.textSecondary + ";\n\
}\n\
\n\
.navigation-sidebar row:selected {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        }

        var menus;
        if (version === 3) {
            menus = "menu, .menu, .popup {\n\
    background-color: " + s.surface2 + ";\n\
    color: " + s.textPrimary + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
}\n\
\n\
menuitem:hover {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
toolbar, .toolbar, statusbar {\n\
    background-color: " + s.void_ + ";\n\
    color: " + s.textSecondary + ";\n\
}\n\n";
        } else {
            menus = "";
        }

        var popover;
        if (version === 3) {
            popover = "popover, popover.background {\n";
        } else {
            popover = "popover, popover.background, popover contents {\n";
        }
        popover += "    background-color: " + s.surface2 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
tooltip" + (version === 3 ? ", .tooltip" : "") + " {\n\
    background-color: " + s.surface2 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";

        var notebooks = "notebook > header {\n\
    background-color: " + s.void_ + ";\n\
    border-color: " + s.accentDim + ";\n\
}\n\
\n\
notebook > header tab:checked {\n\
    background-color: " + s.surface2 + ";\n\
    border-color: " + s.accent + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
notebook > header tab {\n\
    color: " + s.textDim + ";\n\
}\n\
\n\
notebook > stack {\n\
    background-color: " + s.surface0 + ";\n\
}\n\n";

        var buttons = "/* === Buttons === */\n\
button {\n\
    background-" + (version === 3 ? "image: none;\n    background-" : "") + "color: " + s.surface3 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
    border-radius: 6px;\n\
}\n\
\n\
button:hover {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
button:active, button:checked {\n\
    background-color: " + s.accent + ";\n\
    color: " + s.void_ + ";\n\
}\n\
\n\
button:disabled {\n\
    background-color: " + s.surface1 + ";\n\
    color: " + s.textDim + ";\n\
    border-color: " + s.surface3 + ";\n\
}\n\
\n\
button.suggested-action {\n\
    background-color: " + s.accent + ";\n\
    color: " + s.void_ + ";\n\
    border-color: " + s.accentBright + ";\n\
}\n\
\n\
button.suggested-action:hover {\n\
    background-color: " + s.accentBright + ";\n\
}\n\
\n\
button.destructive-action {\n\
    background-color: #F87171;\n\
    color: " + s.void_ + ";\n" + (version === 3 ? "    border-color: #F87171;\n" : "") + "\
}\n\
\n\
button.destructive-action:hover {\n\
    background-color: #FCA5A5;\n\
}\n\n";

        var entries = "/* === Text Entries / Inputs === */\n\
entry {\n\
    background-color: " + s.surface1 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
    border-radius: 6px;\n\
    caret-color: " + s.accent + ";\n\
}\n\
\n\
entry:" + (version === 3 ? "focus" : "focus-within") + " {\n\
    border-color: " + s.accent + ";\n\
    " + (version === 3 ? "box-shadow: 0 0 0 1px " + s.accent + ";" : "outline-color: " + s.accent + ";") + "\n\
}\n\
\n\
entry:disabled {\n\
    background-color: " + s.surface0 + ";\n\
    color: " + s.textDim + ";\n\
}\n\n";

        var selections = "/* === Selections === */\n\
selection" + (version === 3 ? ", *:selected" : "") + " {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
row:selected, row:active {\n\
    background-color: " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
row:hover {\n\
    background-color: " + s.surface3 + ";\n\
}\n\n";

        var switches = "/* === Switches / Toggles === */\n\
switch {\n\
    background-color: " + s.surface3 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    border-radius: 12px;\n\
}\n\
\n\
switch:checked {\n\
    background-color: " + s.accent + ";\n\
}\n\
\n" + (version === 3 ? "switch slider {\n\
    background-color: " + s.textPrimary + ";\n\
    border-radius: 10px;\n\
}\n\n" : "");

        var checkRadio = "/* === Check / Radio buttons === */\n\
check, radio {\n\
    background-color: " + s.surface1 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.accent + ";\n\
}\n\
\n\
check:checked, radio:checked {\n\
    background-color: " + s.accent + ";\n\
    color: " + s.void_ + ";\n\
    border-color: " + s.accent + ";\n\
}\n\
\n\
check:hover, radio:hover {\n\
    border-color: " + s.accentBright + ";\n\
}\n\n";

        var scales = "/* === Scales / Sliders === */\n\
scale trough {\n\
    background-color: " + s.surface3 + ";\n\
    border-radius: 4px;\n\
}\n\
\n\
scale highlight {\n\
    background-color: " + s.accent + ";\n\
    border-radius: 4px;\n\
}\n\
\n\
scale slider {\n\
    background-color: " + s.textPrimary + ";\n\
    border: 1px solid " + s.accent + ";\n\
    border-radius: 50%;\n\
}\n\
\n\
scale slider:hover {\n\
    background-color: " + s.accentBright + ";\n\
}\n\n";

        var scrollbars = "/* === Scrollbars === */\n\
scrollbar slider {\n\
    background-color: " + s.accentDim + ";\n\
    border-radius: 4px;\n\
    min-width: 6px;\n\
    min-height: 6px;\n\
}\n\
\n\
scrollbar slider:hover {\n\
    background-color: " + s.accent + ";\n\
}\n\
\n\
scrollbar trough {\n\
    background-color: " + s.surface0 + ";\n\
}\n\n";

        var progress = "/* === Progress bars === */\n\
progressbar trough {\n\
    background-color: " + s.surface3 + ";\n\
    border-radius: 4px;\n\
}\n\
\n\
progressbar progress {\n\
    background-color: " + s.accent + ";\n\
    border-radius: 4px;\n\
}\n\n";

        var separators = "/* === Separators === */\n\
separator {\n\
    background-color: " + s.accentDim + ";\n\
    opacity: 0.5;\n\
}\n\n";

        var frames = "/* === Frames === */\n\
frame > border {\n\
    border-color: " + s.surface3 + ";\n\
}\n\n";

        var spinbuttons = "/* === Spinbuttons === */\n\
spinbutton {\n\
    background-color: " + s.surface1 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n" + (version === 3 ? "spinbutton button {\n\
    border: none;\n\
    border-radius: 0;\n\
}\n\n" : "");

        var combo;
        if (version === 3) {
            combo = "/* === Combo boxes === */\n\
combobox button.combo {\n\
    background-color: " + s.surface3 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\
\n\
combobox window menu {\n\
    background-color: " + s.surface2 + ";\n\
}\n\n";
        } else {
            combo = "/* === Combo boxes === */\n\
dropdown button {\n\
    background-color: " + s.surface3 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        }

        var links;
        if (version === 3) {
            links = "/* === Link color === */\n\
*:link, button.link {\n\
    color: " + s.accentBright + ";\n\
}\n\
\n\
*:link:hover, button.link:hover {\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        } else {
            links = "/* === Links === */\n\
link, button.link {\n\
    color: " + s.accentBright + ";\n\
}\n\
\n\
link:hover, button.link:hover {\n\
    color: " + s.textPrimary + ";\n\
}\n\n";
        }

        var dialogs = version === 3 ? "/* === Dialogs === */\n\
dialog .dialog-action-area button {\n\
    min-height: 28px;\n\
}\n\
\n\
messagedialog .titlebar {\n\
    background-color: " + s.void_ + ";\n\
}\n\n" : "";

        var infobar = version === 3 ? "/* === Infobar === */\n\
infobar {\n\
    background-color: " + s.surface2 + ";\n\
    border: 1px solid " + s.accentDim + ";\n\
}\n" : "";

        return header + comment + bgSection + headerbar + views + textview + textviewBorder +
               sidebar + menus + popover + notebooks + buttons + entries + selections +
               switches + checkRadio + scales + scrollbars + progress + separators + frames +
               spinbuttons + combo + links + dialogs + infobar;
    }

    function generateQt6ctColors(s) {
        function hexToArgb(hex) {
            return "#ff" + hex.substring(1);
        }
        // QPalette: Window, WindowText, Base, AlternateBase, ToolTipBase, ToolTipText,
        // PlaceholderText, Text, Button, ButtonText, BrightText, Light, Midlight, Dark,
        // Mid, Shadow, Highlight, HighlightedText, Link, LinkVisited, (21 entries)
        var active = [
            hexToArgb(s.surface0),    // Window
            hexToArgb(s.textPrimary), // WindowText
            hexToArgb(s.surface1),    // Base
            hexToArgb(s.surface2),    // AlternateBase
            hexToArgb(s.surface2),    // ToolTipBase
            hexToArgb(s.textPrimary), // ToolTipText
            hexToArgb(s.textDim),     // PlaceholderText
            hexToArgb(s.textPrimary), // Text
            hexToArgb(s.surface3),    // Button
            hexToArgb(s.textPrimary), // ButtonText
            "#ffffffff",              // BrightText
            hexToArgb(s.surface3),    // Light
            hexToArgb(s.surface2),    // Midlight
            hexToArgb(s.void_),       // Dark
            hexToArgb(s.surface1),    // Mid
            "#ff111111",              // Shadow
            hexToArgb(s.qtHighlight), // Highlight
            "#ffffffff",              // HighlightedText
            hexToArgb(s.accentBright),// Link
            hexToArgb(s.accent),      // LinkVisited
            hexToArgb(s.textDim)      // NoRole / accent hint
        ].join(", ");

        var disabled = [
            hexToArgb(s.surface0),
            hexToArgb(s.textDim),
            hexToArgb(s.surface1),
            hexToArgb(s.surface2),
            hexToArgb(s.surface2),
            hexToArgb(s.textDim),
            hexToArgb(s.textDim),
            hexToArgb(s.textDim),
            hexToArgb(s.surface3),
            hexToArgb(s.textDim),
            "#ffffffff",
            hexToArgb(s.surface3),
            hexToArgb(s.surface2),
            hexToArgb(s.void_),
            hexToArgb(s.surface1),
            "#ff111111",
            hexToArgb(s.accentDim),
            hexToArgb(s.textDim),
            hexToArgb(s.accentBright),
            hexToArgb(s.accent),
            hexToArgb(s.textDim)
        ].join(", ");

        return "[ColorScheme]\n\
active_colors=" + active + "\n\
disabled_colors=" + disabled + "\n\
inactive_colors=" + active + "\n";
    }

    function generateFastfetchConfig(s) {
        function hexToAnsi(hex) {
            var r = parseInt(hex.substring(1,3), 16);
            var g = parseInt(hex.substring(3,5), 16);
            var b = parseInt(hex.substring(5,7), 16);
            return "38;2;" + r + ";" + g + ";" + b;
        }

        // Use a placeholder for ESC, then replace after JSON.stringify
        // to avoid QML/JSON issues with literal control characters
        var ESC = "%%ESC%%";
        var accentAnsi = hexToAnsi(s.accent);
        var sepLine = ESC + "[" + accentAnsi + "m---------------------------------------------";
        var titleFmt = ESC + "[" + accentAnsi + "m{user-name}" + ESC + "[0m @ " + ESC + "[" + hexToAnsi(s.textDim) + "m{host-name}";

        var config = {
            "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
            "logo": {
                "source": "~/.config/fastfetch/logo.txt",
                "type": "file",
                "color": {
                    "1": hexToAnsi(s.surface3),
                    "2": hexToAnsi(s.accent),
                    "3": hexToAnsi(s.textDim)
                },
                "padding": { "top": 1, "left": 2, "right": 3 }
            },
            "display": {
                "separator": "  ",
                "color": { "separator": "white" }
            },
            "modules": [
                { "type": "custom", "format": sepLine },
                { "type": "title", "format": titleFmt },
                { "type": "custom", "format": sepLine },
                "break",
                { "type": "os", "key": "  OS", "keyColor": hexToAnsi(s.ansi.color11) },
                { "type": "kernel", "key": "  Kernel", "keyColor": hexToAnsi(s.ansi.color11) },
                { "type": "uptime", "key": "  Uptime", "keyColor": hexToAnsi(s.ansi.color11) },
                { "type": "packages", "key": "  Packages", "keyColor": hexToAnsi(s.ansi.color11) },
                "break",
                { "type": "wm", "key": "  WM", "keyColor": hexToAnsi(s.ansi.color9) },
                { "type": "theme", "key": "  Theme", "keyColor": hexToAnsi(s.ansi.color9) },
                { "type": "cursor", "key": "  Cursor", "keyColor": hexToAnsi(s.ansi.color9) },
                { "type": "terminal", "key": "  Term", "keyColor": hexToAnsi(s.ansi.color9) },
                { "type": "shell", "key": "  Shell", "keyColor": hexToAnsi(s.ansi.color9) },
                "break",
                { "type": "cpu", "key": "  CPU", "keyColor": hexToAnsi(s.ansi.color14) },
                { "type": "gpu", "key": "  GPU", "keyColor": hexToAnsi(s.ansi.color14) },
                { "type": "display", "key": "  Display", "keyColor": hexToAnsi(s.ansi.color14) },
                { "type": "memory", "key": "  Memory", "keyColor": hexToAnsi(s.ansi.color14) },
                { "type": "disk", "key": "  Disk(/)", "keyColor": hexToAnsi(s.ansi.color14), "folders": "/" },
                "break",
                { "type": "localip", "key": "  Network", "keyColor": hexToAnsi(s.ansi.color10) },
                "break",
                { "type": "custom", "format": sepLine },
                { "type": "colors", "paddingLeft": 2, "symbol": "block" }
            ]
        };

        return JSON.stringify(config, null, 4).replace(/%%ESC%%/g, "\\u001b");
    }

    function generateVesktopCss(s) {
        return "/* Void Command Vesktop Theme — " + root.currentScheme + " */\n\
/* Auto-generated by theme switcher — do not edit manually */\n\
\n\
/* === Base backgrounds === */\n\
.theme-dark {\n\
    --background-primary: " + s.surface0 + ";\n\
    --background-secondary: " + s.void_ + ";\n\
    --background-secondary-alt: " + s.surface1 + ";\n\
    --background-tertiary: " + s.void_ + ";\n\
    --background-accent: " + s.accentDim + ";\n\
    --background-floating: " + s.surface1 + ";\n\
    --background-modifier-hover: " + s.surface2 + ";\n\
    --background-modifier-active: " + s.surface3 + ";\n\
    --background-modifier-selected: " + s.surface2 + ";\n\
    --background-modifier-accent: rgba(255, 255, 255, 0.06);\n\
\n\
    /* === Surfaces === */\n\
    --bg-overlay-1: " + s.surface1 + ";\n\
    --bg-overlay-2: " + s.surface2 + ";\n\
    --bg-overlay-3: " + s.surface3 + ";\n\
    --bg-overlay-hover: " + s.surface2 + ";\n\
    --bg-overlay-active: " + s.surface3 + ";\n\
\n\
    /* === Channels / sidebar === */\n\
    --channeltextarea-background: " + s.surface1 + ";\n\
    --activity-card-background: " + s.surface1 + ";\n\
    --input-background: " + s.surface1 + ";\n\
\n\
    /* === Text === */\n\
    --text-normal: " + s.textPrimary + ";\n\
    --text-muted: " + s.textDim + ";\n\
    --text-link: " + s.accentBright + ";\n\
    --header-primary: " + s.textPrimary + ";\n\
    --header-secondary: " + s.textSecondary + ";\n\
    --interactive-normal: " + s.textSecondary + ";\n\
    --interactive-hover: " + s.textPrimary + ";\n\
    --interactive-active: " + s.textPrimary + ";\n\
    --interactive-muted: " + s.textDim + ";\n\
    --channels-default: " + s.textSecondary + ";\n\
\n\
    /* === Accent / brand === */\n\
    --brand-500: " + s.accent + ";\n\
    --brand-560: " + s.accentDim + ";\n\
    --brand-600: " + s.accentDim + ";\n\
    --brand-experiment: " + s.accent + ";\n\
    --brand-experiment-560: " + s.accentDim + ";\n\
    --brand-experiment-600: " + s.accentDim + ";\n\
\n\
    /* === Misc === */\n\
    --scrollbar-thin-thumb: " + s.surface3 + ";\n\
    --scrollbar-thin-track: transparent;\n\
    --scrollbar-auto-thumb: " + s.surface3 + ";\n\
    --scrollbar-auto-track: " + s.surface0 + ";\n\
    --modal-background: " + s.surface0 + ";\n\
    --modal-footer-background: " + s.void_ + ";\n\
    --card-primary-bg: " + s.surface1 + ";\n\
    --card-secondary-bg: " + s.surface2 + ";\n\
    --profile-body-background-color: " + s.surface0 + ";\n\
    --button-secondary-background: " + s.surface2 + ";\n\
    --mention-background: " + s.accentDim + "33;\n\
    --mention-foreground: " + s.accent + ";\n\
}\n\
\n\
/* === Titlebar === */\n\
.withFrame__5765e {\n\
    background-color: " + s.void_ + " !important;\n\
}\n\
\n\
/* === Member list / DM list hover === */\n\
.member__5. a2:hover, .channel_c21249:hover {\n\
    background-color: " + s.surface2 + " !important;\n\
}\n\
\n\
/* === Active channel highlight === */\n\
.link__95dc0.selected_f5ec8e .linkTop__8c552 {\n\
    background-color: " + s.surface2 + " !important;\n\
}\n";
    }
}
