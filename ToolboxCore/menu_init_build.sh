#!/usr/bin/env bash
#MN Toolbox Menu Init Build
#MD Builds the toolbox menu database
#MDD Scans toolbox directories and scripts to generate the menu database with numbering and preview
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
set -euo pipefail

source /opt/toolbox/ToolboxCore/generic_functions.sh
source /opt/toolbox/ToolboxCore/db_menu_meta_functions.sh
resolve_user_home

DBFILE="$USER_HOME/.config/toolbox/state.db"
TOOLBOX_DIR="${TOOLBOX_DIR:-/opt/toolbox}"
CONFIG="$TOOLBOX_DIR/ToolboxCore/toolbox_scan_config.ini"

# Ensure database file exists
mkdir -p "$(dirname "$DBFILE")"
if [ ! -f "$DBFILE" ]; then
  sqlite3 "$DBFILE" "VACUUM;"
fi

declare -A AlwaysExclude AlwaysInclude IgnorePatterns
current_section=""
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%;*}" ; line="${line//[$'\t\r\n ']}"
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^\[.*\]$ ]]; then
    current_section="${line#[}"; current_section="${current_section%]}"
  else
    case "$current_section" in
      AlwaysExclude) AlwaysExclude["$line"]=1 ;;
      AlwaysInclude) AlwaysInclude["$line"]=1 ;;
      IgnorePatterns) IgnorePatterns["$line"]=1 ;;
    esac
  fi
done < "$CONFIG"

ENTRIES_FILE=$(mktemp)
PREVIEW_FILE=$(mktemp)

declare -A parent_number
global_index=0

process_dir() {
  local dir_path="$1"
  local parent_id="$2"

  rel_path="${dir_path#$TOOLBOX_DIR/}"
  name="$(basename "$dir_path")"

  [[ "$rel_path" == "." ]] && return
  [[ -n "${AlwaysExclude["$rel_path"]:-}" && -z "${AlwaysInclude["$rel_path"]:-}" ]] && return

  global_index=$((global_index + 1))
  local menu_number
  if [[ -n "$parent_id" && -n "${parent_number["$parent_id"]:-}" ]]; then
    menu_number="${parent_number["$parent_id"]}.$global_index"
  else
    menu_number="$global_index"
  fi
  parent_number["$rel_path"]="$menu_number"

  echo "$rel_path|$parent_id|$menu_number|$name|||ToolboxCore|https://github.com/ToolboxMenu|default|50|📁|menu|unknown|menu||0|true" >> "$ENTRIES_FILE"
  indent=$(printf '  %.0s' $(echo "$menu_number" | tr -cd '.' | wc -c))
  echo "${indent}${menu_number}. 📁 $name" >> "$PREVIEW_FILE"

  find "$dir_path" -mindepth 1 -maxdepth 1 -type f -name "*.sh" | sort | while read -r script; do
    script_name=$(basename "$script")
    global_index=$((global_index + 1))
    script_number="${menu_number}.$global_index"
    mn=$(grep '^#MN' "$script" | cut -d' ' -f2- || true); mn="${mn:-$script_name}"
    echo "$script|$rel_path|$script_number|$mn|||ToolboxCore|https://github.com/ToolboxMenu|default|50|📝|script|unknown|command|$script|0|true" >> "$ENTRIES_FILE"
    echo "${indent}  ${script_number}. 📝 $mn" >> "$PREVIEW_FILE"
  done

  find "$dir_path" -mindepth 1 -maxdepth 1 -type d | sort | while read -r subdir; do
    process_dir "$subdir" "$rel_path"
  done
}

find "$TOOLBOX_DIR" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
  process_dir "$dir" ""
done

cat "$PREVIEW_FILE"

# Force drop and clean recreate of menu table
sqlite3 "$DBFILE" <<SQL
PRAGMA foreign_keys = OFF;
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  id TEXT PRIMARY KEY,
  parent_id TEXT,
  menu_number TEXT,
  mn TEXT,
  md TEXT,
  mdd TEXT,
  mi TEXT,
  info TEXT,
  mc TEXT,
  mp TEXT,
  miicon TEXT,
  mtags TEXT,
  mauthor TEXT,
  type TEXT,
  command TEXT,
  order_num INTEGER,
  installed TEXT
);
PRAGMA foreign_keys = ON;
SQL

# Confirm table existence before inserts
if ! sqlite3 "$DBFILE" ".tables" | grep -qw menu; then
  echo "❌ ERROR: 'menu' table creation failed. Exiting."
  exit 1
fi

while IFS='|' read -r id parent_id menu_number mn md mdd mi info mc mp miicon mtags mauthor type command order_num installed; do
  db_menu_insert_meta "$id" "$parent_id" "$menu_number" "$mn" "$md" "$mdd" "$mi" "$info" "$mc" "$mp" "$miicon" "$mtags" "$mauthor" "$type" "$command" "$order_num" "$installed"
done < "$ENTRIES_FILE"

rm -f "$ENTRIES_FILE" "$PREVIEW_FILE"
