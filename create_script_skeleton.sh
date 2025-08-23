#!/usr/bin/env bash

#MN create_script_skeleton
#MD Create new Toolbox script skeleton
#MDD Interactive generator for new Toolbox scripts with standard metadata headers, selectable or creatable directories, colour highlights for dangerous scripts, saved with executable permission.
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

# Radio list for Icon selection
icon=$(dialog --radiolist "Select Icon (#MICON):" 20 60 10 \
"🛠️" "Tool / General" ON \
"⚙️" "Configuration" OFF \
"📦" "Package / Install" OFF \
"🚀" "Launch / Deploy" OFF \
"✅" "Check / Verify" OFF \
"❌" "Exit / Remove" OFF \
"📝" "Edit / Write" OFF \
"🔒" "Security / Lock" OFF \
"🔧" "Maintenance" OFF \
"💡" "Info / Tips" OFF \
3>&1 1>&2 2>&3) || exit 1

# Ask if script requires special colour highlight
special_colour=$(dialog --yesno "Does this script require a special colour highlight?\n\nExamples:\n- Red for dangerous or destructive scripts\n- Orange for caution\n\nSelect YES to choose a specific colour, or NO to use global theme branding." 15 60; echo $?)

if [ "$special_colour" -eq 0 ]; then
    # User chose YES
    color=$(dialog --radiolist "Select Colour Highlight (#MCOLOR):" 15 60 5 \
    "Z1" "Red - Dangerous / Destructive" ON \
    "Z3" "Orange - Warning / Caution" OFF \
    "Z2" "Green - Safe / Standard" OFF \
    "Z4" "Blue - Info / Non-critical" OFF \
    "GLOBAL" "Use global branding" OFF \
    3>&1 1>&2 2>&3) || exit 1

    # If GLOBAL chosen, set to empty to follow global branding script
    [ "$color" == "GLOBAL" ] && color=""
else
    # User chose NO
    color=""
fi

order=$(dialog --inputbox "Enter Order (#MORDER, numeric):" 10 60 "999999" 3>&1 1>&2 2>&3) || exit 1
default=$(dialog --inputbox "Set as default selection? (#MDEFAULT, true/false):" 10 60 "false" 3>&1 1>&2 2>&3) || exit 1
separator=$(dialog --inputbox "Enter Separator label (#MSEPARATOR, optional):" 10 60 3>&1 1>&2 2>&3) || exit 1

# Confirm before creation
dialog --yesno "Create script:\n\nName: $script_name\nDir: $save_dir\nDesc: $menu_desc\nIcon: $icon\nColour: $color\nOrder: $order" 15 60 || exit 1

# Script filename
script_file="$save_dir/${script_name}.sh"

# Create script with metadata header
cat << EOF2 > "$script_file"
#!/usr/bin/env bash
#MN $script_name
#MD $menu_desc
#MDD $menu_ddesc
#MI $integration_obj
#INFO $project_url
#MICON $icon
#MCOLOR $color
#MORDER $order
#MDEFAULT $default
#MSEPARATOR $separator

# Your script logic starts here

EOF2

chmod +x "$script_file"

dialog --msgbox "Script skeleton created at:\n$script_file\n\nExecutable permission set." 10 60
clear
