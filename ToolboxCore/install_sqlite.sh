#!/usr/bin/env bash
#MN install_sqlite
#MD Install SQLite dependency
#MDD Installs sqlite3 package required for Toolbox persistent state tracking.
#MI ToolboxCore
#INFO https://sqlite.org/

echo "🔧 Installing SQLite..."

if ! command -v sqlite3 &>/dev/null; then
  sudo apt update && sudo apt install -y sqlite3
  echo "✅ SQLite installed."
else
  echo "ℹ️ SQLite already installed."
fi
