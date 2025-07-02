#!/bin/bash

# MN: UpdatePages
# MD: Update GitHub Pages markdown files for recently modified scripts

set -e

output_dir="docs"
instructions="ReadmeInstructions.md"
days="${1:-1}"

mkdir -p "$output_dir"

echo "[INFO] Updating pages for scripts modified in last $days day(s)."

# Create global index.md with static instructions
global_index="$output_dir/index.md"
cat "$instructions" > "$global_index"
echo "" >> "$global_index"
echo "# All Scripts (Updated)" >> "$global_index"
echo "" >> "$global_index"

for dir in */ ; do
    [ -d "$dir" ] || continue
    [[ "$dir" == "docs/" ]] && continue

    section="${dir%/}"
    section_dir="$output_dir/$section"
    mkdir -p "$section_dir"

    index_md="$section_dir/index.md"
    [ -f "$index_md" ] || {
        echo "# $section" > "$index_md"
        echo "" >> "$index_md"
    }

    # Find scripts modified in last N days recursively
    find "$dir" -type f -name "*.sh" -mtime -$days | while read -r script; do
        script_rel=$(realpath --relative-to="$dir" "$script")
        script_name=$(basename "$script")
        script_path=$(dirname "$script_rel")
        mn=$(grep -m 1 '^# *MN:' "$script" | sed -E 's/^# *MN:[[:space:]]*//')
        md=$(grep -m 1 '^# *MD:' "$script" | sed -E 's/^# *MD:[[:space:]]*//')
        info=$(grep -m 1 '^# *INFO:' "$script" | sed -E 's/^# *INFO:[[:space:]]*//')
        mdd=$(grep -m 1 '^# *MDD:' "$script" | sed -E 's/^# *MDD:[[:space:]]*//')

        # Determine output subdirectory
        if [ "$script_path" != "." ]; then
            sub_dir="$section_dir/$script_path"
            mkdir -p "$sub_dir"
        else
            sub_dir="$section_dir"
        fi

        # Update module index.md if entry missing
        grep -q "\[$script_rel\]" "$index_md" || {
            echo "## [$script_rel]($script_rel.md)" >> "$index_md"
            echo "- **Menu Name:** ${mn:-N/A}" >> "$index_md"
            echo "- **Description:** ${md:-N/A}" >> "$index_md"
            [ -n "$info" ] && echo "- **Info:** $info" >> "$index_md"
            echo "" >> "$index_md"
        }

        # Update global index.md
        echo "## [$section/$script_rel]($section/$script_rel.md)" >> "$global_index"
        echo "- **Menu Name:** ${mn:-N/A}" >> "$global_index"
        echo "- **Description:** ${md:-N/A}" >> "$global_index"
        [ -n "$info" ] && echo "- **Info:** $info" >> "$global_index"
        echo "" >> "$global_index"

        # Update individual script page
        script_md="$sub_dir/$script_name.md"
        echo "# $script_name" > "$script_md"
        echo "" >> "$script_md"
        echo "## Description" >> "$script_md"
        echo "${mdd:-${md:-No description}}" >> "$script_md"
        echo "" >> "$script_md"
        echo "## Info" >> "$script_md"
        [ -n "$info" ] && echo "$info" || echo "N/A" >> "$script_md"
        echo "" >> "$script_md"
        echo "## Script" >> "$script_md"
        echo "\`\`\`bash" >> "$script_md"
        cat "$script" >> "$script_md"
        echo "\`\`\`" >> "$script_md"
    done
done

echo "[INFO] Incremental page update complete."
