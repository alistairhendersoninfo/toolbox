#!/usr/bin/env bash
#MN SELinux ChatGPT Stream
#MD Stream AVC denials to ChatGPT
#MDD Tails the audit log for SELinux AVC denials and sends each to ChatGPT to generate suggested allow rules in audit2allow syntax. Prompts for an OpenAI API key if not already configured.
#INFO https://platform.openai.com/docs/api-reference

echo "Checking Python 3..."
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python3 not found. Installing..."
  if [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt install -y python3 python3-pip
  elif [ -f /etc/redhat-release ]; then
    sudo yum install -y python3 python3-pip
  else
    echo "Unsupported OS. Install Python 3 manually."
    exit 1
  fi
fi

echo "Checking pip..."
if ! command -v pip3 >/dev/null 2>&1; then
  echo "pip3 not found. Installing..."
  if [ -f /etc/debian_version ]; then
    sudo apt install -y python3-pip
  elif [ -f /etc/redhat-release ]; then
    sudo yum install -y python3-pip
  fi
fi

echo "Checking required Python modules..."
if ! python3 -c "import openai" >/dev/null 2>&1; then
  echo "Installing openai module..."
  pip3 install openai
fi

if ! python3 -c "import rich" >/dev/null 2>&1; then
  echo "Installing rich module..."
  pip3 install rich
fi

CONFIG_PATH="$HOME/.config/openai"
API_KEY_FILE="$CONFIG_PATH/api_key"

if [ -z "$OPENAI_API_KEY" ]; then
  if [ -f "$API_KEY_FILE" ]; then
    export OPENAI_API_KEY=$(cat "$API_KEY_FILE")
    echo "Loaded OPENAI_API_KEY from $API_KEY_FILE"
  else
    echo "OPENAI_API_KEY not found."
    read -rp "Enter your OpenAI API key: " key
    mkdir -p "$CONFIG_PATH"
    echo "$key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    export OPENAI_API_KEY="$key"
    echo "API key saved to $API_KEY_FILE with restricted permissions."
  fi
fi

python3 selinux_chatgpt_stream.py
