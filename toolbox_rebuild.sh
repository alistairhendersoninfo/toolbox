#!/usr/bin/env bash
#MN toolbox_rebuild
#MD Rebuild Toolbox Ninja menu and launcher
#MDD Rebuilds toolbox_menu.ini and regenerates the toolboxninja launcher to include all new scripts.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 5
#MIICON refresh
#MTAGS toolbox,update,rebuild
#MAUTHOR $(whoami)

set -e

echo "🔧 Rebuilding Toolbox menu system..."

# Rebuild toolboxninja
sudo -E $TOOLBOX_DIR/ToolboxCore/create_toolbox.sh

echo "✅ Toolbox rebuild complete. Launch with: toolboxninja"
