#!/usr/bin/env bash
#MN DB Functions
#MD SQLite read and write function library
#MDD Provides db_read and db_write wrapper functions for Toolbox database access.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu

DB_PATH="$HOME/.config/toolbox/state.db"

db_read() {
  local query="$1"
  sqlite3 "$DB_PATH" "$query"
}

db_write() {
  local query="$1"
  sqlite3 "$DB_PATH" "$query"
}
