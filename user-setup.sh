#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 3 (Runs as $USER inside chroot via su -l)
# Installs AUR packages, deploys dotfiles, configures theming
# =============================================================================
set -euo pipefail

# SCRIPT_DIR and GIT_NAME/GIT_EMAIL are passed via environment from chroot.sh
SCRIPT_DIR="${SCRIPT_DIR:-/root/arch-install}"
source "$SCRIPT_DIR/lib.sh"

# --- Helper: back up existing config dir before overwriting ---
backup_config() {
    local target="$1"
    if [[ -e "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        info "Backing up existing $target → $backup"
        mv "$target" "$backup"
    fi
}

# =============================================================================
# Install paru (AUR Helper) from Chaotic-AUR
# =============================================================================
header "Installing paru"

sudo pacman -S --noconfirm --needed paru

info "paru installed from Chaotic-AUR"

# =============================================================================
# Install AUR Packages
# =============================================================================
if checkpoint_reached "aur-packages-installed"; then
    info "AUR packages already installed — skipping"
else
    header "Installing AUR Packages"

    # Read AUR package list (strip comments and blank lines)
    AUR_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/aur.txt" | grep -v '^\s*$' | tr '\n' ' ')

    # --skipreview: don't prompt to review PKGBUILDs
    # --noconfirm: auto-accept provider selection (picks default=1)
    spinner "Installing AUR packages" paru -S --noconfirm --needed --skipreview $AUR_PKGS

    info "AUR packages installed"
    checkpoint "aur-packages-installed"
fi

# =============================================================================
# Deploy Hyprland Configs
# =============================================================================
if checkpoint_reached "configs-deployed"; then
    info "Configs already deployed — skipping"
else
    header "Deploying Hyprland Configs"

    backup_config ~/.config/hypr
    mkdir -p ~/.config/hypr
    cp "$SCRIPT_DIR/configs/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf
    if [[ -f "$SCRIPT_DIR/configs/hyprland/monitors.conf" ]]; then
        cp "$SCRIPT_DIR/configs/hyprland/monitors.conf" ~/.config/hypr/monitors.conf
    elif [[ ! -f ~/.config/hypr/monitors.conf ]]; then
        cp "$SCRIPT_DIR/configs/hyprland/monitors.conf.example" ~/.config/hypr/monitors.conf
    fi
    cp "$SCRIPT_DIR/configs/hyprland/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf
    cp "$SCRIPT_DIR/configs/hyprland/hyprlock.conf" ~/.config/hypr/hyprlock.conf
    cp "$SCRIPT_DIR/configs/hyprland/hypridle.conf" ~/.config/hypr/hypridle.conf

    info "Hyprland + Hyprlock + Hypridle config deployed"

    # Quickshell (desktop shell — bar, launcher, notifications, power menu, sidebar)
    backup_config ~/.config/quickshell
    mkdir -p ~/.config/quickshell
    cp -r "$SCRIPT_DIR/configs/quickshell/"* ~/.config/quickshell/
    mkdir -p ~/.local/share/quickshell
    mkdir -p ~/.local/share/cliphist

    info "Quickshell config deployed"

    # =========================================================================
    # Deploy Shared Configs
    # =========================================================================
    header "Deploying Shared Configs"

    # Kitty
    backup_config ~/.config/kitty
    mkdir -p ~/.config/kitty
    cp "$SCRIPT_DIR/configs/kitty/kitty.conf" ~/.config/kitty/kitty.conf

    # Starship
    backup_config ~/.config/starship.toml
    cp "$SCRIPT_DIR/configs/starship/starship.toml" ~/.config/starship.toml

    # Qt6ct
    backup_config ~/.config/qt6ct
    mkdir -p ~/.config/qt6ct/colors
    cp "$SCRIPT_DIR/configs/qt6ct/qt6ct.conf" ~/.config/qt6ct/qt6ct.conf
    cp "$SCRIPT_DIR/configs/qt6ct/colors/BreezeDarkPurple.conf" ~/.config/qt6ct/colors/BreezeDarkPurple.conf

    # GTK-3.0
    backup_config ~/.config/gtk-3.0
    mkdir -p ~/.config/gtk-3.0
    cp "$SCRIPT_DIR/configs/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini
    cp "$SCRIPT_DIR/configs/gtk-3.0/gtk.css" ~/.config/gtk-3.0/gtk.css

    # GTK-4.0
    backup_config ~/.config/gtk-4.0
    mkdir -p ~/.config/gtk-4.0
    cp "$SCRIPT_DIR/configs/gtk-4.0/settings.ini" ~/.config/gtk-4.0/settings.ini
    cp "$SCRIPT_DIR/configs/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css

    # gsettings overrides — write dconf database directly (gsettings needs D-Bus, unavailable in chroot)
    mkdir -p ~/.config/dconf
    cat > /tmp/dconf-settings.ini <<DCONF
[org/gnome/desktop/interface]
gtk-theme='Layan-Dark'
icon-theme='Tela-circle-dark'
cursor-theme='Bibata-Modern-Classic'
cursor-size=24
font-name='Noto Sans 10'
color-scheme='prefer-dark'
DCONF
    dconf load / < /tmp/dconf-settings.ini 2>/dev/null || \
        DCONF_PROFILE=user dbus-run-session dconf load / < /tmp/dconf-settings.ini 2>/dev/null || \
        warn "dconf write skipped (no D-Bus) — gsettings will apply on first login"
    rm -f /tmp/dconf-settings.ini

    # Replace __HOME__ placeholder in configs that need absolute paths
    sed -i "s|__HOME__|$HOME|g" ~/.config/qt6ct/qt6ct.conf
    sed -i "s|__HOME__|$HOME|g" ~/.config/hypr/hyprpaper.conf
    sed -i "s|__HOME__|$HOME|g" ~/.config/hypr/hyprlock.conf
    sed -i "s|__HOME__|$HOME|g" ~/.config/hypr/hypridle.conf

    # MPD
    backup_config ~/.config/mpd
    mkdir -p ~/.config/mpd ~/.local/share/mpd/playlists ~/Music
    cp "$SCRIPT_DIR/configs/mpd/mpd.conf" ~/.config/mpd/mpd.conf

    # ncmpcpp
    backup_config ~/.config/ncmpcpp
    mkdir -p ~/.config/ncmpcpp
    cp "$SCRIPT_DIR/configs/ncmpcpp/config" ~/.config/ncmpcpp/config

    # Enable mpd and mpdris2 as systemd user services
    # systemctl --user doesn't work in chroot (no D-Bus session), so create symlinks manually
    mkdir -p ~/.config/systemd/user/default.target.wants
    ln -sf /usr/lib/systemd/user/mpd.service ~/.config/systemd/user/default.target.wants/mpd.service
    ln -sf /usr/lib/systemd/user/mpdris2.service ~/.config/systemd/user/default.target.wants/mpdris2.service

    # Fastfetch
    backup_config ~/.config/fastfetch
    mkdir -p ~/.config/fastfetch
    cp "$SCRIPT_DIR/configs/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
    cp "$SCRIPT_DIR/configs/fastfetch/logo.txt" ~/.config/fastfetch/logo.txt

    info "Shared configs deployed (kitty, starship, qt6ct, GTK, mpd, ncmpcpp, fastfetch)"

    checkpoint "configs-deployed"
fi

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
# Build & Install Welcome App
# =============================================================================
header "Building Void Command Welcome App"

if command -v void-command-welcome &>/dev/null; then
    info "Welcome app already installed — skipping"
else
    WELCOME_BUILD=$(mktemp -d)
    cmake -B "$WELCOME_BUILD" -S "$SCRIPT_DIR/welcome-app" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr 2>&1 | tail -5
    cmake --build "$WELCOME_BUILD" -j"$(nproc)" 2>&1 | tail -5
    sudo cmake --install "$WELCOME_BUILD" 2>&1
    rm -rf "$WELCOME_BUILD"

    # Autostart on first login (removes itself after first run)
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/void-command-welcome.desktop <<'AUTOSTART'
[Desktop Entry]
Name=Void Command Welcome
Exec=bash -c 'void-command-welcome; rm -f ~/.config/autostart/void-command-welcome.desktop'
Type=Application
X-GNOME-Autostart-enabled=true
AUTOSTART

    info "Welcome app installed to /usr/bin/void-command-welcome"
fi

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

    # scp from remote host
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
echo "The Void Command Welcome App will launch on first login to help you"
echo "install apps, enable services, and apply common fixes."
echo ""
echo "Remaining manual steps after reboot:"
echo "  1. GitHub authentication:  gh auth login -p ssh"
if [[ -z "${SSH_RESTORE_SOURCE:-}" ]]; then
    echo "  2. Restore SSH keys:       scp -r user@host:/path/to/ssh-backup/ ~/.ssh/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*"
fi
echo ""
echo "Login: greetd (tuigreet) → Hyprland + Quickshell (Void Command theme)"
echo ""
