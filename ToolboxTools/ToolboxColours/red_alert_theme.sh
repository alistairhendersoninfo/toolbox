#!/usr/bin/env bash
#MN Apply Red Alert Theme
#MD Applies red alert colour theme to dialog
#MDD Requires backup to have been performed; records change in database.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../ToolboxCore/db_functions.sh"

BACKUP_FILE="$HOME/.config/toolbox/dialogrc.original.backup"
BACKUP_DONE=$(db_read "SELECT value FROM config WHERE key='dialogrc_backup_done';")

if [ "$BACKUP_DONE" != "yes" ]; then
  echo "Backup not recorded in database. Please run backup_dialogrc.sh first."
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file missing. Please run backup_dialogrc.sh to recreate it."
  exit 1
fi

CUSTOM_DIALOGRC="$SCRIPT_DIR/.dialogrc"
tee "$CUSTOM_DIALOGRC" << EOF2
# Red Alert theme
use_shadow = NO
screen_color = (BLACK,WHITE,ON)
title_color = (WHITE,RED,ON)
border_color = (WHITE,RED,ON)
button_active_color = (BLACK,RED,ON)
button_inactive_color = (WHITE,BLACK,ON)
EOF2

ln -sf "$CUSTOM_DIALOGRC" "$HOME/.dialogrc"
echo "Red Alert theme applied."

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
db_write "INSERT INTO installs (software_name, task_group, task_name, status, updated_at) VALUES ('ToolboxColours', 'Theme Change', 'Red Alert Theme', 'completed', '$TIMESTAMP');"

exit 0
