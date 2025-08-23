#!/usr/bin/env bash

#MN create_toolbox
#MD Create Toolbox Menu Launcher
#MDD Builds the toolbox launcher script from toolbox_menu.ini, prioritising TopLevel, with icons, colours, ordering, separators, and default selections. Uses global branding if #MCOLOR is blank.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox

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

echo "[INFO] Generating toolbox launcher at $OUTPUT_SCRIPT from $INI_FILE"

# Function to extract numeric part for sorting
numeric_sort_key() {
    if [[ "$1" =~ ^[0-9]+ ]]; then
        echo "${BASH_REMATCH[0]}"
    else
        echo "999999"
    fi
}

# Start building the toolbox launcher script
cat << 'LAUNCHER_EOF' > "$OUTPUT_SCRIPT"
#!/usr/bin/env bash

show_menu() {
    local title="\$1"
    local options=("\${!2}")
    local actions=("\${!3}")
    local default="\$4"

    while true; do
        # Remove previous Exit entry to avoid duplicates
        if [ "\${#options[@]}" -gt 0 ] && [ "\${options[-2]}" == "X" ]; then
            unset 'options[-1]'
            unset 'options[-1]'
        fi

        options+=("X" "\Z1❌ Exit\Zn")

        if [ -n "\$default" ]; then
            choice=\$(dialog --clear \
                --backtitle "🛡️ Toolbox Suite" \
                --title "\$title" \
                --colors \
                --default-item "\$default" \
                --menu "Choose an option:" \
                20 80 15 \
                "\${options[@]}" \
                3>&1 1>&2 2>&3)
        else
            choice=\$(dialog --clear \
                --backtitle "🛡️ Toolbox Suite" \
                --title "\$title" \
                --colors \
                --menu "Choose an option:" \
                20 80 15 \
                "\${options[@]}" \
                3>&1 1>&2 2>&3)
        fi

        exit_status=\$?

        clear

        if [ \$exit_status -eq 0 ]; then
            if [[ "\$choice" == "X" || "\$choice" == "x" ]]; then
                return
            else
                eval "\${actions[\$choice]}"
            fi
        else
            echo "Cancelled."
            exit 0
        fi
    done
}

LAUNCHER_EOF

chmod +x "$OUTPUT_SCRIPT"

echo "build_main_menu() {" >> "$OUTPUT_SCRIPT"
echo "    local options=()" >> "$OUTPUT_SCRIPT"
echo "    local actions=()" >> "$OUTPUT_SCRIPT"

index=0
declare -A section_scripts
declare -A section_meta

# Parse INI and build associative arrays
current_section=""
while IFS= read -r line; do
    [[ "$line" =~ ^\;.*$ || -z "$line" ]] && continue

    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        current_section="${BASH_REMATCH[1]}"
        section_scripts["$current_section"]=""
        section_order=$(numeric_sort_key "$current_section")
        section_meta["$current_section,order"]=$section_order
        continue
    fi

    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        script_key="${BASH_REMATCH[1]}"
        metadata="${BASH_REMATCH[2]}"
        section_scripts["$current_section"]+="$script_key|$metadata"$'\n'
    fi
done < "$INI_FILE"

# Sort sections by order then name
declare -a sorted_sections=()
for section in "${!section_scripts[@]}"; do
    order="${section_meta["$section,order"]:-999999}"
    sorted_sections+=("$order|$section")
done

IFS=$'\n' sorted_sections=($(sort -t'|' -k1n -k2 <<<"${sorted_sections[*]}"))
unset IFS

# Generate main menu entries with TopLevel first if exists
for entry in "${sorted_sections[@]}"; do
    section="${entry##*|}"

    # Skip section if no scripts
    if [ -z "${section_scripts[$section]}" ]; then
        echo "[INFO] Skipping section $section as it has no scripts."
        continue
    fi

    function_name="build_${section}_menu"
    display_name="$section"

    if [ "$section" == "TopLevel" ]; then
        echo "    options=(\"$index\" \"🏠 $display_name\")" >> "$OUTPUT_SCRIPT"
        echo "    actions[$index]=\"$function_name\"" >> "$OUTPUT_SCRIPT"
    else
        echo "    options+=(\"$index\" \"📂 $display_name\")" >> "$OUTPUT_SCRIPT"
        echo "    actions[$index]=\"$function_name\"" >> "$OUTPUT_SCRIPT"
    fi
    index=$((index + 1))
done

# Generate submenu functions with sorted scripts
for entry in "${sorted_sections[@]}"; do
    section="${entry##*|}"
    function_name="build_${section}_menu"
    echo "$function_name() {" >> "$OUTPUT_SCRIPT"
    echo "    local options=()" >> "$OUTPUT_SCRIPT"
    echo "    local actions=()" >> "$OUTPUT_SCRIPT"
    echo "    local default=\"\"" >> "$OUTPUT_SCRIPT"

    # Build array of script entries for sorting
    declare -a entries=()
    while IFS= read -r script_entry; do
        [ -z "$script_entry" ] && continue
        entries+=("$script_entry")
    done <<< "${section_scripts[$section]}"

    # Sort scripts by order then name
    sorted_entries=$(for e in "${entries[@]}"; do
        IFS='|' read -r script_key path icon color order default separator <<< "$e"
        echo "$order|$script_key|$e"
    done | sort -t'|' -k1n -k2 | cut -d'|' -f3-)

    subindex=0
    current_separator=""

    while IFS= read -r script_entry; do
        [ -z "$script_entry" ] && continue
        IFS='|' read -r script_key path icon color order is_default separator <<< "$script_entry"

        # Insert separator if needed
        if [ -n "$separator" ] && [ "$separator" != "$current_separator" ]; then
            echo "    options+=(\"sep$subindex\" \"──── $separator ────\")" >> "$OUTPUT_SCRIPT"
            echo "    actions[sep$subindex]=\"echo 'Separator'\"" >> "$OUTPUT_SCRIPT"
            current_separator="$separator"
            subindex=$((subindex + 1))
        fi

        # Build display name with icon and colour
        if [ -n "$color" ]; then
            display_name="\\$color$icon $script_key\\Zn"
        else
            display_name="$icon $script_key"
        fi

        echo "    options+=(\"$subindex\" \"$display_name\")" >> "$OUTPUT_SCRIPT"
        echo "    actions[$subindex]=\"bash '$path'\"" >> "$OUTPUT_SCRIPT"

        # Set default if marked
        if [ "$is_default" == "true" ]; then
            echo "    default=\"$subindex\"" >> "$OUTPUT_SCRIPT"
        fi

        subindex=$((subindex + 1))
    done <<< "$sorted_entries"

    echo "    show_menu \"$section\" options[@] actions[@] \"\$default\"" >> "$OUTPUT_SCRIPT"
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
