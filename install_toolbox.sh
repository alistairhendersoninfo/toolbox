#!/bin/bash

# install_toolbox.sh
# Run as root
# Installs toolbox, updater script, systemd service, and timer with logging

set -e

TOOLBOX_DIR="/opt/toolbox"
TOOLBOX_REPO="https://github.com/yourorg/toolbox.git"
LOGFILE="/var/log/toolbox_update.log"

echo "[INFO] Installing prerequisites..."
apt update
apt install -y git dialog

echo "[INFO] Creating log directory if needed..."
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 644 "$LOGFILE"

echo "[INFO] Cloning toolbox repository to $TOOLBOX_DIR..."
if [ ! -d "$TOOLBOX_DIR/.git" ]; then
    git clone "$TOOLBOX_REPO" "$TOOLBOX_DIR"
else
    cd "$TOOLBOX_DIR"
    git pull
fi

echo "[INFO] Installing toolbox launcher to /usr/local/bin/toolbox..."
cp "$TOOLBOX_DIR/toolbox" /usr/local/bin/toolbox
chmod +x /usr/local/bin/toolbox

echo "[INFO] Creating toolbox updater script at /usr/local/bin/toolbox_update.sh..."
tee /usr/local/bin/toolbox_update.sh <<EOF
#!/bin/bash
# Toolbox updater script

TOOLBOX_DIR="$TOOLBOX_DIR"

echo "[\$(date)] Starting toolbox update..." >> "$LOGFILE"

if [ ! -d "\$TOOLBOX_DIR/.git" ]; then
    echo "[\$(date)] Cloning toolbox repository..." >> "$LOGFILE"
    git clone "$TOOLBOX_REPO" "\$TOOLBOX_DIR" >> "$LOGFILE" 2>&1
else
    echo "[\$(date)] Updating toolbox repository..." >> "$LOGFILE"
    cd "\$TOOLBOX_DIR" || exit 1
    git pull >> "$LOGFILE" 2>&1
fi

echo "[\$(date)] Regenerating toolbox menu..." >> "$LOGFILE"
bash "\$TOOLBOX_DIR/create_toolbox.sh" >> "$LOGFILE" 2>&1

echo "[\$(date)] Toolbox update complete." >> "$LOGFILE"
EOF
chmod +x /usr/local/bin/toolbox_update.sh

echo "[INFO] Creating systemd service..."
tee /etc/systemd/system/toolbox-update.service <<EOF
[Unit]
Description=Update toolbox scripts from Git and regenerate menu
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/toolbox_update.sh
StandardOutput=append:$LOGFILE
StandardError=append:$LOGFILE
EOF

echo "[INFO] Creating systemd timer..."
tee /etc/systemd/system/toolbox-update.timer <<EOF
[Unit]
Description=Run toolbox update weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "[INFO] Enabling and starting toolbox update timer..."
systemctl daemon-reload
systemctl enable --now toolbox-update.timer

echo "[INFO] Running initial toolbox update..."
/usr/local/bin/toolbox_update.sh

echo "[INFO] Toolbox installation complete. Use 'toolbox' to launch."
echo "[INFO] Updates are logged to $LOGFILE"
