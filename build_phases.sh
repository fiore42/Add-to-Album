# Type a script or drag a script file from your workspace to insert its path.

#!/bin/sh

# Define your repository path
REPO_PATH="$SRCROOT"

# Define commit message
COMMIT_MSG="Auto-commit: $(date +'%Y-%m-%d %H:%M:%S')"

# Navigate to repo
cd "$REPO_PATH" || exit 1

# Check for changes
if [[ $(/opt/homebrew/bin/git status --porcelain) ]]; then
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

