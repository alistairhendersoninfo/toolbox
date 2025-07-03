#!/usr/bin/env bash
#MN View Install Progress
#MD View install progress status from Toolbox state.db with graphical mixed gauge
#MDD Displays software install progress with per-task group bars and task checkmarks in dialog mixedgauge for ToolboxTools.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu

# Source database functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../ToolboxCore/db_functions.sh"

# Check dependencies
if ! command -v dialog >/dev/null 2>&1; then
  echo "dialog is not installed. Please install it to continue."
  exit 1
fi

# Get list of software installs
SOFTWARE_LIST=$(db_read "SELECT DISTINCT software_name FROM installs;")

# Build dialog command input
MENU_ITEMS=()
for software in $SOFTWARE_LIST; do
  TOTAL_TASKS=$(db_read "SELECT COUNT(*) FROM installs WHERE software_name='$software';")
  COMPLETED_TASKS=$(db_read "SELECT COUNT(*) FROM installs WHERE software_name='$software' AND status='completed';")

  if [ "$TOTAL_TASKS" -eq 0 ]; then
    PERCENT=0
  else
    PERCENT=$(( COMPLETED_TASKS * 100 / TOTAL_TASKS ))
  fi

  MENU_ITEMS+=("$software" "$PERCENT% Complete")
done

# Display menu of software
CHOICE=$(dialog --clear --backtitle "Toolbox Install Progress" \
  --title "Installed Software" \
  --menu "Select a software to view task details:" 20 60 10 \
  "${MENU_ITEMS[@]}" \
  3>&1 1>&2 2>&3)

clear

if [ -z "$CHOICE" ]; then
  echo "No selection made."
  exit 0
fi

# Build mixed gauge input
MIXED_ITEMS=()

# Retrieve task groups
TASK_GROUPS=$(db_read "SELECT DISTINCT task_group FROM installs WHERE software_name='$CHOICE';")

for group in $TASK_GROUPS; do
  GROUP_TOTAL=$(db_read "SELECT COUNT(*) FROM installs WHERE software_name='$CHOICE' AND task_group='$group';")
  GROUP_DONE=$(db_read "SELECT COUNT(*) FROM installs WHERE software_name='$CHOICE' AND task_group='$group' AND status='completed';")
  if [ "$GROUP_TOTAL" -eq 0 ]; then
    GROUP_PERCENT=0
  else
    GROUP_PERCENT=$(( GROUP_DONE * 100 / GROUP_TOTAL ))
  fi

  MIXED_ITEMS+=("$group" "$GROUP_PERCENT" "Task Group Progress")
done

# Display mixed gauge
dialog --mixedgauge "Install Progress for $CHOICE" 20 70 0 \
  "${MIXED_ITEMS[@]}"

# Display checklist of tasks with status ticks
TASKS=$(db_read "SELECT task_name, status FROM installs WHERE software_name='$CHOICE';")
CHECKLIST_ITEMS=()
while IFS='|' read -r task_name status; do
  if [ "$status" == "completed" ]; then
    CHECKLIST_ITEMS+=("$task_name" "Completed" "on")
  else
    CHECKLIST_ITEMS+=("$task_name" "Pending" "off")
  fi
done <<< "$TASKS"

dialog --checklist "Task Status for $CHOICE" 20 70 10 \
  "${CHECKLIST_ITEMS[@]}" \
  3>&1 1>&2 2>&3

clear
echo "Progress view complete."

exit 0
