#!/usr/bin/env bash
#MN toolbox_scan
#MD Scan Toolbox scripts and generate menu INI
#MDD Scans TOOLBOX_DIR for scripts, extracts metadata tags including icons, colours, ordering, and outputs toolbox_menu.ini to ToolboxCore. Includes TopLevel entries from toolbox_scan_config.ini.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 2
#MIICON wrench
#MTAGS toolbox,scan,ini
#MAUTHOR $(whoami)

INI_FILE="$TOOLBOX_DIR/ToolboxCore/toolbox_menu.ini"
CONFIG_FILE="$TOOLBOX_DIR/ToolboxCore/toolbox_scan_config.ini"

echo "[INFO] Generating $INI_FILE ..."

# Write header
echo "; Auto-generated toolbox menu index" > "$INI_FILE"

# Include TopLevel scripts from config if present
if [ -f "$CONFIG_FILE" ]; then
    echo "[TopLevel]" >> "$INI_FILE"
    grep -v '^#' "$CONFIG_FILE" | grep -v '^\s*$' >> "$INI_FILE"
fi

# Scan each module directory for scripts
for dir in "$TOOLBOX_DIR"/*/; do
    [ -d "$dir" ] || continue
    module=$(basename "$dir")
    echo "" >> "$INI_FILE"
    echo "[$module]" >> "$INI_FILE"

    find "$dir" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
        script_name=$(basename "$script")
        echo "$script_name=$script" >> "$INI_FILE"
    done
done

echo "[INFO] toolbox_menu.ini generated successfully at $INI_FILE"
