#!/usr/bin/env python3
#MN ToolBox Ninja Menu
#MD Static Bash skeleton generator with depth detection and level data export
#MDD Creates the basic shell script skeleton for the ToolBox Ninja menu, detects max menu depth, and exports per-level entries to text files.
#MI ToolboxCore
#INFO https://intra.tool-box.ninja/
#MC default
#MP top
#MIICON ninja
#MTAGS generator,menu,dialog,python,toolbox
#MAUTHOR Alistair Henderson

import os
import sys
import sqlite3
from pathlib import Path

# Resolve USER_HOME via generic_functions.sh
def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    cmd = f"bash -lc 'source {generic_funcs} && resolve_user_home && echo $USER_HOME'"
    result = os.popen(cmd).read().strip()
    if not result:
        sys.exit("ERROR: unable to resolve USER_HOME")
    return result

# Export a level to dialog format and raw SQL dump
def export_level(level, db_path, output_dir):
    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()
    cur.execute(
        "SELECT menu_number, mn, type, command FROM menu "
        "WHERE (LENGTH(menu_number) - LENGTH(REPLACE(menu_number, '.', ''))) + 1 = ? "
        "ORDER BY menu_number;",
        (level,)
    )
    rows = cur.fetchall()
    conn.close()

    dialog_file = Path(output_dir) / f"menu_output_{level}.txt"
    raw_file = Path(output_dir) / f"menu_output_{level}-sql.txt"

    with open(dialog_file, 'w') as f, open(raw_file, 'w') as rf:
        if level == 1:
            # Main menu
            f.write("# Main Menu\n")
            f.write("while true; do\n")
            num_opts = len(rows)
            f.write("  choice=$(dialog --stdout --clear --backtitle \"$BACKTITLE\" --title \"$TITLE\" \\\n")
            f.write("    --menu \"Select an option:\" 15 60 {} \\\n".format(num_opts + 2))
            for num, mn, typ, cmd in rows:
                f.write(f"    {num} \"{mn}\" \\\n")
            f.write("    {} \"Exit\")\n".format(num_opts + 1))
            f.write("  case \"$choice\" in\n")
            for num, mn, typ, cmd in rows:
                if typ == 'menu':
                    f.write(f"    {num})\n      level2_menu\n      ;;\n")
                else:
                    f.write(f"    {num})\n      if {cmd}; then\n        dialog --backtitle \"$BACKTITLE\" --title \"✅ Success\" --msgbox \"Script executed: {mn}\" 6 50\n      else\n        dialog --backtitle \"$BACKTITLE\" --title \"❌ Error\" --msgbox \"Failed: {mn}\" 6 50\n      fi\n      ;;\n")
            f.write(f"    {num_opts+1})\n      dialog --backtitle \"$BACKTITLE\" --title \"🥷 Farewell\" --msgbox \"Demo complete.\nGoodbye, ninja warrior.\" 6 50\n      clear\n      exit 0\n      ;;\n")
            f.write("    *)\n      clear\n      exit 0\n      ;;\n")
            f.write("  esac\n")
            f.write("done\nclear\n")
        else:
            # Submenus
            f.write(f"# Level {level} menu submenu\n")
            f.write(f"level{level}_menu() {{\n")
            f.write("  while true; do\n")
            num_opts = len(rows)
            f.write("    choice=$(dialog --stdout --backtitle \"$BACKTITLE\" --title \"$TITLE Menu\" \\\n")
            f.write("      --menu \"Select an option:\" 15 60 {} \\\n".format(num_opts + 2))
            for num, mn, typ, cmd in rows:
                f.write(f"      {num} \"{num} {mn}\" \\\n")
            f.write(f"      Return \"Return to Main Menu\")\n")
            f.write("    case \"$choice\" in\n")
            for num, mn, typ, cmd in rows:
                if typ == 'menu':
                    f.write(f"      {num})\n        level{level+1}_menu\n        ;;\n")
                else:
                    f.write(f"      {num})\n        if {cmd}; then\n          dialog --backtitle \"$BACKTITLE\" --title \"✅ Success\" --msgbox \"Script executed: {mn}\" 6 50\n        else\n          dialog --backtitle \"$BACKTITLE\" --title \"❌ Error\" --msgbox \"Failed: {mn}\" 6 50\n        fi\n        ;;\n")
            f.write("      Return)\n        break\n        ;;\n")
            f.write("      *)\n        break\n        ;;\n")
            f.write("    esac\n  done\n}\n")

        # write raw SQL
        for num, mn, typ, cmd in rows:
            rf.write(f"{num} | {mn} | {typ} | {cmd}\n")

    print(f"Exported level {level} to: {dialog_file} and {raw_file}")

# Entry point
def main():
    toolbox_dir = os.environ.get("TOOLBOX_DIR")
    if not toolbox_dir:
        sys.exit("ERROR: TOOLBOX_DIR environment variable not set.")

    user_home = resolve_user_home(toolbox_dir)
    db_path = Path(user_home) / ".config" / "toolbox" / "state.db"
    core_dir = Path(toolbox_dir) / "ToolboxCore"

    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()
    cur.execute(
        "SELECT MAX((LENGTH(menu_number) - LENGTH(REPLACE(menu_number, '.', ''))) + 1) FROM menu;"
    )
    max_depth = cur.fetchone()[0] or 1
    conn.close()
    print(f"Detected max menu depth: {max_depth}")

    # Export levels and generate static_menu.sh
    for level in range(1, max_depth + 1):
        export_level(level, db_path, core_dir)

    output_sh = core_dir / "static_menu.sh"
    with open(output_sh, 'w') as out:
        # Header metadata
        out.write("#!/usr/bin/env bash\n")
        out.write("#MN ToolBox Ninja Deep Nested Demo\n")
        out.write("#MD Multi-layer deep nested menu demo\n")
        out.write("#MDD Demonstrates a multi-level deeply nested Dialog menu structure branded as ToolBox Ninja for complex workflows and task navigation.\n")
        out.write("#MI DialogTools\n")
        out.write("#INFO https://intra.tool-box.ninja/\n")
        out.write("#MC default\n")
        out.write("#MP top\n")
        out.write("#MIICON ninja\n")
        out.write("#MTAGS demo,dialog,multilayer,nested,toolbox\n")
        out.write("#MAUTHOR Alistair Henderson\n\n")
        out.write("# ============================================\n")
        out.write("# ToolBox Ninja Deep Nested Menu Demonstration\n")
        out.write("# ============================================\n\n")
        out.write("set -euo pipefail\n\n")
        out.write("TITLE=\"🥷 ToolBox Ninja\"\n")
        out.write("BACKTITLE=\"ToolBox Ninja Deep Nested Menu Demo System\"\n\n")

        # Insert generated functions in reverse order (deepest first)
                # Insert generated functions in reverse order (deepest first)
        for lvl in range(max_depth, 1, -1):
            fn = core_dir / f"menu_output_{lvl}.txt"
            content = fn.read_text()
            out.write(content)
            out.write("")
        # Main Menu from level 1
        main_fn = core_dir / "menu_output_1.txt"
        out.write(main_fn.read_text())
        out.write("clear\n")
        out.write("echo \"🥷 ToolBox Ninja Deep Nested Demo completed.\"\n")

    os.chmod(output_sh, 0o755)
    print(f"✅ Skeleton script generated at: {output_sh}")

if __name__ == '__main__':
    main()
