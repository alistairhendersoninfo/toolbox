#!/usr/bin/env bash
#MN generic_functions
#MD Generic utility functions for Toolbox scripts
#MDD Provides EFFECTIVE_USER resolution, HOME detection, TOOLBOX_DIR detection, and common path utilities.
#MI ToolboxCore
#INFO https://your-toolbox-project-url/

# Resolve TOOLBOX_DIR if not already set
if [ -z "$TOOLBOX_DIR" ]; then
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  TOOLBOX_DIR="$(dirname "$SCRIPT_DIR")"
  export TOOLBOX_DIR
fi

# Resolve EFFECTIVE_USER
resolve_effective_user() {
  if [ -z "$EFFECTIVE_USER" ]; then
    if [ -n "$SUDO_USER" ]; then
      EFFECTIVE_USER="$SUDO_USER"
    else
      EFFECTIVE_USER="$USER"
    fi
  fi
  export EFFECTIVE_USER
}

# Resolve USER_HOME
resolve_user_home() {
  resolve_effective_user
  USER_HOME=$(eval echo "~$EFFECTIVE_USER")
  export USER_HOME
}
