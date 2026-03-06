#!/bin/bash
# Void Command Arch Installer — Bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/ckngh9vhcv-eng/arch-install/main/bootstrap.sh)
set -euo pipefail

REPO="https://github.com/ckngh9vhcv-eng/arch-install.git"
DEST="/tmp/arch-install"

echo "==> Void Command Arch Installer"
echo ""

# Must be root
[[ $EUID -eq 0 ]] || { echo "ERROR: Run as root."; exit 1; }

# Need git
if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    pacman -Sy --noconfirm git
fi

# Clone or update
if [[ -d "$DEST/.git" ]]; then
    echo "==> Updating existing clone..."
    git -C "$DEST" pull --ff-only
else
    rm -rf "$DEST"
    echo "==> Cloning installer..."
    git clone "$REPO" "$DEST"
fi

echo "==> Starting install..."
echo ""
cd "$DEST"
bash install.sh
