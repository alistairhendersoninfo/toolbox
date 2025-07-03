#!/usr/bin/env bash
#MN install_toolbox_ninja
#MD Full Toolbox Ninja installer
#MDD Installs all Toolbox components, initialises database, sets TOOLBOX_DIR globally, and prepares menus with branding.
#MI ToolboxCore
#INFO https://your-toolbox-project-url/

set -e

LOGFILE=~/toolbox_full_setup.log
exec > >(tee -a "$LOGFILE") 2>&1

# Determine and export EFFECTIVE_USER
if [ -n "$SUDO_USER" ]; then
  export EFFECTIVE_USER="$SUDO_USER"
else
  export EFFECTIVE_USER="$USER"
fi

# Source generic_functions to resolve TOOLBOX_DIR
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/ToolboxCore/generic_functions.sh"

echo "🔧 Starting FULL Toolbox setup at $(date)"
echo "🔧 Detected TOOLBOX_DIR as $TOOLBOX_DIR"

# Install Toolbox core components
echo "🔧 Running install_toolbox.sh..."
sudo -E $TOOLBOX_DIR/ToolboxCore/install_toolbox.sh

# Create initial Toolbox scripts/config
echo "🔧 Running create_toolbox.sh..."
sudo -E $TOOLBOX_DIR/ToolboxCore/create_toolbox.sh

echo "✅ FULL Toolbox setup complete at $(date)"
