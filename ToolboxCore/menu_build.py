#!/usr/bin/env python3
#MN menu_build
#MD Build menu numbering and insert into database
#MDD Reads structured JSON from menu_scan_output.json, assigns hierarchical numbering, generates human-readable preview and populates the SQLite menu table accordingly.
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MC default
#MP top
#MIICON database
#MTAGS build,menu,db,toolbox
#MAUTHOR Alistair Henderson

import os
import sys
import json
import sqlite3
import subprocess
from pathlib import Path

# Resolve USER_HOME via generic_functions.sh
def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    result = subprocess.run(
        ["bash", "-c", f"source {generic_funcs} && resolve_user_home && echo $USER_HOME"],
        capture_output=True, text=True
    )
    return result.stdout.strip()

# Environment
toolbox_dir = os.environ.get("TOOLBOX_DIR")
if not toolbox_dir:
    sys.exit("ERROR: TOOLBOX_DIR environment variable not set.")
user_home = resolve_user_home(toolbox_dir)

# Paths
core_dir = Path(toolbox_dir) / "ToolboxCore"
json_file = core_dir / "menu_scan_output.json"
preview_file = core_dir / "menu_build_preview.txt"
db_file = Path(user_home) / ".config" / "toolbox" / "state.db"

# Ensure scan output exists
if not json_file.exists():
    sys.exit(f"ERROR: Scan output '{json_file}' not found. Please run 'menu_scan.py' first.")
# Initialize menu table (drop/create)
init_script = core_dir / "db_init_menu_extended.sh"
if not init_script.exists():
    sys.exit(f"ERROR: Initialization script '{init_script}' not found.")
subprocess.run(["bash","-c", str(init_script)], check=True)

# Load JSON tree
tree = json.loads(json_file.read_text())

entries = []  # for DB insertion
preview_lines = []  # for human preview

# Recursive numbering and preview
def recurse(nodes, parent_id="", depth=0):
    for idx, node in enumerate(nodes, start=1):
        # DB menu_number: hierarchical
        menu_number = f"{idx}" if depth == 0 else f"{parent_id}.{idx}" if parent_id else str(idx)
        path = node.get("path")
        name = node.get("name")
        is_dir = node.get("type") == "directory"
        entry_type = "menu" if is_dir else "script"
        command = "" if is_dir else str(Path(toolbox_dir) / path)

        # Append DB entry
        entries.append((
            path,
            parent_id,
            menu_number,
            name,
            "",
            "",
            "ToolboxCore",
            "https://github.com/ToolboxMenu",
            "default",
            "50",
            "📁" if is_dir else "📝",
            "",
            "",
            entry_type,
            command,
            idx,
            "true"
        ))

        # Prepare preview line: scripts restart numbering at each level
        indent = "  " * depth
        if is_dir:
            preview_lines.append(f"{indent}{menu_number}. 📁 {name}")
            # Recurse into directory children
            recurse(node.get("children", []), menu_number, depth + 1)
        else:
            # script numbering resets: use idx without prefix
            preview_lines.append(f"{indent}{idx}. 📝 {name}")

# Build
recurse(tree)

# Write preview
preview_file.parent.mkdir(parents=True, exist_ok=True)
with preview_file.open("w") as pf:
    pf.write("\n".join(preview_lines))

# Insert into DB
conn = sqlite3.connect(str(db_file))
cur = conn.cursor()
for e in entries:
    cur.execute(
        "INSERT OR REPLACE INTO menu (id, parent_id, menu_number, mn, md, mdd, mi, info, mc, mp, miicon, mtags, mauthor, type, command, order_num, installed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        e
    )
conn.commit()
conn.close()

print(f"✅ Menu build complete. Preview: {preview_file}\nInserted {len(entries)} entries into {db_file}")
