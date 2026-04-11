# Arch Linux Install Script

Automated Arch Linux installer with a custom Hyprland + Quickshell "Void Command" desktop.

## What You Get

- **CachyOS kernel** (optimized, Clang + ThinLTO, EEVDF scheduler)
- **BTRFS** with subvolumes (@, @home, @pkg, @log, @snapshots) + Snapper
- **systemd-boot** bootloader
- **Hyprland** tiling WM with Void Command theme (8 static color schemes + `auto` — a wallpaper-driven scheme that generates its palette from any image via matugen)
- **Quickshell** unified desktop shell (bar, launcher, notifications, power menu, sidebar, clipboard, screenshot)
- **greetd + tuigreet** login manager
- **Welcome App** for post-install setup — app catalog, common fixes, service toggles
- **GPU auto-detection**: AMD and NVIDIA drivers installed based on detected hardware
- **Zram** swap (25% RAM, zstd)
- Performance tuning: BBR, sched-ext, NVMe optimizations

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

### After Reboot

The **Void Command Welcome App** launches automatically on first login. Use it to:
- Install apps (browsers, gaming, emulators, dev tools, media players)
- Apply common fixes (NVIDIA flickering, bluetooth, audio, pacman keyring)
- Enable optional services (Docker, SSH, Tailscale, libvirtd, bluetooth)

```bash
# GitHub CLI auth
gh auth login
gh auth setup-git
```

## Project Structure

```
arch-install/
├── install.sh          # Phase 1: Run from Arch ISO — prompts, partitioning, pacstrap, chroot
├── chroot.sh           # Phase 2: System config (runs as root in chroot)
├── user-setup.sh       # Phase 3: User config (runs as $USER in chroot via su -l)
├── packages/
│   ├── base.txt        # Pacstrap packages
│   ├── official.txt    # Pacman packages (core system + desktop)
│   └── aur.txt         # AUR packages (desktop shell + theming)
├── configs/
│   ├── hyprland/       # Hyprland WM + hyprpaper + hyprlock configs
│   ├── quickshell/     # Quickshell QML desktop shell (bar, launcher, notifications, etc.)
│   ├── greetd/         # Login manager config (tuigreet → Hyprland)
│   ├── kitty/          # Terminal config
│   ├── starship/       # Shell prompt config
│   ├── qt6ct/          # Qt6 theming
│   ├── gtk-3.0/        # GTK3 theme
│   ├── gtk-4.0/        # GTK4 theme settings
│   └── bash/           # Shell aliases and integrations
├── welcome-app/        # Qt6/QML post-install welcome app (C++ backend)
├── wallpapers/         # Desktop wallpapers
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
