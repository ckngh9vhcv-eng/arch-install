#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 2 (Run inside chroot)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="/root/arch-install"
source "$SCRIPT_DIR/lib.sh"

# Load hardware detection + user config
source /root/hw-detect

# =============================================================================
# Locale & Timezone
# =============================================================================
header "Locale & Timezone"

# Configurable locale/keymap — override via environment or hw-detect
LOCALE="${LOCALE:-en_US.UTF-8}"
KEYMAP="${KEYMAP:-us}"

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i "s/^#${LOCALE} /${LOCALE} /" /etc/locale.gen
locale-gen

echo "LANG=${LOCALE}" > /etc/locale.conf

# Create vconsole.conf (needed by mkinitcpio sd-vconsole hook)
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

info "Timezone: $TIMEZONE"
info "Locale: $LOCALE"
info "Keymap: $KEYMAP"

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
if checkpoint_reached "cachyos-keys"; then
    info "CachyOS repo already configured — skipping"
else
    header "Setting Up CachyOS Repository"

    info "Downloading CachyOS repo setup..."
    cd /tmp
    curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz
    cd cachyos-repo

    info "Running CachyOS repo setup (auto-detects CPU arch)..."
    # Temporarily allow non-zero exit — script may return 1 even on success
    set +e
    echo "Y" | ./cachyos-repo.sh
    _cachyos_rc=$?
    set -e

    cd /tmp
    rm -rf cachyos-repo cachyos-repo.tar.xz

    # Validate CachyOS keys were imported successfully
    if ! pacman-key --list-keys 2>/dev/null | grep -qi cachyos; then
        error "CachyOS keyring import failed (exit code $_cachyos_rc). Check network and retry."
    fi
    info "CachyOS keys verified"

    checkpoint "cachyos-keys"
fi

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
if checkpoint_reached "chaotic-aur-keys"; then
    info "Chaotic-AUR repo already configured — skipping"
else
    header "Setting Up Chaotic-AUR Repository"

    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
    fi

    info "Chaotic-AUR repository enabled"
    checkpoint "chaotic-aur-keys"
fi

# =============================================================================
# Sync Repos
# =============================================================================
header "Syncing Package Databases"

info "Syncing package databases with CachyOS + Chaotic-AUR repos..."
# Post-transaction hooks (mkinitcpio) may return non-zero on first run before
# the CachyOS kernel is installed — we regenerate initramfs properly below.
set +e
pacman -Syu --noconfirm
_syu_rc=$?
set -e
if [[ $_syu_rc -ne 0 ]]; then
    warn "pacman -Syu exited with code $_syu_rc (may be harmless hook failure — continuing)"
fi

# =============================================================================
# CachyOS Kernel
# =============================================================================
header "Installing CachyOS Kernel"

spinner "Installing CachyOS kernel" pacman -S --noconfirm linux-cachyos linux-cachyos-headers

# Remove stock kernel if present (not installed by default, but may exist from manual pacstrap)
if pacman -Qi linux &>/dev/null; then
    info "Removing stock linux kernel..."
    pacman -Rns --noconfirm linux
fi

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
else
    warn "No microcode installed (CPU vendor: $CPU_TYPE)"
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
if checkpoint_reached "packages-installed"; then
    info "Official packages already installed — skipping"
else
    header "Installing Official Packages"

    # Read package list (strip comments and blank lines)
    OFFICIAL_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/official.txt" | grep -v '^\s*$' | tr '\n' ' ')

    spinner "Installing official packages" pacman -S --noconfirm --needed $OFFICIAL_PKGS

    # Install lib32 packages unless SKIP_LIB32=1
    if [[ "${SKIP_LIB32:-0}" != "1" ]] && [[ -f "$SCRIPT_DIR/packages/lib32.txt" ]]; then
        LIB32_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/lib32.txt" | grep -v '^\s*$' | tr '\n' ' ')
        if [[ -n "$LIB32_PKGS" ]]; then
            spinner "Installing lib32 packages" pacman -S --noconfirm --needed $LIB32_PKGS
        fi
    fi

    info "Official packages installed"
    checkpoint "packages-installed"
fi

# =============================================================================
# User Creation (after packages so docker/libvirt groups exist)
# =============================================================================
if checkpoint_reached "user-created"; then
    info "User $USERNAME already exists — skipping creation"
else
    header "Creating User"

    useradd -m -G wheel,docker,video,audio,libvirt,input -s /bin/bash "$USERNAME"

    echo "$USERNAME:$USER_PASSWORD" | chpasswd

    info "User $USERNAME created with groups: wheel, docker, video, audio, libvirt, input"
    checkpoint "user-created"
fi

# =============================================================================
# GPU Drivers
# =============================================================================
header "Installing GPU Drivers"

if [[ "$GPU_TYPE" == "nvidia" ]]; then
    pacman -S --noconfirm --needed \
        nvidia-dkms nvidia-utils lib32-nvidia-utils \
        nvidia-settings
    info "NVIDIA GPU drivers installed"
elif [[ "$GPU_TYPE" == "amd" ]]; then
    # CachyOS mesa-git already provides mesa, vulkan-radeon, and VA-API drivers.
    # Only install lib32 variants (for Steam/gaming) and corectrl.
    pacman -S --noconfirm --needed \
        lib32-mesa lib32-vulkan-radeon \
        corectrl
    info "AMD GPU drivers installed (mesa-git from CachyOS already active)"
elif [[ "$GPU_TYPE" == "intel" ]]; then
    pacman -S --noconfirm --needed \
        mesa vulkan-intel lib32-mesa lib32-vulkan-intel
    info "Intel GPU drivers installed"
else
    # VM or unrecognized — basic mesa
    pacman -S --noconfirm --needed mesa
    info "Basic mesa drivers installed (no dedicated GPU detected)"
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
systemctl enable power-profiles-daemon.service
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable tailscaled.service
systemctl enable scx_loader.service

info "System services enabled"

# =============================================================================
# Login Manager (greetd)
# =============================================================================
header "Configuring greetd Login Manager"

# Deploy greetd config
mkdir -p /etc/greetd
cp "$SCRIPT_DIR/configs/greetd/config.toml" /etc/greetd/config.toml

systemctl enable greetd.service
systemctl disable getty@tty1.service

info "greetd login manager enabled"

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
# User Setup (runs as $USERNAME inside chroot)
# =============================================================================
header "Running User Setup as $USERNAME"

# Grant temporary passwordless sudo for AUR installs
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-installer
chmod 0440 /etc/sudoers.d/99-installer

# Allow user to traverse /root and read installer files (default /root is 700)
chmod a+x /root
chmod -R a+rX /root/arch-install

su -l "$USERNAME" -c "SCRIPT_DIR=/root/arch-install GIT_NAME='$GIT_NAME' GIT_EMAIL='$GIT_EMAIL' SSH_RESTORE_SOURCE='$SSH_RESTORE_SOURCE' bash /root/arch-install/user-setup.sh"

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
