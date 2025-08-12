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

# Level 4 menu submenu
level4_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "$TITLE Menu" \
      --menu "Select an option:" 15 60 8 \
      3.6.1.1 "3.6.1.1 selinux_chatgpt_stream.sh" \
      3.6.1.2 "3.6.1.2 selinux_disable.sh" \
      3.6.1.3 "3.6.1.3 selinux_install.sh" \
      3.6.1.4 "3.6.1.4 selinux_set_enforcing.sh" \
      3.6.1.5 "3.6.1.5 selinux_set_permissive.sh" \
      3.6.2.1 "3.6.2.1 install_letsencrypt_certbot.sh" \
      Return "Return to Main Menu")
    case "$choice" in
      3.6.1.1)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/selinux/selinux_chatgpt_stream.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_chatgpt_stream.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_chatgpt_stream.sh" 6 50
        fi
        ;;
      3.6.1.2)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/selinux/selinux_disable.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_disable.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_disable.sh" 6 50
        fi
        ;;
      3.6.1.3)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/selinux/selinux_install.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_install.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_install.sh" 6 50
        fi
        ;;
      3.6.1.4)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/selinux/selinux_set_enforcing.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_set_enforcing.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_set_enforcing.sh" 6 50
        fi
        ;;
      3.6.1.5)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/selinux/selinux_set_permissive.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_set_permissive.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_set_permissive.sh" 6 50
        fi
        ;;
      3.6.2.1)
        if /opt/toolbox/LinuxTools/SystemSecurityUtilities/ssl/install_letsencrypt_certbot.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: install_letsencrypt_certbot.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: install_letsencrypt_certbot.sh" 6 50
        fi
        ;;
      Return)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}
# Level 3 menu submenu
level3_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "$TITLE Menu" \
      --menu "Select an option:" 15 60 21 \
      3.5.1 "3.5.1 htop.sh" \
      3.5.2 "3.5.2 iftop.sh" \
      3.5.3 "3.5.3 iotop.sh" \
      3.5.4 "3.5.4 top.sh" \
      3.6.1 "3.6.1 selinux" \
      3.6.2 "3.6.2 ssl" \
      3.7.1 "3.7.1 disable_ipv6.sh" \
      3.8.1 "3.8.1 install_advcp.sh" \
      3.8.2 "3.8.2 install_and_run_speedtest.sh" \
      4.1.1 "4.1.1 backup_dialogrc.sh" \
      4.1.10 "4.1.10 yellow_green_theme.sh" \
      4.1.2 "4.1.2 blue_steel_theme.sh" \
      4.1.3 "4.1.3 cyan_ice_theme.sh" \
      4.1.4 "4.1.4 dark_theme.sh" \
      4.1.5 "4.1.5 green_matrix_theme.sh" \
      4.1.6 "4.1.6 magenta_glow_theme.sh" \
      4.1.7 "4.1.7 red_alert_theme.sh" \
      4.1.8 "4.1.8 reset_theme.sh" \
      4.1.9 "4.1.9 set_custom_theme.sh" \
      Return "Return to Main Menu")
    case "$choice" in
      3.5.1)
        if /opt/toolbox/LinuxTools/PerformanceMonitoring/htop.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: htop.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: htop.sh" 6 50
        fi
        ;;
      3.5.2)
        if /opt/toolbox/LinuxTools/PerformanceMonitoring/iftop.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: iftop.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: iftop.sh" 6 50
        fi
        ;;
      3.5.3)
        if /opt/toolbox/LinuxTools/PerformanceMonitoring/iotop.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: iotop.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: iotop.sh" 6 50
        fi
        ;;
      3.5.4)
        if /opt/toolbox/LinuxTools/PerformanceMonitoring/top.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: top.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: top.sh" 6 50
        fi
        ;;
      3.6.1)
        level4_menu
        ;;
      3.6.2)
        level4_menu
        ;;
      3.7.1)
        if /opt/toolbox/LinuxTools/SystemTweaks/disable_ipv6.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: disable_ipv6.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: disable_ipv6.sh" 6 50
        fi
        ;;
      3.8.1)
        if /opt/toolbox/LinuxTools/SystemUtilities/install_advcp.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: install_advcp.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: install_advcp.sh" 6 50
        fi
        ;;
      3.8.2)
        if /opt/toolbox/LinuxTools/SystemUtilities/install_and_run_speedtest.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: install_and_run_speedtest.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: install_and_run_speedtest.sh" 6 50
        fi
        ;;
      4.1.1)
        if /opt/toolbox/ToolboxTools/ToolboxColours/backup_dialogrc.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: backup_dialogrc.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: backup_dialogrc.sh" 6 50
        fi
        ;;
      4.1.10)
        if /opt/toolbox/ToolboxTools/ToolboxColours/yellow_green_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: yellow_green_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: yellow_green_theme.sh" 6 50
        fi
        ;;
      4.1.2)
        if /opt/toolbox/ToolboxTools/ToolboxColours/blue_steel_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: blue_steel_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: blue_steel_theme.sh" 6 50
        fi
        ;;
      4.1.3)
        if /opt/toolbox/ToolboxTools/ToolboxColours/cyan_ice_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: cyan_ice_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: cyan_ice_theme.sh" 6 50
        fi
        ;;
      4.1.4)
        if /opt/toolbox/ToolboxTools/ToolboxColours/dark_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: dark_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: dark_theme.sh" 6 50
        fi
        ;;
      4.1.5)
        if /opt/toolbox/ToolboxTools/ToolboxColours/green_matrix_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: green_matrix_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: green_matrix_theme.sh" 6 50
        fi
        ;;
      4.1.6)
        if /opt/toolbox/ToolboxTools/ToolboxColours/magenta_glow_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: magenta_glow_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: magenta_glow_theme.sh" 6 50
        fi
        ;;
      4.1.7)
        if /opt/toolbox/ToolboxTools/ToolboxColours/red_alert_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: red_alert_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: red_alert_theme.sh" 6 50
        fi
        ;;
      4.1.8)
        if /opt/toolbox/ToolboxTools/ToolboxColours/reset_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: reset_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: reset_theme.sh" 6 50
        fi
        ;;
      4.1.9)
        if /opt/toolbox/ToolboxTools/ToolboxColours/set_custom_theme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: set_custom_theme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: set_custom_theme.sh" 6 50
        fi
        ;;
      Return)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}
# Level 2 menu submenu
level2_menu() {
  while true; do
    choice=$(dialog --stdout --backtitle "$BACKTITLE" --title "$TITLE Menu" \
      --menu "Select an option:" 15 60 22 \
      1.1 "1.1 create_script_skeleton.sh" \
      2.1 "2.1 init_pages.sh" \
      2.2 "2.2 update_pages.sh" \
      2.3 "2.3 generate_readme.sh" \
      3.1 "3.1 01.install_browsh.sh" \
      3.2 "3.2 02.install_elinks.sh" \
      3.3 "3.3 03.install_links.sh" \
      3.4 "3.4 04.install_w3m.sh" \
      3.5 "3.5 PerformanceMonitoring" \
      3.6 "3.6 SystemSecurityUtilities" \
      3.7 "3.7 SystemTweaks" \
      3.8 "3.8 SystemUtilities" \
      4.1 "4.1 ToolboxColours" \
      4.2 "4.2 view_install_progress.sh" \
      5.1 "5.1 update_coolwsd_config.sh" \
      6.1 "6.1 selinux_chatgpt_stream.sh" \
      6.2 "6.2 selinux_disable.sh" \
      6.3 "6.3 selinux_install.sh" \
      6.4 "6.4 selinux_set_enforcing.sh" \
      6.5 "6.5 selinux_set_permissive.sh" \
      Return "Return to Main Menu")
    case "$choice" in
      1.1)
        if /opt/toolbox/ToolboxSetup/create_script_skeleton.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: create_script_skeleton.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: create_script_skeleton.sh" 6 50
        fi
        ;;
      2.1)
        if /opt/toolbox/ToolboxPages/init_pages.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: init_pages.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: init_pages.sh" 6 50
        fi
        ;;
      2.2)
        if /opt/toolbox/ToolboxPages/update_pages.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: update_pages.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: update_pages.sh" 6 50
        fi
        ;;
      2.3)
        if /opt/toolbox/ToolboxPages/generate_readme.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: generate_readme.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: generate_readme.sh" 6 50
        fi
        ;;
      3.1)
        if /opt/toolbox/LinuxTools/01.install_browsh.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: 01.install_browsh.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: 01.install_browsh.sh" 6 50
        fi
        ;;
      3.2)
        if /opt/toolbox/LinuxTools/02.install_elinks.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: 02.install_elinks.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: 02.install_elinks.sh" 6 50
        fi
        ;;
      3.3)
        if /opt/toolbox/LinuxTools/03.install_links.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: 03.install_links.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: 03.install_links.sh" 6 50
        fi
        ;;
      3.4)
        if /opt/toolbox/LinuxTools/04.install_w3m.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: 04.install_w3m.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: 04.install_w3m.sh" 6 50
        fi
        ;;
      3.5)
        level3_menu
        ;;
      3.6)
        level3_menu
        ;;
      3.7)
        level3_menu
        ;;
      3.8)
        level3_menu
        ;;
      4.1)
        level3_menu
        ;;
      4.2)
        if /opt/toolbox/ToolboxTools/view_install_progress.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: view_install_progress.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: view_install_progress.sh" 6 50
        fi
        ;;
      5.1)
        if /opt/toolbox/CollaboraOnline/update_coolwsd_config.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: update_coolwsd_config.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: update_coolwsd_config.sh" 6 50
        fi
        ;;
      6.1)
        if /opt/toolbox/SystemSecurityUtilities/selinux_chatgpt_stream.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_chatgpt_stream.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_chatgpt_stream.sh" 6 50
        fi
        ;;
      6.2)
        if /opt/toolbox/SystemSecurityUtilities/selinux_disable.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_disable.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_disable.sh" 6 50
        fi
        ;;
      6.3)
        if /opt/toolbox/SystemSecurityUtilities/selinux_install.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_install.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_install.sh" 6 50
        fi
        ;;
      6.4)
        if /opt/toolbox/SystemSecurityUtilities/selinux_set_enforcing.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_set_enforcing.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_set_enforcing.sh" 6 50
        fi
        ;;
      6.5)
        if /opt/toolbox/SystemSecurityUtilities/selinux_set_permissive.sh; then
          dialog --backtitle "$BACKTITLE" --title "✅ Success" --msgbox "Script executed: selinux_set_permissive.sh" 6 50
        else
          dialog --backtitle "$BACKTITLE" --title "❌ Error" --msgbox "Failed: selinux_set_permissive.sh" 6 50
        fi
        ;;
      Return)
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
    --menu "Select an option:" 15 60 8 \
    1 "ToolboxSetup" \
    2 "ToolboxPages" \
    3 "LinuxTools" \
    4 "ToolboxTools" \
    5 "CollaboraOnline" \
    6 "SystemSecurityUtilities" \
    7 "Exit")
  case "$choice" in
    1)
      level2_menu
      ;;
    2)
      level2_menu
      ;;
    3)
      level2_menu
      ;;
    4)
      level2_menu
      ;;
    5)
      level2_menu
      ;;
    6)
      level2_menu
      ;;
    7)
      dialog --backtitle "$BACKTITLE" --title "🥷 Farewell" --msgbox "Demo complete.
Goodbye, ninja warrior." 6 50
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
clear
echo "🥷 ToolBox Ninja Deep Nested Demo completed."
