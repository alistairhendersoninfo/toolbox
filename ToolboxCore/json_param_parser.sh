#!/usr/bin/env bash
#MN JSON Parameter Parser
#MD Parse and validate JSON parameters from script headers
#MDD Extracts JSON parameter definitions from scripts, validates input, and generates step-by-step forms using dialog
#MI ToolboxCore
#INFO https://github.com/ToolboxMenu
#MICON ⚙️
#MCOLOR Z4
#MORDER 100

# JSON Parameter Parser for Toolbox Scripts
# Supports parameter types: text, number, select, radio, checkbox, password, file, directory

source "$(dirname "$0")/db_functions.sh" 2>/dev/null || true

parse_json_params() {
    local script_file="$1"
    local temp_json="/tmp/toolbox_params_$$.json"
    
    # Extract JSON block from script (between #JSON_PARAMS_START and #JSON_PARAMS_END)
    sed -n '/#JSON_PARAMS_START/,/#JSON_PARAMS_END/p' "$script_file" | \
        grep -v '#JSON_PARAMS_START\|#JSON_PARAMS_END' | \
        sed 's/^#//' > "$temp_json"
    
    # Check if JSON exists and is valid
    if [ ! -s "$temp_json" ] || ! jq empty "$temp_json" 2>/dev/null; then
        rm -f "$temp_json"
        return 1
    fi
    
    echo "$temp_json"
}

validate_parameter() {
    local param_name="$1"
    local param_value="$2"
    local param_config="$3"
    
    local param_type=$(echo "$param_config" | jq -r '.type // "text"')
    local required=$(echo "$param_config" | jq -r '.required // false')
    local min_length=$(echo "$param_config" | jq -r '.min_length // 0')
    local max_length=$(echo "$param_config" | jq -r '.max_length // 1000')
    local pattern=$(echo "$param_config" | jq -r '.pattern // ""')
    
    # Check required
    if [ "$required" = "true" ] && [ -z "$param_value" ]; then
        echo "ERROR: Parameter '$param_name' is required"
        return 1
    fi
    
    # Skip further validation if empty and not required
    [ -z "$param_value" ] && return 0
    
    # Length validation
    local value_length=${#param_value}
    if [ "$value_length" -lt "$min_length" ]; then
        echo "ERROR: Parameter '$param_name' must be at least $min_length characters"
        return 1
    fi
    
    if [ "$value_length" -gt "$max_length" ]; then
        echo "ERROR: Parameter '$param_name' must be no more than $max_length characters"
        return 1
    fi
    
    # Pattern validation
    if [ -n "$pattern" ] && ! echo "$param_value" | grep -qE "$pattern"; then
        local pattern_desc=$(echo "$param_config" | jq -r '.pattern_description // "match the required pattern"')
        echo "ERROR: Parameter '$param_name' must $pattern_desc"
        return 1
    fi
    
    # Type-specific validation
    case "$param_type" in
        "number")
            if ! [[ "$param_value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
                echo "ERROR: Parameter '$param_name' must be a valid number"
                return 1
            fi
            
            local min_val=$(echo "$param_config" | jq -r '.min // empty')
            local max_val=$(echo "$param_config" | jq -r '.max // empty')
            
            if [ -n "$min_val" ] && (( $(echo "$param_value < $min_val" | bc -l) )); then
                echo "ERROR: Parameter '$param_name' must be >= $min_val"
                return 1
            fi
            
            if [ -n "$max_val" ] && (( $(echo "$param_value > $max_val" | bc -l) )); then
                echo "ERROR: Parameter '$param_name' must be <= $max_val"
                return 1
            fi
            ;;
        "file")
            if [ -n "$param_value" ] && [ ! -f "$param_value" ]; then
                echo "ERROR: File '$param_value' does not exist"
                return 1
            fi
            ;;
        "directory")
            if [ -n "$param_value" ] && [ ! -d "$param_value" ]; then
                echo "ERROR: Directory '$param_value' does not exist"
                return 1
            fi
            ;;
    esac
    
    return 0
}

generate_dialog_form() {
    local param_name="$1"
    local param_config="$2"
    local current_value="$3"
    
    local param_type=$(echo "$param_config" | jq -r '.type // "text"')
    local label=$(echo "$param_config" | jq -r '.label // .name')
    local description=$(echo "$param_config" | jq -r '.description // ""')
    local default_value=$(echo "$param_config" | jq -r '.default // ""')
    local required=$(echo "$param_config" | jq -r '.required // false')
    
    # Use current value or default
    local initial_value="${current_value:-$default_value}"
    
    # Build dialog title
    local title="$label"
    [ "$required" = "true" ] && title="$title (Required)"
    
    # Build dialog text
    local dialog_text="$description"
    [ -n "$dialog_text" ] && dialog_text="$dialog_text\n\n"
    
    case "$param_type" in
        "text"|"password")
            local input_type="inputbox"
            [ "$param_type" = "password" ] && input_type="passwordbox"
            
            dialog --clear \
                --title "$title" \
                --"$input_type" "$dialog_text" \
                12 60 "$initial_value" \
                3>&1 1>&2 2>&3
            ;;
        "number")
            dialog --clear \
                --title "$title" \
                --inputbox "${dialog_text}Enter a number:" \
                12 60 "$initial_value" \
                3>&1 1>&2 2>&3
            ;;
        "select"|"radio")
            local options_json=$(echo "$param_config" | jq -r '.options[]')
            local dialog_options=()
            local default_tag=""
            
            while IFS= read -r option; do
                local value=$(echo "$option" | jq -r '.value')
                local label=$(echo "$option" | jq -r '.label // .value')
                local selected="OFF"
                
                if [ "$value" = "$initial_value" ]; then
                    selected="ON"
                    default_tag="$value"
                fi
                
                dialog_options+=("$value" "$label" "$selected")
            done <<< "$options_json"
            
            if [ "$param_type" = "select" ]; then
                dialog --clear \
                    --title "$title" \
                    --menu "${dialog_text}Choose an option:" \
                    15 60 8 \
                    "${dialog_options[@]}" \
                    3>&1 1>&2 2>&3
            else
                dialog --clear \
                    --title "$title" \
                    --radiolist "${dialog_text}Choose an option:" \
                    15 60 8 \
                    "${dialog_options[@]}" \
                    3>&1 1>&2 2>&3
            fi
            ;;
        "checkbox")
            local options_json=$(echo "$param_config" | jq -r '.options[]')
            local dialog_options=()
            
            # Parse current value as comma-separated list
            IFS=',' read -ra current_values <<< "$initial_value"
            
            while IFS= read -r option; do
                local value=$(echo "$option" | jq -r '.value')
                local label=$(echo "$option" | jq -r '.label // .value')
                local selected="OFF"
                
                # Check if this value is in current selection
                for cv in "${current_values[@]}"; do
                    [ "$cv" = "$value" ] && selected="ON" && break
                done
                
                dialog_options+=("$value" "$label" "$selected")
            done <<< "$options_json"
            
            dialog --clear \
                --title "$title" \
                --checklist "${dialog_text}Choose options (space to select):" \
                15 60 8 \
                "${dialog_options[@]}" \
                3>&1 1>&2 2>&3
            ;;
        "file")
            dialog --clear \
                --title "$title" \
                --fselect "$initial_value" \
                14 48 \
                3>&1 1>&2 2>&3
            ;;
        "directory")
            dialog --clear \
                --title "$title" \
                --dselect "$initial_value" \
                14 48 \
                3>&1 1>&2 2>&3
            ;;
        *)
            # Default to text input
            dialog --clear \
                --title "$title" \
                --inputbox "$dialog_text" \
                12 60 "$initial_value" \
                3>&1 1>&2 2>&3
            ;;
    esac
}

collect_parameters() {
    local script_file="$1"
    local json_file
    json_file=$(parse_json_params "$script_file")
    
    if [ $? -ne 0 ]; then
        echo "No parameters defined for this script."
        return 0
    fi
    
    local params_json=$(cat "$json_file")
    local param_names=$(echo "$params_json" | jq -r 'keys[]')
    local collected_params=()
    local param_values=()
    
    # Collect each parameter
    while IFS= read -r param_name; do
        local param_config=$(echo "$params_json" | jq -c ".[\"$param_name\"]")
        local current_value=""
        
        # Try to get saved value from database
        if command -v db_read >/dev/null 2>&1; then
            current_value=$(db_read "SELECT message FROM state WHERE script='$(basename "$script_file")' AND step='param_$param_name' LIMIT 1" 2>/dev/null || echo "")
        fi
        
        while true; do
            local input_value
            input_value=$(generate_dialog_form "$param_name" "$param_config" "$current_value")
            local dialog_exit=$?
            
            # Handle dialog cancellation
            if [ $dialog_exit -ne 0 ]; then
                rm -f "$json_file"
                return 1
            fi
            
            # Validate input
            local validation_result
            validation_result=$(validate_parameter "$param_name" "$input_value" "$param_config")
            
            if [ $? -eq 0 ]; then
                # Save parameter value
                collected_params+=("$param_name")
                param_values+=("$input_value")
                
                # Save to database if available
                if command -v db_write >/dev/null 2>&1; then
                    db_write "INSERT OR REPLACE INTO state (script, step, status, message, timestamp) VALUES ('$(basename "$script_file")', 'param_$param_name', 'set', '$input_value', datetime('now'))" 2>/dev/null || true
                fi
                
                current_value="$input_value"
                break
            else
                # Show validation error and retry
                dialog --msgbox "$validation_result" 8 60
                current_value="$input_value"
            fi
        done
    done <<< "$param_names"
    
    # Export parameters as environment variables
    for i in "${!collected_params[@]}"; do
        export "TOOLBOX_PARAM_${collected_params[i]^^}"="${param_values[i]}"
    done
    
    rm -f "$json_file"
    return 0
}

# Main function for testing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <script_file>"
        exit 1
    fi
    
    collect_parameters "$1"
fi