#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 1 (Run from Arch ISO)
# Replicates NixOS workstation setup: BTRFS, systemd-boot, CachyOS kernel
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Log everything to a file as well as the terminal
INSTALL_LOG="/tmp/void-command-install.log"
exec > >(tee -a "$INSTALL_LOG") 2>&1

# =============================================================================
# Preflight Checks
# =============================================================================
header "Preflight Checks"

# Must be root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Must be UEFI
[[ -d /sys/firmware/efi ]] || error "UEFI mode not detected. Boot in UEFI mode."

# Internet connectivity
info "Checking internet connectivity..."
if ping -c 1 -W 3 1.1.1.1 &>/dev/null || ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    info "Internet OK"
else
    error "No internet connection. Connect first (iwctl or ethernet)."
fi

# =============================================================================
# Hardware Detection
# =============================================================================
header "Hardware Detection"

# GPU detection
GPU_TYPE="unknown"
if lspci | grep -qi "NVIDIA"; then
    GPU_TYPE="nvidia"
    info "Detected NVIDIA GPU"
elif lspci | grep -qi "AMD.*VGA\|Radeon\|AMD/ATI"; then
    GPU_TYPE="amd"
    info "Detected AMD GPU"
elif lspci | grep -qi "Intel.*Graphics\|Intel.*Xe\|Intel.*Arc"; then
    GPU_TYPE="intel"
    info "Detected Intel GPU"
else
    warn "No dedicated GPU detected — installing basic mesa"
    GPU_TYPE="mesa"
fi

# CPU detection
CPU_TYPE="unknown"
if grep -qi "GenuineIntel" /proc/cpuinfo; then
    CPU_TYPE="intel"
    info "Detected Intel CPU"
elif grep -qi "AuthenticAMD" /proc/cpuinfo; then
    CPU_TYPE="amd"
    info "Detected AMD CPU"
else
    warn "Unknown CPU vendor — skipping microcode"
    CPU_TYPE="none"
fi

# =============================================================================
# Disk Selection
# =============================================================================
header "Disk Selection"

echo "Available disks:"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v "loop\|sr\|rom"
echo ""

read -rp "Enter target disk (e.g., sda, nvme0n1): " DISK_NAME
DISK="/dev/${DISK_NAME}"

[[ -b "$DISK" ]] || error "Disk $DISK does not exist"

echo ""
echo -e "${RED}${BOLD}WARNING: ALL DATA ON $DISK WILL BE DESTROYED${NC}"
lsblk "$DISK"
echo ""
read -rp "Type 'YES' to confirm: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || error "Aborted by user"

# =============================================================================
# User Configuration Prompts
# =============================================================================
header "User Configuration"

# Username (required, validated)
while true; do
    read -rp "Enter username: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo -e "${RED}Username cannot be empty${NC}"
    elif [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo -e "${RED}Username must start with a lowercase letter and contain only lowercase letters, digits, hyphens, or underscores${NC}"
    else
        break
    fi
done

# Password (required, with confirmation)
while true; do
    read -srp "Enter password for $USERNAME: " USER_PASSWORD
    echo ""
    read -srp "Confirm password: " USER_PASSWORD_CONFIRM
    echo ""
    if [[ -z "$USER_PASSWORD" ]]; then
        echo -e "${RED}Password cannot be empty${NC}"
    elif [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
        echo -e "${RED}Passwords do not match. Try again.${NC}"
    else
        break
    fi
done

# Hostname
read -rp "Enter hostname [archbox]: " HOSTNAME
HOSTNAME="${HOSTNAME:-archbox}"

# Timezone (validated)
read -rp "Enter timezone [America/Chicago]: " TIMEZONE
TIMEZONE="${TIMEZONE:-America/Chicago}"
if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    error "Invalid timezone: $TIMEZONE (check: timedatectl list-timezones)"
fi

# Locale & keymap (overridable via environment)
LOCALE="${LOCALE:-en_US.UTF-8}"
KEYMAP="${KEYMAP:-us}"

# Git config (optional)
GIT_NAME=""
GIT_EMAIL=""
read -rp "Configure git? (y/n) [n]: " CONFIGURE_GIT
if [[ "${CONFIGURE_GIT,,}" == "y" ]]; then
    read -rp "Git display name: " GIT_NAME
    read -rp "Git email: " GIT_EMAIL
fi

# SSH key restore (optional)
SSH_RESTORE_SOURCE=""
read -rp "Restore SSH keys from a remote host? (y/n) [n]: " RESTORE_SSH
if [[ "${RESTORE_SSH,,}" == "y" ]]; then
    read -rp "Enter source (user@host:/path/to/.ssh): " SSH_RESTORE_SOURCE
    if [[ -n "$SSH_RESTORE_SOURCE" ]]; then
        info "SSH keys will be restored from: $SSH_RESTORE_SOURCE"
    fi
fi

info "Username:  $USERNAME"
info "Hostname:  $HOSTNAME"
info "Timezone:  $TIMEZONE"
info "Locale:    $LOCALE"
info "Keymap:    $KEYMAP"
if [[ -n "$GIT_NAME" ]]; then
    info "Git name:  $GIT_NAME"
    info "Git email: $GIT_EMAIL"
fi

# =============================================================================
# Partitioning
# =============================================================================
if checkpoint_reached "partitioned"; then
    info "Partitioning already done — skipping"
else
    header "Partitioning $DISK"

    # Determine partition naming (nvme uses p1, sata uses 1)
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi

    info "Wiping partition table..."
    sgdisk --zap-all "$DISK"

    info "Creating GPT partition table..."
    sgdisk -n 1:0:+1G -t 1:EF00 -c 1:"EFI" "$DISK"
    sgdisk -n 2:0:0   -t 2:8300 -c 2:"Linux" "$DISK"

    # Inform kernel of partition changes
    partprobe "$DISK"
    sleep 2

    checkpoint "partitioned"
fi

# Partition paths (needed whether we partitioned or skipped)
if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi
ESP="${PART_PREFIX}1"
ROOT_PART="${PART_PREFIX}2"

info "ESP: $ESP"
info "Root: $ROOT_PART"

# =============================================================================
# Formatting
# =============================================================================
if checkpoint_reached "formatted"; then
    info "Formatting already done — skipping"
else
    header "Formatting"

    info "Formatting ESP as FAT32..."
    mkfs.vfat -F 32 -n EFI "$ESP"

    info "Formatting root as BTRFS..."
    mkfs.btrfs -f -L archroot "$ROOT_PART"

    # =========================================================================
    # BTRFS Subvolumes
    # =========================================================================
    header "Creating BTRFS Subvolumes"

    mount "$ROOT_PART" /mnt

    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@snapshots

    umount /mnt

    checkpoint "formatted"
fi

# =============================================================================
# Mount Subvolumes
# =============================================================================
header "Mounting Subvolumes"

BTRFS_OPTS="noatime,compress=zstd:1,space_cache=v2,discard=async"

mount -o "subvol=@,${BTRFS_OPTS}" "$ROOT_PART" /mnt

mkdir -p /mnt/{home,var/cache/pacman/pkg,var/log,.snapshots,boot}

mount -o "subvol=@home,${BTRFS_OPTS}" "$ROOT_PART" /mnt/home
mount -o "subvol=@pkg,${BTRFS_OPTS}" "$ROOT_PART" /mnt/var/cache/pacman/pkg
mount -o "subvol=@log,${BTRFS_OPTS}" "$ROOT_PART" /mnt/var/log
mount -o "subvol=@snapshots,${BTRFS_OPTS}" "$ROOT_PART" /mnt/.snapshots

mount "$ESP" /mnt/boot

info "All subvolumes mounted"

# =============================================================================
# Disk Space Check
# =============================================================================
avail=$(df --output=avail /mnt | tail -1)
if [[ "$avail" -lt 20971520 ]]; then
    error "Less than 20GB available on /mnt ($((avail / 1048576))GB). Need at least 20GB."
fi
info "Disk space OK: $((avail / 1048576))GB available"

# =============================================================================
# Pacstrap
# =============================================================================
if checkpoint_reached "pacstrapped"; then
    info "Base system already installed — skipping pacstrap"
else
    header "Installing Base System"

    # Read base packages (strip comments and blank lines)
    BASE_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/base.txt" | grep -v '^\s*$' | tr '\n' ' ')

    spinner "Installing base system (pacstrap)" pacstrap -K /mnt $BASE_PKGS

    info "Base system installed"
    checkpoint "pacstrapped"
fi

# =============================================================================
# Generate fstab
# =============================================================================
header "Generating fstab"

genfstab -U /mnt >> /mnt/etc/fstab
info "fstab generated"
cat /mnt/etc/fstab

# =============================================================================
# Pass Hardware Detection to Chroot
# =============================================================================
cat > /mnt/root/hw-detect <<EOF
GPU_TYPE=$GPU_TYPE
CPU_TYPE=$CPU_TYPE
ROOT_PART=$ROOT_PART
ESP=$ESP
USERNAME=$USERNAME
USER_PASSWORD=$USER_PASSWORD
HOSTNAME=$HOSTNAME
TIMEZONE=$TIMEZONE
LOCALE=$LOCALE
KEYMAP=$KEYMAP
GIT_NAME=$GIT_NAME
GIT_EMAIL=$GIT_EMAIL
SSH_RESTORE_SOURCE=$SSH_RESTORE_SOURCE
EOF
chmod 600 /mnt/root/hw-detect

# =============================================================================
# Copy Project into Chroot
# =============================================================================
header "Copying Installer to Chroot"

cp -r "$SCRIPT_DIR" /mnt/root/arch-install
info "Project copied to /mnt/root/arch-install"

# =============================================================================
# Enter Chroot
# =============================================================================
header "Entering Chroot"

arch-chroot /mnt /root/arch-install/chroot.sh

# =============================================================================
# Copy Install Log to Target System
# =============================================================================
if [[ -f "$INSTALL_LOG" ]]; then
    mkdir -p /mnt/var/log
    cp "$INSTALL_LOG" /mnt/var/log/void-command-install.log
    info "Install log saved to /var/log/void-command-install.log"
fi

# =============================================================================
# Done
# =============================================================================
header "Installation Complete!"

echo -e "${GREEN}${BOLD}Installation complete! Your system is fully configured.${NC}"
echo ""
echo "Reboot: umount -R /mnt && reboot"
echo ""
