#!/usr/bin/env bash
#MN menu_init_build
#MD Build Toolbox menu SQL database with hierarchical numbering and debug
#MDD Builds the menu table from TOOLBOX_DIR with hierarchical numbering, displays debug info, and inserts entries into the database.
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MC danger
#MP top
#MIICON database
#MTAGS db,init,menu,scan,numbering,debug,toolbox
#MAUTHOR Alistair Henderson

set -euo pipefail

# Load functions
source /opt/toolbox/ToolboxCore/generic_functions.sh
source /opt/toolbox/ToolboxCore/db_menu_meta_functions.sh
resolve_user_home

AUTO_APPROVE=false
if [[ "${1:-}" == "--auto-approve" ]]; then
  AUTO_APPROVE=true
fi

DBFILE="$USER_HOME/.config/toolbox/state.db"

if [ -z "${TOOLBOX_DIR:-}" ]; then
  TOOLBOX_DIR="/opt/toolbox"
fi

echo "🔧 TOOLBOX_DIR resolved to $TOOLBOX_DIR"

CONFIG="$TOOLBOX_DIR/ToolboxCore/toolbox_scan_config.ini"
declare -A TopLevel AlwaysExclude AlwaysInclude IgnorePatterns

current_section=""
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%;*}"
  line="${line//[$'\t\r\n ']}"

  [[ -z "$line" ]] && continue

  if [[ "$line" =~ ^\[.*\]$ ]]; then
    current_section="${line#[}"
    current_section="${current_section%]}"
  else
    case "$current_section" in
      TopLevel) TopLevel["$line"]=1 ;;
      AlwaysExclude) AlwaysExclude["$line"]=1 ;;
      AlwaysInclude) AlwaysInclude["$line"]=1 ;;
      IgnorePatterns) IgnorePatterns["$line"]=1 ;;
    esac
  fi
done < "$CONFIG"

TREE_FILE=$(mktemp)
ENTRIES_FILE=$(mktemp)

echo "DEBUG: Starting build_tree with TOOLBOX_DIR=$TOOLBOX_DIR"
ls -la "$TOOLBOX_DIR"

build_tree() {
  local dir="$1"
  local prefix="$2"
  local parent_id="$3"
  local numbering="$4"

  echo "DEBUG: Entered build_tree for dir=$dir with numbering=$numbering"

  local entries
  IFS=$'\n' read -d '' -r -a entries < <(find "$dir" -mindepth 1 -maxdepth 1 | sort && printf '\0')

  echo "DEBUG: Number of entries found in $dir: ${#entries[@]}"

  local index=0
  for entry in "${entries[@]}"; do
    ((index++))
    echo "DEBUG ENTRY: $entry"

    rel_path="${entry#$TOOLBOX_DIR/}"
    name="$(basename "$entry")"

    ignore=false
    for pattern in "${!IgnorePatterns[@]}"; do
      if [[ "$name" == $pattern ]]; then
        echo "DEBUG: Ignoring $name due to pattern $pattern"
        ignore=true
        break
      fi
    done
    $ignore && continue

    rel_top="${rel_path%%/*}"
    if [[ ${AlwaysExclude[$rel_top]+_} && ! ${AlwaysInclude[$rel_top]+_} && ! ${TopLevel[$rel_path]+_} ]]; then
      echo "DEBUG: Excluding $rel_path due to AlwaysExclude"
      continue
    fi

    id="$rel_path"
    type=""
    command=""
    installed=""
    current_number="${numbering}${index}"

    if [ -d "$entry" ]; then
      type="menu"
      mn="$name"
      echo "${prefix}${current_number}. 📁 $mn" >> "$TREE_FILE"
      echo "$id|$parent_id|$current_number|$mn|N/A|N/A|ToolboxCore|https://github.com/ToolboxMenu|default|50|folder|folder,menu|unknown|menu||0|true" >> "$ENTRIES_FILE"
      build_tree "$entry" "$prefix  " "$id" "${current_number}."
    elif [ -f "$entry" ] && [[ "$name" == *.sh ]]; then
      type="command"
      command="$entry"

      echo "DEBUG: Processing script file $entry"

      mn=$(grep '^#MN' "$entry" | cut -d' ' -f2- || true); mn="${mn:-N/A}"; echo "DEBUG: MN=$mn"
      md=$(grep '^#MD' "$entry" | cut -d' ' -f2- || true); md="${md:-N/A}"; echo "DEBUG: MD=$md"
      mdd=$(grep '^#MDD' "$entry" | cut -d' ' -f2- || true); mdd="${mdd:-N/A}"; echo "DEBUG: MDD=$mdd"
      mi=$(grep '^#MI' "$entry" | cut -d' ' -f2- || true); mi="${mi:-ToolboxCore}"; echo "DEBUG: MI=$mi"
      info=$(grep '^#INFO' "$entry" | cut -d' ' -f2- || true); info="${info:-https://github.com/ToolboxMenu}"; echo "DEBUG: INFO=$info"
      mc=$(grep '^#MC' "$entry" | cut -d' ' -f2- || true); mc="${mc:-default}"; echo "DEBUG: MC=$mc"
      mp=$(grep '^#MP' "$entry" | cut -d' ' -f2- || true); mp="${mp:-50}"; echo "DEBUG: MP=$mp"
      miicon=$(grep '^#MIICON' "$entry" | cut -d' ' -f2- || true); miicon="${miicon:-gear}"; echo "DEBUG: MIICON=$miicon"
      mtags=$(grep '^#MTAGS' "$entry" | cut -d' ' -f2- || true); mtags="${mtags:-}"; echo "DEBUG: MTAGS=$mtags"
      mauthor=$(grep '^#MAUTHOR' "$entry" | cut -d' ' -f2- || true); mauthor="${mauthor:-unknown}"; echo "DEBUG: MAUTHOR=$mauthor"

      if command -v "$mi" >/dev/null 2>&1; then
        installed="true"
      else
        installed="false"
      fi
      echo "DEBUG: MI installed=$installed"

      echo "${prefix}${current_number}. 📝 $mn (MI: $mi installed: $installed)" >> "$TREE_FILE"
      echo "$id|$parent_id|$current_number|$mn|$md|$mdd|$mi|$info|$mc|$mp|$miicon|$mtags|$mauthor|$type|$command|0|$installed" >> "$ENTRIES_FILE"
    fi
  done
}

# Start numbering at 1.
build_tree "$TOOLBOX_DIR" "" "" "1."

if [ -s "$TREE_FILE" ]; then
  dialog --backtitle "ToolBox Ninja Menu Build" \
    --title "Menu Structure Preview" \
    --textbox "$TREE_FILE" 30 90
else
  echo "❌ No menu entries detected. Exiting."
  exit 1
fi

if [ "$AUTO_APPROVE" = false ]; then
  dialog --yesno "Proceed with inserting this menu structure into the database?" 10 60 || { echo "❌ Operation cancelled."; exit 1; }
fi

sqlite3 "$DBFILE" "DROP TABLE IF EXISTS menu;"
/opt/toolbox/ToolboxCore/db_init_menu_extended.sh

while IFS='|' read -r id parent_id menu_number mn md mdd mi info mc mp miicon mtags mauthor type command order_num installed; do
  db_menu_insert_meta "$id" "$parent_id" "$menu_number" "$mn" "$md" "$mdd" "$mi" "$info" "$mc" "$mp" "$miicon" "$mtags" "$mauthor" "$type" "$command" "$order_num" "$installed"
done < "$ENTRIES_FILE"

echo "✅ Menu database build complete."

rm -f "$TREE_FILE" "$ENTRIES_FILE"
