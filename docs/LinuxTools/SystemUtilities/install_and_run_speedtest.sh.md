# install_and_run_speedtest.sh

## Description
Check if Ookla Speedtest CLI is installed, install if missing, then run it

## Info
N/A

## Script
```bash
#!/bin/bash

# MN: InstallAndRunSpeedTest
# MD: Check if Ookla Speedtest CLI is installed, install if missing, then run it

echo "Checking for Ookla Speedtest CLI..."

if command -v speedtest &> /dev/null; then
    echo "Speedtest CLI is already installed."
else
    echo "Speedtest CLI not found. Installing..."

    # Import Ookla GPG key
    curl -s https://packagecloud.io/ookla/speedtest-cli/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/speedtest-archive-keyring.gpg

    # Add repository directly without apt update
    echo "deb [signed-by=/usr/share/keyrings/speedtest-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/debian/ bullseye main" | sudo tee /etc/apt/sources.list.d/speedtest.list

    # Install using dpkg with direct download to avoid apt update
    ARCH=\$(dpkg --print-architecture)
    URL=\$(curl -s https://packagecloud.io/api/v1/repos/ookla/speedtest-cli/packages/debian/bullseye/speedtest.deb | grep -oP '(?<="browser_download_url": ")[^"]*' | grep \$ARCH | head -n1)
    curl -o /tmp/speedtest.deb "\$URL"
    sudo dpkg -i /tmp/speedtest.deb
    rm /tmp/speedtest.deb

    echo "Speedtest CLI installation completed."
fi

echo "Running Speed Test..."
speedtest
```
