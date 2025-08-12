#!/usr/bin/env python3
#MN generate_menu_script_py
#MD Generate static Dialog-based menu script from database using Python
#MDD Reads the Toolbox SQLite menu table and outputs a standalone Bash script with nested dialog menus, leveraging Python for parsing and file generation.
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MC default
#MP top
#MIICON code
#MTAGS generator,menu,dialog,python,toolbox
#MAUTHOR Alistair Henderson

import os
import sys
import sqlite3
from pathlib import Path
from collections import defaultdict

def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    # Use bash -lc to ensure 'source' and resolve_user_home are available
    cmd = f"bash -lc 'source {generic_funcs} && resolve_user_home && echo $USER_HOME'"
    result = os.popen(cmd).read().strip()
    if not result:
        sys.exit("ERROR: unable to resolve USER_HOME")
    return result

def main():
    toolbox_dir = os.environ.get("TOOLBOX_DIR")
    if not toolbox_dir:
        sys.exit("ERROR: TOOLBOX_DIR environment variable not set.")
    user_home = resolve_user_home(toolbox_dir)

    db_file   = Path(user_home) / ".config" / "toolbox" / "state.db"
    output    = Path(toolbox_dir) / "ToolboxCore" / "static_menu.sh"

    # Fetch all menu rows
    conn = sqlite3.connect(str(db_file))
    cur = conn.cursor()
    cur.execute(
        "SELECT id, parent_id, menu_number, mn, type, command, order_num "
        "FROM menu ORDER BY parent_id, order_num"
    )
    rows = cur.fetchall()
    conn.close()

    # Build hierarchy
    items = {}
    children = defaultdict(list)
    for id_, parent, num, mn, typ, cmd, order in rows:
        items[id_] = {"num": num, "mn": mn, "type": typ, "cmd": cmd}
        children[parent].append(id_)

    # Write the static bash menu
    with open(output, "w") as out:
        out.write("#!/usr/bin/env bash\n")
        out.write("set -euo pipefail\n\n")
        out.write('source "${TOOLBOX_DIR}/ToolboxCore/generic_functions.sh"\n')
        out.write("resolve_user_home\n")
        out.write('DBFILE="${USER_HOME}/.config/toolbox/state.db"\n')
        out.write('TITLE="🥷 ToolBox Ninja"\n')
        out.write('BACKTITLE="ToolBox Ninja Static Menu"\n\n')

        def write_function(parent_id):
            if parent_id == "":
                func = "menu_level_root"
            else:
                func = "menu_level_" + items[parent_id]["num"].replace(".", "_")
            out.write(f"{func}() {{\n")
            out.write("    local choice\n")
            out.write("    options=(\n")
            for cid in children.get(parent_id, []):
                data = items[cid]
                icon = "📁" if data["type"] == "menu" else "📝"
                label = f"{data['num']} {icon} {data['mn']}"
                out.write(f"        \"{cid}\" \"{label}\"\n")
            out.write("    )\n")
            out.write(
                "    choice=$(dialog --clear --backtitle \"$BACKTITLE\" "
                "--title \"$TITLE\" --menu \"Select an option:\" 0 0 0 "
                "\"${options[@]}\" 2>&1 >/dev/tty)\n"
            )
            out.write("    [[ -z \"$choice\" ]] && return\n")
            out.write("    case \"$choice\" in\n")
            for cid in children.get(parent_id, []):
                data = items[cid]
                if data["type"] == "menu":
                    nextf = "menu_level_root" if parent_id == "" else "menu_level_" + data["num"].replace(".", "_")
                    out.write(f"        {cid}) {nextf} ;;\n")
                else:
                    out.write(f"        {cid}) bash -c '{data['cmd']}' ;;\n")
                    out.write(
                        f"        {cid}) dialog --msgbox \"Executed: {data['num']} {data['mn']}\" 5 50 ;;\n"
                    )
            out.write("    esac\n}\n\n")

        # Generate all functions
        write_function("")
        for pid in children:
            if pid and children[pid]:
                write_function(pid)

        # Entry point
        out.write("clear\n")
        out.write("menu_level_root\n")
        out.write("clear\n")

    os.chmod(output, 0o755)
    print(f"✅ Generated static menu script at: {output}")

if __name__ == "__main__":
    main()
