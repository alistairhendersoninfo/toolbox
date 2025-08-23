#!/bin/bash
#MN Extract Script Metadata
#MD Extract metadata from script headers for documentation generation
#MDD Parses script files and extracts all metadata tags (MN, MD, MDD, INFO, MICON, etc.) while gracefully handling missing tags. Used by the documentation generation system.
#MI SystemUtilities
#INFO https://github.com/ToolboxMenu
#MICON 📄
#MCOLOR Z4
#MORDER 10

# Function to safely extract metadata field
extract_field() {
    local file="$1"
    local field="$2"
    local default="$3"
    
    # Extract field, return default if not found or empty
    local value=$(grep "^#${field}\s" "$file" 2>/dev/null | head -n1 | sed "s/^#${field}\s*//" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Function to extract script metadata as JSON
extract_script_metadata() {
    local script_file="$1"
    local relative_path="$2"
    
    if [ ! -f "$script_file" ]; then
        echo "Error: Script file not found: $script_file" >&2
        return 1
    fi
    
    # Extract all metadata fields with safe defaults
    local name=$(extract_field "$script_file" "MN" "$(basename "$script_file" .sh)")
    local description=$(extract_field "$script_file" "MD" "No description available")
    local detailed_description=$(extract_field "$script_file" "MDD" "")
    local info_url=$(extract_field "$script_file" "INFO" "")
    local icon=$(extract_field "$script_file" "MICON" "📝")
    local color=$(extract_field "$script_file" "MCOLOR" "")
    local order=$(extract_field "$script_file" "MORDER" "999")
    local default_selection=$(extract_field "$script_file" "MDEFAULT" "false")
    local separator=$(extract_field "$script_file" "MSEPARATOR" "")
    local tags=$(extract_field "$script_file" "MTAGS" "")
    local author=$(extract_field "$script_file" "MAUTHOR" "")
    
    # Convert tags to array format
    local tags_array=""
    if [ -n "$tags" ]; then
        # Split tags by comma and create JSON array
        IFS=',' read -ra tag_array <<< "$tags"
        local tag_json_items=()
        for tag in "${tag_array[@]}"; do
            tag=$(echo "$tag" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ -n "$tag" ]; then
                tag_json_items+=("\"$tag\"")
            fi
        done
        tags_array="[$(IFS=','; echo "${tag_json_items[*]}")]"
    else
        tags_array="[]"
    fi
    
    # Determine category from path
    local category="Uncategorized"
    if [[ "$relative_path" == */* ]]; then
        category=$(dirname "$relative_path")
        category=$(echo "$category" | sed 's|/|::|g')
    fi
    
    # Check if script has JSON parameters
    local has_parameters="false"
    if grep -q "#JSON_PARAMS_START" "$script_file" 2>/dev/null; then
        has_parameters="true"
    fi
    
    # Get file stats
    local file_size=$(stat -f%z "$script_file" 2>/dev/null || stat -c%s "$script_file" 2>/dev/null || echo "0")
    local last_modified=$(stat -f%m "$script_file" 2>/dev/null || stat -c%Y "$script_file" 2>/dev/null || echo "0")
    
    # Escape JSON strings properly
    name=$(echo "$name" | sed 's/"/\\"/g')
    description=$(echo "$description" | sed 's/"/\\"/g')
    detailed_description=$(echo "$detailed_description" | sed 's/"/\\"/g')
    info_url=$(echo "$info_url" | sed 's/"/\\"/g')
    icon=$(echo "$icon" | sed 's/"/\\"/g')
    color=$(echo "$color" | sed 's/"/\\"/g')
    separator=$(echo "$separator" | sed 's/"/\\"/g')
    author=$(echo "$author" | sed 's/"/\\"/g')
    category=$(echo "$category" | sed 's/"/\\"/g')
    
    # Ensure order is a valid number
    if ! [[ "$order" =~ ^[0-9]+$ ]]; then
        order="999"
    fi
    
    # Output JSON
    cat << EOF
{
  "name": "$name",
  "filename": "$(basename "$script_file")",
  "path": "$relative_path",
  "category": "$category",
  "description": "$description",
  "detailed_description": "$detailed_description",
  "info_url": "$info_url",
  "icon": "$icon",
  "color": "$color",
  "order": $order,
  "is_default": "$default_selection",
  "separator": "$separator",
  "tags": $tags_array,
  "author": "$author",
  "has_parameters": "$has_parameters",
  "file_size": $file_size,
  "last_modified": $last_modified
}
EOF
}

# Function to extract all scripts metadata
extract_all_metadata() {
    local base_dir="${1:-.}"
    local output_file="$2"
    
    echo "🔍 Extracting metadata from scripts in: $base_dir"
    
    # Create temporary file for JSON array
    local temp_file=$(mktemp)
    echo "[" > "$temp_file"
    
    local first_item=true
    local script_count=0
    
    # Find all .sh files
    while IFS= read -r -d '' script_file; do
        # Get relative path
        local relative_path=$(realpath --relative-to="$base_dir" "$script_file")
        
        # Skip if in .git directory or other hidden directories
        if [[ "$relative_path" == .git/* ]] || [[ "$relative_path" == */.*/* ]]; then
            continue
        fi
        
        echo "  📄 Processing: $relative_path"
        
        # Add comma separator for JSON array
        if [ "$first_item" = false ]; then
            echo "," >> "$temp_file"
        fi
        first_item=false
        
        # Extract and append metadata
        extract_script_metadata "$script_file" "$relative_path" >> "$temp_file"
        script_count=$((script_count + 1))
        
    done < <(find "$base_dir" -name "*.sh" -type f -print0)
    
    echo "]" >> "$temp_file"
    
    # Move to final location if specified
    if [ -n "$output_file" ]; then
        mv "$temp_file" "$output_file"
        echo "✅ Metadata extracted for $script_count scripts → $output_file"
    else
        cat "$temp_file"
        rm "$temp_file"
        echo "✅ Metadata extracted for $script_count scripts" >&2
    fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        "single")
            if [ -z "$2" ]; then
                echo "Usage: $0 single <script_file> [relative_path]"
                exit 1
            fi
            extract_script_metadata "$2" "${3:-$(basename "$2")}"
            ;;
        "all")
            extract_all_metadata "${2:-.}" "$3"
            ;;
        "help"|*)
            echo "Script Metadata Extractor"
            echo "========================="
            echo ""
            echo "Usage:"
            echo "  $0 single <script_file> [relative_path]  # Extract single script metadata"
            echo "  $0 all [base_dir] [output_file]          # Extract all scripts metadata"
            echo "  $0 help                                   # Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 single script.sh                      # Extract metadata from script.sh"
            echo "  $0 all . scripts_metadata.json           # Extract all to JSON file"
            echo "  $0 all /opt/toolbox                      # Extract all and output to stdout"
            ;;
    esac
fi