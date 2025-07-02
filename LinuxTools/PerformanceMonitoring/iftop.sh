#!/bin/bash
#MN: Iftop
#MD: Displays real-time bandwidth usage per connection.

if ! command -v iftop >/dev/null 2>&1; then
    echo "Installing iftop..."
    sudo apt update && sudo apt install -y iftop
fi

sudo iftop
