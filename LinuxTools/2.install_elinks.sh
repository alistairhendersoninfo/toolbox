#!/usr/bin/env bash
#MN install_elinks
#MD Install ELinks browser
#MDD Installs ELinks, a feature-rich text-based browser with support for frames, tables, and extensive customisation.
#MI LinuxTools
#INFO http://elinks.or.cz/
#MC default
#MP 50
#MIICON globe
#MTAGS browser,text-based,elinks
#MAUTHOR Alistair Henderson

set -e

echo "[INFO] Installing ELinks browser..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y elinks
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y elinks
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y elinks
else
    echo "[ERROR] Unsupported package manager. Please install ELinks manually."
    exit 1
fi

echo "[SUCCESS] ELinks installation complete."
exit 0
