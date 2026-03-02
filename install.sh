#!/bin/bash
# =============================================================================
# Arch Linux Installer — Phase 1 (Run from Arch ISO)
# Replicates NixOS workstation setup: BTRFS, systemd-boot, CachyOS kernel
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
if lspci | grep -qi "AMD.*VGA\|Radeon\|AMD/ATI"; then
    GPU_TYPE="amd"
    info "Detected AMD GPU"
elif lspci | grep -qi "NVIDIA"; then
    GPU_TYPE="nvidia"
    info "Detected NVIDIA GPU"
else
    warn "No AMD or NVIDIA GPU detected, defaulting to mesa"
    GPU_TYPE="amd"
fi

# CPU detection
CPU_TYPE="unknown"
if grep -qi "AMD" /proc/cpuinfo; then
    CPU_TYPE="amd"
    info "Detected AMD CPU"
elif grep -qi "Intel" /proc/cpuinfo; then
    CPU_TYPE="intel"
    info "Detected Intel CPU"
else
    warn "Could not detect CPU vendor"
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
# Partitioning
# =============================================================================
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

ESP="${PART_PREFIX}1"
ROOT_PART="${PART_PREFIX}2"

info "ESP: $ESP"
info "Root: $ROOT_PART"

# =============================================================================
# Formatting
# =============================================================================
header "Formatting"

info "Formatting ESP as FAT32..."
mkfs.vfat -F 32 -n EFI "$ESP"

info "Formatting root as BTRFS..."
mkfs.btrfs -f -L archroot "$ROOT_PART"

# =============================================================================
# BTRFS Subvolumes
# =============================================================================
header "Creating BTRFS Subvolumes"

mount "$ROOT_PART" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots

umount /mnt

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
# Pacstrap
# =============================================================================
header "Installing Base System"

# Read base packages (strip comments and blank lines)
BASE_PKGS=$(grep -v '^\s*#' "$SCRIPT_DIR/packages/base.txt" | grep -v '^\s*$' | tr '\n' ' ')

pacstrap -K /mnt $BASE_PKGS

info "Base system installed"

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
EOF

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
# Done
# =============================================================================
header "Installation Complete!"

echo -e "${GREEN}${BOLD}The base system is installed.${NC}"
echo ""
echo "Next steps:"
echo "  1. Reboot: umount -R /mnt && reboot"
echo "  2. Log in as mike"
echo "  3. Run: ~/arch-install/post-install.sh"
echo ""
