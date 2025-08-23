#!/bin/bash
#MN Validate Documentation
#MD Validate generated documentation for completeness and accuracy
#MDD Comprehensive validation script that checks generated documentation for missing files, broken links, inconsistent metadata, and ensures all scripts are properly documented.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON ✅
#MCOLOR Z4
#MORDER 7

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_ROOT/docs"
METADATA_FILE="$DOCS_DIR/scripts_metadata.json"

ERRORS=0
WARNINGS=0

echo "✅ Validating Toolbox Documentation"
echo "==================================="
echo "📁 Project Root: $PROJECT_ROOT"
echo "📄 Docs Directory: $DOCS_DIR"
echo ""

# Function to report error
report_error() {
    echo "❌ ERROR: $1"
    ERRORS=$((ERRORS + 1))
}

# Function to report warning
report_warning() {
    echo "⚠️  WARNING: $1"
    WARNINGS=$((WARNINGS + 1))
}

# Function to report success
report_success() {
    echo "✅ $1"
}

# Check if documentation exists
echo "🔍 Step 1: Checking Documentation Structure"
echo "------------------------------------------"

if [ ! -d "$DOCS_DIR" ]; then
    report_error "Documentation directory not found: $DOCS_DIR"
    exit 1
fi

# Check required files
required_files=("README.md" "SCRIPT_INDEX.md" "STATISTICS.md" "scripts_metadata.json")
for file in "${required_files[@]}"; do
    if [ -f "$DOCS_DIR/$file" ]; then
        report_success "Required file exists: $file"
    else
        report_error "Required file missing: $file"
    fi
done

echo ""

# Validate metadata file
echo "🔍 Step 2: Validating Metadata"
echo "------------------------------"

if [ ! -f "$METADATA_FILE" ]; then
    report_error "Metadata file not found: $METADATA_FILE"
    exit 1
fi

# Check if metadata is valid JSON
if jq empty "$METADATA_FILE" 2>/dev/null; then
    report_success "Metadata file is valid JSON"
else
    report_error "Metadata file is not valid JSON"
    exit 1
fi

# Check metadata completeness
total_scripts=$(jq length "$METADATA_FILE")
if [ "$total_scripts" -eq 0 ]; then
    report_error "No scripts found in metadata"
else
    report_success "Found $total_scripts scripts in metadata"
fi

# Check for required fields in metadata
echo ""
echo "📋 Checking metadata fields..."

scripts_missing_name=$(jq '[.[] | select(.name == "" or .name == null)] | length' "$METADATA_FILE")
scripts_missing_description=$(jq '[.[] | select(.description == "" or .description == null)] | length' "$METADATA_FILE")
scripts_missing_category=$(jq '[.[] | select(.category == "" or .category == null)] | length' "$METADATA_FILE")

if [ "$scripts_missing_name" -eq 0 ]; then
    report_success "All scripts have names"
else
    report_warning "$scripts_missing_name scripts missing names"
fi

if [ "$scripts_missing_description" -eq 0 ]; then
    report_success "All scripts have descriptions"
else
    report_warning "$scripts_missing_description scripts missing descriptions"
fi

if [ "$scripts_missing_category" -eq 0 ]; then
    report_success "All scripts have categories"
else
    report_error "$scripts_missing_category scripts missing categories"
fi

echo ""

# Check file system consistency
echo "🔍 Step 3: Checking File System Consistency"
echo "-------------------------------------------"

# Check if all documented scripts exist
missing_files=0
jq -r '.[].path' "$METADATA_FILE" | while read -r script_path; do
    full_path="$PROJECT_ROOT/$script_path"
    if [ ! -f "$full_path" ]; then
        report_error "Documented script not found: $script_path"
        missing_files=$((missing_files + 1))
    fi
done

# Check if all .sh files are documented
undocumented_files=0
while IFS= read -r -d '' script_file; do
    relative_path=$(realpath --relative-to="$PROJECT_ROOT" "$script_file")
    
    # Skip hidden directories and .git
    if [[ "$relative_path" == .git/* ]] || [[ "$relative_path" == */.*/* ]]; then
        continue
    fi
    
    # Check if this file is in metadata
    if ! jq -e ".[] | select(.path == \"$relative_path\")" "$METADATA_FILE" >/dev/null 2>&1; then
        report_warning "Script not documented: $relative_path"
        undocumented_files=$((undocumented_files + 1))
    fi
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)

if [ "$undocumented_files" -eq 0 ]; then
    report_success "All scripts are documented"
else
    report_warning "$undocumented_files scripts are not documented"
fi

echo ""

# Validate category documentation
echo "🔍 Step 4: Validating Category Documentation"
echo "--------------------------------------------"

categories=$(jq -r '.[].category' "$METADATA_FILE" | sort -u)
missing_category_docs=0

while IFS= read -r category; do
    if [ -z "$category" ] || [ "$category" = "null" ]; then
        continue
    fi
    
    category_file="$DOCS_DIR/$(echo "$category" | tr '::' '_' | tr '/' '_').md"
    
    if [ -f "$category_file" ]; then
        report_success "Category documentation exists: $(basename "$category_file")"
        
        # Check if category file mentions all scripts in that category
        script_count=$(jq "[.[] | select(.category == \"$category\")] | length" "$METADATA_FILE")
        
        # Count script mentions in the category file (rough check)
        mentions=$(grep -c "^### " "$category_file" 2>/dev/null || echo "0")
        
        if [ "$mentions" -eq "$script_count" ]; then
            report_success "Category $category has all $script_count scripts documented"
        else
            report_warning "Category $category: expected $script_count scripts, found $mentions mentions"
        fi
    else
        report_error "Category documentation missing: $(basename "$category_file")"
        missing_category_docs=$((missing_category_docs + 1))
    fi
done <<< "$categories"

echo ""

# Check for broken internal links
echo "🔍 Step 5: Checking Internal Links"
echo "----------------------------------"

broken_links=0

# Check links in README.md
if [ -f "$DOCS_DIR/README.md" ]; then
    while IFS= read -r link; do
        if [[ "$link" == *.md* ]]; then
            # Extract filename from link
            link_file=$(echo "$link" | sed 's/.*(\([^)]*\)).*/\1/' | cut -d'#' -f1)
            if [ -n "$link_file" ] && [ ! -f "$DOCS_DIR/$link_file" ]; then
                report_error "Broken link in README.md: $link_file"
                broken_links=$((broken_links + 1))
            fi
        fi
    done < <(grep -o '\[.*\](.*\.md[^)]*)' "$DOCS_DIR/README.md" 2>/dev/null || true)
fi

if [ "$broken_links" -eq 0 ]; then
    report_success "No broken internal links found"
fi

echo ""

# Check documentation freshness
echo "🔍 Step 6: Checking Documentation Freshness"
echo "-------------------------------------------"

if [ -f "$DOCS_DIR/README.md" ]; then
    # Check if README was generated recently (within last day of newest script)
    newest_script=$(find "$PROJECT_ROOT" -name "*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2- || echo "")
    
    if [ -n "$newest_script" ]; then
        newest_script_time=$(stat -c %Y "$newest_script" 2>/dev/null || echo "0")
        readme_time=$(stat -c %Y "$DOCS_DIR/README.md" 2>/dev/null || echo "0")
        
        if [ "$readme_time" -ge "$newest_script_time" ]; then
            report_success "Documentation is up to date"
        else
            report_warning "Documentation may be outdated (README older than newest script)"
        fi
    fi
fi

echo ""

# Validate statistics
echo "🔍 Step 7: Validating Statistics"
echo "--------------------------------"

if [ -f "$DOCS_DIR/STATISTICS.md" ]; then
    # Check if statistics file contains expected sections
    required_sections=("Overview" "Category Breakdown" "Color Distribution")
    
    for section in "${required_sections[@]}"; do
        if grep -q "## $section" "$DOCS_DIR/STATISTICS.md"; then
            report_success "Statistics contains section: $section"
        else
            report_warning "Statistics missing section: $section"
        fi
    done
else
    report_error "Statistics file missing"
fi

echo ""

# Check for duplicate scripts
echo "🔍 Step 8: Checking for Duplicates"
echo "----------------------------------"

# Check for duplicate names
duplicate_names=$(jq -r '.[].name' "$METADATA_FILE" | sort | uniq -d)
if [ -n "$duplicate_names" ]; then
    while IFS= read -r name; do
        report_warning "Duplicate script name: $name"
    done <<< "$duplicate_names"
else
    report_success "No duplicate script names found"
fi

# Check for duplicate files
duplicate_files=$(jq -r '.[].filename' "$METADATA_FILE" | sort | uniq -d)
if [ -n "$duplicate_files" ]; then
    while IFS= read -r filename; do
        report_warning "Duplicate filename: $filename"
    done <<< "$duplicate_files"
else
    report_success "No duplicate filenames found"
fi

echo ""

# Final summary
echo "📊 Validation Summary"
echo "===================="
echo "✅ Successful checks: $(grep -c "✅" <<< "$(grep "✅\|❌\|⚠️" <<< "$output" 2>/dev/null || echo "")" 2>/dev/null || echo "0")"
echo "⚠️  Warnings: $WARNINGS"
echo "❌ Errors: $ERRORS"
echo ""

if [ "$ERRORS" -eq 0 ]; then
    if [ "$WARNINGS" -eq 0 ]; then
        echo "🎉 Documentation validation passed with no issues!"
        exit 0
    else
        echo "✅ Documentation validation passed with $WARNINGS warnings"
        echo "💡 Consider addressing warnings for better documentation quality"
        exit 0
    fi
else
    echo "❌ Documentation validation failed with $ERRORS errors"
    echo ""
    echo "🔧 To fix issues:"
    echo "1. Run: ./scripts/generate_documentation.sh"
    echo "2. Check for missing or moved script files"
    echo "3. Validate script metadata headers"
    echo "4. Re-run this validation script"
    exit 1
fi