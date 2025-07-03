#!/usr/bin/env bash
#MN create_toolbox
#MD Create Toolbox Menu Launcher
#MDD Builds the toolbox launcher script from toolbox_menu.ini, prioritising TopLevel, with icons, colours, ordering, separators, and default selections. Uses global branding if #MCOLOR is blank.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 1
#MIICON rocket
#MTAGS toolbox,menu,launcher
#MAUTHOR $(whoami)

OUTPUT_SCRIPT="/usr/local/bin/toolbox"
INI_FILE="$TOOLBOX_DIR/ToolboxCore/toolbox_menu.ini"
SCAN_SCRIPT="$TOOLBOX_DIR/ToolboxCore/toolbox_scan.sh"

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

# Start building the toolbox launcher script
cat << LAUNCHER_EOF > "$OUTPUT_SCRIPT"
#!/usr/bin/env bash

show_menu() {
    local title="\$1"
    local options=(\"\${!2}\")
    local actions=(\"\${!3}\")
    local default="\$4"

    while true; do
        options+=("X" "\Z1❌ Exit\Zn")

        if [ -n "\$default" ]; then
            choice=\$(dialog --clear \
                --backtitle " Toolbox Suite" \
                --title "\$title" \
                --colors \
                --default-item "\$default" \
                --menu "Choose an option:" \
                20 80 15 \
                "\${options[@]}" \
                3>&1 1>&2 2>&3)
        else
            choice=\$(dialog --clear \
                --backtitle " Toolbox Suite" \
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

echo "[INFO] Toolbox launcher generated at $OUTPUT_SCRIPT"
