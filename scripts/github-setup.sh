#!/usr/bin/env bash
# Requires GitHub CLI: https://cli.github.com/ (gh auth login)
set -euo pipefail

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "Usage: scripts/github-setup.sh <owner/repo>"
  exit 1
fi

# Create labels
cat .github/labels.json | jq -c '.[]' | while read -r lbl; do
  name=$(echo "$lbl" | jq -r .name)
  color=$(echo "$lbl" | jq -r .color)
  gh label create "$name" --color "$color" --force --repo "$REPO" || true
done

# Create milestones
gh milestone create "Milestone 0: Bootstrap & Policies" --repo "$REPO" || true
gh milestone create "Milestone 1: Single-device offline Q&A" --repo "$REPO" || true
gh milestone create "Milestone 2: Hub skeleton + Hub-Embeds" --repo "$REPO" || true
gh milestone create "Milestone 3: Egress tools & caching" --repo "$REPO" || true
gh milestone create "Milestone 4: PA/Ops + Coder" --repo "$REPO" || true
gh milestone create "Optional: Voice I/O + Speaker Verification" --repo "$REPO" || true

echo "GitHub labels and milestones created for $REPO"
