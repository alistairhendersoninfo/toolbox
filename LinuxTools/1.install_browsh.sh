#!/usr/bin/env bash
#MN install_browsh
#MD Install Browsh browser
#MDD Installs Browsh, a modern text-based browser supporting HTML5, CSS3, JS, and video rendering via Firefox headless.
#MI LinuxTools
#INFO https://www.brow.sh/
#MC default
#MP 53
#MIICON globe
#MTAGS browser,text-based,browsh
#MAUTHOR Alistair Henderson

set -e

echo "[INFO] Installing Browsh browser..."

if ! command -v firefox >/dev/null 2>&1; then
    echo "[INFO] Firefox is required for Browsh. Installing Firefox..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y firefox
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y firefox
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y firefox
    else
        echo "[ERROR] Unsupported package manager. Please install Firefox manually."
        exit 1
    fi
fi

BROWSH_URL="https://github.com/browsh-org/browsh/releases/latest/download/browsh_amd64.deb"

if command -v apt-get >/dev/null 2>&1; then
    curl -LO "$BROWSH_URL"
    sudo dpkg -i browsh_amd64.deb || sudo apt-get install -f -y
    rm browsh_amd64.deb
elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
    echo "[ERROR] Browsh .rpm installation not yet implemented in this script."
    exit 1
else
    echo "[ERROR] Unsupported package manager. Please install Browsh manually."
    exit 1
fi

echo "[SUCCESS] Browsh installation complete."
exit 0
