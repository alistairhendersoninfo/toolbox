#!/usr/bin/env bash

#MN toolbox_scan
#MD Scan Toolbox scripts and generate menu INI
#MDD Scans /opt/toolbox for scripts, extracts metadata tags including icons, colours, ordering, and outputs toolbox_menu.ini. Includes TopLevel entries from toolbox_scan_config.ini.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox

TOOLBOX_DIR="/opt/toolbox"
INI_FILE="$TOOLBOX_DIR/toolbox_menu.ini"
CONFIG_FILE="$TOOLBOX_DIR/toolbox_scan_config.ini"

echo "[INFO] Generating $INI_FILE ..."
echo "; Auto-generated toolbox menu index with metadata" > "$INI_FILE"

# Insert TopLevel scripts from toolbox_scan_config.ini if exists
if [ -f "$CONFIG_FILE" ]; then
    echo "[TopLevel]" >> "$INI_FILE"
    read_top=false

    while IFS= read -r line; do
        [[ "$line" =~ ^\;.*$ || -z "$line" ]] && continue

        if [[ "$line" =~ ^\[TopLevel\]$ ]]; then
            read_top=true
            continue
        fi

        if [[ "$line" =~ ^\[.*\]$ ]]; then
            read_top=false
            continue
        fi

        if [ "$read_top" == true ]; then
            script="$TOOLBOX_DIR/$line"
            [ -f "$script" ] || continue

            script_key=$(basename "$script" .sh)

            # Extract metadata tags
            icon=$(grep '^#MICON ' "$script" | head -n1 | cut -d' ' -f2-)
            color=$(grep '^#MCOLOR ' "$script" | head -n1 | cut -d' ' -f2-)
            order=$(grep '^#MORDER ' "$script" | head -n1 | cut -d' ' -f2-)
            default=$(grep '^#MDEFAULT ' "$script" | head -n1 | cut -d' ' -f2-)
            separator=$(grep '^#MSEPARATOR ' "$script" | head -n1 | cut -d' ' -f2-)

            # Set defaults if tags are missing
            icon="${icon:-📝}"
            color="${color:-Z2}"
            order="${order:-999999}"
            default="${default:-false}"
            separator="${separator:-}"

            # Output line: script_key=path|icon|color|order|default|separator
            echo "$script_key=$script|$icon|$color|$order|$default|$separator" >> "$INI_FILE"
        fi
    done < "$CONFIG_FILE"
fi

# Scan each subdirectory as section
for section_dir in "$TOOLBOX_DIR"/*/; do
    section=$(basename "$section_dir")
    echo "[$section]" >> "$INI_FILE"

    for script in "$section_dir"*.sh; do
        [ -f "$script" ] || continue

        script_key=$(basename "$script" .sh)

        # Extract metadata tags
        icon=$(grep '^#MICON ' "$script" | head -n1 | cut -d' ' -f2-)
        color=$(grep '^#MCOLOR ' "$script" | head -n1 | cut -d' ' -f2-)
        order=$(grep '^#MORDER ' "$script" | head -n1 | cut -d' ' -f2-)
        default=$(grep '^#MDEFAULT ' "$script" | head -n1 | cut -d' ' -f2-)
        separator=$(grep '^#MSEPARATOR ' "$script" | head -n1 | cut -d' ' -f2-)

        # Set defaults if tags are missing
        icon="${icon:-📝}"
        color="${color:-Z2}"
        order="${order:-999999}"
        default="${default:-false}"
        separator="${separator:-}"

        # Output line: script_key=path|icon|color|order|default|separator
        echo "$script_key=$script|$icon|$color|$order|$default|$separator" >> "$INI_FILE"
    done
done

echo "[INFO] toolbox_menu.ini generated successfully at $INI_FILE"
