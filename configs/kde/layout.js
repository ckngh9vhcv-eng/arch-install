// Plasma Panel Layout — macOS-style top bar + bottom dock
// Installed to: /usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js
// Runs automatically on first Plasma login when no existing panel config exists.

// Remove any default panels
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    allPanels[i].remove();
}

// ===== TOP BAR =====
var topPanel = new Panel;
topPanel.location = "top";
topPanel.height = 28;
topPanel.lengthMode = "fill";
topPanel.alignment = "center";
topPanel.hiding = "none";

// Panel Colorizer (transparent blur)
topPanel.addWidget("luisbocanegra.panel.colorizer");

// App Menu (global menu bar)
topPanel.addWidget("org.kde.plasma.appmenu");

// Left spacer
topPanel.addWidget("org.kde.plasma.panelspacer");

// Centered clock
var clock = topPanel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "shortDate");
clock.writeConfig("use24hFormat", 0);
clock.currentConfigGroup = ["Configuration", "General"];
clock.writeConfig("firstDayOfWeek", 0);

// Right spacer
topPanel.addWidget("org.kde.plasma.panelspacer");

// System tray
var systray = topPanel.addWidget("org.kde.plasma.systemtray");

// ===== BOTTOM DOCK =====
var dock = new Panel;
dock.location = "bottom";
dock.height = 56;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "autohide";

// Panel Colorizer
dock.addWidget("luisbocanegra.panel.colorizer");

// Kickoff launcher
dock.addWidget("org.kde.plasma.kickoff");

// Icon-only task manager
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "preferred://filemanager",
    "preferred://browser",
    "applications:kitty.desktop",
    "applications:code.desktop"
].join(","));
