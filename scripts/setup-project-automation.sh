#!/usr/bin/env bash
# Setup GitHub Project automation rules
# This creates workflows directly in the project settings

set -euo pipefail

PROJECT_NUMBER="${1:-17}"
REPO="${2:-JoshLuedeman/Valen}"

echo "Setting up project automation for project #$PROJECT_NUMBER in $REPO"

# Note: This requires the GitHub CLI and project access
# You'll need to run this manually or use the GitHub web UI

cat << 'EOF'
To set up native GitHub Project automation:

1. Go to your project: https://github.com/users/JoshLuedeman/projects/17
2. Click "Settings" (gear icon)
3. Go to "Workflows" section
4. Add these built-in workflows:

   📝 **Auto-add items:**
   - When: Issues and PRs are opened in JoshLuedeman/Valen
   - Then: Add to project with status "Backlog"

   🏷️ **Label-based status updates:**
   - When: Issue labeled with "committed" 
   - Then: Set status to "Committed"
   
   - When: Issue labeled with "in progress"
   - Then: Set status to "In Progress"
   
   - When: Issue labeled with "review" 
   - Then: Set status to "In Review"
   
   - When: Issue closed
   - Then: Set status to "Done"

   🔄 **Milestone sync:**
   - When: Issue milestone changed
   - Then: Update project fields accordingly

This provides native automation without needing GitHub Actions!
EOF
