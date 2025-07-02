#!/bin/bash

# MN: InstallAdvcp
# MD: Install advcp/advmv with optional aliases configured in .bashrc

set -e

echo "[INFO] Installing advcp and advmv..."

sudo add-apt-repository -y ppa:daniel-milde/ppa
sudo apt update
sudo apt install -y advcp

echo "[INFO] advcp and advmv installed."

# Remove MI tags for advcp and advmv in scripts
echo "[INFO] Removing MI tags for advcp/advmv from scripts..."
grep -rl '^# *MI:.*advcp' . | xargs sed -i '/^# *MI:.*advcp/d'
grep -rl '^# *MI:.*advmv' . | xargs sed -i '/^# *MI:.*advmv/d'

# Prompt for alias configuration
read -rp "Enter alias for cp (leave blank to skip aliasing cp): " cp_alias
read -rp "Enter alias for mv (leave blank to skip aliasing mv): " mv_alias

bashrc="$HOME/.bashrc"

if [ -n "$cp_alias" ]; then
    echo "alias $cp_alias='advcp'" >> "$bashrc"
    echo "[INFO] Added alias: $cp_alias -> advcp in $bashrc"
fi

if [ -n "$mv_alias" ]; then
    echo "alias $mv_alias='advmv'" >> "$bashrc"
    echo "[INFO] Added alias: $mv_alias -> advmv in $bashrc"
fi

echo "[INFO] Installation and alias configuration complete."
echo "[INFO] Reload your shell or run 'source ~/.bashrc' to activate aliases."
