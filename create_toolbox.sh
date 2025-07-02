#!/bin/bash

TOOLBOX_DIR="/opt/toolbox"
OUTPUT_SCRIPT="/usr/local/bin/toolbox"
INI_FILE="$TOOLBOX_DIR/toolbox_menu.ini"
SCAN_SCRIPT="$TOOLBOX_DIR/toolbox_scan.sh"

echo "[INFO] Running toolbox scan to generate $INI_FILE..."

# Run toolbox_scan.sh first
if [ -x "$SCAN_SCRIPT" ]; then
    "$SCAN_SCRIPT"
else
    echo "[ERROR] Scan script not found or not executable: $SCAN_SCRIPT"
    exit 1
fi

# Verify ini file was generated
if [ ! -f "$INI_FILE" ]; then
    echo "[ERROR] $INI_FILE not found after scanning. Aborting."
    exit 1
fi

echo "[INFO] Generating toolbox at $OUTPUT_SCRIPT from $INI_FILE"

# Function to convert string to CamelCase
camel_case() {
    echo "$1" | sed -E 's/(^|_|\-)([a-z])/\U\2/g'
}

# Start building the toolbox launcher script
cat << 'EOF' > "$OUTPUT_SCRIPT"
#!/bin/bash

show_menu() {
    local title="$1"
    local options=("${!2}")
    local actions=("${!3}")

    while true; do
        # Remove previous Exit entry to avoid duplicates
        if [ "${#options[@]}" -gt 0 ] && [ "${options[-2]}" == "X" ]; then
            unset 'options[-1]'
            unset 'options[-1]'
        fi

        options+=("X" "Exit this menu")

        choice=$(dialog --clear \
            --backtitle "Toolbox" \
            --title "$title" \
            --menu "Choose an option:" \
            20 80 15 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        exit_status=$?

        clear

        if [ $exit_status -eq 0 ]; then
            if [[ "$choice" == "X" || "$choice" == "x" ]]; then
                return
            else
                eval "${actions[$choice]}"
            fi
        else
            echo "Cancelled."
            exit 0
        fi
    done
}

EOF

chmod +x "$OUTPUT_SCRIPT"

echo "build_main_menu() {" >> "$OUTPUT_SCRIPT"
echo "    local options=()" >> "$OUTPUT_SCRIPT"
echo "    local actions=()" >> "$OUTPUT_SCRIPT"

index=0
current_section=""
declare -A section_scripts

# First pass: parse INI and build associative array of sections and scripts
current_section=""
while IFS= read -r line; do
    [[ "$line" =~ ^\;.*$ || -z "$line" ]] && continue

    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        current_section="${BASH_REMATCH[1]}"
        section_scripts["$current_section"]=""
        continue
    fi

    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        script_key="${BASH_REMATCH[1]}"
        script_path="${BASH_REMATCH[2]}"
        section_scripts["$current_section"]+="$script_key|$script_path"$'\n'
    fi
done < "$INI_FILE"

# Always add LinuxTools first
echo "    options+=(\"$index\" \"LinuxTools\")" >> "$OUTPUT_SCRIPT"
echo "    actions[$index]=\"build_LinuxTools_menu\"" >> "$OUTPUT_SCRIPT"
index=$((index + 1))

# Add other sections to main menu only if they have scripts
for section in "${!section_scripts[@]}"; do
    if [ "$section" != "LinuxTools" ]; then
        # Skip section if no scripts
        if [ -z "${section_scripts[$section]}" ]; then
            echo "[INFO] Skipping section $section as it has no scripts."
            continue
        fi

        function_name="build_${section}_menu"
        display_name=$(camel_case "$section")

        echo "    options+=(\"$index\" \"$display_name\")" >> "$OUTPUT_SCRIPT"
        echo "    actions[$index]=\"$function_name\"" >> "$OUTPUT_SCRIPT"
        index=$((index + 1))
    fi
done

# Generate submenu functions
for section in "${!section_scripts[@]}"; do
    function_name="build_${section}_menu"
    echo "$function_name() {" >> "$OUTPUT_SCRIPT"
    echo "    local options=()" >> "$OUTPUT_SCRIPT"
    echo "    local actions=()" >> "$OUTPUT_SCRIPT"

    subindex=0
    while IFS= read -r script_entry; do
        [ -z "$script_entry" ] && continue
        script_key="${script_entry%%|*}"
        script_path="${script_entry##*|}"

        display_name=$(camel_case "$script_key")

        echo "    options+=(\"$subindex\" \"$display_name\")" >> "$OUTPUT_SCRIPT"
        echo "    actions[$subindex]=\"bash '$script_path'\"" >> "$OUTPUT_SCRIPT"
        subindex=$((subindex + 1))
    done <<< "${section_scripts[$section]}"

    echo "    show_menu \"$section\" options[@] actions[@]" >> "$OUTPUT_SCRIPT"
    echo "}" >> "$OUTPUT_SCRIPT"
    echo ""
done

# Finalise main menu
echo "    show_menu \"Toolbox Main Menu\" options[@] actions[@]" >> "$OUTPUT_SCRIPT"
echo "}" >> "$OUTPUT_SCRIPT"
echo "" >> "$OUTPUT_SCRIPT"

# Script entry point
echo "build_main_menu" >> "$OUTPUT_SCRIPT"

echo "[INFO] Toolbox launcher generated at $OUTPUT_SCRIPT"
