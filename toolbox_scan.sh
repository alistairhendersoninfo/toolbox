#!/bin/bash

TOOLBOX_DIR="/opt/toolbox"
OUTPUT_INI="$TOOLBOX_DIR/toolbox_menu.ini"

echo "[INFO] Generating toolbox_menu.ini"
echo "; Auto-generated toolbox menu index" > "$OUTPUT_INI"

for subdir in "$TOOLBOX_DIR"/*; do
    if [ -d "$subdir" ]; then
        folder_name=$(basename "$subdir")
        echo "[$folder_name]" >> "$OUTPUT_INI"

        for script in "$subdir"/*.sh; do
            if [ -f "$script" ]; then
                mn=$(grep '^#MN:' "$script" | head -n1 | cut -d':' -f2- | xargs)
                mi=$(grep '^#MI:' "$script" | head -n1 | cut -d':' -f2- | xargs)

                # Skip if no menu name
                if [ -z "$mn" ]; then
                    continue
                fi

                # For LinuxTools, include all scripts unconditionally
                if [ "$folder_name" == "LinuxTools" ]; then
                    script_key=$(echo "$mn" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                    echo "$script_key=$script" >> "$OUTPUT_INI"
                    continue
                fi

                # For other folders, apply MI check if defined
                if [ -n "$mi" ] && [ ! -e "$mi" ]; then
                    echo "[INFO] Skipping $script due to missing indicator file: $mi"
                    continue
                fi

                script_key=$(echo "$mn" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                echo "$script_key=$script" >> "$OUTPUT_INI"
            fi
        done

        echo "" >> "$OUTPUT_INI"
    fi
done

echo "[INFO] toolbox_menu.ini generated at $OUTPUT_INI"
