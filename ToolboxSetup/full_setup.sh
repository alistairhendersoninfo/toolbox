#!/usr/bin/env bash
#MN full_toolbox_setup
#MD Full Toolbox setup and initialise
#MDD Runs install, database initialisation, and creates the initial Toolbox scripts and menus.
#MI ToolboxCore
#INFO https://your-toolbox-project-url/

set -e

LOGFILE=~/toolbox_full_setup.log
exec > >(tee -a "$LOGFILE") 2>&1

echo "🔧 Starting FULL Toolbox setup at $(date)"

# Install Toolbox core components
echo "🔧 Running install_toolbox.sh..."
sudo /opt/toolbox/ToolboxCore/install_toolbox.sh

# Create initial Toolbox scripts/config
echo "🔧 Running create_toolbox.sh..."
sudo /opt/toolbox/ToolboxCore/create_toolbox.sh

echo "✅ FULL Toolbox setup complete at $(date)"
