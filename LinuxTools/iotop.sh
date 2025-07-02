#!/bin/bash
#MN: Iotop
#MD: Monitor disk I/O usage by processes.

if ! command -v iotop >/dev/null 2>&1; then
    echo "Installing iotop..."
    sudo apt update && sudo apt install -y iotop
fi

sudo iotop
