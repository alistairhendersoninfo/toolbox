#!/bin/bash
#MN Check Script Dependencies
#MD Check and report missing dependencies for toolbox scripts
#MDD Scans all toolbox scripts and checks if their MI (Menu Integration) dependencies are available. Provides installation suggestions for missing dependencies.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON 🔍
#MCOLOR Z4
#MORDER 3

set -e

TOOLBOX_DIR="${1:-/opt/toolbox}"
MISSING_DEPS=()
AVAILABLE_DEPS=()

echo "🔍 Checking Script Dependencies"
echo "==============================="
echo "📁 Scanning: $TOOLBOX_DIR"
echo ""

# Function to check if command/package exists
check_dependency() {
    local dep="$1"
    
    # Skip certain categories that don't represent commands
    case "$dep" in
        "ToolboxCore"|"SystemUtilities"|"LinuxTools"|"NetworkUtils"|"BackupUtilities"|"Examples")
            return 0
            ;;
    esac
    
    # Check if it's a file path
    if [[ "$dep" == /* ]]; then
        if [ -e "$dep" ]; then
            return 0
        else
            return 1
        fi
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

# Function to suggest installation command
suggest_installation() {
    local dep="$1"
    
    if [ -f /etc/debian_version ]; then
        echo "   sudo apt install -y $dep"
    elif [ -f /etc/redhat-release ]; then
        if command -v dnf >/dev/null 2>&1; then
            echo "   sudo dnf install -y $dep"
        else
            echo "   sudo yum install -y $dep"
        fi
    else
        echo "   # Install $dep using your package manager"
    fi
}

# Scan all scripts
echo "📊 Dependency Analysis:"
echo "----------------------"

total_scripts=0
scripts_with_deps=0

while IFS= read -r -d '' script_file; do
    total_scripts=$((total_scripts + 1))
    
    # Extract MI (Menu Integration) field
    mi_dep=$(grep '^#MI ' "$script_file" 2>/dev/null | head -n1 | cut -d' ' -f2- || echo "")
    
    if [ -n "$mi_dep" ]; then
        scripts_with_deps=$((scripts_with_deps + 1))
        script_name=$(basename "$script_file" .sh)
        
        if check_dependency "$mi_dep"; then
            echo "✅ $script_name: $mi_dep"
            AVAILABLE_DEPS+=("$mi_dep")
        else
            echo "❌ $script_name: $mi_dep (MISSING)"
            MISSING_DEPS+=("$mi_dep")
        fi
    fi
done < <(find "$TOOLBOX_DIR" -name "*.sh" -type f -print0)

echo ""
echo "📈 Summary:"
echo "----------"
echo "📝 Total scripts: $total_scripts"
echo "🔗 Scripts with dependencies: $scripts_with_deps"
echo "✅ Available dependencies: ${#AVAILABLE_DEPS[@]}"
echo "❌ Missing dependencies: ${#MISSING_DEPS[@]}"

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo "🚨 Missing Dependencies:"
    echo "----------------------"
    
    # Remove duplicates and sort
    IFS=$'\n' sorted_missing=($(printf '%s\n' "${MISSING_DEPS[@]}" | sort -u))
    
    for dep in "${sorted_missing[@]}"; do
        echo "❌ $dep"
        suggest_installation "$dep"
        echo ""
    done
    
    echo "🔧 Quick Fix Commands:"
    echo "--------------------"
    
    if [ -f /etc/debian_version ]; then
        echo "# Ubuntu/Debian:"
        echo "sudo apt update"
        echo -n "sudo apt install -y"
        for dep in "${sorted_missing[@]}"; do
            echo -n " $dep"
        done
        echo ""
    elif [ -f /etc/redhat-release ]; then
        if command -v dnf >/dev/null 2>&1; then
            echo "# Fedora/RHEL 8+:"
            echo -n "sudo dnf install -y"
        else
            echo "# CentOS/RHEL 7:"
            echo -n "sudo yum install -y"
        fi
        for dep in "${sorted_missing[@]}"; do
            echo -n " $dep"
        done
        echo ""
    fi
    
    echo ""
    echo "💡 After installing dependencies, run:"
    echo "   toolbox --scan"
    echo "   to refresh the database with updated dependency status."
    
    exit 1
else
    echo ""
    echo "🎉 All dependencies are satisfied!"
    echo ""
    echo "✨ Your toolbox is ready to use. Run 'toolbox' to start."
    exit 0
fi