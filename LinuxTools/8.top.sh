#!/bin/bash
#MN: Top
#MD: Displays real-time system processes and CPU usage.

if ! command -v top >/dev/null 2>&1; then
    echo "Installing top..."
    sudo apt update && sudo apt install -y procps
fi

top
