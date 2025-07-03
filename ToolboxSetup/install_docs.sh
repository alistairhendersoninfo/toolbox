#!/bin/bash

# MN: InstallDocs
# MD: Install MkDocs and generate initial GitHub Pages structure for toolbox using pipx

set -e

echo "[INFO] Installing python3-pip and pipx..."
sudo apt update
sudo apt install -y python3-pip pipx
pipx ensurepath

# Ensure pipx is in PATH immediately for this script
export PATH=$PATH:~/.local/bin

echo "[INFO] Installing MkDocs and Material theme via pipx..."
pipx install mkdocs
pipx inject mkdocs mkdocs-material

echo "[INFO] Creating docs/ directory..."
mkdir -p docs

echo "[INFO] Running init_pages.sh to populate docs/..."
./init_pages.sh

echo "[INFO] Creating mkdocs.yml configuration..."

tee mkdocs.yml <<'EOL'
site_name: Toolbox Documentation
theme:
  name: material

nav:
  - Home: index.md
EOL

echo "[INFO] MkDocs installation and initialisation complete."
echo "[INFO] To preview locally, run: mkdocs serve"
