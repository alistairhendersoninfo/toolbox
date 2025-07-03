#!/usr/bin/env bash
#MN db_init
#MD Initialise Toolbox SQLite database
#MDD Creates the SQLite database and state table for persistent tracking of all Toolbox scripts, including error message support.
#MI ToolboxCore
#INFO https://sqlite.org/

mkdir -p ~/.config/toolbox

sqlite3 ~/.config/toolbox/state.db <<SQL
CREATE TABLE IF NOT EXISTS state (
  script TEXT NOT NULL,
  step TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT,
  timestamp TEXT NOT NULL,
  PRIMARY KEY (script, step)
);
SQL

echo "✅ Toolbox database initialised at ~/.config/toolbox/state.db with message column support."
