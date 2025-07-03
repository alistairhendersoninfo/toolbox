#!/usr/bin/env bash
#MN InitPages
#MD Generate GitHub Pages markdown for all scripts
#MDD Generates full pages for all scripts under docs/ with dialog progress gauge.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 10
#MIICON rocket
#MTAGS docs,init
#MAUTHOR $(whoami)

{
  echo "10"; sleep 0.5
  echo "# Initialising pages directory..."
  output_dir="docs"
  instructions="ReadmeInstructions.md"
  mkdir -p "$output_dir"

  echo "30"; sleep 0.5
  echo "# Generating global index.md..."
  global_index="$output_dir/index.md"
  cat "$instructions" > "$global_index"
  echo "" >> "$global_index"
  echo "# All Scripts" >> "$global_index"
  echo "" >> "$global_index"

  echo "50"; sleep 0.5
  echo "# Generating module pages..."
  for dir in */ ; do
      [ -d "$dir" ] || continue
      [[ "$dir" == "docs/" ]] && continue

      section="${dir%/}"
      section_dir="$output_dir/$section"
      mkdir -p "$section_dir"

      index_md="$section_dir/index.md"
      echo "# $section" > "$index_md"
      echo "" >> "$index_md"

      find "$dir" -type f -name "*.sh" | while read -r script; do
          script_name=$(basename "$script")
          script_md="$section_dir/$script_name.md"
          echo "# $script_name" > "$script_md"
          echo "" >> "$script_md"
          echo "## Script" >> "$script_md"
          echo "\`\`\`bash" >> "$script_md"
          cat "$script" >> "$script_md"
          echo "\`\`\`" >> "$script_md"
      done
  done

  echo "90"; sleep 0.5
  echo "# Finalising generation..."
  sleep 0.5

  echo "100"; sleep 0.3
  echo "# Page generation complete."
} | dialog --gauge "Generating Pages..." 15 70 0
