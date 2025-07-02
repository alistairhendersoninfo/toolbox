#!/bin/bash

#MN:Update Coolwsd XML File
#MD:This change the xml file base on your inputs for the Online collabora server
#MI:/etc/coolwsd/coolwsd.xml

# Collabora Online coolwsd.xml configuration updater (full tee version)
# Author: Your Infra Team
# Date: 2025-06-24

CONFIG_FILE="/etc/coolwsd/coolwsd.xml"
BACKUP_FILE="/etc/coolwsd/coolwsd.xml.backup.$(date +%Y%m%d%H%M%S)"

# Backup original file
echo "Creating backup at $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Prompt for required inputs
read -rp "Enter Collabora FQDN (server_name): " COLLABORA_FQDN
read -rp "Enter Nextcloud FQDN: " NEXTCLOUD_FQDN
read -rp "Enter Nextcloud public IP: " NEXTCLOUD_IP
read -rp "Enter Admin username: " ADMIN_USER
read -rsp "Enter Admin password: " ADMIN_PASS
echo

# Escape dots for XML regex where needed
NEXTCLOUD_IP_ESCAPED=$(echo "$NEXTCLOUD_IP" | sed 's/\./\\./g')

# Write new config with tee
sudo tee "$CONFIG_FILE" > /dev/null <<EOF
<config>
  <server_name>$COLLABORA_FQDN</server_name>

  <ssl>
    <enable>false</enable>
    <termination>true</termination>
  </ssl>

  <storage>
    <wopi allow="true">
      <alias_groups mode="groups">
        <group>
          <host allow="true">https://$NEXTCLOUD_FQDN</host>
        </group>
      </alias_groups>
    </wopi>
  </storage>

  <net>
    <post_allow>
      <host desc="Nextcloud public IP">$NEXTCLOUD_IP_ESCAPED</host>
    </post_allow>
  </net>

  <admin_console>
    <enable>true</enable>
    <username>$ADMIN_USER</username>
    <password>$ADMIN_PASS</password>
  </admin_console>

  <!-- Additional required defaults and settings here -->
</config>
EOF

echo "✅ Config written to $CONFIG_FILE"
echo "🔒 Original backed up at $BACKUP_FILE"

