#!/usr/bin/env bash
#MN install_toolbox
#MD Install Toolbox core components
#MDD Installs core dependencies, SQLite, initialises the database, and prepares the Toolbox environment with logging.
#MI ToolboxCore
#INFO https://your-toolbox-project-url/

LOGFILE=~/toolbox_install.log
exec > >(tee -a "$LOGFILE") 2>&1

echo "🔧 Starting Toolbox installation at $(date)"

# Install SQLite
echo "🔧 Installing SQLite..."
./ToolboxCore/install_sqlite.sh

# Initialise database
echo "🔧 Initialising Toolbox database..."
./ToolboxCore/db_init.sh

echo "✅ Toolbox installation complete at $(date)"
