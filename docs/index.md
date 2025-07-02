## 🚀 Toolbox Installation and Usage

### 🛠️ Initial Setup

Clone or copy the toolbox repository to your server:

\`\`\`bash
git clone <your-repo-url> toolbox
cd toolbox
\`\`\`

Run the installation script to deploy required dependencies:

\`\`\`bash
./install_toolbox.sh
\`\`\`

### 🔄 Regenerating READMEs

\`\`\`bash
./generate_readme.sh
\`\`\`

### 🔍 Scanning and Menu Indexing

\`\`\`bash
./toolbox_scan.sh
\`\`\`

### 🔧 Execution

\`\`\`bash
./create_toolbox.sh
\`\`\`

### 🔁 Recommended Maintenance

1. **generate_readme.sh** – update documentation
2. **toolbox_scan.sh** – refresh indexes
3. **create_toolbox.sh** – test menu system

### 📅 Automated Updates

Set up a **cron job** to pull new scripts daily or weekly:

- **Daily example (runs at 2am):**

\`\`\`bash
0 2 * * * cd /path/to/toolbox && git pull && ./generate_readme.sh && ./toolbox_scan.sh
\`\`\`

- **Weekly example (runs every Sunday at 3am):**

\`\`\`bash
0 3 * * 0 cd /path/to/toolbox && git pull && ./generate_readme.sh && ./toolbox_scan.sh
\`\`\`

This ensures your toolbox is always up to date with the latest scripts and documentation.

### ℹ️ Note

Ensure all scripts include standard headers:

- \`# MN:\` – **Menu Name** (display name in toolbox menu)
- \`# MD:\` – **Menu Description** (what the script does)
- \`# MI:\` – **Menu Install requirement** (required command/package for menu to show entry)

# All Scripts

## [CollaboraOnline/update_coolwsd_config.sh](CollaboraOnline/update_coolwsd_config.sh.md)
- **Menu Name:** Update Coolwsd XML File
- **Description:** This change the xml file base on your inputs for the Online collabora server

## [LinuxTools/SystemUtilities/install_and_run_speedtest.sh](LinuxTools/SystemUtilities/install_and_run_speedtest.sh.md)
- **Menu Name:** InstallAndRunSpeedTest
- **Description:** Check if Ookla Speedtest CLI is installed, install if missing, then run it

## [LinuxTools/SystemUtilities/install_advcp.sh](LinuxTools/SystemUtilities/install_advcp.sh.md)
- **Menu Name:** InstallAdvcp
- **Description:** Install advcp/advmv with optional aliases configured in .bashrc

## [LinuxTools/iftop.sh](LinuxTools/iftop.sh.md)
- **Menu Name:** Iftop
- **Description:** Displays real-time bandwidth usage per connection.

## [LinuxTools/iotop.sh](LinuxTools/iotop.sh.md)
- **Menu Name:** Iotop
- **Description:** Monitor disk I/O usage by processes.

## [LinuxTools/top.sh](LinuxTools/top.sh.md)
- **Menu Name:** Top
- **Description:** Displays real-time system processes and CPU usage.

## [LinuxTools/PerformanceMonitoring/iftop.sh](LinuxTools/PerformanceMonitoring/iftop.sh.md)
- **Menu Name:** Iftop
- **Description:** Displays real-time bandwidth usage per connection.

## [LinuxTools/PerformanceMonitoring/iotop.sh](LinuxTools/PerformanceMonitoring/iotop.sh.md)
- **Menu Name:** Iotop
- **Description:** Monitor disk I/O usage by processes.

## [LinuxTools/PerformanceMonitoring/top.sh](LinuxTools/PerformanceMonitoring/top.sh.md)
- **Menu Name:** Top
- **Description:** Displays real-time system processes and CPU usage.

## [LinuxTools/PerformanceMonitoring/htop.sh](LinuxTools/PerformanceMonitoring/htop.sh.md)
- **Menu Name:** Htop
- **Description:** Interactive process viewer with color and tree view.

## [LinuxTools/htop.sh](LinuxTools/htop.sh.md)
- **Menu Name:** Htop
- **Description:** Interactive process viewer with color and tree view.

## [LinuxTools/SystemTweaks/disable_ipv6.sh](LinuxTools/SystemTweaks/disable_ipv6.sh.md)
- **Menu Name:** DisableIPv6
- **Description:** Temporarily disable IPv6 on all interfaces

