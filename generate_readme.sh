#!/bin/bash

# MN: GenerateReadme
# MD: Generate README.md in each subdirectory and an overall master README.md summarising scripts with MD and MI

echo "# Toolbox README Generation"

master="README.md"
echo "# Toolbox Scripts Summary" > "$master"
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

    if [ -n "$mi" ]; then
        echo "- **MI:** $mi (menu will appear if this exists)" >> "$readme"
    fi

    echo "" >> "$readme"

    echo "### [$section] $script_name" >> "$master"
    echo "- **Description:** ${md:-N/A}" >> "$master"

    if [ -n "$mi" ]; then
        echo "- **MI:** $mi (menu will appear if this exists)" >> "$master"
    fi

    echo "" >> "$master"
}

if [ -d "LinuxTools/" ]; then
    echo "## Linux Tools" >> "$master"
    echo "" >> "$master"

    for subdir in LinuxTools/*/ ; do
        [ -d "$subdir" ] || continue
        echo "Processing directory: $subdir"

        readme="${subdir}README.md"
        echo "# $(basename "$subdir") Scripts" > "$readme"
        echo "" >> "$readme"

        find "$subdir" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
            process_script "$script" "$readme" "$(basename "$subdir")"
        done
    done
fi

for dir in */ ; do
    [ -d "$dir" ] || continue
    [[ "$dir" == "LinuxTools/" ]] && continue

    echo "Processing directory: $dir"

    readme="${dir}README.md"
    echo "# $(basename "$dir") Scripts" > "$readme"
    echo "" >> "$readme"

    echo "## $(basename "$dir")" >> "$master"
    echo "" >> "$master"

    find "$dir" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
        process_script "$script" "$readme" "$(basename "$dir")"
    done
done

echo "README.md files generated for all directories and master README.md created."
