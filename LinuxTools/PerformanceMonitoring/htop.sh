#!/bin/bash
#MN: Htop
#MD: Interactive process viewer with color and tree view.

if ! command -v htop >/dev/null 2>&1; then
    echo "Installing htop..."
    sudo apt update && sudo apt install -y htop
fi

htop
