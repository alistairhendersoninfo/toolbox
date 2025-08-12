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

# Resolve USER_HOME via generic_functions.sh
def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    cmd = f"bash -lc 'source {generic_funcs} && resolve_user_home && echo $USER_HOME'"
    result = os.popen(cmd).read().strip()
    if not result:
        sys.exit("ERROR: unable to resolve USER_HOME")
    return result

# Helper to write each menu level function
def write_function(out, parent_id, items, children):
    # Determine function name
    if parent_id == "":
        func_name = "menu_level_root"
    else:
        if parent_id not in items:
            return
        func_name = "menu_level_" + items[parent_id]["num"].replace('.', '_')
    out.write(f"{func_name}() {{\n")
    out.write("    local choice\n")
    # Build options array
    out.write("    options=(\n")
    for cid in children.get(parent_id, []):
        data = items.get(cid)
        if not data:
            continue
        num = data['num']
        icon = '📁' if data['type'] == 'menu' else '📝'
        mn = data['mn']
        label = f"{icon} {mn}"
        out.write(f"        \"{num}\" \"{label}\"\n")
    out.write("    )\n")
    # Dialog invocation
    dialog_line = (
        "    choice=$(dialog --clear --backtitle \"$BACKTITLE\" "
        "--title \"$TITLE\" --menu \"Select an option:\" 0 0 0 "
        "\"${options[@]}\" 2>&1 >/dev/tty)\n"
    )
    out.write(dialog_line)
    out.write("    [[ -z \"$choice\" ]] && return\n")
    # Handle choice
    out.write("    case \"$choice\" in\n")
    for cid in children.get(parent_id, []):
        data = items.get(cid)
        if not data:
            continue
        num = data['num']
        if data['type'] == 'menu':
            if parent_id == "":
                next_func = "menu_level_root"
            else:
                next_func = "menu_level_" + num.replace('.', '_')
            out.write(f"        {num}) {next_func} ;;\n")
        else:
            cmd = data['cmd']
            mn = data['mn']
            out.write(f"        {num}) bash -c '{cmd}' ;;")
            out.write("\n")
            out.write(f"        {num}) dialog --msgbox 'Executed: {num} {mn}' 5 50 ;;\n")
    out.write("    esac\n")
    out.write("}\n\n")

# Main generator
if __name__ == '__main__':
    toolbox_dir = os.environ.get("TOOLBOX_DIR")
    if not toolbox_dir:
        sys.exit("ERROR: TOOLBOX_DIR environment variable not set.")
    user_home = resolve_user_home(toolbox_dir)
    db_file = Path(user_home) / ".config" / "toolbox" / "state.db"
    output = Path(toolbox_dir) / "ToolboxCore" / "static_menu.sh"

    # Fetch all menu entries
    conn = sqlite3.connect(str(db_file))
    cur = conn.cursor()
    cur.execute(
        "SELECT id, parent_id, menu_number, mn, type, command, order_num "
        "FROM menu ORDER BY parent_id, order_num"
    )
    rows = cur.fetchall()
    conn.close()

    # Build hierarchy maps
    items = {}
    children = defaultdict(list)
    for id_, parent, num, mn, typ, cmd, order in rows:
        items[id_] = {"num": num, "mn": mn, "type": typ, "cmd": cmd}
        children[parent].append(id_)

    # Write static bash menu script
    with open(output, 'w') as out:
        out.write("#!/usr/bin/env bash\n")
        out.write("set -euo pipefail\n\n")
        out.write("source \"${TOOLBOX_DIR}/ToolboxCore/generic_functions.sh\"\n")
        out.write("resolve_user_home\n")
        out.write("DBFILE=\"${USER_HOME}/.config/toolbox/state.db\"\n")
        out.write("TITLE=\"🥷 ToolBox Ninja\"\n")
        out.write("BACKTITLE=\"ToolBox Ninja Static Menu\"\n\n")

        # Generate menu functions
        write_function(out, '', items, children)
        for pid in children:
            write_function(out, pid, items, children)

        # Entry point
        out.write("clear\n")
        out.write("menu_level_root\n")
        out.write("clear\n")

    os.chmod(output, 0o755)
    print(f"✅ Generated static menu script at: {output}")
