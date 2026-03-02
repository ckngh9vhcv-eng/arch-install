#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 2 (Run inside chroot)
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

SCRIPT_DIR="/root/arch-install"

# Load hardware detection
source /root/hw-detect

# =============================================================================
# Locale & Timezone
# =============================================================================
header "Locale & Timezone"

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create vconsole.conf (needed by mkinitcpio sd-vconsole hook)
echo "KEYMAP=us" > /etc/vconsole.conf

info "Timezone: America/Chicago"
info "Locale: en_US.UTF-8"

# =============================================================================
# Hostname
# =============================================================================
header "Hostname"

read -rp "Enter hostname [archbox]: " HOSTNAME
HOSTNAME="${HOSTNAME:-archbox}"

echo "$HOSTNAME" > /etc/hostname

cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

info "Hostname set to: $HOSTNAME"

# =============================================================================
# CachyOS Repository
# =============================================================================
header "Setting Up CachyOS Repository"

info "Downloading CachyOS repo setup..."
cd /tmp
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo

info "Running CachyOS repo setup (auto-detects CPU arch)..."
# Use echo to answer prompts; avoid `yes |` which causes SIGPIPE with pipefail
echo "Y" | ./cachyos-repo.sh || true

cd /tmp
rm -rf cachyos-repo cachyos-repo.tar.xz

info "Syncing package databases with CachyOS repos..."
# || true: post-transaction hooks (mkinitcpio) may return non-zero on first run;
# we regenerate initramfs properly after installing the CachyOS kernel below.
pacman -Syu --noconfirm || true

# =============================================================================
# CachyOS Kernel
# =============================================================================
header "Installing CachyOS Kernel"

pacman -S --noconfirm linux-cachyos linux-cachyos-headers

# Remove stock kernel (installed by pacstrap)
info "Removing stock linux kernel..."
pacman -Rns --noconfirm linux || true

info "CachyOS kernel installed"

# =============================================================================
# Initramfs
# =============================================================================
header "Configuring Initramfs"

# Add btrfs to MODULES
sed -i 's/^MODULES=(.*)/MODULES=(btrfs)/' /etc/mkinitcpio.conf

mkinitcpio -P

info "Initramfs regenerated with btrfs module"

# =============================================================================
# Bootloader (systemd-boot)
# =============================================================================
header "Installing Bootloader"

bootctl install

# loader.conf
cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF

# Get root partition PARTUUID
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")

# Determine microcode
UCODE_INITRD=""
if [[ "$CPU_TYPE" == "amd" ]]; then
    UCODE_INITRD="initrd  /amd-ucode.img"
elif [[ "$CPU_TYPE" == "intel" ]]; then
    UCODE_INITRD="initrd  /intel-ucode.img"
fi

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux (CachyOS)
linux   /vmlinuz-linux-cachyos
${UCODE_INITRD}
initrd  /initramfs-linux-cachyos.img
options root=PARTUUID=${ROOT_PARTUUID} rootflags=subvol=@ rw quiet split_lock_detect=off
EOF

info "systemd-boot configured"

# =============================================================================
# Microcode
# =============================================================================
header "Installing CPU Microcode"

if [[ "$CPU_TYPE" == "amd" ]]; then
    pacman -S --noconfirm amd-ucode
    info "AMD microcode installed"
elif [[ "$CPU_TYPE" == "intel" ]]; then
    pacman -S --noconfirm intel-ucode
    info "Intel microcode installed"
fi

# =============================================================================
# User Creation
# =============================================================================
header "Creating User"

useradd -m -G wheel,docker,video,audio,libvirt,input -s /bin/bash mike

echo "Set password for mike:"
passwd mike

info "User mike created with groups: wheel, docker, video, audio, libvirt, input"

# =============================================================================
# Sudo
# =============================================================================
header "Configuring Sudo"

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

info "wheel group can now use sudo"

# =============================================================================
# Install Official Packages
# =============================================================================
header "Installing Official Packages"

# Read package list (strip comments and blank lines)
OFFICIAL_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/official.txt" | grep -v '^\s*$' | tr '\n' ' ')

pacman -S --noconfirm --needed $OFFICIAL_PKGS

info "Official packages installed"

# =============================================================================
# GPU Drivers
# =============================================================================
header "Installing GPU Drivers"

if [[ "$GPU_TYPE" == "amd" ]]; then
    pacman -S --noconfirm --needed \
        mesa vulkan-radeon libva-mesa-driver \
        rocm-opencl-runtime \
        lib32-mesa lib32-vulkan-radeon \
        corectrl
    info "AMD GPU drivers installed"
elif [[ "$GPU_TYPE" == "nvidia" ]]; then
    pacman -S --noconfirm --needed \
        nvidia-dkms nvidia-utils lib32-nvidia-utils \
        nvidia-settings
    info "NVIDIA GPU drivers installed"
fi

# =============================================================================
# Enable System Services
# =============================================================================
header "Enabling Services"

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable docker.service
systemctl enable libvirtd.service
systemctl enable sshd.service
systemctl enable tlp.service
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable tailscaled.service

info "System services enabled"

# =============================================================================
# Plasma Login Manager
# =============================================================================
header "Configuring Plasma Login Manager"

systemctl enable plasma-login-manager.service

# Autologin config
mkdir -p /etc/plasmalogin.conf.d
cp "$SCRIPT_DIR/configs/plasmalogin/autologin.conf" /etc/plasmalogin.conf.d/autologin.conf

info "Plasma Login Manager enabled with autologin for mike"

# =============================================================================
# Zram
# =============================================================================
header "Configuring Zram"

cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
compression-algorithm = zstd
zram-size = ram / 4
EOF

info "Zram configured (25% RAM, zstd compression)"

# =============================================================================
# Snapper
# =============================================================================
header "Configuring Snapper"

# Snapper needs the subvolume mounted — create config for root
# Unmount .snapshots first since snapper wants to create it
umount /.snapshots 2>/dev/null || true
rm -rf /.snapshots

snapper -c root create-config /

# Snapper creates its own .snapshots subvolume, remove it and remount ours
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -o subvol=@snapshots "$(findmnt -n -o SOURCE /)" /.snapshots

# Set snapshot limits
snapper -c root set-config \
    "ALLOW_USERS=mike" \
    "TIMELINE_CREATE=yes" \
    "TIMELINE_CLEANUP=yes" \
    "TIMELINE_LIMIT_HOURLY=0" \
    "TIMELINE_LIMIT_DAILY=7" \
    "TIMELINE_LIMIT_WEEKLY=2" \
    "TIMELINE_LIMIT_MONTHLY=1" \
    "TIMELINE_LIMIT_YEARLY=0"

info "Snapper root config created"

# =============================================================================
# TLP Power Management
# =============================================================================
header "Configuring TLP"

cat > /etc/tlp.conf <<EOF
# Performance governor on AC
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_BOOST_ON_AC=1
EOF

info "TLP configured for performance on AC"

# =============================================================================
# Git Configuration
# =============================================================================
header "Configuring Git"

# Set git config for mike (run as mike via su)
su - mike -c 'git config --global user.name "Mike"'
su - mike -c 'git config --global user.email "ckngh9vhcv-eng@users.noreply.github.com"'
su - mike -c 'git config --global init.defaultBranch "main"'
su - mike -c 'git config --global pull.rebase true'
su - mike -c 'git config --global credential.helper "!gh auth git-credential"'

info "Git configured for mike"

# =============================================================================
# KDE Panel Layout (System Default)
# =============================================================================
header "Installing KDE Panel Layout"

# Install layout.js as the system default panel layout
# This runs when a user first logs into Plasma with no existing panel config
LAYOUT_DIR="/usr/share/plasma/shells/org.kde.plasma.desktop/contents"
if [[ -d "$LAYOUT_DIR" ]]; then
    cp "$SCRIPT_DIR/configs/kde/layout.js" "$LAYOUT_DIR/layout.js"
    info "KDE panel layout installed"
else
    warn "Plasma layout directory not found — layout.js will be installed post-reboot"
    mkdir -p "$LAYOUT_DIR"
    cp "$SCRIPT_DIR/configs/kde/layout.js" "$LAYOUT_DIR/layout.js"
fi

# =============================================================================
# KDE Config Pre-seeding (via /etc/skel)
# =============================================================================
header "Pre-seeding KDE Config Files"

# These go to /etc/skel so new users inherit them.
# Also copy directly to mike's home since user already exists.

SKEL_CONFIG="/etc/skel/.config"
MIKE_CONFIG="/home/mike/.config"

mkdir -p "$SKEL_CONFIG" "$MIKE_CONFIG"

# KDE config files
for cfg in kwinrc kdeglobals kglobalshortcutsrc kscreenlockerrc kwalletrc powerdevilrc; do
    if [[ -f "$SCRIPT_DIR/configs/kde/$cfg" ]]; then
        cp "$SCRIPT_DIR/configs/kde/$cfg" "$SKEL_CONFIG/$cfg"
        cp "$SCRIPT_DIR/configs/kde/$cfg" "$MIKE_CONFIG/$cfg"
    fi
done

# Klassy config
mkdir -p "$SKEL_CONFIG/klassy" "$MIKE_CONFIG/klassy"
cp "$SCRIPT_DIR/configs/kde/klassyrc" "$SKEL_CONFIG/klassy/klassyrc"
cp "$SCRIPT_DIR/configs/kde/klassyrc" "$MIKE_CONFIG/klassy/klassyrc"

# KDE custom shortcut .desktop files
mkdir -p "$SKEL_CONFIG/autostart" "$MIKE_CONFIG/autostart"
if [[ -d "$SCRIPT_DIR/configs/kde/shortcuts" ]]; then
    for desktop_file in "$SCRIPT_DIR"/configs/kde/shortcuts/*.desktop; do
        [[ -f "$desktop_file" ]] || continue
        cp "$desktop_file" "$SKEL_CONFIG/"
        cp "$desktop_file" "$MIKE_CONFIG/"
    done
fi

# Fix ownership
chown -R mike:mike /home/mike

info "KDE configs pre-seeded to /etc/skel and /home/mike/.config"

# =============================================================================
# Copy Installer for Post-Reboot
# =============================================================================
header "Preparing Post-Reboot Setup"

cp -r "$SCRIPT_DIR" /home/mike/arch-install
chown -R mike:mike /home/mike/arch-install

info "Post-install script ready at /home/mike/arch-install/post-install.sh"

# =============================================================================
# Done
# =============================================================================
header "Chroot Phase Complete"

echo -e "${GREEN}${BOLD}System configured successfully.${NC}"
echo "Exit chroot, unmount, and reboot."
