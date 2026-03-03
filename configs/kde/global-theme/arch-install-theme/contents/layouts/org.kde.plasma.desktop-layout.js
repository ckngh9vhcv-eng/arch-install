// =============================================================================
// Arch Install Theme — Plasma Desktop Layout
// Dual-panel layout: top bar + bottom dock
// Applied via: plasma-apply-lookandfeel --apply arch-install-theme --resetLayout
// =============================================================================

// Remove any existing panels so we start clean
var existingPanels = panels();
for (var i = 0; i < existingPanels.length; i++) {
    existingPanels[i].remove();
}

// =============================================================================
// Top Panel — full-width bar with app menu, centered clock, system tray
// =============================================================================
var topPanel = new Panel("org.kde.panel");
topPanel.location = "top";
topPanel.height = 28;
topPanel.alignment = "center";
topPanel.lengthMode = "fill";
topPanel.hiding = "none";
topPanel.floating = true;

// Panel Colorizer (hidden widget, enables transparency preset)
var topColorizer = topPanel.addWidget("luisbocanegra.panel.colorizer");
topColorizer.writeConfig("isEnabled", true, "General");
topColorizer.writeConfig("hideWidget", true, "General");

// Global application menu
topPanel.addWidget("org.kde.plasma.appmenu");

// Left spacer (pushes clock to center)
topPanel.addWidget("org.kde.plasma.panelspacer");

// Digital clock (centered)
var clock = topPanel.addWidget("org.kde.plasma.digitalclock");
clock.writeConfig("showDate", true, "Appearance");
clock.writeConfig("dateFormat", "shortDate", "Appearance");
clock.writeConfig("use24hFormat", 0, "Appearance");

// Right spacer (pushes system tray to right)
topPanel.addWidget("org.kde.plasma.panelspacer");

// System tray
topPanel.addWidget("org.kde.plasma.systemtray");

// =============================================================================
// Bottom Dock — centered icon taskbar with app launcher
// =============================================================================
var bottomPanel = new Panel("org.kde.panel");
bottomPanel.location = "bottom";
bottomPanel.height = 56;
bottomPanel.alignment = "center";
bottomPanel.lengthMode = "fit";
bottomPanel.hiding = "dodgewindows";
bottomPanel.floating = true;

// Panel Colorizer (hidden widget, enables transparency preset)
var bottomColorizer = bottomPanel.addWidget("luisbocanegra.panel.colorizer");
bottomColorizer.writeConfig("isEnabled", true, "General");
bottomColorizer.writeConfig("hideWidget", true, "General");

// Application launcher (Kickoff)
bottomPanel.addWidget("org.kde.plasma.kickoff");

// Icon-only task manager with pinned apps
var tasks = bottomPanel.addWidget("org.kde.plasma.icontasks");
tasks.writeConfig(
    "launchers",
    [
        "preferred://filemanager",
        "preferred://browser",
        "applications:kitty.desktop",
        "applications:code.desktop"
    ].join(","),
    "General"
);

// =============================================================================
// Wallpaper — set on all desktops
// =============================================================================
// userDataPath("") returns ~/.local/share — derive home directory
var homePath = userDataPath("").replace(/\/.local\/share$/, "");
var wallpaper = "file://" + homePath + "/wallpapers/wallhaven-49z1pw_2560x1440.png";

var allDesktops = desktops();
for (var d = 0; d < allDesktops.length; d++) {
    allDesktops[d].wallpaperPlugin = "org.kde.image";
    allDesktops[d].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    allDesktops[d].writeConfig("Image", wallpaper);
    allDesktops[d].writeConfig("FillMode", 1);
}
