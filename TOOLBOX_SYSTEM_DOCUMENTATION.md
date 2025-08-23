# 🛡️ Advanced Toolbox Menu System

## Overview

This is a comprehensive Rust-based CLI menu system designed to create an interactive, searchable, and highly organized interface for managing system administration scripts, tools, and utilities. Think of it as a "Swiss Army knife" for sysadmins with a modern, intuitive interface.

## 🎯 Key Features

### 🗂️ Hierarchical Menu System
- **Folder-based organization**: Each directory becomes a submenu
- **Numbered selection**: Quick access via 1-9, 0 keys
- **Breadcrumb navigation**: Always know where you are
- **Smart categorization**: Scripts auto-categorized by directory structure

### 🔍 Advanced Search
- **Typeahead search**: Real-time fuzzy matching as you type
- **Multi-field search**: Searches names, descriptions, tags, categories
- **Relevance scoring**: Best matches appear first
- **Search shortcuts**: Press 's' from anywhere to search

### 🎨 Rich UI/UX
- **Dialog/TailwindCSS-inspired styling**: Modern, clean interface
- **Color-coded scripts**: Red for dangerous, yellow for caution, green for safe
- **Icons and emojis**: Visual indicators for different script types
- **Progress bars**: Real-time feedback for package installations
- **Responsive layout**: Adapts to terminal size

### 🏷️ Comprehensive Metadata System
Scripts support rich metadata tags:
- `#MN` - Menu Name (display name)
- `#MD` - Menu Description (short description)
- `#MDD` - Detailed Description (comprehensive info)
- `#MI` - Menu Integration (category/requirement)
- `#INFO` - Information URL (documentation link)
- `#MICON` - Menu Icon (emoji/symbol)
- `#MCOLOR` - Menu Color (Z1=red, Z2=green, Z3=yellow, Z4=blue)
- `#MORDER` - Menu Order (numeric sorting)
- `#MDEFAULT` - Default selection (true/false)
- `#MSEPARATOR` - Section separator label
- `#MTAGS` - Comma-separated tags for searching
- `#MAUTHOR` - Script author

### 🗄️ Database-Backed Performance
- **SQLite database**: Fast script indexing and retrieval
- **Two-phase scanning**: Scan once, query many times
- **Execution history**: Track script usage and performance
- **User preferences**: Persistent settings and favorites

### ⚙️ JSON Parameter System
Scripts can define interactive parameters:
```bash
#JSON_PARAMS_START
#{
#  "server_name": {
#    "type": "text",
#    "label": "Server Name",
#    "description": "Enter the target server hostname",
#    "required": true,
#    "pattern": "^[a-zA-Z0-9.-]+$",
#    "pattern_description": "be a valid hostname"
#  },
#  "port": {
#    "type": "number",
#    "label": "Port Number",
#    "default": "22",
#    "min": 1,
#    "max": 65535
#  },
#  "backup_type": {
#    "type": "select",
#    "label": "Backup Type",
#    "options": [
#      {"value": "full", "label": "Full Backup"},
#      {"value": "incremental", "label": "Incremental Backup"},
#      {"value": "differential", "label": "Differential Backup"}
#    ]
#  }
#}
#JSON_PARAMS_END
```

### 🚀 Enhanced Script Execution
- **Progress tracking**: Automatic detection of package managers (apt, yum, dnf)
- **Output enhancement**: Special handling for file viewing (cat, tail, less)
- **Interactive support**: Preserves script interactivity
- **Error handling**: Clear success/failure reporting
- **Execution history**: Database logging of all script runs

### ⌨️ Keyboard Shortcuts
- **Navigation**: ↑↓/jk (move), Enter (select), 1-9,0 (quick select)
- **Menu control**: X (back), H (home), S (search), Q (quit)
- **Search mode**: Type to search, X/Esc to exit
- **File viewing**: F (find in text), B/F (back/forward pages)
- **Help**: F1 or ? for help dialog

## 🏗️ Architecture

### Core Components

1. **Scanner (`src/scanner.rs`)**
   - Recursively scans `/opt/toolbox` directory
   - Extracts metadata from script headers
   - Parses JSON parameter definitions
   - Detects script features (package managers, file output, etc.)

2. **Database (`src/database.rs`)**
   - SQLite-based storage for scripts and metadata
   - Efficient querying and search capabilities
   - Execution history tracking
   - User preference storage

3. **Menu System (`src/menu.rs`)**
   - State management for navigation
   - Event handling for keyboard input
   - Menu item organization and display
   - Search mode coordination

4. **UI Layer (`src/ui.rs`)**
   - Ratatui-based terminal interface
   - Color-coded display with icons
   - Progress bars and dialogs
   - Responsive layout management

5. **Search Engine (`src/search.rs`)**
   - Fuzzy matching with relevance scoring
   - Multi-field search capabilities
   - Suggestion generation
   - Match highlighting

6. **Script Executor (`src/display.rs`)**
   - Enhanced script execution with progress tracking
   - File viewing with search capabilities
   - Interactive parameter collection
   - Output capture and display

### Data Flow

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   File System   │───▶│   Scanner    │───▶│  Database   │
│  /opt/toolbox   │    │              │    │   SQLite    │
└─────────────────┘    └──────────────┘    └─────────────┘
                                                    │
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   Terminal UI   │◀───│ Menu System  │◀───│ Search Eng. │
│   (Ratatui)     │    │              │    │             │
└─────────────────┘    └──────────────┘    └─────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────┐
│ Script Executor │    │  Parameter   │
│                 │    │  Collection  │
└─────────────────┘    └──────────────┘
```

## 📁 Project Structure

```
toolbox-menu/
├── Cargo.toml                 # Rust project configuration
├── src/
│   ├── main.rs               # Application entry point
│   ├── models.rs             # Data structures and types
│   ├── scanner.rs            # File system scanning
│   ├── database.rs           # SQLite operations
│   ├── menu.rs               # Menu system logic
│   ├── ui.rs                 # Terminal UI components
│   ├── search.rs             # Search and fuzzy matching
│   └── display.rs            # Script execution and display
├── examples/
│   ├── example_script.sh     # Example script with metadata
│   └── parameterized_script.sh # Example with JSON parameters
└── docs/
    └── TOOLBOX_SYSTEM_DOCUMENTATION.md
```

## 🚀 Installation & Usage

### Prerequisites
- Rust 1.70+ (for compilation)
- SQLite3 (bundled with rusqlite)
- Linux/Unix system with bash

### Building
```bash
# Clone the repository
git clone <repository-url>
cd toolbox-menu

# Build the application
cargo build --release

# Install to system
sudo cp target/release/toolbox /usr/local/bin/
```

### First Run
```bash
# Scan the toolbox directory and build database
toolbox --scan

# Start the menu system
toolbox
```

### Command Line Options
```bash
toolbox [OPTIONS]

OPTIONS:
    -s, --scan              Scan and rebuild the database
    -p, --path <PATH>       Toolbox directory path [default: /opt/toolbox]
    -d, --database <PATH>   Database file path [default: ~/.config/toolbox/menu.db]
    --debug                 Enable debug mode
    -h, --help              Print help information
    -V, --version           Print version information
```

## 📝 Script Authoring Guide

### Basic Script Template
```bash
#!/usr/bin/env bash
#MN Script Name
#MD Brief description of what this script does
#MDD Detailed description with more context and usage information
#MI CategoryName
#INFO https://example.com/documentation
#MICON 🛠️
#MCOLOR Z2
#MORDER 100
#MDEFAULT false
#MSEPARATOR System Tools
#MTAGS system,utility,admin
#MAUTHOR Your Name

# Your script logic here
echo "Hello from toolbox script!"
```

### Parameterized Script Template
```bash
#!/usr/bin/env bash
#MN Parameterized Script
#MD Example script with interactive parameters
#MDD This script demonstrates the JSON parameter system for collecting user input
#MI Examples
#INFO https://example.com/docs
#MICON ⚙️
#MCOLOR Z4

#JSON_PARAMS_START
#{
#  "target_host": {
#    "type": "text",
#    "label": "Target Host",
#    "description": "Enter the hostname or IP address",
#    "required": true,
#    "pattern": "^[a-zA-Z0-9.-]+$",
#    "pattern_description": "be a valid hostname or IP"
#  },
#  "operation_mode": {
#    "type": "radio",
#    "label": "Operation Mode",
#    "description": "Select the operation to perform",
#    "required": true,
#    "options": [
#      {"value": "check", "label": "Health Check"},
#      {"value": "backup", "label": "Create Backup"},
#      {"value": "restore", "label": "Restore from Backup"}
#    ]
#  },
#  "verbose": {
#    "type": "checkbox",
#    "label": "Verbose Output",
#    "description": "Enable detailed logging",
#    "default": "false"
#  }
#}
#JSON_PARAMS_END

# Access parameters via environment variables
TARGET_HOST="${TOOLBOX_PARAM_TARGET_HOST}"
OPERATION_MODE="${TOOLBOX_PARAM_OPERATION_MODE}"
VERBOSE="${TOOLBOX_PARAM_VERBOSE}"

echo "Executing ${OPERATION_MODE} on ${TARGET_HOST}"
[ "$VERBOSE" = "true" ] && echo "Verbose mode enabled"

# Your script logic here
```

## 🎨 UI/UX Features

### Color Coding System
- 🔴 **Red (Z1)**: Dangerous operations (rm -rf, format, etc.)
- 🟡 **Yellow (Z3)**: Caution required (system changes, network ops)
- 🟢 **Green (Z2)**: Safe operations (viewing, monitoring)
- 🔵 **Blue (Z4)**: Information/utilities (help, status)

### Icon Categories
- 🛠️ Tools/General utilities
- ⚙️ Configuration scripts
- 📦 Package/Installation scripts
- 🚀 Launch/Deploy operations
- ✅ Check/Verify operations
- 🔒 Security operations
- 🔧 Maintenance tasks
- 💡 Information/Tips

### Navigation Patterns
```
Home Menu
├── TopLevel Scripts (immediate access)
├── ──── Categories ──── (separator)
├── 📁 LinuxTools (15 items)
├── 📁 SystemSecurity (8 items)
├── 📁 NetworkUtils (12 items)
├── 🔍 Search
└── ❌ Exit

Category Menu: LinuxTools
├── ──── Performance Monitoring ────
├── 🔍 1. htop - Interactive process viewer
├── 📊 2. iotop - Disk I/O monitoring
├── 📈 3. iftop - Network bandwidth usage
├── ──── System Information ────
├── 💻 4. system_info - Display system details
├── ⬅️  X. Back
├── 🏠 H. Home
└── 🔍 S. Search
```

## 🔧 Advanced Features

### Search Capabilities
- **Fuzzy matching**: Finds partial matches with typos
- **Multi-field search**: Searches across names, descriptions, tags
- **Relevance scoring**: Better matches appear first
- **Real-time filtering**: Results update as you type
- **Search suggestions**: Auto-complete based on available scripts

### Enhanced Script Execution
- **Progress tracking**: Detects apt/yum operations and shows progress
- **Output enhancement**: Special handling for file viewing commands
- **Error reporting**: Clear success/failure indicators
- **Execution history**: Tracks performance and usage patterns
- **Parameter validation**: Client-side validation before execution

### File Viewing Enhancements
- **Find in text**: Built-in search without vi commands
- **Tail with filtering**: `tail -f | grep pattern` made easy
- **Syntax highlighting**: Automatic detection and highlighting
- **Page navigation**: B/F keys for back/forward
- **Line numbers**: Optional line numbering for reference

## 🔒 Security Considerations

### Script Safety
- **Color-coded warnings**: Red scripts clearly marked as dangerous
- **Confirmation dialogs**: Double-confirmation for destructive operations
- **Execution logging**: All script runs recorded with timestamps
- **Parameter validation**: Input sanitization before script execution

### System Integration
- **Minimal privileges**: Runs with user permissions, sudo only when needed
- **Sandboxed execution**: Scripts run in controlled environment
- **Path validation**: Prevents directory traversal attacks
- **Input sanitization**: All user inputs validated and escaped

## 🚀 Performance Optimizations

### Database Efficiency
- **Indexed searches**: Fast lookups on commonly searched fields
- **Prepared statements**: Efficient query execution
- **Connection pooling**: Reuse database connections
- **Lazy loading**: Load data only when needed

### UI Responsiveness
- **Async operations**: Non-blocking file operations
- **Efficient rendering**: Only redraw changed components
- **Keyboard buffering**: Smooth navigation even with rapid input
- **Progress indicators**: Visual feedback for long operations

## 🔮 Future Enhancements

### Planned Features
- **Remote script execution**: SSH integration for remote systems
- **Script templates**: Wizard-based script generation
- **Plugin system**: Extensible architecture for custom features
- **Web interface**: Optional web UI for remote management
- **Script scheduling**: Cron integration for automated execution
- **Backup/restore**: Configuration and script backup system
- **Multi-language support**: Internationalization support
- **Theme system**: Customizable color schemes and layouts

### Integration Possibilities
- **Docker integration**: Container management scripts
- **Kubernetes support**: K8s cluster management tools
- **Cloud provider APIs**: AWS/Azure/GCP automation scripts
- **Monitoring integration**: Prometheus/Grafana setup scripts
- **CI/CD pipelines**: Jenkins/GitLab integration scripts

## 🤝 Contributing

### Development Setup
```bash
# Clone and setup development environment
git clone <repository-url>
cd toolbox-menu
cargo build

# Run tests
cargo test

# Run with debug output
cargo run -- --debug --scan
```

### Code Style
- Follow Rust standard formatting (`cargo fmt`)
- Run clippy for linting (`cargo clippy`)
- Write tests for new features
- Document public APIs
- Follow conventional commit messages

### Adding New Features
1. Create feature branch
2. Implement with tests
3. Update documentation
4. Submit pull request
5. Code review and merge

This system represents a modern approach to system administration tooling, combining the power and flexibility of shell scripts with a sophisticated, user-friendly interface that makes complex operations accessible to both novice and expert users.