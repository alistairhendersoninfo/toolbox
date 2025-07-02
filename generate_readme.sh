#!/bin/bash

# Generate README.md files for toolbox directories and master README.md

master="README.md"
instructions="ReadmeInstructions.md"

# Start master README with static instructions
cat "$instructions" > "$master"
echo "" >> "$master"
echo "# Toolbox Scripts Summary" >> "$master"
echo "" >> "$master"

process_script() {
    local script="$1"
    local readme="$2"
    local section="$3"

    md=$(grep -m 1 '^# *MD:' "$script" | sed -E 's/^# *MD:[[:space:]]*//')
    mi=$(grep -m 1 '^# *MI:' "$script" | sed -E 's/^# *MI:[[:space:]]*//')
    script_name=$(basename "$script")

    echo "### $script_name" >> "$readme"
    echo "- **Description:** ${md:-N/A}" >> "$readme"
    [ -n "$mi" ] && echo "- **MI:** $mi (menu will appear if this exists)" >> "$readme"
    echo "" >> "$readme"

    echo "### [$section] $script_name" >> "$master"
    echo "- **Description:** ${md:-N/A}" >> "$master"
    [ -n "$mi" ] && echo "- **MI:** $mi (menu will appear if this exists)" >> "$master"
    echo "" >> "$master"
}

# Process LinuxTools subdirectories
if [ -d "LinuxTools/" ]; then
    echo "## Linux Tools" >> "$master"
    echo "" >> "$master"
    for subdir in LinuxTools/*/ ; do
        [ -d "$subdir" ] || continue
        readme="${subdir}README.md"
        cat "$instructions" > "$readme"
        echo "" >> "$readme"
        echo "# $(basename "$subdir") Scripts" >> "$readme"
        echo "" >> "$readme"
        find "$subdir" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
            process_script "$script" "$readme" "$(basename "$subdir")"
        done
    done
fi

# Process other top-level directories (excluding LinuxTools)
for dir in */ ; do
    [ -d "$dir" ] || continue
    [[ "$dir" == "LinuxTools/" ]] && continue
    readme="${dir}README.md"
    cat "$instructions" > "$readme"
    echo "" >> "$readme"
    echo "# $(basename "$dir") Scripts" >> "$readme"
    echo "" >> "$readme"
    echo "## $(basename "$dir")" >> "$master"
    echo "" >> "$master"
    find "$dir" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
        process_script "$script" "$readme" "$(basename "$dir")"
    done
done

echo "README.md files generated for all directories and master README.md created."
