#!/usr/bin/env bash
#MN UpdatePages
#MD Update GitHub Pages markdown for modified scripts
#MDD Updates pages for scripts modified in the last N days with dialog progress gauge.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 30
#MIICON wrench
#MTAGS docs,update
#MAUTHOR $(whoami)

{
  echo "10"; sleep 0.5
  echo "# Starting incremental page update..."

  output_dir="docs"
  instructions="ReadmeInstructions.md"
  days="${1:-1}"

  mkdir -p "$output_dir"

  echo "30"; sleep 0.5
  echo "# Updating global index.md..."
  global_index="$output_dir/index.md"
  cat "$instructions" > "$global_index"
  echo "" >> "$global_index"
  echo "# All Scripts (Updated)" >> "$global_index"
  echo "" >> "$global_index"

  echo "50"; sleep 0.5
  echo "# Processing modified scripts..."
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

      find "$dir" -type f -name "*.sh" -mtime -$days | while read -r script; do
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
  echo "# Incremental update complete."
  sleep 0.3
  echo "100"
} | dialog --gauge "Updating Pages..." 15 70 0
