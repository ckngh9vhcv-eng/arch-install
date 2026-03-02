#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 3 (Run as mike after first reboot)
# Installs AUR packages, deploys dotfiles, configures theming
# =============================================================================
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
header() { echo -e "\n${PURPLE}${BOLD}=== $* ===${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Must not be root
[[ $EUID -ne 0 ]] || error "Run this script as mike, not root"

# =============================================================================
# Install paru (AUR Helper)
# =============================================================================
header "Installing paru"

if command -v paru &>/dev/null; then
    info "paru already installed"
else
    info "Building paru from AUR..."
    cd /tmp
    rm -rf paru-bin
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
    cd /tmp
    rm -rf paru-bin
    info "paru installed"
fi

# =============================================================================
# Install AUR Packages
# =============================================================================
header "Installing AUR Packages"

# Read AUR package list (strip comments and blank lines)
AUR_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/aur.txt" | grep -v '^\s*$' | tr '\n' ' ')

paru -S --noconfirm --needed $AUR_PKGS

info "AUR packages installed"

# =============================================================================
# Deploy Hyprland Configs
# =============================================================================
header "Deploying Hyprland Configs"

mkdir -p ~/.config/hypr
cp "$SCRIPT_DIR/configs/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf
cp "$SCRIPT_DIR/configs/hyprpaper/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf

info "Hyprland config deployed"

# Waybar
mkdir -p ~/.config/waybar
cp "$SCRIPT_DIR/configs/waybar/config.jsonc" ~/.config/waybar/config.jsonc
cp "$SCRIPT_DIR/configs/waybar/style.css" ~/.config/waybar/style.css

info "Waybar config deployed"

# Wofi
mkdir -p ~/.config/wofi
cp "$SCRIPT_DIR/configs/wofi/config" ~/.config/wofi/config
cp "$SCRIPT_DIR/configs/wofi/style.css" ~/.config/wofi/style.css

info "Wofi config deployed"

# Dunst
mkdir -p ~/.config/dunst
cp "$SCRIPT_DIR/configs/dunst/dunstrc" ~/.config/dunst/dunstrc

info "Dunst config deployed"

# =============================================================================
# Deploy Shared Configs
# =============================================================================
header "Deploying Shared Configs"

# Kitty
mkdir -p ~/.config/kitty
cp "$SCRIPT_DIR/configs/kitty/kitty.conf" ~/.config/kitty/kitty.conf

# Starship
cp "$SCRIPT_DIR/configs/starship/starship.toml" ~/.config/starship.toml

# Qt6ct
mkdir -p ~/.config/qt6ct/colors
cp "$SCRIPT_DIR/configs/qt6ct/qt6ct.conf" ~/.config/qt6ct/qt6ct.conf
cp "$SCRIPT_DIR/configs/qt6ct/colors/BreezeDarkPurple.conf" ~/.config/qt6ct/colors/BreezeDarkPurple.conf

# GTK-3.0
mkdir -p ~/.config/gtk-3.0
cp "$SCRIPT_DIR/configs/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini
cp "$SCRIPT_DIR/configs/gtk-3.0/gtk.css" ~/.config/gtk-3.0/gtk.css

# GTK-4.0
mkdir -p ~/.config/gtk-4.0
cp "$SCRIPT_DIR/configs/gtk-4.0/settings.ini" ~/.config/gtk-4.0/settings.ini

info "Shared configs deployed (kitty, starship, qt6ct, GTK)"

# =============================================================================
# Deploy Zoom Helper Scripts
# =============================================================================
header "Installing Zoom Helper Scripts"

mkdir -p ~/.local/bin

cat > ~/.local/bin/hypr-zoom-in <<'SCRIPT'
#!/bin/bash
current=$(hyprctl getoption cursor:zoom_factor -j | jq '.float')
new=$(echo "$current + 0.5" | bc)
max="10.0"
if [ "$(echo "$new > $max" | bc)" -eq 1 ]; then
    new="$max"
fi
hyprctl keyword cursor:zoom_factor "$new"
SCRIPT

cat > ~/.local/bin/hypr-zoom-out <<'SCRIPT'
#!/bin/bash
current=$(hyprctl getoption cursor:zoom_factor -j | jq '.float')
new=$(echo "$current - 0.5" | bc)
if [ "$(echo "$new < 1.0" | bc)" -eq 1 ]; then
    new="1.0"
fi
hyprctl keyword cursor:zoom_factor "$new"
SCRIPT

cat > ~/.local/bin/hypr-zoom-reset <<'SCRIPT'
#!/bin/bash
hyprctl keyword cursor:zoom_factor 1
SCRIPT

chmod +x ~/.local/bin/hypr-zoom-{in,out,reset}

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

info "Zoom helper scripts installed to ~/.local/bin/"

# =============================================================================
# Copy Wallpaper
# =============================================================================
header "Installing Wallpaper"

mkdir -p ~/wallpapers
cp "$SCRIPT_DIR/wallpapers/wallhaven-49z1pw_2560x1440.png" ~/wallpapers/ 2>/dev/null || \
    warn "Wallpaper not found in installer — copy manually to ~/wallpapers/"

info "Wallpaper installed"

# =============================================================================
# Bash Configuration
# =============================================================================
header "Configuring Bash"

# Append our config if not already added
if ! grep -q "Arch Install — Shell Configuration" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    cat "$SCRIPT_DIR/configs/bash/bashrc.append" >> ~/.bashrc
    info "Bash config appended to ~/.bashrc"
else
    info "Bash config already present"
fi

# =============================================================================
# Panel Colorizer Preset
# =============================================================================
header "Deploying Panel Colorizer Preset"

PRESET_DIR="$HOME/.config/panel-colorizer/presets/transparent-blur"
mkdir -p "$PRESET_DIR"
cp "$SCRIPT_DIR/configs/kde/panel-colorizer/preset.json" "$PRESET_DIR/preset.json"

# Create autostart script to apply preset on first KDE login
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/panel-colorizer-preset.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Apply Panel Colorizer Preset
Exec=bash -c 'sleep 3 && dbus-send --session --type=signal /preset luisbocanegra.panel.colorizer.all.preset string:"$HOME/.config/panel-colorizer/presets/transparent-blur/" && rm -f ~/.config/autostart/panel-colorizer-preset.desktop'
X-KDE-autostart-phase=2
OnlyShowIn=KDE;
EOF

info "Panel Colorizer preset deployed with one-time autostart"

# =============================================================================
# Cursor Theme
# =============================================================================
header "Setting Cursor Theme"

# Set cursor for Hyprland (already in hyprland.conf env vars)
# Set cursor for GTK apps
mkdir -p ~/.icons/default
cat > ~/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=Bibata-Modern-Classic
EOF

# Set cursor via environment
if ! grep -q "XCURSOR_THEME" ~/.profile 2>/dev/null; then
    cat >> ~/.profile <<'EOF'

# Cursor theme
export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=24
EOF
fi

info "Cursor theme set to Bibata-Modern-Classic"

# =============================================================================
# Flatpak
# =============================================================================
header "Setting Up Flatpak"

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

info "Flathub remote added"

# =============================================================================
# KDE Wallpaper (Plasma Desktop)
# =============================================================================
header "Configuring KDE Wallpaper"

# Create a plasma wallpaper script that runs on login
cat > ~/.config/plasma-org.kde.plasma.desktop-appletsrc.wallpaper <<'EOF'
# This is handled by the wallpaper setting below
EOF

# Use kwriteconfig6 if available to set wallpaper
if command -v kwriteconfig6 &>/dev/null; then
    # Set wallpaper path in Plasma config
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group 'Containments' --group '1' --group 'Wallpaper' \
        --group 'org.kde.image' --group 'General' \
        --key 'Image' "file://$HOME/wallpapers/wallhaven-49z1pw_2560x1440.png"
    info "KDE wallpaper configured"
else
    warn "kwriteconfig6 not available — set wallpaper manually in Plasma settings"
fi

# Remove the temp file
rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc.wallpaper

# =============================================================================
# Done
# =============================================================================
header "Post-Install Complete!"

echo -e "${GREEN}${BOLD}Your Arch Linux workstation is ready.${NC}"
echo ""
echo "Remaining manual steps:"
echo "  1. Change password if needed:  passwd"
echo "  2. GitHub authentication:      gh auth login && gh auth setup-git"
echo "  3. Tailscale:                  sudo tailscale up"
echo "  4. Libvirt default pool:       virsh pool-define-as default dir - - - - /var/lib/libvirt/images && virsh pool-start default && virsh pool-autostart default"
echo "  5. Log out and back in for full theme application"
echo ""
echo "Sessions available at login:"
echo "  - Plasma (Wayland) — KDE desktop with macOS-style panels"
echo "  - Hyprland — tiling WM with purple theme"
echo ""
