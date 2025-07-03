#!/usr/bin/env bash
#MN create_script_skeleton
#MD Create new Toolbox script skeleton
#MDD Interactive generator for new Toolbox scripts with full metadata, selectable/creatable directories, colour highlights, and EFFECTIVE_USER logic.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox

TOOLBOX_DIR="/opt/toolbox"

# Prompt for Menu Name (script filename)
script_name=$(dialog --inputbox "Enter script filename (without .sh extension):" 10 60 3>&1 1>&2 2>&3) || exit 1
script_name=$(echo "$script_name" | tr -d '[:space:]')
[ -z "$script_name" ] && echo "Script name cannot be empty." && exit 1

# Build list of existing directories for selection
mapfile -t dir_options < <(find "$TOOLBOX_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
dir_options+=("NEW" "Create a new directory")

# Select directory or choose to create new
selected_dir=$(dialog --menu "Select directory for the new script:" 15 60 8 "${dir_options[@]}" 3>&1 1>&2 2>&3) || exit 1

# If NEW, prompt for directory name
if [ "$selected_dir" == "NEW" ]; then
    selected_dir=$(dialog --inputbox "Enter new directory name:" 10 60 3>&1 1>&2 2>&3) || exit 1
    selected_dir=$(echo "$selected_dir" | tr -d '[:space:]')
    [ -z "$selected_dir" ] && echo "Directory name cannot be empty." && exit 1
    mkdir -p "$TOOLBOX_DIR/$selected_dir"
fi

save_dir="$TOOLBOX_DIR/$selected_dir"

# Prompt for remaining metadata fields
menu_desc=$(dialog --inputbox "Enter Menu Description (#MD):" 10 60 3>&1 1>&2 2>&3) || exit 1
menu_ddesc=$(dialog --inputbox "Enter Detailed Description (#MDD):" 10 60 3>&1 1>&2 2>&3) || exit 1
integration_obj="$selected_dir"  # Auto-assign to selected directory as MI

project_url=$(dialog --inputbox "Enter Project or Software URL (#INFO):" 10 60 3>&1 1>&2 2>&3) || exit 1
menu_colour=$(dialog --inputbox "Enter Menu Colour (#MC, default/danger/etc):" 10 60 "default" 3>&1 1>&2 2>&3) || exit 1
menu_pos=$(dialog --inputbox "Enter Menu Position (#MP, numeric or keyword):" 10 60 "50" 3>&1 1>&2 2>&3) || exit 1
menu_tags=$(dialog --inputbox "Enter Additional Tags (#MTAGS, comma-separated):" 10 60 3>&1 1>&2 2>&3) || exit 1
author=$(dialog --inputbox "Enter Author (#MAUTHOR):" 10 60 "$(whoami)" 3>&1 1>&2 2>&3) || exit 1

# Radio list for Icon selection
icon=$(dialog --radiolist "Select Icon (#MIICON):" 20 60 10 \
"gear" "General / Config" ON \
"package" "Package / Install" OFF \
"rocket" "Launch / Deploy" OFF \
"check" "Check / Verify" OFF \
"cross" "Exit / Remove" OFF \
"edit" "Edit / Write" OFF \
"lock" "Security / Lock" OFF \
"wrench" "Maintenance" OFF \
"info" "Info / Tips" OFF \
3>&1 1>&2 2>&3) || exit 1

# Confirm before creation
dialog --yesno "Create script:\n\nName: $script_name\nDir: $save_dir\nDesc: $menu_desc\nIcon: $icon\nColour: $menu_colour\nPosition: $menu_pos" 15 60 || exit 1

# Script filename
script_file="$save_dir/${script_name}.sh"

# Create script with full metadata header
cat << EOF2 > "$script_file"
#!/usr/bin/env bash
#MN $script_name
#MD $menu_desc
#MDD $menu_ddesc
#MI $integration_obj
#INFO $project_url
#MC $menu_colour
#MP $menu_pos
#MIICON $icon
#MTAGS $menu_tags
#MAUTHOR $author

source \$TOOLBOX_DIR/ToolboxCore/generic_functions.sh
resolve_user_home

# Script logic starts here

EOF2

chmod +x "$script_file"

dialog --msgbox "Script skeleton created at:\n$script_file\n\nExecutable permission set." 10 60
clear
