#!/usr/bin/env bash
#MN db_menu_meta_functions
#MD SQLite menu metadata function library (with numbering)
#MDD Provides db_menu_insert_meta with menu_number support for Toolbox menu database.
#MI SQLiteDB
#INFO https://github.com/ToolboxMenu
#MC default
#MP top
#MIICON database
#MTAGS db,functions,menu,toolbox
#MAUTHOR Alistair Henderson

DB_PATH="$HOME/.config/toolbox/state.db"

db_menu_insert_meta() {
  local id="$1"
  local parent_id="$2"
  local menu_number="$3"
  local mn="$4"
  local md="$5"
  local mdd="$6"
  local mi="$7"
  local info="$8"
  local mc="$9"
  local mp="${10}"
  local miicon="${11}"
  local mtags="${12}"
  local mauthor="${13}"
  local type="${14}"
  local command="${15}"
  local order_num="${16}"
  local installed="${17}"

  sqlite3 "$DB_PATH" <<SQL
INSERT OR REPLACE INTO menu (
  id, parent_id, menu_number, mn, md, mdd, mi, info, mc, mp, miicon, mtags, mauthor, type, command, order_num, installed
) VALUES (
  '$id', '$parent_id', '$menu_number', '$mn', '$md', '$mdd', '$mi', '$info', '$mc', '$mp', '$miicon', '$mtags', '$mauthor', '$type', '$command', $order_num, '$installed'
);
SQL
}
