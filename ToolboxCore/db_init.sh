#!/usr/bin/env bash
#MN db_init
#MD Initialise Toolbox SQLite database
#MDD Creates the SQLite database and state table for persistent tracking of all Toolbox scripts, including error message support.
#MI ToolboxCore
#INFO https://sqlite.org/

# Determine target user home directory robustly
if [ -n "$EFFECTIVE_USER" ]; then
  USER_HOME=$(eval echo "~$EFFECTIVE_USER")
else
  USER_HOME="$HOME"
fi

DB_DIR="$USER_HOME/.config/toolbox"
DBFILE="$DB_DIR/state.db"

echo "🔧 Initialising Toolbox database at $DBFILE..."

# Ensure directory exists with correct ownership
sudo mkdir -p "$DB_DIR"
sudo chown "$EFFECTIVE_USER:$EFFECTIVE_USER" "$DB_DIR"

# Create database and table
sqlite3 "$DBFILE" <<SQL
CREATE TABLE IF NOT EXISTS state (
  script TEXT NOT NULL,
  step TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT,
  timestamp TEXT NOT NULL,
  PRIMARY KEY (script, step)
);
SQL

echo "✅ Toolbox database initialised at $DBFILE with message column support."
