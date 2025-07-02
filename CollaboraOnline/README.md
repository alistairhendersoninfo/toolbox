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

# CollaboraOnline Scripts

### update_coolwsd_config.sh
- **Description:** This change the xml file base on your inputs for the Online collabora server
- **MI:** /etc/coolwsd/coolwsd.xml (menu will appear if this exists)

