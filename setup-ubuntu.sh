#!/usr/bin/env bash
set -euo pipefail

if command -v love &> /dev/null; then
    echo "love is already installed: $(love --version)"
else
    echo "Installing love2d..."
    sudo apt update && sudo apt install -y love2d
    echo "love installed: $(love --version)"
fi

if command -v luarocks &> /dev/null; then
    echo "luarocks is already installed: $(luarocks --version)"
else
    echo "Installing luarocks..."
    sudo apt update && sudo apt install -y luarocks
    echo "luarocks installed: $(luarocks --version)"
fi

echo "love: $(love --version)"
echo "luarocks: $(luarocks --version)"
echo "Run the game with: love ."