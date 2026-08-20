#!/usr/bin/env bash
set -euo pipefail

if command -v love &>/dev/null; then
    echo "love is already installed: $(love --version)"
else
    echo "Installing love via pacman..."
    sudo pacman -S --needed love
fi

love --version
echo "Run the game with: love ."