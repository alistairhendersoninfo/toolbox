#!/usr/bin/env bash
#MN db_init_menu_extended
#MD Initialise Toolbox extended menu database schema (with numbering)
#MDD Drops and recreates the menu table with menu_number column for hierarchical numbering support.
#MI ToolboxCore
#INFO https://sqlite.org/
#MC danger
#MP top
#MIICON database
#MTAGS db,init,menu,schema,toolbox
#MAUTHOR Alistair Henderson

set -euo pipefail

source /opt/toolbox/ToolboxCore/generic_functions.sh
resolve_user_home

DBFILE="$USER_HOME/.config/toolbox/state.db"

echo "⚠️ Dropping and recreating menu table in $DBFILE..."
sqlite3 "$DBFILE" <<SQL
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  id TEXT PRIMARY KEY,
  parent_id TEXT,
  menu_number TEXT,
  mn TEXT NOT NULL,
  md TEXT,
  mdd TEXT,
  mi TEXT,
  info TEXT,
  mc TEXT,
  mp TEXT,
  miicon TEXT,
  mtags TEXT,
  mauthor TEXT,
  type TEXT NOT NULL,
  command TEXT,
  order_num INTEGER,
  installed TEXT,
  FOREIGN KEY (parent_id) REFERENCES menu(id)
);
CREATE INDEX IF NOT EXISTS idx_menu_parent_order ON menu(parent_id, order_num);
SQL

echo "✅ Menu table recreated with menu_number column."
