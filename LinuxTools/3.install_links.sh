#!/usr/bin/env bash
#MN install_links
#MD Install Links browser
#MDD Installs Links, a versatile text-based browser with multiple rendering modes and extensive features.
#MI LinuxTools
#INFO http://links.twibright.com/
#MC default
#MP 52
#MIICON globe
#MTAGS browser,text-based,links
#MAUTHOR Alistair Henderson

set -e

echo "[INFO] Installing Links browser..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y links
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y links
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y links
else
    echo "[ERROR] Unsupported package manager. Please install Links manually."
    exit 1
fi

echo "[SUCCESS] Links installation complete."
exit 0
