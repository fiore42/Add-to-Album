#!/bin/sh

# Define your repository path
REPO_PATH="$SRCROOT"

# Define commit message file paths
COMMIT_MSG_FILE="$REPO_PATH/commit_message.txt"
OLD_COMMIT_MSG_FILE="$REPO_PATH/commit_message.old"

# Default commit message
COMMIT_MSG="Auto-commit: $(date +'%Y-%m-%d %H:%M:%S')"

# Navigate to repo
cd "$REPO_PATH" || exit 1

# Determine commit message
if [ -f "$COMMIT_MSG_FILE" ]; then
    # Check if the file is empty (only spaces or newlines)
    if [ -s "$COMMIT_MSG_FILE" ] && grep -q '[^[:space:]]' "$COMMIT_MSG_FILE"; then
        # If present and not empty, check against commit_message.old
        if [ -f "$OLD_COMMIT_MSG_FILE" ] && cmp -s "$COMMIT_MSG_FILE" "$OLD_COMMIT_MSG_FILE"; then
            COMMIT_MSG="Auto-commit: $(date +'%Y-%m-%d %H:%M:%S')"
        else
            # Use the first line as the commit message and update commit_message.old
            COMMIT_MSG=$(head -n 1 "$COMMIT_MSG_FILE")
            cp "$COMMIT_MSG_FILE" "$OLD_COMMIT_MSG_FILE"
        fi
    fi
fi

# Check for changes
if /opt/homebrew/bin/git status --porcelain | grep -q .; then
    echo "🔄 Changes detected, committing..."
    # Add all changes
    git add .
    # Commit the changes
    git commit -m "$COMMIT_MSG"
    # Push to GitHub
    git push origin main # Change 'main' to your default branch if needed
    echo "✅ Code successfully pushed to GitHub."
else
    echo "✅ No changes detected. Nothing to commit."
fi
