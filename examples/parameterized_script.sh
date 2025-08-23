#!/usr/bin/env bash
#MN Backup Manager
#MD Create and manage system backups
#MDD Advanced backup script with multiple options for creating, verifying, and managing system backups. Supports different backup types and compression levels.
#MI BackupUtilities
#INFO https://rsync.samba.org/
#MICON 💾
#MCOLOR Z3
#MORDER 50
#MDEFAULT false
#MSEPARATOR Backup & Recovery
#MTAGS backup,archive,recovery,rsync
#MAUTHOR Toolbox Team

#JSON_PARAMS_START
#{
#  "backup_type": {
#    "type": "radio",
#    "label": "Backup Type",
#    "description": "Select the type of backup to perform",
#    "required": true,
#    "options": [
#      {"value": "full", "label": "Full Backup - Complete system backup"},
#      {"value": "incremental", "label": "Incremental - Only changed files since last backup"},
#      {"value": "home", "label": "Home Directory - User data only"},
#      {"value": "config", "label": "Configuration - System config files only"}
#    ]
#  },
#  "destination": {
#    "type": "directory",
#    "label": "Backup Destination",
#    "description": "Choose the directory where backups will be stored",
#    "required": true,
#    "default": "/backup"
#  },
#  "compression": {
#    "type": "select",
#    "label": "Compression Level",
#    "description": "Select compression level (higher = smaller size, slower)",
#    "required": true,
#    "default": "medium",
#    "options": [
#      {"value": "none", "label": "No Compression (fastest)"},
#      {"value": "low", "label": "Low Compression (fast)"},
#      {"value": "medium", "label": "Medium Compression (balanced)"},
#      {"value": "high", "label": "High Compression (slow, smallest)"}
#    ]
#  },
#  "exclude_patterns": {
#    "type": "text",
#    "label": "Exclude Patterns",
#    "description": "Comma-separated list of patterns to exclude (e.g., *.tmp,*.log)",
#    "required": false,
#    "default": "*.tmp,*.log,*~,.cache"
#  },
#  "verify_backup": {
#    "type": "checkbox",
#    "label": "Verify Backup",
#    "description": "Verify backup integrity after creation",
#    "default": "true"
#  },
#  "email_notification": {
#    "type": "text",
#    "label": "Email Notification",
#    "description": "Email address for backup completion notification (optional)",
#    "required": false,
#    "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
#    "pattern_description": "be a valid email address"
#  }
#}
#JSON_PARAMS_END

# Get parameters from environment variables set by the menu system
BACKUP_TYPE="${TOOLBOX_PARAM_BACKUP_TYPE}"
DESTINATION="${TOOLBOX_PARAM_DESTINATION}"
COMPRESSION="${TOOLBOX_PARAM_COMPRESSION}"
EXCLUDE_PATTERNS="${TOOLBOX_PARAM_EXCLUDE_PATTERNS}"
VERIFY_BACKUP="${TOOLBOX_PARAM_VERIFY_BACKUP}"
EMAIL_NOTIFICATION="${TOOLBOX_PARAM_EMAIL_NOTIFICATION}"

# Set compression options
case "$COMPRESSION" in
    "none") COMPRESS_OPTS="" ;;
    "low") COMPRESS_OPTS="-z --compress-level=1" ;;
    "medium") COMPRESS_OPTS="-z --compress-level=6" ;;
    "high") COMPRESS_OPTS="-z --compress-level=9" ;;
esac

# Create backup directory if it doesn't exist
mkdir -p "$DESTINATION"

# Generate timestamp for backup name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${BACKUP_TYPE}_${TIMESTAMP}"
BACKUP_PATH="$DESTINATION/$BACKUP_NAME"

echo "🚀 Starting Backup Process"
echo "=========================="
echo "Type: $BACKUP_TYPE"
echo "Destination: $BACKUP_PATH"
echo "Compression: $COMPRESSION"
echo "Verify: $VERIFY_BACKUP"
echo ""

# Set source directories based on backup type
case "$BACKUP_TYPE" in
    "full")
        SOURCE_DIRS="/ --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run --exclude=/mnt --exclude=/media"
        echo "📁 Full system backup selected"
        ;;
    "incremental")
        LAST_BACKUP=$(find "$DESTINATION" -name "backup_*" -type d | sort | tail -1)
        if [ -n "$LAST_BACKUP" ]; then
            SOURCE_DIRS="/ --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run --exclude=/mnt --exclude=/media --compare-dest=$LAST_BACKUP"
            echo "📁 Incremental backup since: $(basename "$LAST_BACKUP")"
        else
            echo "⚠️  No previous backup found, performing full backup"
            SOURCE_DIRS="/ --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run --exclude=/mnt --exclude=/media"
        fi
        ;;
    "home")
        SOURCE_DIRS="/home"
        echo "📁 Home directory backup selected"
        ;;
    "config")
        SOURCE_DIRS="/etc /usr/local/etc"
        echo "📁 Configuration backup selected"
        ;;
esac

# Build exclude options
EXCLUDE_OPTS=""
if [ -n "$EXCLUDE_PATTERNS" ]; then
    IFS=',' read -ra PATTERNS <<< "$EXCLUDE_PATTERNS"
    for pattern in "${PATTERNS[@]}"; do
        EXCLUDE_OPTS="$EXCLUDE_OPTS --exclude=$pattern"
    done
    echo "🚫 Excluding patterns: $EXCLUDE_PATTERNS"
fi

echo ""
echo "📦 Creating backup..."

# Perform the backup using rsync
rsync -av --progress $COMPRESS_OPTS $EXCLUDE_OPTS $SOURCE_DIRS "$BACKUP_PATH/"

BACKUP_EXIT_CODE=$?

if [ $BACKUP_EXIT_CODE -eq 0 ]; then
    echo "✅ Backup completed successfully!"
    
    # Calculate backup size
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    echo "📊 Backup size: $BACKUP_SIZE"
    
    # Verify backup if requested
    if [ "$VERIFY_BACKUP" = "true" ]; then
        echo ""
        echo "🔍 Verifying backup integrity..."
        
        # Simple verification by comparing file counts
        if [ "$BACKUP_TYPE" = "home" ]; then
            ORIGINAL_COUNT=$(find /home -type f | wc -l)
            BACKUP_COUNT=$(find "$BACKUP_PATH" -type f | wc -l)
        elif [ "$BACKUP_TYPE" = "config" ]; then
            ORIGINAL_COUNT=$(find /etc -type f | wc -l)
            BACKUP_COUNT=$(find "$BACKUP_PATH" -type f | wc -l)
        else
            echo "ℹ️  Verification skipped for full/incremental backups (too time-consuming)"
            ORIGINAL_COUNT=0
            BACKUP_COUNT=0
        fi
        
        if [ $ORIGINAL_COUNT -gt 0 ] && [ $BACKUP_COUNT -gt 0 ]; then
            if [ $((ORIGINAL_COUNT - BACKUP_COUNT)) -le 10 ]; then
                echo "✅ Backup verification passed (file count: $BACKUP_COUNT)"
            else
                echo "⚠️  Backup verification warning: file count mismatch (original: $ORIGINAL_COUNT, backup: $BACKUP_COUNT)"
            fi
        fi
    fi
    
    # Create backup manifest
    echo "Creating backup manifest..."
    cat > "$BACKUP_PATH/backup_info.txt" << EOF
Backup Information
==================
Type: $BACKUP_TYPE
Created: $(date)
Hostname: $(hostname)
Size: $BACKUP_SIZE
Compression: $COMPRESSION
Exclude Patterns: $EXCLUDE_PATTERNS
Verification: $VERIFY_BACKUP
EOF
    
    # Send email notification if configured
    if [ -n "$EMAIL_NOTIFICATION" ] && command -v mail >/dev/null 2>&1; then
        echo "📧 Sending notification to $EMAIL_NOTIFICATION"
        echo "Backup completed successfully on $(hostname) at $(date). Size: $BACKUP_SIZE" | \
            mail -s "Backup Completed: $BACKUP_NAME" "$EMAIL_NOTIFICATION"
    elif [ -n "$EMAIL_NOTIFICATION" ]; then
        echo "⚠️  Email notification requested but 'mail' command not available"
    fi
    
    echo ""
    echo "🎉 Backup process completed successfully!"
    echo "📁 Backup location: $BACKUP_PATH"
    
else
    echo "❌ Backup failed with exit code: $BACKUP_EXIT_CODE"
    
    # Send failure notification if email configured
    if [ -n "$EMAIL_NOTIFICATION" ] && command -v mail >/dev/null 2>&1; then
        echo "Backup FAILED on $(hostname) at $(date). Exit code: $BACKUP_EXIT_CODE" | \
            mail -s "Backup FAILED: $BACKUP_NAME" "$EMAIL_NOTIFICATION"
    fi
    
    exit $BACKUP_EXIT_CODE
fi