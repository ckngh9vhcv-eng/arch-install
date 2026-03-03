#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 3 (Runs as $USER inside chroot via su -l)
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

# SCRIPT_DIR and GIT_NAME/GIT_EMAIL are passed via environment from chroot.sh
SCRIPT_DIR="${SCRIPT_DIR:-/root/arch-install}"

# =============================================================================
# Install paru (AUR Helper) from Chaotic-AUR
# =============================================================================
header "Installing paru"

sudo pacman -S --noconfirm --needed paru

info "paru installed from Chaotic-AUR"

# =============================================================================
# Install AUR Packages
# =============================================================================
header "Installing AUR Packages"

# Read AUR package list (strip comments and blank lines)
AUR_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/aur.txt" | grep -v '^\s*$' | tr '\n' ' ')

# --skipreview: don't prompt to review PKGBUILDs
# --noconfirm: auto-accept provider selection (picks default=1)
paru -S --noconfirm --needed --skipreview $AUR_PKGS

info "AUR packages installed"

# =============================================================================
# Deploy KDE Configs
# =============================================================================
header "Deploying KDE Configs"

mkdir -p ~/.config/klassy ~/.config/autostart

# KDE config files (INI-style settings)
for cfg in kwinrc kdeglobals kglobalshortcutsrc kscreenlockerrc kwalletrc powerdevilrc; do
    if [[ -f "$SCRIPT_DIR/configs/kde/$cfg" ]]; then
        cp "$SCRIPT_DIR/configs/kde/$cfg" ~/.config/"$cfg"
    fi
done

# Klassy config
cp "$SCRIPT_DIR/configs/kde/klassyrc" ~/.config/klassy/klassyrc

# KDE custom shortcut .desktop files
if [[ -d "$SCRIPT_DIR/configs/kde/shortcuts" ]]; then
    for desktop_file in "$SCRIPT_DIR"/configs/kde/shortcuts/*.desktop; do
        [[ -f "$desktop_file" ]] || continue
        cp "$desktop_file" ~/.config/
    done
fi

info "KDE configs deployed"

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
# Panel Colorizer Preset + Global Theme Autostart
# =============================================================================
header "Deploying Panel Colorizer Preset & Theme Autostart"

PRESET_DIR="$HOME/.config/panel-colorizer/presets/transparent-blur"
mkdir -p "$PRESET_DIR"
cp "$SCRIPT_DIR/configs/kde/panel-colorizer/preset.json" "$PRESET_DIR/preset.json"

# One-shot autostart: apply global theme layout + panel colorizer preset, then self-delete
cat > ~/.config/autostart/arch-install-theme-setup.desktop <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Arch Install Theme Setup
Comment=One-shot: apply panel layout and colorizer preset on first login
Exec=bash -c 'sleep 3 && plasma-apply-lookandfeel --apply arch-install-theme --resetLayout && sleep 2 && dbus-send --session --type=signal /preset luisbocanegra.panel.colorizer.all.preset string:"$HOME/.config/panel-colorizer/presets/transparent-blur/" && rm -f "$HOME/.config/autostart/arch-install-theme-setup.desktop"'
X-KDE-autostart-phase=2
OnlyShowIn=KDE;
AUTOSTART

info "Global theme + Panel Colorizer one-shot autostart deployed"

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

# Ensure ~/.local/bin is in PATH
if ! grep -q '$HOME/.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# =============================================================================
# Cursor Theme
# =============================================================================
header "Setting Cursor Theme"

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
# Git Configuration (optional)
# =============================================================================
if [[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]]; then
    header "Configuring Git"

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global credential.helper "!gh auth git-credential"

    info "Git configured (name: $GIT_NAME, email: $GIT_EMAIL)"
fi

# =============================================================================
# Flatpak
# =============================================================================
header "Setting Up Flatpak"

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

info "Flathub remote added"

# =============================================================================
# Done
# =============================================================================
header "User Setup Complete!"

echo -e "${GREEN}${BOLD}Your Arch Linux workstation is ready.${NC}"
echo ""
echo "Remaining manual steps after reboot:"
echo "  1. GitHub authentication:  gh auth login && gh auth setup-git"
echo "  2. Tailscale:              sudo tailscale up"
echo "  3. Libvirt default pool:   virsh pool-define-as default dir - - - - /var/lib/libvirt/images && virsh pool-start default && virsh pool-autostart default"
echo "  4. Log out and back in for full theme application"
echo ""
echo "Sessions available at login:"
echo "  - Plasma (Wayland) — KDE desktop with macOS-style panels"
echo "  - Hyprland — tiling WM with purple theme"
echo ""
