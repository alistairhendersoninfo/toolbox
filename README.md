# 🛡️ Advanced Toolbox Menu System

A modern, Rust-based CLI menu system for organizing and executing system administration scripts with an intuitive, searchable interface.

## ✨ Features

- 🗂️ **Hierarchical Menu System** - Folder-based organization with numbered selection
- 🔍 **Advanced Search** - Real-time fuzzy matching with typeahead
- 🎨 **Rich UI/UX** - Dialog/TailwindCSS-inspired styling with colors and icons
- 🏷️ **Comprehensive Metadata** - Rich script tagging and categorization
- 🗄️ **Database-Backed** - Fast SQLite-based indexing and retrieval
- ⚙️ **JSON Parameter System** - Interactive parameter collection with validation
- 🚀 **Enhanced Execution** - Progress bars, output capture, and history tracking
- ⌨️ **Keyboard Shortcuts** - Efficient navigation and control

## 🚀 Quick Start

### Prerequisites
- Rust 1.70+ (for building)
- Linux/Unix system with bash
- SQLite3 (bundled)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd toolbox-menu

# Build and install
chmod +x build.sh
./build.sh --install

# First run - scan your toolbox directory
toolbox --scan --path /opt/toolbox

# Start the menu system
toolbox
```

## ⌨️ Navigation

| Key | Action |
|-----|--------|
| `↑↓` or `j/k` | Move selection |
| `Enter` | Execute/Select |
| `1-9, 0` | Quick select by number |
| `X` | Go back |
| `H` | Go home |
| `S` | Search mode |
| `Q` | Quit |
| `F1` or `?` | Help |

## 📝 Script Format

```bash
#!/usr/bin/env bash
#MN Script Name
#MD Brief description
#MDD Detailed description
#MI Category
#INFO https://docs-url.com
#MICON 🛠️
#MCOLOR Z2
#MORDER 100
#MTAGS tag1,tag2,tag3

# Your script here
echo "Hello from toolbox!"
```

## 🎨 Color Coding

- 🔴 **Red (Z1)** - Dangerous operations
- 🟡 **Yellow (Z3)** - Caution required  
- 🟢 **Green (Z2)** - Safe operations
- 🔵 **Blue (Z4)** - Information/utilities

## 📚 Documentation

See [TOOLBOX_SYSTEM_DOCUMENTATION.md](TOOLBOX_SYSTEM_DOCUMENTATION.md) for comprehensive documentation.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `cargo test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for system administrators who deserve better tools.**