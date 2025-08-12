#!/usr/bin/env bash
#MN install_toolbox_foundations
#MD Install Toolbox foundational dependencies (root)
#MDD Installs sqlite3, jq, dialog, initialises database and menu table system-wide as root, setting correct ownership and permissions for ToolBox Ninja operations for the EFFECTIVE_USER.
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MC danger
#MP top
#MIICON wrench
#MTAGS install,foundation,root,toolbox
#MAUTHOR Alistair Henderson

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

TOOLBOX_CORE="/opt/toolbox/ToolboxCore"

# Load generic functions
source "$TOOLBOX_CORE/generic_functions.sh"
resolve_user_home

# Ensure EFFECTIVE_USER is exported for child scripts
export EFFECTIVE_USER

echo "🔧 Starting ROOT installation of Toolbox foundational dependencies..."
echo "🔧 Installing for EFFECTIVE_USER=$EFFECTIVE_USER"

# Update package index
echo "🔧 Updating package index..."
apt update

# Install sqlite3 if not installed
if ! command -v sqlite3 &>/dev/null; then
  echo "🔧 Installing sqlite3..."
  apt install -y sqlite3
else
  echo "ℹ️ sqlite3 already installed."
fi

# Install jq if not installed
if ! command -v jq &>/dev/null; then
  echo "🔧 Installing jq..."
  apt install -y jq
else
  echo "ℹ️ jq already installed."
fi

# Install dialog if not installed
if ! command -v dialog &>/dev/null; then
  echo "🔧 Installing dialog..."
  apt install -y dialog
else
  echo "ℹ️ dialog already installed."
fi


# Install python3-dialog if not installed
if ! dpkg -l | grep -q python3-dialog; then
    echo "🔧 Installing python3-dialog..."
    sudo apt-get install -y python3-dialog >/dev/null
    echo "✅ python3-dialog installed successfully."
else
    echo "ℹ️ python3-dialog is already installed."
fi



# Initialise state.db if not present
DB_DIR="$USER_HOME/.config/toolbox"
DBFILE="$DB_DIR/state.db"

if [ ! -f "$DBFILE" ]; then
  echo "🔧 Creating initial state.db database..."
  sudo -u "$EFFECTIVE_USER" "$TOOLBOX_CORE/db_init.sh"
else
  echo "ℹ️ Database state.db already exists."
fi

# Ensure correct ownership and permissions
echo "🔧 Setting ownership and permissions on $DBFILE..."
chown "$EFFECTIVE_USER:$EFFECTIVE_USER" "$DBFILE"
chmod 600 "$DBFILE"

# Initialise menu table schema (drop and recreate)
echo "🔧 Initialising menu table schema..."
sudo -u "$EFFECTIVE_USER" EFFECTIVE_USER="$EFFECTIVE_USER" "$TOOLBOX_CORE/db_init_menu_extended.sh"

echo "✅ Toolbox foundational installation complete for user: $EFFECTIVE_USER (run as root)."
