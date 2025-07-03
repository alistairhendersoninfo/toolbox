#!/usr/bin/env bash
#MN GenerateReadme
#MD Generate README summaries for Toolbox scripts
#MDD Generates README.md files for all modules and a master README.md with dialog progress gauge.
#MI ToolboxCore
#INFO https://internal.tool/docs/toolbox
#MC default
#MP 20
#MIICON edit
#MTAGS docs,readme
#MAUTHOR $(whoami)

{
  echo "10"; sleep 0.5
  echo "# Starting README generation..."

  master="README.md"
  instructions="ReadmeInstructions.md"

  cat "$instructions" > "$master"
  echo "" >> "$master"
  echo "# Toolbox Scripts Summary" >> "$master"
  echo "" >> "$master"

  echo "30"; sleep 0.5

  process_script() {
      local script="$1"
      local readme="$2"
      local section="$3"

      md=$(grep -m 1 '^# *MD:' "$script" | sed -E 's/^# *MD:[[:space:]]*//')
      mdd=$(grep -m 1 '^# *MDD:' "$script" | sed -E 's/^# *MDD:[[:space:]]*//')
      mi=$(grep -m 1 '^# *MI:' "$script" | sed -E 's/^# *MI:[[:space:]]*//')
      info=$(grep -m 1 '^# *INFO:' "$script" | sed -E 's/^# *INFO:[[:space:]]*//')
      script_name=$(basename "$script")

      echo "### $script_name" >> "$readme"
      echo "- **Description:** ${md:-N/A}" >> "$readme"
      [ -n "$mdd" ] && echo "- **Extra:** $mdd" >> "$readme"
      if [ -n "$mi" ]; then
          if command -v "$mi" >/dev/null 2>&1; then
              echo "- **MI:** $mi (installed, menu available)" >> "$readme"
          else
              echo "- **MI:** $mi (not installed, menu hidden)" >> "$readme"
          fi
      fi
      [ -n "$info" ] && echo "- **Info:** $info" >> "$readme"
      echo "" >> "$readme"

      echo "### [$section] $script_name" >> "$master"
      echo "- **Description:** ${md:-N/A}" >> "$master"
      [ -n "$mdd" ] && echo "- **Extra:** $mdd" >> "$master"
      if [ -n "$mi" ]; then
          if command -v "$mi" >/dev/null 2>&1; then
              echo "- **MI:** $mi (installed, menu available)" >> "$master"
          else
              echo "- **MI:** $mi (not installed, menu hidden)" >> "$master"
          fi
      fi
      [ -n "$info" ] && echo "- **Info:** $info" >> "$master"
      echo "" >> "$master"
  }

  echo "50"; sleep 0.5

  for dir in */ ; do
      [ -d "$dir" ] || continue
      [[ "$dir" == "docs/" ]] && continue
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

  echo "90"; sleep 0.5
  echo "# README generation complete."
  sleep 0.3
  echo "100"
} | dialog --gauge "Generating READMEs..." 15 70 0
