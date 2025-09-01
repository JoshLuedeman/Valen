#!/usr/bin/env bash
# Add all open issues from a repo into a GitHub Project and set Status defaults.
# Usage: ./scripts/project-populate.sh <owner/repo> <project_number> [status_default]
# Example: ./scripts/project-populate.sh yourname/assistant 1 Backlog
set -euo pipefail

REPO="${1:-}"
NUMBER="${2:-}"
DEFAULT_STATUS="${3:-Backlog}"

if [[ -z "$REPO" || -z "$NUMBER" ]]; then
  echo "Usage: $0 <owner/repo> <project_number> [status_default]"
  exit 1
fi

# Resolve project ID from number
OWNER="${REPO%%/*}"
PROJECT_ID=$(gh project view $NUMBER --owner "$OWNER" --format json | jq -r '.id')

# Find Status field ID
STATUS_FIELD_ID=$(gh project view $NUMBER --owner "$OWNER" --format json | jq -r '.fields[] | select(.name=="Status") | .id')
if [[ -z "$STATUS_FIELD_ID" ]]; then
  echo "Status field not found; run project-setup.sh first."
  exit 1
fi

# Map label shortcuts to Status, else default
function status_for() {
  labels="$1"
  if echo "$labels" | grep -qi "committed"; then echo "Committed"; return; fi
  if echo "$labels" | grep -qi "in progress"; then echo "In Progress"; return; fi
  if echo "$labels" | grep -qi "review"; then echo "In Review"; return; fi
  if echo "$labels" | grep -qi "done"; then echo "Done"; return; fi
  echo "$DEFAULT_STATUS"
}

# Add items and set Status
issues=$(gh issue list --repo "$REPO" --state open --limit 500 --json number,title,labels | jq -c '.[]')
for row in $issues; do
  num=$(echo "$row" | jq -r '.number')
  labels=$(echo "$row" | jq -r '[.labels[].name] | join(",")')
  status=$(status_for "$labels")

  ITEM_ID=$(gh project item-add $NUMBER --owner "$OWNER" --url "https://github.com/$REPO/issues/$num" --format json | jq -r '.id')
  # Find the option ID matching our status text
  OPTION_ID=$(gh project view $NUMBER --owner "$OWNER" --format json | jq -r --arg s "$status" '.fields[] | select(.name=="Status") | .options[] | select(.name==$s) | .id')
  gh project item-edit --id "$ITEM_ID" --field-id "$STATUS_FIELD_ID" --single-select-option-id "$OPTION_ID"
  echo "Added issue #$num with Status=$status"
done

echo "Done. Open the project board to view items grouped by Status."
