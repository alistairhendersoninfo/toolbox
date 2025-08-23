#!/bin/bash
#MN Install Script Dependencies
#MD Automatically install missing dependencies for toolbox scripts
#MDD Analyzes all toolbox scripts, identifies missing MI dependencies, and attempts to install them automatically using the system package manager.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON 📦
#MCOLOR Z3
#MORDER 4

set -e

TOOLBOX_DIR="${1:-/opt/toolbox}"
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS] [TOOLBOX_DIR]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be installed without installing"
            echo "  --force      Install without confirmation prompts"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Install missing deps for /opt/toolbox"
            echo "  $0 --dry-run                # Show what would be installed"
            echo "  $0 --force /custom/path     # Force install for custom path"
            exit 0
            ;;
        *)
            TOOLBOX_DIR="$1"
            shift
            ;;
    esac
done

echo "📦 Toolbox Dependency Installer"
echo "==============================="
echo "📁 Toolbox Directory: $TOOLBOX_DIR"
echo "🔍 Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "INSTALL")"
echo ""

if [ ! -d "$TOOLBOX_DIR" ]; then
    echo "❌ Error: Toolbox directory not found: $TOOLBOX_DIR"
    exit 1
fi

# Detect package manager
PACKAGE_MANAGER=""
INSTALL_CMD=""

if command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
elif command -v yum >/dev/null 2>&1; then
    PACKAGE_MANAGER="yum"
    INSTALL_CMD="sudo yum install -y"
else
    echo "❌ Error: No supported package manager found (apt, dnf, yum)"
    exit 1
fi

echo "📋 Detected package manager: $PACKAGE_MANAGER"
echo ""

# Function to check if dependency exists
check_dependency() {
    local dep="$1"
    
    # Skip certain categories
    case "$dep" in
        "ToolboxCore"|"SystemUtilities"|"LinuxTools"|"NetworkUtils"|"BackupUtilities"|"Examples")
            return 0
            ;;
    esac
    
    # Check if it's a file path
    if [[ "$dep" == /* ]]; then
        [ -e "$dep" ]
        return $?
    fi
    
    # Check if it's a command
    if command -v "$dep" >/dev/null 2>&1; then
        return 0
    fi
    
    # Check package managers
    if dpkg -l "$dep" >/dev/null 2>&1 || rpm -q "$dep" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Collect missing dependencies
MISSING_DEPS=()
SCRIPT_COUNT=0

echo "🔍 Scanning for missing dependencies..."

while IFS= read -r -d '' script_file; do
    SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    
    # Extract MI field
    mi_dep=$(grep '^#MI ' "$script_file" 2>/dev/null | head -n1 | cut -d' ' -f2- || echo "")
    
    if [ -n "$mi_dep" ] && ! check_dependency "$mi_dep"; then
        MISSING_DEPS+=("$mi_dep")
    fi
done < <(find "$TOOLBOX_DIR" -name "*.sh" -type f -print0)

# Remove duplicates
IFS=$'\n' UNIQUE_MISSING=($(printf '%s\n' "${MISSING_DEPS[@]}" | sort -u))

echo "📊 Scan Results:"
echo "  📝 Scripts scanned: $SCRIPT_COUNT"
echo "  ❌ Missing dependencies: ${#UNIQUE_MISSING[@]}"
echo ""

if [ ${#UNIQUE_MISSING[@]} -eq 0 ]; then
    echo "🎉 All dependencies are already satisfied!"
    exit 0
fi

echo "📦 Missing Dependencies:"
for dep in "${UNIQUE_MISSING[@]}"; do
    echo "  ❌ $dep"
done
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN - Would execute:"
    echo "  $INSTALL_CMD ${UNIQUE_MISSING[*]}"
    echo ""
    echo "💡 To actually install, run without --dry-run"
    exit 0
fi

# Confirmation prompt
if [ "$FORCE" != true ]; then
    echo "🤔 Do you want to install these dependencies? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled."
        exit 1
    fi
    echo ""
fi

# Update package lists
echo "🔄 Updating package lists..."
case "$PACKAGE_MANAGER" in
    "apt")
        sudo apt-get update
        ;;
    "dnf"|"yum")
        # Package lists are updated automatically
        echo "✅ Package lists ready"
        ;;
esac

echo ""

# Install dependencies
echo "📦 Installing dependencies..."
echo "Command: $INSTALL_CMD ${UNIQUE_MISSING[*]}"
echo ""

FAILED_INSTALLS=()
SUCCESSFUL_INSTALLS=()

for dep in "${UNIQUE_MISSING[@]}"; do
    echo "📦 Installing $dep..."
    
    if eval "$INSTALL_CMD $dep"; then
        echo "✅ $dep installed successfully"
        SUCCESSFUL_INSTALLS+=("$dep")
    else
        echo "❌ Failed to install $dep"
        FAILED_INSTALLS+=("$dep")
    fi
    echo ""
done

# Summary
echo "📊 Installation Summary:"
echo "======================="
echo "✅ Successfully installed: ${#SUCCESSFUL_INSTALLS[@]}"
for dep in "${SUCCESSFUL_INSTALLS[@]}"; do
    echo "  ✅ $dep"
done

if [ ${#FAILED_INSTALLS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed to install: ${#FAILED_INSTALLS[@]}"
    for dep in "${FAILED_INSTALLS[@]}"; do
        echo "  ❌ $dep"
    done
    echo ""
    echo "💡 You may need to:"
    echo "  • Check if the package name is correct"
    echo "  • Enable additional repositories"
    echo "  • Install manually from source"
fi

echo ""
echo "🔄 Refreshing toolbox database..."
if command -v toolbox >/dev/null 2>&1; then
    toolbox --scan --path "$TOOLBOX_DIR"
    echo "✅ Database refreshed"
else
    echo "⚠️  Toolbox command not found, database not refreshed"
    echo "   Run 'toolbox --scan' manually after installation"
fi

echo ""
if [ ${#FAILED_INSTALLS[@]} -eq 0 ]; then
    echo "🎉 All dependencies installed successfully!"
    echo "🚀 Your toolbox is ready to use. Run 'toolbox' to start."
    exit 0
else
    echo "⚠️  Installation completed with some failures."
    echo "   Check the failed packages above and install them manually if needed."
    exit 1
fi