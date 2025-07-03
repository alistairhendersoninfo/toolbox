#!/usr/bin/env bash
#MN install_toolbox
#MD Install Toolbox core components
#MDD Installs core dependencies, SQLite, initialises the database, sets global TOOLBOX_DIR, and prepares the Toolbox environment with logging.
#MI ToolboxCore
#INFO https://your-toolbox-project-url/

# Source generic_functions to set TOOLBOX_DIR
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/generic_functions.sh"

LOGFILE=~/toolbox_install.log
exec > >(tee -a "$LOGFILE") 2>&1

echo "🔧 Starting Toolbox installation at $(date)"
echo "🔧 Detected TOOLBOX_DIR as $TOOLBOX_DIR"

# Install SQLite
echo "🔧 Installing SQLite..."
$TOOLBOX_DIR/ToolboxCore/install_sqlite.sh

# Initialise database
echo "🔧 Initialising Toolbox database..."
$TOOLBOX_DIR/ToolboxCore/db_init.sh

# Set TOOLBOX_DIR globally for all users via /etc/profile.d
echo "🔧 Setting TOOLBOX_DIR globally in /etc/profile.d/toolbox_env.sh"
sudo tee /etc/profile.d/toolbox_env.sh > /dev/null << EOL
#!/usr/bin/env bash
# Set TOOLBOX_DIR globally for Toolbox scripts and users
export TOOLBOX_DIR="$TOOLBOX_DIR"
EOL

sudo chmod +x /etc/profile.d/toolbox_env.sh

echo "✅ TOOLBOX_DIR set globally to $TOOLBOX_DIR"
echo "✅ Toolbox installation complete at $(date)"
