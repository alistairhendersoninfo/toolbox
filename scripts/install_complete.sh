#!/bin/bash
#MN Complete Installation
#MD Complete automated installation of toolbox menu system
#MDD Fully automated installation script that checks prerequisites, builds the application, installs it system-wide, creates necessary directories, and performs initial setup.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON 🚀
#MCOLOR Z2
#MORDER 2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Toolbox Menu System - Complete Installation"
echo "=============================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/Cargo.toml" ]; then
    echo "❌ Error: Not in project root directory"
    echo "   Please run this script from the toolbox-menu directory"
    exit 1
fi

cd "$PROJECT_ROOT"

# Step 1: Check prerequisites
echo "📋 Step 1/6: Checking Prerequisites"
echo "-----------------------------------"
if ! "$SCRIPT_DIR/check_prerequisites.sh"; then
    echo ""
    echo "❌ Prerequisites check failed. Please install missing dependencies first."
    exit 1
fi

echo ""
echo "✅ Prerequisites satisfied!"
echo ""

# Step 2: Build application
echo "🔨 Step 2/6: Building Application"
echo "---------------------------------"
if [ -f "./build.sh" ]; then
    chmod +x ./build.sh
    ./build.sh --install --no-scan
else
    echo "❌ build.sh not found"
    exit 1
fi

echo ""
echo "✅ Application built and installed!"
echo ""

# Step 3: Create directory structure
echo "📁 Step 3/6: Creating Directory Structure"
echo "----------------------------------------"

# Create toolbox scripts directory
if [ ! -d "/opt/toolbox" ]; then
    echo "📂 Creating /opt/toolbox directory..."
    if [ -w "/opt" ]; then
        mkdir -p /opt/toolbox
    else
        sudo mkdir -p /opt/toolbox
        sudo chown $USER:$USER /opt/toolbox
    fi
    echo "✅ Created /opt/toolbox"
else
    echo "✅ /opt/toolbox already exists"
fi

# Create config directory
echo "📂 Creating config directory..."
mkdir -p ~/.config/toolbox
mkdir -p ~/.config/toolbox/logs
echo "✅ Created ~/.config/toolbox"

# Set permissions
echo "🔐 Setting permissions..."
find /opt/toolbox -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "✅ Permissions set"

echo ""

# Step 4: Copy example scripts
echo "📝 Step 4/6: Installing Example Scripts"
echo "--------------------------------------"
if [ -d "./examples" ]; then
    echo "📋 Copying example scripts to /opt/toolbox..."
    cp -r ./examples/* /opt/toolbox/ 2>/dev/null || true
    
    # Make scripts executable
    find /opt/toolbox -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    echo "✅ Example scripts installed"
else
    echo "⚠️  No examples directory found, skipping example scripts"
fi

echo ""

# Step 5: Create symlinks and shortcuts
echo "🔗 Step 5/6: Creating System Integration"
echo "---------------------------------------"

# Verify binary is installed
if [ -f "/usr/local/bin/toolbox" ]; then
    echo "✅ Binary installed at /usr/local/bin/toolbox"
else
    echo "❌ Binary not found at /usr/local/bin/toolbox"
    exit 1
fi

# Add to PATH if needed
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    echo "⚠️  /usr/local/bin not in PATH, adding to ~/.bashrc"
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    echo "✅ Added to PATH (restart shell or run: source ~/.bashrc)"
fi

# Create desktop entry (optional)
if [ -d "$HOME/.local/share/applications" ]; then
    cat > "$HOME/.local/share/applications/toolbox.desktop" << EOF
[Desktop Entry]
Name=Toolbox Menu
Comment=System Administration Toolbox
Exec=gnome-terminal -- toolbox
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;Administration;
EOF
    echo "✅ Desktop entry created"
fi

echo ""

# Step 6: Initial scan and verification
echo "🔍 Step 6/6: Initial Scan and Verification"
echo "-----------------------------------------"

echo "📊 Scanning toolbox directory..."
if toolbox --scan --path /opt/toolbox; then
    echo "✅ Initial scan completed successfully"
else
    echo "⚠️  Initial scan had issues, but installation completed"
fi

echo ""
echo "🔍 Verifying installation..."

# Check binary
if command -v toolbox >/dev/null 2>&1; then
    VERSION=$(toolbox --version 2>/dev/null || echo "version unknown")
    echo "✅ Binary: $VERSION"
else
    echo "❌ Binary not accessible"
    exit 1
fi

# Check database
if [ -f "$HOME/.config/toolbox/menu.db" ]; then
    DB_SIZE=$(du -h "$HOME/.config/toolbox/menu.db" | cut -f1)
    echo "✅ Database: $DB_SIZE"
else
    echo "⚠️  Database not created yet"
fi

# Check scripts
SCRIPT_COUNT=$(find /opt/toolbox -name "*.sh" -type f | wc -l)
echo "✅ Scripts found: $SCRIPT_COUNT"

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "📍 Installation Summary:"
echo "  • Binary: /usr/local/bin/toolbox"
echo "  • Scripts: /opt/toolbox"
echo "  • Database: ~/.config/toolbox/menu.db"
echo "  • Config: ~/.config/toolbox/"
echo ""
echo "🚀 Quick Start:"
echo "  toolbox              # Start the menu system"
echo "  toolbox --scan       # Rescan for new scripts"
echo "  toolbox --help       # Show all options"
echo ""
echo "📚 Documentation:"
echo "  • Installation Guide: INSTALLATION_GUIDE.md"
echo "  • Full Documentation: TOOLBOX_SYSTEM_DOCUMENTATION.md"
echo "  • Examples: /opt/toolbox/examples/"
echo ""
echo "⚡ Pro Tips:"
echo "  • Press 'S' in the menu to search scripts"
echo "  • Use number keys (1-9) for quick selection"
echo "  • Press 'H' to return to home menu"
echo "  • Press '?' for help in the menu"
echo ""

# Final test
echo "🧪 Testing installation..."
if timeout 5 toolbox --version >/dev/null 2>&1; then
    echo "✅ Installation test passed!"
    echo ""
    echo "🎯 Ready to use! Run 'toolbox' to start."
else
    echo "⚠️  Installation test had issues, but basic installation completed."
    echo "   Try running 'toolbox --help' to verify functionality."
fi

echo ""
echo "🙏 Thank you for using Toolbox Menu System!"