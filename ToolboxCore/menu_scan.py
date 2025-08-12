#!/usr/bin/env python3
#MN menu_scan
#MD Toolbox directory scan with include/exclude logic
#MDD Scans TOOLBOX_DIR applying TopLevel, AlwaysInclude, AlwaysExclude, IgnorePatterns and outputs preview and JSON structured results, ensuring TopLevel directories appear first, LinuxTools immediately after, then all other entries alphabetically.
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MC default
#MP top
#MIICON gear
#MTAGS scan,menu,toolbox
#MAUTHOR Alistair Henderson

import os
import json
import configparser
import subprocess
from pathlib import Path
import fnmatch

# Resolve USER_HOME from generic_functions.sh
def resolve_user_home(toolbox_dir):
    generic_funcs = Path(toolbox_dir) / "ToolboxCore" / "generic_functions.sh"
    result = subprocess.run([
        "bash", "-c", f"source {generic_funcs} && resolve_user_home && echo $USER_HOME"
    ], capture_output=True, text=True)
    return result.stdout.strip()

# Environment
box_dir = os.environ.get("TOOLBOX_DIR")
if not box_dir:
    raise RuntimeError("TOOLBOX_DIR not set")
toolbox_dir = box_dir
user_home = resolve_user_home(toolbox_dir)
config_path = Path(toolbox_dir) / "ToolboxCore" / "toolbox_scan_config.ini"

# Parse config
config = configparser.ConfigParser(allow_no_value=True)
config.optionxform = str
config.read(config_path)

# Load sections
# Maintain order for TopLevel and AlwaysInclude
top_level_paths = list(config["TopLevel"].keys()) if "TopLevel" in config else []
always_include_keys = list(config["AlwaysInclude"].keys()) if "AlwaysInclude" in config else []
always_exclude = {k.lower() for k in config["AlwaysExclude"].keys()} if "AlwaysExclude" in config else set()
ignore_patterns = list(config["IgnorePatterns"].keys()) if "IgnorePatterns" in config else []

# Determine unique TopLevel roots in config order
ordered_roots = []
for tl in top_level_paths:
    root = tl.split('/')[0]
    if root not in ordered_roots:
        ordered_roots.append(root)

# Helper: pattern ignore
def is_ignored(name):
    return any(fnmatch.fnmatch(name, pat) for pat in ignore_patterns)

# Recursive scan
def scan_dir(path: Path, rel_path=""):
    items = []
    for entry in sorted(path.iterdir(), key=lambda p: p.name.lower()):
        name = entry.name
        lower = name.lower()
        rel = os.path.join(rel_path, name) if rel_path else name
        # Skip root TopLevel directories here
        if not rel_path and name in ordered_roots:
            continue
        # Exclude directory if in always_exclude
        if entry.is_dir() and lower in always_exclude:
            continue
        # Exclude file patterns
        if is_ignored(name):
            continue
        # Directory
        if entry.is_dir():
            children = scan_dir(entry, rel)
            if children:
                items.append({"type": "directory", "name": name, "path": rel, "children": children})
        # Script
        elif entry.is_file() and name.endswith('.sh'):
            items.append({"type": "script", "name": name, "path": rel})
    return items

# Build initial tree: TopLevel injection + scanned rest
tree = []
# Insert TopLevel entries (directories and scripts)
for tl in top_level_paths:
    parts = tl.split('/')
    curr = tree
    # directories
    for part in parts[:-1]:
        node = next((n for n in curr if n['type'] == 'directory' and n['name'] == part), None)
        if not node:
            node = {'type': 'directory', 'name': part, 'path': part, 'children': []}
            curr.append(node)
        curr = node['children']
    # final script
    script = parts[-1]
    full = tl
    if not any(n for n in curr if n['type'] == 'script' and n['path'] == full):
        curr.append({'type': 'script', 'name': script, 'path': full})

# Append other scan results
for node in scan_dir(Path(toolbox_dir)):
    tree.append(node)

# Sort children within each node
def sort_tree(nodes):
    nodes.sort(key=lambda n: (n['type'] != 'directory', n['name'].lower()))
    for n in nodes:
        if 'children' in n:
            sort_tree(n['children'])

# Reorder root: TopLevel directories first, LinuxTools immediately after, then others alphabetically
def reorder_root(original):
    result = []
    # TopLevel
    for root in ordered_roots:
        node = next((n for n in original if n['type'] == 'directory' and n['name'] == root), None)
        if node:
            result.append(node)
    # AlwaysInclude directories after TopLevel
    for inc in always_include_keys:
        if inc not in ordered_roots:
            node = next((n for n in original if n['type'] == 'directory' and n['name'] == inc), None)
            if node:
                result.append(node)
    # Others
    others = [n for n in original if n not in result]
    sort_tree(others)
    result.extend(others)
    return result

tree = reorder_root(tree)

# Write human preview
preview_file = Path(toolbox_dir) / "ToolboxCore" / "menu_scan_preview.txt"
with preview_file.open('w') as pf:
    def write_preview(nodes, indent=0):
        for n in nodes:
            pf.write('  ' * indent)
            pf.write(('📁 ' if n['type'] == 'directory' else '📝 ') + n['name'] + '\n')
            if 'children' in n:
                write_preview(n['children'], indent + 1)
    write_preview(tree)

# Write JSON
json_file = Path(toolbox_dir) / "ToolboxCore" / "menu_scan_output.json"
with json_file.open('w') as jf:
    json.dump(tree, jf, indent=2)

print(f"✅ Scan complete.\n- Preview: {preview_file}\n- JSON: {json_file}")
