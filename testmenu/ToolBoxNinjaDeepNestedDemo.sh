#!/usr/bin/env bash
#MN ToolBox Ninja Deep Nested Demo
#MD Multi-layer deep nested menu demo
#MDD Demonstrates a multi-level deeply nested Dialog menu structure branded as ToolBox Ninja for complex workflows and task navigation.
#MI DialogTools
#INFO https://intra.tool-box.ninja/
#MC default
#MP top
#MIICON ninja
#MTAGS demo,dialog,multilayer,nested,toolbox
#MAUTHOR Alistair Henderson

# ============================================
# ToolBox Ninja Deep Nested Menu Demonstration
# ============================================

set -euo pipefail

TITLE="🥷 ToolBox Ninja"
BACKTITLE="ToolBox Ninja Deep Nested Menu Demo System"

# Level 4 menu (1.1.1.1, 1.1.1.2)
level4_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 1.1.1 Menu" \
      --menu "Select a command:" 15 60 4 \
      1 "1.1.1.1 This is a command" \
      2 "1.1.1.2 This is a command" \
      3 "Return")

    case "$choice" in
      1)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.1.1.1 This is a command" 6 50
        ;;
      2)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.1.1.2 This is a command" 6 50
        ;;
      3)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

# Level 3 menu (1.1.1 This is a menu)
level3_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 1.1 Menu" \
      --menu "Select an option:" 15 60 4 \
      1 "1.1.1 This is a menu" \
      2 "1.1.2 This is a command" \
      3 "Return")

    case "$choice" in
      1)
        level4_menu
        ;;
      2)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.1.2 This is a command" 6 50
        ;;
      3)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

# Level 3 menu for 1.2
level3_menu_1_2() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 1.2 Menu" \
      --menu "Select an option:" 15 60 4 \
      1 "1.2.1 This is a command" \
      2 "1.2.2 This is a command" \
      3 "Return")

    case "$choice" in
      1)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.2.1 This is a command" 6 50
        ;;
      2)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.2.2 This is a command" 6 50
        ;;
      3)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

# Level 2 menu (Checklist Demo submenu)
level2_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 Checklist Demo Menu" \
      --menu "Select an option:" 15 60 6 \
      1 "1.1 This is menu" \
      2 "1.2 This is menu" \
      3 "1.3 This is a command" \
      4 "1.4 This is a command" \
      5 "Return to Main Menu")

    case "$choice" in
      1)
        level3_menu
        ;;
      2)
        level3_menu_1_2
        ;;
      3)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.3 This is a command" 6 50
        ;;
      4)
        dialog --backtitle "$BACKTITLE" --msgbox "Executed: 1.4 This is a command" 6 50
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
    --menu "Select an option:" 15 60 4 \
    1 "🥷 Checklist Demo" \
    2 "🥷 Exit")

  case "$choice" in
    1)
      level2_menu
      ;;
    2)
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
echo "🥷 ToolBox Ninja Deep Nested Demo completed."
