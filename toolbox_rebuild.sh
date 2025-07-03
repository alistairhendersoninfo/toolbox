#!/usr/bin/env bash
#MN toolbox_rebuild
#MD Rebuild Toolbox menu and launcher
#MDD Rebuilds toolbox_menu.ini and regenerates the launcher to include all new scripts, ensuring menus are up to date.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 5
#MIICON refresh
#MTAGS toolbox,update
#MAUTHOR $(whoami)

set -e

echo "🔧 Rebuilding Toolbox menu system..."

# Source generic functions to resolve TOOLBOX_DIR
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/ToolboxCore/generic_functions.sh"

# Rebuild toolbox
sudo -E $TOOLBOX_DIR/ToolboxCore/create_toolbox.sh

echo "✅ Toolbox rebuild complete. Launch with: toolbox"
