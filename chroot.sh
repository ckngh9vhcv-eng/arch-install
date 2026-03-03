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

# Load hardware detection + user config
source /root/hw-detect

# =============================================================================
# Locale & Timezone
# =============================================================================
header "Locale & Timezone"

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create vconsole.conf (needed by mkinitcpio sd-vconsole hook)
echo "KEYMAP=us" > /etc/vconsole.conf

info "Timezone: $TIMEZONE"
info "Locale: en_US.UTF-8"

# =============================================================================
# Hostname
# =============================================================================
header "Hostname"

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

# Enable multilib repo (needed for lib32-* gaming packages)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
    info "multilib repository enabled"
fi

# Enable parallel downloads
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
info "Pacman parallel downloads set to 10"

# =============================================================================
# Chaotic-AUR Repository
# =============================================================================
header "Setting Up Chaotic-AUR Repository"

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

info "Chaotic-AUR repository enabled"

# =============================================================================
# Sync Repos
# =============================================================================
header "Syncing Package Databases"

info "Syncing package databases with CachyOS + Chaotic-AUR repos..."
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
# User Creation (after packages so docker/libvirt groups exist)
# =============================================================================
header "Creating User"

useradd -m -G wheel,docker,video,audio,libvirt,input -s /bin/bash "$USERNAME"

echo "$USERNAME:$USER_PASSWORD" | chpasswd

info "User $USERNAME created with groups: wheel, docker, video, audio, libvirt, input"

# =============================================================================
# GPU Drivers
# =============================================================================
header "Installing GPU Drivers"

if [[ "$GPU_TYPE" == "amd" ]]; then
    # CachyOS mesa-git already provides mesa, vulkan-radeon, and VA-API drivers.
    # Only install lib32 variants (for Steam/gaming) and corectrl.
    # Skip mesa/vulkan-radeon — they conflict with CachyOS mesa-git.
    pacman -S --noconfirm --needed \
        lib32-mesa lib32-vulkan-radeon \
        corectrl
    info "AMD GPU drivers installed (mesa-git from CachyOS already active)"
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

systemctl enable plasmalogin.service

info "Plasma Login Manager enabled"

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

# snapper create-config uses D-Bus which isn't available in chroot.
# Write the config file manually instead.
mkdir -p /etc/snapper/configs
cat > /etc/snapper/configs/root <<SNAPEOF
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS="$USERNAME"
ALLOW_GROUPS=""
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="0"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="2"
TIMELINE_LIMIT_MONTHLY="1"
TIMELINE_LIMIT_YEARLY="0"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
SNAPEOF

# Register root config in snapper's config list
if ! grep -q "^SNAPPER_CONFIGS=" /etc/conf.d/snapper 2>/dev/null; then
    mkdir -p /etc/conf.d
    echo 'SNAPPER_CONFIGS="root"' > /etc/conf.d/snapper
else
    sed -i 's/^SNAPPER_CONFIGS=.*/SNAPPER_CONFIGS="root"/' /etc/conf.d/snapper
fi

info "Snapper root config created (manual — D-Bus unavailable in chroot)"

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
# KDE Config Pre-seeding (via /etc/skel only)
# =============================================================================
header "Pre-seeding KDE Config to /etc/skel"

SKEL_CONFIG="/etc/skel/.config"
mkdir -p "$SKEL_CONFIG"

# KDE config files (INI-style settings)
for cfg in kwinrc kdeglobals kglobalshortcutsrc kscreenlockerrc kwalletrc powerdevilrc; do
    if [[ -f "$SCRIPT_DIR/configs/kde/$cfg" ]]; then
        cp "$SCRIPT_DIR/configs/kde/$cfg" "$SKEL_CONFIG/$cfg"
    fi
done

# Klassy config
mkdir -p "$SKEL_CONFIG/klassy"
cp "$SCRIPT_DIR/configs/kde/klassyrc" "$SKEL_CONFIG/klassy/klassyrc"

# KDE custom shortcut .desktop files
mkdir -p "$SKEL_CONFIG/autostart"
if [[ -d "$SCRIPT_DIR/configs/kde/shortcuts" ]]; then
    for desktop_file in "$SCRIPT_DIR"/configs/kde/shortcuts/*.desktop; do
        [[ -f "$desktop_file" ]] || continue
        cp "$desktop_file" "$SKEL_CONFIG/"
    done
fi

info "KDE configs pre-seeded to /etc/skel"

# =============================================================================
# KDE Global Theme (Panel Layout)
# =============================================================================
header "Installing KDE Global Theme"

THEME_DEST="/usr/share/plasma/look-and-feel/arch-install-theme"
mkdir -p "$THEME_DEST"
cp -r "$SCRIPT_DIR/configs/kde/global-theme/arch-install-theme/"* "$THEME_DEST/"

info "Global theme installed to $THEME_DEST"

# =============================================================================
# User Setup (runs as $USERNAME inside chroot)
# =============================================================================
header "Running User Setup as $USERNAME"

# Grant temporary passwordless sudo for AUR installs
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-installer
chmod 0440 /etc/sudoers.d/99-installer

# Allow user to traverse /root and read installer files (default /root is 700)
chmod a+x /root
chmod -R a+rX /root/arch-install

su -l "$USERNAME" -c "SCRIPT_DIR=/root/arch-install GIT_NAME='$GIT_NAME' GIT_EMAIL='$GIT_EMAIL' bash /root/arch-install/user-setup.sh"

# Remove temporary passwordless sudo
rm -f /etc/sudoers.d/99-installer

info "User setup complete"

# =============================================================================
# Cleanup
# =============================================================================
header "Cleaning Up"

rm -f /root/hw-detect

info "Sensitive data cleaned up"

# =============================================================================
# Done
# =============================================================================
header "Chroot Phase Complete"

echo -e "${GREEN}${BOLD}System configured successfully.${NC}"
echo "Exit chroot, unmount, and reboot."
