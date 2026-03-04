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
# Deploy Hyprland Configs
# =============================================================================
header "Deploying Hyprland Configs"

mkdir -p ~/.config/hypr
cp "$SCRIPT_DIR/configs/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf
cp "$SCRIPT_DIR/configs/hyprpaper/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf
cp "$SCRIPT_DIR/configs/hyprlock/hyprlock.conf" ~/.config/hypr/hyprlock.conf

info "Hyprland + Hyprlock config deployed"

# Quickshell (desktop shell — bar, launcher, notifications, power menu, sidebar)
mkdir -p ~/.config/quickshell
cp -r "$SCRIPT_DIR/configs/quickshell/"* ~/.config/quickshell/
mkdir -p ~/.local/share/quickshell
mkdir -p ~/.local/share/cliphist

info "Quickshell config deployed"

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
cp "$SCRIPT_DIR/configs/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css

# gsettings overrides (some GTK apps read these instead of settings.ini)
gsettings set org.gnome.desktop.interface gtk-theme 'Layan-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

info "Shared configs deployed (kitty, starship, qt6ct, GTK)"

# =============================================================================
# Deploy Zoom & Screenshot Helper Scripts
# =============================================================================
header "Installing Zoom & Screenshot Helper Scripts"

mkdir -p ~/.local/bin

cat > ~/.local/bin/hypr-zoom-in <<'SCRIPT'
#!/bin/bash
current=$(hyprctl getoption cursor:zoom_factor -j | jq '.float')
new=$(echo "$current + 1.0" | bc)
max="10.0"
if [ "$(echo "$new > $max" | bc)" -eq 1 ]; then
    new="$max"
fi
hyprctl keyword cursor:zoom_factor "$new"
SCRIPT

cat > ~/.local/bin/hypr-zoom-out <<'SCRIPT'
#!/bin/bash
current=$(hyprctl getoption cursor:zoom_factor -j | jq '.float')
new=$(echo "$current - 1.0" | bc)
if [ "$(echo "$new < 1.0" | bc)" -eq 1 ]; then
    new="1.0"
fi
hyprctl keyword cursor:zoom_factor "$new"
SCRIPT

cat > ~/.local/bin/hypr-zoom-reset <<'SCRIPT'
#!/bin/bash
hyprctl keyword cursor:zoom_factor 1
SCRIPT

cat > ~/.local/bin/screenshot-full <<'SCRIPT'
#!/bin/bash
FILE="/tmp/screenshot-$(date +%s).png"
grim "$FILE"
wl-copy < "$FILE"
notify-send "Screenshot" "Copied to clipboard" -i "$FILE"
SCRIPT

chmod +x ~/.local/bin/hypr-zoom-{in,out,reset}
chmod +x ~/.local/bin/screenshot-full

info "Zoom & screenshot helper scripts installed to ~/.local/bin/"

# =============================================================================
# Copy Wallpaper
# =============================================================================
header "Installing Wallpaper"

mkdir -p ~/wallpapers
cp "$SCRIPT_DIR"/wallpapers/*.png "$SCRIPT_DIR"/wallpapers/*.jpg ~/wallpapers/ 2>/dev/null || \
    warn "Wallpapers not found in installer — copy manually to ~/wallpapers/"

info "Wallpapers installed"

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
# SSH Key Restore (optional)
# =============================================================================
if [[ -n "${SSH_RESTORE_SOURCE:-}" ]]; then
    header "Restoring SSH Keys"

    mkdir -p ~/.ssh && chmod 700 ~/.ssh

    # scp from remote host (e.g., root@192.168.9.141:/root/mike-ssh-backup/)
    scp -o StrictHostKeyChecking=accept-new -r "${SSH_RESTORE_SOURCE}/"* ~/.ssh/ && {
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/id_* 2>/dev/null || true
        chmod 644 ~/.ssh/*.pub 2>/dev/null || true
        chmod 644 ~/.ssh/known_hosts 2>/dev/null || true
        chmod 644 ~/.ssh/authorized_keys 2>/dev/null || true
        chmod 644 ~/.ssh/config 2>/dev/null || true
        info "SSH keys restored from $SSH_RESTORE_SOURCE"
    } || warn "Failed to restore SSH keys from $SSH_RESTORE_SOURCE — restore manually after reboot"
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
echo "  1. GitHub authentication:  gh auth login -p ssh"
echo "  2. Tailscale:              sudo tailscale up"
echo "  3. Libvirt default pool:   virsh pool-define-as default dir - - - - /var/lib/libvirt/images && virsh pool-start default && virsh pool-autostart default"
if [[ -z "${SSH_RESTORE_SOURCE:-}" ]]; then
    echo "  4. Restore SSH keys:       scp -r user@host:/path/to/ssh-backup/ ~/.ssh/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*"
fi
echo ""
echo "Login: greetd (tuigreet) → Hyprland + Quickshell (Void Command theme)"
echo ""
