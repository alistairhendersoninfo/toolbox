#!/bin/bash
#MN Check Prerequisites
#MD Verify all required dependencies for building toolbox menu
#MDD Comprehensive prerequisite checker that verifies Rust, Git, build tools, and system dependencies required for compiling and running the toolbox menu system.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON ✅
#MCOLOR Z4
#MORDER 1

set -e

echo "🔍 Checking Prerequisites for Toolbox Menu System"
echo "=================================================="

ERRORS=0
WARNINGS=0

# Function to check if command exists
check_command() {
    local cmd="$1"
    local desc="$2"
    local required="$3"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version=$($cmd --version 2>/dev/null | head -n1 || echo "version unknown")
        echo "✅ $desc: $version"
    else
        if [ "$required" = "true" ]; then
            echo "❌ $desc: NOT FOUND (REQUIRED)"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠️  $desc: NOT FOUND (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Function to check file/directory
check_path() {
    local path="$1"
    local desc="$2"
    local required="$3"
    
    if [ -e "$path" ]; then
        echo "✅ $desc: $path"
    else
        if [ "$required" = "true" ]; then
            echo "❌ $desc: NOT FOUND (REQUIRED)"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠️  $desc: NOT FOUND (will be created)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Function to check package
check_package() {
    local package="$1"
    local desc="$2"
    local required="$3"
    
    if dpkg -l "$package" >/dev/null 2>&1 || rpm -q "$package" >/dev/null 2>&1; then
        echo "✅ $desc: installed"
    else
        if [ "$required" = "true" ]; then
            echo "❌ $desc: NOT INSTALLED (REQUIRED)"
            ERRORS=$((ERRORS + 1))
        else
            echo "⚠️  $desc: NOT INSTALLED (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

echo ""
echo "🦀 Rust Toolchain"
echo "------------------"
check_command "rustc" "Rust Compiler" "true"
check_command "cargo" "Cargo Package Manager" "true"

if command -v rustc >/dev/null 2>&1; then
    RUST_VERSION=$(rustc --version | awk '{print $2}')
    if [ "$(printf '%s\n' "1.70.0" "$RUST_VERSION" | sort -V | head -n1)" = "1.70.0" ]; then
        echo "✅ Rust version $RUST_VERSION is compatible"
    else
        echo "⚠️  Rust version $RUST_VERSION may be too old (recommended: 1.70+)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo "🔧 Build Tools"
echo "--------------"
check_command "git" "Git Version Control" "true"
check_command "gcc" "GCC Compiler" "true"
check_command "make" "GNU Make" "true"
check_command "pkg-config" "Package Config" "true"

echo ""
echo "📚 System Libraries"
echo "------------------"
if [ -f /etc/debian_version ]; then
    check_package "build-essential" "Build Essential" "true"
    check_package "libsqlite3-dev" "SQLite Development Headers" "true"
    check_package "pkg-config" "Package Config" "true"
elif [ -f /etc/redhat-release ]; then
    check_package "gcc" "GCC Compiler" "true"
    check_package "sqlite-devel" "SQLite Development Headers" "true"
    check_package "pkgconfig" "Package Config" "true"
fi

echo ""
echo "📁 Directory Structure"
echo "--------------------"
check_path "/opt" "Base directory (/opt)" "true"
check_path "/opt/toolbox" "Toolbox scripts directory" "false"
check_path "/usr/local/bin" "System binary directory" "true"
check_path "$HOME/.config" "User config directory" "false"

echo ""
echo "🔧 Optional Tools"
echo "----------------"
check_command "dialog" "Dialog (for enhanced UI)" "false"
check_command "sqlite3" "SQLite CLI" "false"
check_command "mail" "Mail command (for notifications)" "false"

echo ""
echo "🖥️  System Information"
echo "--------------------"
echo "📋 OS: $(uname -s) $(uname -r)"
echo "🏗️  Architecture: $(uname -m)"
echo "💾 Available Memory: $(free -h | grep '^Mem:' | awk '{print $7}' 2>/dev/null || echo 'unknown')"
echo "💿 Available Disk: $(df -h /opt 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"

# Check permissions
echo ""
echo "🔐 Permissions"
echo "-------------"
if [ -w "/opt" ]; then
    echo "✅ Write access to /opt: yes"
else
    echo "⚠️  Write access to /opt: no (will need sudo)"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -w "/usr/local/bin" ]; then
    echo "✅ Write access to /usr/local/bin: yes"
else
    echo "⚠️  Write access to /usr/local/bin: no (will need sudo)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "📊 Summary"
echo "=========="
if [ $ERRORS -eq 0 ]; then
    echo "✅ All required dependencies are satisfied!"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  $WARNINGS optional dependencies missing (installation will still work)"
    fi
    echo ""
    echo "🚀 Ready to build! Run: ./scripts/install_complete.sh"
    exit 0
else
    echo "❌ $ERRORS required dependencies missing"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  $WARNINGS optional dependencies missing"
    fi
    echo ""
    echo "🔧 To fix missing dependencies:"
    echo ""
    
    if [ -f /etc/debian_version ]; then
        echo "   # Ubuntu/Debian:"
        echo "   sudo apt update"
        echo "   sudo apt install -y build-essential git pkg-config libsqlite3-dev"
        echo ""
        echo "   # Install Rust:"
        echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        echo "   source ~/.cargo/env"
    elif [ -f /etc/redhat-release ]; then
        echo "   # CentOS/RHEL/Fedora:"
        echo "   sudo yum groupinstall -y 'Development Tools'"
        echo "   sudo yum install -y git pkgconfig sqlite-devel"
        echo "   # OR for newer versions:"
        echo "   sudo dnf groupinstall -y 'Development Tools'"
        echo "   sudo dnf install -y git pkgconfig sqlite-devel"
        echo ""
        echo "   # Install Rust:"
        echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        echo "   source ~/.cargo/env"
    fi
    
    echo ""
    echo "Then run this script again to verify."
    exit 1
fi