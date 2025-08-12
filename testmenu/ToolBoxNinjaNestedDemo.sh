#!/usr/bin/env bash
#MN ToolBox Ninja Nested Demo
#MD Multi-layer nested menu demo
#MDD Demonstrates a deeply nested multi-level Dialog menu system branded as ToolBox Ninja with multiple submenus and options per layer for training, demonstration, and framework extension.
#MI DialogTools
#INFO https://intra.tool-box.ninja/
#MC default
#MP top
#MIICON ninja
#MTAGS demo,dialog,multilayer,nested,toolbox
#MAUTHOR Alistair Henderson

# ============================================
# ToolBox Ninja Nested Menu Demonstration
# ============================================

set -euo pipefail

# Global variables
TITLE="🥷 ToolBox Ninja"
BACKTITLE="ToolBox Ninja Nested Menu Demo System"

# Function: Level 2 submenu
level2_submenu() {
  local parent_choice="$1"
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 Level 2 Menu - $parent_choice" \
      --menu "Select an option under $parent_choice:" 15 60 5 \
      1 "$parent_choice Option A" \
      2 "$parent_choice Option B" \
      3 "$parent_choice Option C" \
      4 "Return to Previous Menu")

    case "$choice" in
      1)
        dialog --backtitle "$BACKTITLE" --msgbox "You selected: $parent_choice Option A" 6 50
        ;;
      2)
        dialog --backtitle "$BACKTITLE" --msgbox "You selected: $parent_choice Option B" 6 50
        ;;
      3)
        dialog --backtitle "$BACKTITLE" --msgbox "You selected: $parent_choice Option C" 6 50
        ;;
      4)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

# Function: Level 1 submenu
level1_submenu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 Level 1 Menu" \
      --menu "Select a category:" 15 60 6 \
      1 "Ninja Weapons" \
      2 "Stealth Techniques" \
      3 "Escape Tools" \
      4 "Special Missions" \
      5 "Return to Main Menu")

    case "$choice" in
      1)
        level2_submenu "Ninja Weapons"
        ;;
      2)
        level2_submenu "Stealth Techniques"
        ;;
      3)
        level2_submenu "Escape Tools"
        ;;
      4)
        level2_submenu "Special Missions"
        ;;
      5)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

# Main Menu
while true; do
  choice=$(dialog --stdout --clear --backtitle "$BACKTITLE" --title "$TITLE" \
    --menu "Select an option:" 15 60 5 \
    1 "🥷 Enter Ninja Nested Menu" \
    2 "🥷 Show Info" \
    3 "🥷 Exit")

  case "$choice" in
    1)
      level1_submenu
      ;;
    2)
      dialog --backtitle "$BACKTITLE" --title "🥷 Ninja Info" --msgbox "ToolBox Ninja is your modular, multi-layer toolbox menu framework.\nStay stealthy. Stay productive." 7 60
      ;;
    3)
      dialog --backtitle "$BACKTITLE" --title "🥷 Farewell" --msgbox "Demo complete.\nGoodbye, ninja warrior." 6 50
      clear
      exit 0
      ;;
    *)
      clear
      exit 0
      ;;
  esac
done

clear
echo "🥷 ToolBox Ninja Nested Demo completed."
