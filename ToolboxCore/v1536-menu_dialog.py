#!/usr/bin/env python3
#MN menu_dialog
#MD Static menu script generator for main menu
#MDD Reads the Toolbox SQLite menu table and writes the static_menu.sh with only the main menu loop and options.
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

# Resolve USER_HOME via generic_functions.sh
def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    result = os.popen(f"bash -lc 'source {generic_funcs} && resolve_user_home && echo $USER_HOME'").read().strip()
    if not result:
        sys.exit("ERROR: unable to resolve USER_HOME")
    return result

# Entry point
def main():
    toolbox_dir = os.environ.get("TOOLBOX_DIR")
    if not toolbox_dir:
        sys.exit("ERROR: TOOLBOX_DIR environment variable not set.")
    user_home = resolve_user_home(toolbox_dir)
    db_file = Path(user_home) / ".config" / "toolbox" / "state.db"
    output = Path(toolbox_dir) / "ToolboxCore" / "static_menu.sh"

    # Fetch top-level entries
    conn = sqlite3.connect(str(db_file))
    cur = conn.cursor()
    cur.execute(
        "SELECT menu_number, mn, type, command FROM menu WHERE parent_id='' ORDER BY order_num;"
    )
    rows = cur.fetchall()
    conn.close()

    # Compute dialog menu height (one extra for Exit)
    menu_height = len(rows) + 1

    # Write the static bash script
    with open(output, 'w') as out:
        out.write("#!/usr/bin/env bash\n")
        out.write("set -euo pipefail\n\n")
        out.write("TITLE=\"🥷 ToolBox Ninja\"\n")
        out.write("BACKTITLE=\"ToolBox Ninja Static Menu\"\n\n")
        out.write("# Main Menu\n")
        out.write("while true; do\n")
        out.write("  choice=$(dialog --stdout --clear --backtitle \"$BACKTITLE\" --title \"$TITLE\" \
")
        out.write(f"    --menu \"Select an option:\" 15 60 {menu_height} \
")
        for num, mn, typ, cmd in rows:
            icon = '📁' if typ == 'menu' else '📝'
            out.write(f"    \"{num}\" \"{icon} {mn}\" \
")
        out.write("    \"0\" \"🛑 Exit\")\n")
        out.write("  case \"$choice\" in\n")
        for num, mn, typ, cmd in rows:
            if typ == 'menu':
                func = f"level{num.replace('.', '_')}_menu"
                out.write(f"    \"{num}\")\n")
                out.write(f"      {func}\n")
                out.write("      ;;\n")
        out.write("    \"0\")\n")
        out.write("      clear; exit 0\n")
        out.write("      ;;\n")
        out.write("    *)\n")
        out.write("      clear; exit 0\n")
        out.write("      ;;\n")
        out.write("  esac\n")
        out.write("done\n")
        out.write("clear\n")

    os.chmod(output, 0o755)
    print(f"✅ Generated main menu script at: {output}")

if __name__ == '__main__':
    main()
