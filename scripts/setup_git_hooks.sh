#!/bin/bash
#MN Setup Git Hooks
#MD Setup Git hooks for automatic documentation generation
#MDD Installs Git pre-commit and post-commit hooks that automatically generate documentation when scripts are modified. Ensures documentation stays in sync with script changes.
#MI SystemUtilities
#INFO https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
#MICON 🔗
#MCOLOR Z2
#MORDER 6

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔗 Setting up Git Hooks for Documentation"
echo "========================================="
echo "📁 Project Root: $PROJECT_ROOT"
echo "🪝 Hooks Directory: $HOOKS_DIR"
echo ""

if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not in a Git repository"
    echo "   Please run this script from the project root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
echo "📝 Creating pre-commit hook..."
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for toolbox documentation generation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "🔍 Pre-commit: Checking for script changes..."

# Check if any .sh files are being committed
if git diff --cached --name-only | grep -q '\.sh$'; then
    echo "📚 Script files detected, generating documentation..."
    
    # Generate documentation
    if [ -x "$PROJECT_ROOT/scripts/generate_documentation.sh" ]; then
        cd "$PROJECT_ROOT"
        ./scripts/generate_documentation.sh
        
        # Add generated docs to commit if they changed
        if [ -n "$(git status --porcelain docs/)" ]; then
            echo "📄 Adding updated documentation to commit..."
            git add docs/
            echo "✅ Documentation updated and added to commit"
        else
            echo "ℹ️  Documentation unchanged"
        fi
    else
        echo "⚠️  Documentation generator not found, skipping..."
    fi
else
    echo "ℹ️  No script changes detected, skipping documentation generation"
fi

echo "✅ Pre-commit checks complete"
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Pre-commit hook installed"

# Create post-commit hook for additional processing
echo "📝 Creating post-commit hook..."
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Post-commit hook for toolbox documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "🔄 Post-commit: Processing documentation..."

# Check if docs were updated in the last commit
if git diff --name-only HEAD~1 HEAD | grep -q '^docs/'; then
    echo "📚 Documentation was updated in this commit"
    
    # Optional: Run additional post-processing
    # For example, update README timestamps, validate links, etc.
    
    echo "✅ Post-commit processing complete"
else
    echo "ℹ️  No documentation changes in this commit"
fi
EOF

chmod +x "$HOOKS_DIR/post-commit"
echo "✅ Post-commit hook installed"

# Create commit-msg hook for enhanced commit messages
echo "📝 Creating commit-msg hook..."
cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash
# Commit message hook for toolbox

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Check if this is a documentation auto-update
if echo "$COMMIT_MSG" | grep -q "📚 Auto-update documentation"; then
    # This is an auto-generated documentation commit, allow it
    exit 0
fi

# Check if script files are being committed
if git diff --cached --name-only | grep -q '\.sh$'; then
    # Add a note about documentation auto-update if not already present
    if ! echo "$COMMIT_MSG" | grep -q "documentation"; then
        echo "" >> "$COMMIT_MSG_FILE"
        echo "📚 Documentation will be auto-updated" >> "$COMMIT_MSG_FILE"
    fi
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/commit-msg"
echo "✅ Commit-msg hook installed"

# Create prepare-commit-msg hook for automatic commit message enhancement
echo "📝 Creating prepare-commit-msg hook..."
cat > "$HOOKS_DIR/prepare-commit-msg" << 'EOF'
#!/bin/bash
# Prepare commit message hook

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"
SHA1="$3"

# Only enhance the message for regular commits (not merges, etc.)
if [ "$COMMIT_SOURCE" = "message" ] || [ -z "$COMMIT_SOURCE" ]; then
    # Check what types of files are being committed
    SCRIPT_FILES=$(git diff --cached --name-only | grep '\.sh$' | wc -l)
    DOC_FILES=$(git diff --cached --name-only | grep '\.md$' | wc -l)
    
    if [ "$SCRIPT_FILES" -gt 0 ]; then
        # Add script change indicator
        CURRENT_MSG=$(cat "$COMMIT_MSG_FILE")
        if [ -n "$CURRENT_MSG" ] && ! echo "$CURRENT_MSG" | grep -q "^#"; then
            # Add emoji and context if not already a comment-only message
            if ! echo "$CURRENT_MSG" | grep -q "🛠️\|📝\|🔧\|⚙️\|🚀"; then
                echo "🛠️ $CURRENT_MSG" > "$COMMIT_MSG_FILE"
            fi
        fi
    fi
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/prepare-commit-msg"
echo "✅ Prepare-commit-msg hook installed"

# Test the hooks
echo ""
echo "🧪 Testing Git Hooks"
echo "-------------------"

# Test if hooks are executable
for hook in pre-commit post-commit commit-msg prepare-commit-msg; do
    if [ -x "$HOOKS_DIR/$hook" ]; then
        echo "✅ $hook: executable"
    else
        echo "❌ $hook: not executable"
    fi
done

# Create a simple test to verify the documentation generator works
echo ""
echo "🔍 Testing Documentation Generator"
echo "--------------------------------"

if [ -x "$PROJECT_ROOT/scripts/generate_documentation.sh" ]; then
    echo "✅ Documentation generator is executable"
    
    # Test run (dry run style check)
    if [ -x "$PROJECT_ROOT/scripts/extract_script_metadata.sh" ]; then
        echo "✅ Metadata extractor is executable"
        echo "🧪 Running quick test..."
        
        # Test metadata extraction on this script
        if "$PROJECT_ROOT/scripts/extract_script_metadata.sh" single "$0" "scripts/$(basename "$0")" >/dev/null 2>&1; then
            echo "✅ Metadata extraction test passed"
        else
            echo "⚠️  Metadata extraction test failed (non-critical)"
        fi
    else
        echo "❌ Metadata extractor not found or not executable"
    fi
else
    echo "❌ Documentation generator not found or not executable"
    echo "   Please ensure scripts/generate_documentation.sh exists and is executable"
fi

echo ""
echo "📋 Git Hook Summary"
echo "==================="
echo "✅ Pre-commit: Auto-generate docs when .sh files change"
echo "✅ Post-commit: Process documentation after commit"
echo "✅ Commit-msg: Enhance commit messages"
echo "✅ Prepare-commit-msg: Add context to commit messages"
echo ""
echo "🔄 How it works:"
echo "1. When you commit .sh files, pre-commit hook runs"
echo "2. Documentation is automatically generated"
echo "3. Updated docs are added to your commit"
echo "4. Commit message is enhanced with context"
echo "5. Post-commit processing runs if needed"
echo ""
echo "💡 Manual documentation generation:"
echo "   ./scripts/generate_documentation.sh"
echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "⚠️  Note: These are local hooks. For team collaboration,"
echo "   consider using the GitHub Actions workflow instead."