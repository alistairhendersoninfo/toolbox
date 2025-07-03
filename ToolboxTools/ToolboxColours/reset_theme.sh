#!/usr/bin/env bash
#MN Reset Dialog Theme
#MD Restores original .dialogrc from backup
#MDD Requires backup to have been performed; records reset action in database.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../ToolboxCore/db_functions.sh"

BACKUP_FILE="$HOME/.config/toolbox/dialogrc.original.backup"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found. Cannot restore."
  exit 1
fi

cp "$BACKUP_FILE" "$HOME/.dialogrc"
echo "Original .dialogrc restored."

# Record reset in database
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
db_write "INSERT INTO installs (software_name, task_group, task_name, status, updated_at) VALUES ('ToolboxColours', 'Theme Change', 'Reset to Original', 'completed', '$TIMESTAMP');"

exit 0
