#!/usr/bin/env bash
#MN install_w3m
#MD Install w3m browser
#MDD Installs w3m, a text-based browser offering an alternative rendering approach and terminal-friendly interface.
#MI LinuxTools
#INFO http://w3m.sourceforge.net/
#MC default
#MP 51
#MIICON globe
#MTAGS browser,text-based,w3m
#MAUTHOR Alistair Henderson

set -e

echo "[INFO] Installing w3m browser..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y w3m
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y w3m
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y w3m
else
    echo "[ERROR] Unsupported package manager. Please install w3m manually."
    exit 1
fi

echo "[SUCCESS] w3m installation complete."
exit 0
