#!/bin/bash
#MN Build Toolbox Menu
#MD Build and install the Rust-based toolbox menu system
#MDD Compiles the Rust application, installs it to the system, and sets up the initial database. Includes options for development and production builds.
#MI ToolboxCore
#INFO https://doc.rust-lang.org/cargo/
#MICON 🔨
#MCOLOR Z2
#MORDER 1
#MDEFAULT false
#MSEPARATOR Build & Install
#MTAGS build,install,rust,compile
#MAUTHOR Toolbox Team

set -e

echo "🔨 Building Toolbox Menu System"
echo "================================"

# Check if Rust is installed
if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Rust/Cargo not found. Please install Rust first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo "❌ Cargo.toml not found. Please run this script from the project root."
    exit 1
fi

# Parse command line arguments
BUILD_TYPE="release"
INSTALL_SYSTEM=false
SCAN_AFTER_INSTALL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --install)
            INSTALL_SYSTEM=true
            shift
            ;;
        --no-scan)
            SCAN_AFTER_INSTALL=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug     Build in debug mode (faster compile, slower runtime)"
            echo "  --install   Install to system (/usr/local/bin/toolbox)"
            echo "  --no-scan   Skip initial database scan after install"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "📋 Build Configuration:"
echo "  Build Type: $BUILD_TYPE"
echo "  Install to System: $INSTALL_SYSTEM"
echo "  Scan After Install: $SCAN_AFTER_INSTALL"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cargo clean

# Build the application
echo "🔧 Building application..."
if [ "$BUILD_TYPE" = "release" ]; then
    cargo build --release
    BINARY_PATH="target/release/toolbox"
else
    cargo build
    BINARY_PATH="target/debug/toolbox"
fi

# Check if build was successful
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Build failed - binary not found at $BINARY_PATH"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 Binary location: $BINARY_PATH"

# Get binary size and info
BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
echo "📊 Binary size: $BINARY_SIZE"

# Install to system if requested
if [ "$INSTALL_SYSTEM" = true ]; then
    echo ""
    echo "📦 Installing to system..."
    
    # Check if we need sudo
    if [ ! -w "/usr/local/bin" ]; then
        echo "🔐 Requesting sudo privileges for system installation..."
        sudo cp "$BINARY_PATH" /usr/local/bin/toolbox
        sudo chmod +x /usr/local/bin/toolbox
    else
        cp "$BINARY_PATH" /usr/local/bin/toolbox
        chmod +x /usr/local/bin/toolbox
    fi
    
    echo "✅ Installed to /usr/local/bin/toolbox"
    
    # Verify installation
    if command -v toolbox >/dev/null 2>&1; then
        INSTALLED_VERSION=$(toolbox --version 2>/dev/null || echo "version check failed")
        echo "🔍 Verification: $INSTALLED_VERSION"
    else
        echo "⚠️  Warning: toolbox command not found in PATH after installation"
        echo "   You may need to add /usr/local/bin to your PATH"
    fi
    
    # Create config directory
    echo "📁 Creating configuration directory..."
    mkdir -p ~/.config/toolbox
    
    # Initial scan if requested
    if [ "$SCAN_AFTER_INSTALL" = true ]; then
        echo ""
        echo "🔍 Performing initial scan..."
        
        if [ -d "/opt/toolbox" ]; then
            toolbox --scan
            echo "✅ Initial scan completed"
        else
            echo "⚠️  /opt/toolbox directory not found"
            echo "   You can scan a different directory with: toolbox --scan --path /your/path"
        fi
    fi
    
    echo ""
    echo "🎉 Installation completed successfully!"
    echo ""
    echo "Quick Start:"
    echo "  toolbox --scan    # Scan and build database"
    echo "  toolbox           # Start the menu system"
    echo "  toolbox --help    # Show all options"
    
else
    echo ""
    echo "🎯 Build completed! To install system-wide, run:"
    echo "   $0 --install"
    echo ""
    echo "Or run directly:"
    echo "   ./$BINARY_PATH --scan --path /opt/toolbox"
    echo "   ./$BINARY_PATH"
fi

echo ""
echo "📚 Documentation:"
echo "  README: ./TOOLBOX_SYSTEM_DOCUMENTATION.md"
echo "  Examples: ./examples/"
echo ""
echo "🚀 Happy toolboxing!"