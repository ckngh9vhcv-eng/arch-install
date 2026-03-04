# Arch Linux Install Script

Automated Arch Linux installer that replicates a NixOS Hyprland + Quickshell "Void Command" workstation.

## What You Get

- **CachyOS kernel** (optimized, Clang + ThinLTO, EEVDF scheduler)
- **BTRFS** with subvolumes (@, @home, @pkg, @log, @snapshots) + Snapper
- **systemd-boot** bootloader
- **Hyprland** tiling WM with Void Command purple theme (#8B6FC0)
- **Quickshell** unified desktop shell (bar, launcher, notifications, power menu, sidebar, clipboard, screenshot)
- **greetd + tuigreet** login manager
- **Zram** swap (25% RAM, zstd)
- Steam, Wine, emulators, and full gaming stack
- Docker, QEMU/KVM, Tailscale
- **GPU auto-detection**: AMD and NVIDIA drivers installed based on detected hardware

## Usage

```bash
# 1. Boot Arch ISO

# 2. Connect to internet (ethernet auto-connects, or use iwctl for WiFi)
iwctl station wlan0 connect "WiFi Name"

# 3. Get the installer
pacman -Sy git
git clone https://github.com/ckngh9vhcv-eng/arch-install.git
cd arch-install

# 4. Run installer
./install.sh

# 5. Follow prompts: disk, username, password, hostname, timezone, git config

# 6. Reboot — system is fully configured
umount -R /mnt && reboot
```

### After Reboot — Manual Steps

```bash
# GitHub CLI auth
gh auth login
gh auth setup-git

# Tailscale VPN
sudo tailscale up

# Libvirt storage pool
virsh pool-define-as default dir - - - - /var/lib/libvirt/images
virsh pool-start default
virsh pool-autostart default
```

## Project Structure

```
arch-install/
├── install.sh          # Phase 1: Run from Arch ISO — prompts, partitioning, pacstrap, chroot
├── chroot.sh           # Phase 2: System config (runs as root in chroot)
├── user-setup.sh       # Phase 3: User config (runs as $USER in chroot via su -l)
├── packages/
│   ├── base.txt        # Pacstrap packages
│   ├── official.txt    # Pacman packages
│   └── aur.txt         # AUR packages (installed via paru)
├── configs/
│   ├── hyprland/       # Hyprland WM + hyprpaper + hyprlock configs
│   ├── quickshell/     # Quickshell QML desktop shell (bar, launcher, notifications, etc.)
│   ├── greetd/         # Login manager config (tuigreet → Hyprland)
│   ├── kitty/          # Terminal config (Void Command color scheme)
│   ├── starship/       # Shell prompt config
│   ├── qt6ct/          # Qt6 theming (Breeze Dark Purple)
│   ├── gtk-3.0/        # GTK3 theme (Layan-Dark + custom dark overrides)
│   ├── gtk-4.0/        # GTK4 theme settings
│   └── bash/           # Shell aliases and integrations
├── wallpapers/         # Desktop wallpaper
└── README.md
```

## Testing in a VM

```bash
# Create a UEFI VM with virt-manager
# - Firmware: OVMF (UEFI)
# - Disk: 60GB+ virtio
# - RAM: 4GB+
# Boot the Arch ISO and run ./install.sh
```

## Source

Ported from a NixOS Hyprland configuration.
