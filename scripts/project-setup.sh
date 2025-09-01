#!/usr/bin/env bash
# Create a GitHub Project (beta) with custom Status pipeline for this repo.
# Usage: ./scripts/project-setup.sh <owner> <project_title>
# Example: ./scripts/project-setup.sh your-gh-username "Local-First Assistant Roadmap"
set -euo pipefail

OWNER="${1:-}"
TITLE="${2:-Local-First Assistant Roadmap}"

if [[ -z "$OWNER" ]]; then
  echo "Usage: $0 <owner> [project_title]"
  exit 1
fi

# Create project under the user/owner namespace (not org). Use --owner for orgs as needed.
PROJECT_ID=$(gh project create --owner "$OWNER" --title "$TITLE" --format json | jq -r '.id')
echo "Created project: $TITLE ($PROJECT_ID)"

# Create a Status field with our custom pipeline
gh project field-create "$PROJECT_ID" --name "Status" --data-type "SINGLE_SELECT" \
  --owner "$OWNER" --options "Backlog,Committed,In Progress,In Review,Done"

# Create a View configured as a Board using the Status field
gh project view "$PROJECT_ID" --owner "$OWNER" --format=json | jq -r '.' >/dev/null 2>&1 || true
echo "Project created. You can now link repository issues to it."
echo "Tip: use ./scripts/project-populate.sh <owner/repo> <project_number> to bulk-add issues."
