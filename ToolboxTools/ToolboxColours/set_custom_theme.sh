#!/usr/bin/env bash
#MN Set Custom Theme
#MD Allows user to define a custom colour theme for dialog
#MDD Uses radio button menus for colour choices; records in database.
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

# Colour options array
COLOUR_OPTIONS="BLACK '' ON RED '' OFF GREEN '' OFF YELLOW '' OFF BLUE '' OFF MAGENTA '' OFF CYAN '' OFF WHITE '' OFF"

# Function to prompt for each colour
choose_colour() {
  local title="$1"
  dialog --clear --backtitle "Toolbox Custom Theme" \
    --title "$title" \
    --radiolist "Choose $title:" 15 40 8 \
    $COLOUR_OPTIONS \
    3>&1 1>&2 2>&3
}

# Prompt user for colours
SCREEN_TEXT=$(choose_colour "Screen Text Colour")
SCREEN_BG=$(choose_colour "Screen Background Colour")
TITLE_TEXT=$(choose_colour "Title Text Colour")
TITLE_BG=$(choose_colour "Title Background Colour")
BORDER=$(choose_colour "Border Colour")
ACTIVE_BTN=$(choose_colour "Active Button Colour")
INACTIVE_BTN=$(choose_colour "Inactive Button Colour")

clear

# Apply custom theme
CUSTOM_DIALOGRC="$SCRIPT_DIR/.dialogrc"
tee "$CUSTOM_DIALOGRC" << EOF2
# Custom theme
use_shadow = NO
screen_color = ($SCREEN_BG,$SCREEN_TEXT,ON)
title_color = ($TITLE_TEXT,$TITLE_BG,ON)
border_color = ($BORDER,$BORDER,ON)
button_active_color = (BLACK,$ACTIVE_BTN,ON)
button_inactive_color = (BLACK,$INACTIVE_BTN,ON)
EOF2

ln -sf "$CUSTOM_DIALOGRC" "$HOME/.dialogrc"
echo "Custom theme applied."

# Record change in database
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
db_write "INSERT INTO installs (software_name, task_group, task_name, status, updated_at) VALUES ('ToolboxColours', 'Theme Change', 'Custom Theme', 'completed', '$TIMESTAMP');"

exit 0
