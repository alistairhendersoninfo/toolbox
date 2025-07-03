#!/usr/bin/env bash
#MN Backup DialogRC
#MD Backup original .dialogrc before applying themes
#MDD Creates backup file and records state in state.db to allow future theme changes.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../ToolboxCore/db_functions.sh"

BACKUP_FILE="$HOME/.config/toolbox/dialogrc.original.backup"
mkdir -p "$HOME/.config/toolbox"

# Check if backup already done in db
BACKUP_DONE=$(db_read "SELECT value FROM config WHERE key='dialogrc_backup_done';")
if [ "$BACKUP_DONE" == "yes" ]; then
  echo "Backup already recorded in database."
  exit 0
fi

# Perform backup if file exists
if [ -f "$HOME/.dialogrc" ]; then
  cp "$HOME/.dialogrc" "$BACKUP_FILE"
  echo "Backup created at $BACKUP_FILE"
else
  echo "No existing .dialogrc found. Creating empty backup."
  touch "$BACKUP_FILE"
fi

# Record in database with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
db_write "INSERT INTO config (key, value, updated_at) VALUES ('dialogrc_backup_done', 'yes', '$TIMESTAMP');"

echo "Backup recorded in database."

exit 0
