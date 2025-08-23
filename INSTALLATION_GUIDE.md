# 🛡️ Toolbox Menu System - Complete Installation Guide

## 📋 Prerequisites

### System Requirements
- **OS**: Linux/Unix (Ubuntu 20.04+, CentOS 8+, or similar)
- **Architecture**: x86_64 (AMD64)
- **Memory**: 512MB RAM minimum
- **Disk**: 100MB free space

### Required Software

#### 1. **Rust Toolchain** (Required for building)
```bash
# Install Rust using rustup (recommended method)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell environment
source ~/.cargo/env

# Verify installation
rustc --version
cargo --version
```

#### 2. **Git** (Required for cloning)
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y git

# CentOS/RHEL/Fedora
sudo yum install -y git
# OR for newer versions
sudo dnf install -y git

# Verify installation
git --version
```

#### 3. **Build Dependencies** (Required for compilation)
```bash
# Ubuntu/Debian
sudo apt install -y build-essential pkg-config libsqlite3-dev

# CentOS/RHEL
sudo yum groupinstall -y "Development Tools"
sudo yum install -y pkgconfig sqlite-devel

# Fedora
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y pkgconfig sqlite-devel
```

#### 4. **Optional Dependencies** (For enhanced features)
```bash
# For progress bars and enhanced terminal support
sudo apt install -y dialog ncurses-dev

# For mail notifications (if using parameterized scripts)
sudo apt install -y mailutils
```

## 🚀 Installation Process

### Step 1: Clone Repository
```bash
# Create the installation directory
sudo mkdir -p /opt/toolbox-menu
sudo chown $USER:$USER /opt/toolbox-menu

# Clone the repository
cd /opt
git clone <repository-url> toolbox-menu
cd toolbox-menu
```

### Step 2: Verify Prerequisites
```bash
# Run the prerequisite checker
./scripts/check_prerequisites.sh
```

### Step 3: Build and Install
```bash
# Option A: Automated installation (recommended)
./scripts/install_complete.sh

# Option B: Manual installation
chmod +x build.sh
./build.sh --install
```

### Step 4: Setup Toolbox Scripts Directory
```bash
# Create the toolbox scripts directory
sudo mkdir -p /opt/toolbox
sudo chown $USER:$USER /opt/toolbox

# Copy example scripts (optional)
cp -r examples/* /opt/toolbox/

# Set permissions
find /opt/toolbox -name "*.sh" -exec chmod +x {} \;
```

### Step 5: Initial Scan
```bash
# Scan the toolbox directory
toolbox --scan --path /opt/toolbox

# Verify installation
toolbox --version
```

## 📁 Directory Structure

After installation, your system will have:

```
/opt/
├── toolbox-menu/              # Application source code
│   ├── src/                   # Rust source files
│   ├── target/release/        # Compiled binary
│   ├── scripts/               # Installation scripts
│   ├── examples/              # Example scripts
│   └── build.sh               # Build script
│
├── toolbox/                   # Your toolbox scripts
│   ├── LinuxTools/            # Linux utilities
│   ├── SystemSecurity/        # Security tools
│   ├── NetworkUtils/          # Network utilities
│   └── ...                    # Your custom categories
│
/usr/local/bin/
└── toolbox                    # Symlinked executable

/home/$USER/.config/toolbox/
├── menu.db                    # SQLite database
├── preferences.json           # User preferences
└── logs/                      # Application logs
```

## 🗄️ Database Setup

### Automatic Setup
The database is automatically created at:
```
~/.config/toolbox/menu.db
```

### Manual Database Setup (if needed)
```bash
# Create config directory
mkdir -p ~/.config/toolbox

# Initialize database (done automatically on first run)
toolbox --scan
```

### Database Location Options
```bash
# Use custom database location
toolbox --database /custom/path/menu.db

# Use system-wide database (requires sudo)
sudo mkdir -p /var/lib/toolbox
sudo chown $USER:$USER /var/lib/toolbox
toolbox --database /var/lib/toolbox/menu.db
```

## ⚙️ Configuration

### Environment Variables
```bash
# Add to ~/.bashrc or ~/.zshrc
export TOOLBOX_DIR="/opt/toolbox"
export TOOLBOX_DB="~/.config/toolbox/menu.db"
export TOOLBOX_LOG_LEVEL="info"
```

### System Service (Optional)
For automatic scanning on system startup:

```bash
# Create systemd service
sudo tee /etc/systemd/system/toolbox-scan.service << EOF
[Unit]
Description=Toolbox Menu Scanner
After=multi-user.target

[Service]
Type=oneshot
User=$USER
ExecStart=/usr/local/bin/toolbox --scan
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable toolbox-scan.service
sudo systemctl start toolbox-scan.service
```

## 🔧 Verification

### Test Installation
```bash
# Check binary
which toolbox
toolbox --version

# Check database
ls -la ~/.config/toolbox/

# Test menu (may not work in non-interactive shells)
toolbox --help
```

### Troubleshooting

#### Common Issues

1. **Rust not found**
   ```bash
   # Ensure Rust is in PATH
   source ~/.cargo/env
   echo $PATH | grep cargo
   ```

2. **Permission denied**
   ```bash
   # Fix permissions
   sudo chown -R $USER:$USER /opt/toolbox-menu
   chmod +x /opt/toolbox-menu/build.sh
   ```

3. **Database errors**
   ```bash
   # Reset database
   rm ~/.config/toolbox/menu.db
   toolbox --scan
   ```

4. **Missing dependencies**
   ```bash
   # Install missing packages
   sudo apt install -y build-essential pkg-config libsqlite3-dev
   ```

## 🔄 Updates

### Update Application
```bash
cd /opt/toolbox-menu
git pull
./build.sh --install
```

### Update Scripts Database
```bash
toolbox --scan
```

### Automated Updates (Optional)
```bash
# Add to crontab for weekly updates
crontab -e

# Add this line for weekly updates at 3 AM Sunday
0 3 * * 0 cd /opt/toolbox-menu && git pull && ./build.sh --install && toolbox --scan
```

## 🗑️ Uninstallation

### Remove Application
```bash
# Remove binary
sudo rm /usr/local/bin/toolbox

# Remove source code
sudo rm -rf /opt/toolbox-menu

# Remove database and config (optional)
rm -rf ~/.config/toolbox

# Remove scripts (optional - be careful!)
# sudo rm -rf /opt/toolbox
```

### Remove System Service (if installed)
```bash
sudo systemctl stop toolbox-scan.service
sudo systemctl disable toolbox-scan.service
sudo rm /etc/systemd/system/toolbox-scan.service
sudo systemctl daemon-reload
```

## 📞 Support

### Log Files
```bash
# View logs
journalctl -u toolbox-scan.service
tail -f ~/.config/toolbox/logs/toolbox.log
```

### Debug Mode
```bash
# Run with debug output
toolbox --debug

# Verbose scanning
toolbox --scan --debug
```

### Getting Help
- Check the documentation: `TOOLBOX_SYSTEM_DOCUMENTATION.md`
- Run: `toolbox --help`
- View examples: `examples/` directory

---

**🎉 You're ready to use the Toolbox Menu System!**

Run `toolbox` to start your Swiss Army knife of system administration tools.