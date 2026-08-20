#!/usr/bin/env bash
set -euo pipefail

if command -v love &> /dev/null; then
    echo "love is already installed: $(love --version)"
else
    echo "Installing love2d..."
    sudo apt update && sudo apt install -y love2d
    echo "love installed: $(love --version)"
fi

echo "Run the game with: love ."