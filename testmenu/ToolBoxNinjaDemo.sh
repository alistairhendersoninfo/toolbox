#!/usr/bin/env bash
#MN ToolBox Ninja Demo
#MD All-singing, all-dancing multi-layer demo menu
#MDD Demonstration of a feature-rich multi-layer Dialog menu system branded as ToolBox Ninja, with checklists, radiolists, messages, and submenus for rapid deployment templates.
#MI DialogTools
#INFO https://intra.tool-box.ninja/
#MC default
#MP top
#MIICON ninja
#MTAGS demo,dialog,multilayer,toolbox
#MAUTHOR Alistair Henderson

# ============================================
# ToolBox Ninja Multi-Layer Menu Demonstration
# ============================================

set -euo pipefail

# Global variables
TITLE="🥷 ToolBox Ninja"
BACKTITLE="ToolBox Ninja Demo Menu System"

# Function: First Submenu - Checklist demo
first_submenu() {
  CHOICES=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 Ninja Checklist Demo" \
    --checklist "Select your ninja tools:" 15 50 5 \
    katana "Sharp blade for silent operations" on \
    shuriken "Throwing star for distance attack" off \
    kusarigama "Chain-sickle for entrapment" off \
    smoke "Smoke bomb for escape" on)

  clear
  echo "You selected: $CHOICES"
}

# Function: Second Submenu - Radiolist demo
second_submenu() {
  CHOICE=$(dialog --stdout --backtitle "$BACKTITLE" --title "🥷 Ninja Radiolist Demo" \
    --radiolist "Choose your stealth mode:" 15 50 4 \
    shadow "Blend with shadows" on \
    silent "Absolute silence" off \
    vanish "Instant vanish" off)

  clear
  echo "You chose stealth mode: $CHOICE"
}

# Function: Info box demo
infobox_demo() {
  dialog --backtitle "$BACKTITLE" --title "🥷 Ninja Info" --infobox "ToolBox Ninja is your ultimate toolbox menu system.\nFast. Modular. Unstoppable." 5 60
  sleep 3
}

# Function: Message box demo
msgbox_demo() {
  dialog --backtitle "$BACKTITLE" --title "🥷 Mission Complete" --msgbox "Your ToolBox Ninja demo has finished successfully.\nStay stealthy." 7 50
}

# Main Menu
while true; do
  CHOICE=$(dialog --stdout --clear --backtitle "$BACKTITLE" --title "$TITLE" \
    --menu "Select an option:" 15 60 5 \
    1 "🥷 Checklist Demo" \
    2 "🥷 Radiolist Demo" \
    3 "🥷 Show Info" \
    4 "🥷 Exit")

  case "$CHOICE" in
    1)
      first_submenu
      ;;
    2)
      second_submenu
      ;;
    3)
      infobox_demo
      ;;
    4)
      msgbox_demo
      break
      ;;
    *)
      break
      ;;
  esac
done

clear
echo "🥷 ToolBox Ninja Demo completed. Farewell, warrior."
