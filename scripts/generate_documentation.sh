#!/bin/bash
#MN Generate Documentation
#MD Generate comprehensive documentation from script headers
#MDD Main documentation generator that scans all scripts, extracts metadata, and creates organized documentation files including table of contents, category pages, and individual script documentation.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON 📚
#MCOLOR Z2
#MORDER 5

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_ROOT/docs"
METADATA_FILE="$DOCS_DIR/scripts_metadata.json"

echo "📚 Generating Toolbox Documentation"
echo "==================================="
echo "📁 Project Root: $PROJECT_ROOT"
echo "📄 Docs Directory: $DOCS_DIR"
echo ""

# Create docs directory
mkdir -p "$DOCS_DIR"

# Extract metadata from all scripts
echo "🔍 Step 1: Extracting Script Metadata"
echo "-------------------------------------"
"$SCRIPT_DIR/extract_script_metadata.sh" all "$PROJECT_ROOT" "$METADATA_FILE"

if [ ! -f "$METADATA_FILE" ]; then
    echo "❌ Error: Failed to generate metadata file"
    exit 1
fi

echo ""

# Generate documentation files
echo "📝 Step 2: Generating Documentation Files"
echo "-----------------------------------------"

# Function to generate table of contents
generate_table_of_contents() {
    local output_file="$DOCS_DIR/README.md"
    
    echo "📋 Generating table of contents..."
    
    cat > "$output_file" << 'EOF'
# 🛡️ Toolbox Scripts Documentation

This documentation is automatically generated from script headers and provides comprehensive information about all available toolbox scripts.

## 📊 Overview

EOF
    
    # Add statistics
    local total_scripts=$(jq length "$METADATA_FILE")
    local categories=$(jq -r '.[].category' "$METADATA_FILE" | sort -u | wc -l)
    local scripts_with_params=$(jq '[.[] | select(.has_parameters == true)] | length' "$METADATA_FILE")
    local authors=$(jq -r '.[].author' "$METADATA_FILE" | grep -v '^$' | sort -u | wc -l)
    
    cat >> "$output_file" << EOF
- **Total Scripts**: $total_scripts
- **Categories**: $categories
- **Scripts with Parameters**: $scripts_with_params
- **Authors**: $authors
- **Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')

## 📁 Categories

EOF
    
    # Generate category list with counts
    jq -r '.[].category' "$METADATA_FILE" | sort | uniq -c | sort -nr | while read count category; do
        local category_file=$(echo "$category" | tr '::' '_' | tr '/' '_').md
        echo "- **[$category]($category_file)** ($count scripts)" >> "$output_file"
    done
    
    cat >> "$output_file" << 'EOF'

## 🔍 Quick Reference

### By Functionality

EOF
    
    # Group by common tags
    echo "#### System Administration" >> "$output_file"
    jq -r '.[] | select(.tags[] | test("system|admin|monitoring")) | "- [\(.name)](\(.category | gsub("::"; "_") | gsub("/"; "_")).md#\(.name | gsub(" "; "-") | ascii_downcase)) - \(.description)"' "$METADATA_FILE" | sort >> "$output_file" 2>/dev/null || true
    
    echo "" >> "$output_file"
    echo "#### Security Tools" >> "$output_file"
    jq -r '.[] | select(.tags[] | test("security|ssl|firewall")) | "- [\(.name)](\(.category | gsub("::"; "_") | gsub("/"; "_")).md#\(.name | gsub(" "; "-") | ascii_downcase)) - \(.description)"' "$METADATA_FILE" | sort >> "$output_file" 2>/dev/null || true
    
    echo "" >> "$output_file"
    echo "#### Network Utilities" >> "$output_file"
    jq -r '.[] | select(.tags[] | test("network|net|connection")) | "- [\(.name)](\(.category | gsub("::"; "_") | gsub("/"; "_")).md#\(.name | gsub(" "; "-") | ascii_downcase)) - \(.description)"' "$METADATA_FILE" | sort >> "$output_file" 2>/dev/null || true
    
    cat >> "$output_file" << 'EOF'

## 🎯 Script Features

### Color Coding
- 🔴 **Red (Z1)** - Dangerous operations requiring caution
- 🟡 **Yellow (Z3)** - Operations requiring attention
- 🟢 **Green (Z2)** - Safe operations
- 🔵 **Blue (Z4)** - Information and utility scripts

### Icons Guide
- 🛠️ General tools and utilities
- ⚙️ Configuration and setup scripts
- 📦 Installation and package management
- 🚀 Deployment and launch scripts
- 🔒 Security and authentication
- 📊 Monitoring and analysis
- 🔧 Maintenance and repair
- 📝 Documentation and reporting

## 📖 Usage

To use these scripts with the Toolbox Menu System:

```bash
# Install the toolbox menu system
./scripts/install_complete.sh

# Launch the interactive menu
toolbox

# Or run scripts directly
/opt/toolbox/CategoryName/script_name.sh
```

## 🔄 Documentation Updates

This documentation is automatically updated when scripts are modified. The generation process:

1. **Scans** all `.sh` files in the repository
2. **Extracts** metadata from script headers (#MN, #MD, #MDD, etc.)
3. **Generates** category-based documentation
4. **Creates** cross-references and indices
5. **Updates** table of contents and statistics

---

*📅 Generated on $(date '+%Y-%m-%d %H:%M:%S') by the Toolbox Documentation System*
EOF
    
    echo "✅ Table of contents generated: $output_file"
}

# Function to generate category documentation
generate_category_docs() {
    echo "📂 Generating category documentation..."
    
    # Get unique categories
    local categories=$(jq -r '.[].category' "$METADATA_FILE" | sort -u)
    
    while IFS= read -r category; do
        if [ -z "$category" ] || [ "$category" = "null" ]; then
            continue
        fi
        
        local category_file="$DOCS_DIR/$(echo "$category" | tr '::' '_' | tr '/' '_').md"
        local category_display=$(echo "$category" | tr '::' ' > ' | tr '/' ' > ')
        
        echo "  📄 Creating: $(basename "$category_file")"
        
        cat > "$category_file" << EOF
# 📁 $category_display

EOF
        
        # Add category description and stats
        local script_count=$(jq "[.[] | select(.category == \"$category\")] | length" "$METADATA_FILE")
        local scripts_with_params=$(jq "[.[] | select(.category == \"$category\" and .has_parameters == true)] | length" "$METADATA_FILE")
        
        cat >> "$category_file" << EOF
**Category Statistics:**
- Scripts: $script_count
- Interactive Scripts: $scripts_with_params
- Category Path: \`$category\`

## Scripts in this Category

EOF
        
        # Add scripts in this category, sorted by order then name
        jq -r ".[] | select(.category == \"$category\") | [.order, .name, .filename, .description, .detailed_description, .info_url, .icon, .author, .tags, .has_parameters] | @tsv" "$METADATA_FILE" | \
        sort -n | while IFS=$'\t' read -r order name filename description detailed_description info_url icon author tags has_parameters; do
            
            # Convert tags back from JSON-like format
            local tag_list=""
            if [ "$tags" != "[]" ] && [ -n "$tags" ]; then
                tag_list=$(echo "$tags" | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | sed 's/,/, /g')
            fi
            
            cat >> "$category_file" << EOF
### $icon $name

**File:** \`$filename\`  
**Description:** $description

EOF
            
            if [ -n "$detailed_description" ] && [ "$detailed_description" != "null" ]; then
                cat >> "$category_file" << EOF
**Details:** $detailed_description

EOF
            fi
            
            if [ -n "$author" ] && [ "$author" != "null" ]; then
                cat >> "$category_file" << EOF
**Author:** $author  
EOF
            fi
            
            if [ -n "$tag_list" ]; then
                cat >> "$category_file" << EOF
**Tags:** $tag_list  
EOF
            fi
            
            if [ "$has_parameters" = "true" ]; then
                cat >> "$category_file" << EOF
**Interactive:** ✅ This script has interactive parameters  
EOF
            fi
            
            if [ -n "$info_url" ] && [ "$info_url" != "null" ]; then
                cat >> "$category_file" << EOF
**More Info:** [$info_url]($info_url)  
EOF
            fi
            
            cat >> "$category_file" << EOF

---

EOF
        done
        
        # Add navigation footer
        cat >> "$category_file" << EOF

## Navigation

- [🏠 Back to Main Documentation](README.md)
- [📊 All Categories](README.md#-categories)

---

*📅 Generated on $(date '+%Y-%m-%d %H:%M:%S')*
EOF
        
    done <<< "$categories"
    
    echo "✅ Category documentation generated"
}

# Function to generate script index
generate_script_index() {
    local output_file="$DOCS_DIR/SCRIPT_INDEX.md"
    
    echo "📇 Generating script index..."
    
    cat > "$output_file" << 'EOF'
# 📇 Complete Script Index

This is a comprehensive alphabetical index of all scripts in the toolbox.

## Alphabetical Listing

EOF
    
    # Generate alphabetical listing
    jq -r '.[] | [.name, .category, .description, .filename, .icon] | @tsv' "$METADATA_FILE" | \
    sort -f | while IFS=$'\t' read -r name category description filename icon; do
        local category_file=$(echo "$category" | tr '::' '_' | tr '/' '_').md
        local anchor=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        
        cat >> "$output_file" << EOF
### $icon $name

**Category:** [$category]($category_file)  
**File:** \`$filename\`  
**Description:** $description

EOF
    done
    
    cat >> "$output_file" << 'EOF'

## By File Name

EOF
    
    # Generate by filename
    jq -r '.[] | [.filename, .name, .category, .description] | @tsv' "$METADATA_FILE" | \
    sort | while IFS=$'\t' read -r filename name category description; do
        local category_file=$(echo "$category" | tr '::' '_' | tr '/' '_').md
        
        cat >> "$output_file" << EOF
- **\`$filename\`** - [$name]($category_file#$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')) - $description
EOF
    done
    
    cat >> "$output_file" << EOF

---

## Navigation

- [🏠 Back to Main Documentation](README.md)

---

*📅 Generated on $(date '+%Y-%m-%d %H:%M:%S')*
EOF
    
    echo "✅ Script index generated: $output_file"
}

# Function to generate statistics
generate_statistics() {
    local output_file="$DOCS_DIR/STATISTICS.md"
    
    echo "📊 Generating statistics..."
    
    cat > "$output_file" << 'EOF'
# 📊 Toolbox Statistics

Comprehensive statistics about the toolbox script collection.

## Overview

EOF
    
    # Basic statistics
    local total_scripts=$(jq length "$METADATA_FILE")
    local total_categories=$(jq -r '.[].category' "$METADATA_FILE" | sort -u | wc -l)
    local scripts_with_params=$(jq '[.[] | select(.has_parameters == true)] | length' "$METADATA_FILE")
    local scripts_with_info=$(jq '[.[] | select(.info_url != "" and .info_url != null)] | length' "$METADATA_FILE")
    local scripts_with_authors=$(jq '[.[] | select(.author != "" and .author != null)] | length' "$METADATA_FILE")
    local total_size=$(jq '[.[].file_size] | add' "$METADATA_FILE")
    
    cat >> "$output_file" << EOF
- **Total Scripts:** $total_scripts
- **Categories:** $total_categories
- **Interactive Scripts:** $scripts_with_params
- **Scripts with Documentation Links:** $scripts_with_info
- **Scripts with Authors:** $scripts_with_authors
- **Total Size:** $(numfmt --to=iec $total_size 2>/dev/null || echo "$total_size bytes")

## Category Breakdown

EOF
    
    # Category statistics
    echo "| Category | Scripts | Interactive | Avg Size |" >> "$output_file"
    echo "|----------|---------|-------------|----------|" >> "$output_file"
    
    jq -r '.[].category' "$METADATA_FILE" | sort | uniq -c | sort -nr | while read count category; do
        local interactive_count=$(jq "[.[] | select(.category == \"$category\" and .has_parameters == true)] | length" "$METADATA_FILE")
        local avg_size=$(jq "[.[] | select(.category == \"$category\")] | [.[].file_size] | add / length" "$METADATA_FILE")
        local avg_size_formatted=$(echo "$avg_size" | cut -d. -f1)
        
        echo "| $category | $count | $interactive_count | ${avg_size_formatted} bytes |" >> "$output_file"
    done
    
    cat >> "$output_file" << 'EOF'

## Color Distribution

EOF
    
    # Color statistics
    echo "| Color | Count | Purpose |" >> "$output_file"
    echo "|-------|-------|---------|" >> "$output_file"
    
    for color in Z1 Z2 Z3 Z4 ""; do
        local color_name=""
        local purpose=""
        case "$color" in
            "Z1") color_name="🔴 Red"; purpose="Dangerous operations" ;;
            "Z2") color_name="🟢 Green"; purpose="Safe operations" ;;
            "Z3") color_name="🟡 Yellow"; purpose="Caution required" ;;
            "Z4") color_name="🔵 Blue"; purpose="Information/utilities" ;;
            "") color_name="⚪ Default"; purpose="Standard scripts" ;;
        esac
        
        local count=$(jq "[.[] | select(.color == \"$color\")] | length" "$METADATA_FILE")
        echo "| $color_name | $count | $purpose |" >> "$output_file"
    done
    
    cat >> "$output_file" << 'EOF'

## Top Authors

EOF
    
    # Author statistics
    echo "| Author | Scripts |" >> "$output_file"
    echo "|--------|---------|" >> "$output_file"
    
    jq -r '.[] | select(.author != "" and .author != null) | .author' "$METADATA_FILE" | \
    sort | uniq -c | sort -nr | head -10 | while read count author; do
        echo "| $author | $count |" >> "$output_file"
    done
    
    cat >> "$output_file" << 'EOF'

## Most Common Tags

EOF
    
    # Tag statistics
    echo "| Tag | Frequency |" >> "$output_file"
    echo "|-----|-----------|" >> "$output_file"
    
    jq -r '.[] | .tags[]' "$METADATA_FILE" 2>/dev/null | \
    sort | uniq -c | sort -nr | head -15 | while read count tag; do
        echo "| $tag | $count |" >> "$output_file"
    done 2>/dev/null || echo "| No tags found | 0 |" >> "$output_file"
    
    cat >> "$output_file" << EOF

---

## Navigation

- [🏠 Back to Main Documentation](README.md)

---

*📅 Generated on $(date '+%Y-%m-%d %H:%M:%S')*
EOF
    
    echo "✅ Statistics generated: $output_file"
}

# Main execution
echo "🚀 Starting documentation generation..."

# Step 1: Generate table of contents
generate_table_of_contents

# Step 2: Generate category documentation
generate_category_docs

# Step 3: Generate script index
generate_script_index

# Step 4: Generate statistics
generate_statistics

# Step 5: Create .gitkeep for docs directory
touch "$DOCS_DIR/.gitkeep"

echo ""
echo "🎉 Documentation Generation Complete!"
echo "===================================="
echo "📁 Documentation location: $DOCS_DIR"
echo "📄 Files generated:"
echo "  - README.md (Table of Contents)"
echo "  - SCRIPT_INDEX.md (Alphabetical index)"
echo "  - STATISTICS.md (Statistics and metrics)"
echo "  - Category files (*.md)"
echo "  - scripts_metadata.json (Raw metadata)"
echo ""
echo "🔗 View documentation:"
echo "  - Main: $DOCS_DIR/README.md"
echo "  - Index: $DOCS_DIR/SCRIPT_INDEX.md"
echo "  - Stats: $DOCS_DIR/STATISTICS.md"
echo ""
echo "✅ Ready for commit!"