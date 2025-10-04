#!/usr/bin/env bash
# Create GitHub milestones and issues from a JSON config, auto-creating labels as needed.
# Requirements: gh, jq
#
# Usage:
#   ./scripts/create-milestone-issues.sh <owner/repo> <config.json>
#       [--assignee <user>] [--label <Label1,Label2>] [--dry-run] [--hostname <host>]
#
# Config JSON shape:
# {
#   "milestones":[
#     {
#       "title":"M0: Repo + ADRs",
#       "description":"Scaffold repo, ADR boilerplate, automation",
#       "due_on":"2025-09-30T23:59:59Z",
#       "issues":[
#         {"title":"Scaffold repo", "body":"Create base dirs and templates", "labels":["infra"]},
#         {"title":"ADR: Decision Records framework", "body":"Adopt MADR; add template", "labels":["adr"]}
#       ]
#     }
#   ]
# }
set -euo pipefail

need(){ command -v "$1" >/dev/null || { echo "Error: $1 not found"; exit 1; }; }
need gh; need jq

REPO="${1:-}"; CONFIG="${2:-}"
if [[ -z "$REPO" || -z "$CONFIG" ]]; then
  echo "Usage: $0 <owner/repo> <config.json> [--assignee <user>] [--label <Label1,Label2>] [--dry-run] [--hostname <host>]"
  exit 1
fi
shift 2

ASSIGNEE=""
EXTRA_LABELS=""
DRY_RUN="false"
HOSTNAME="github.com"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assignee) ASSIGNEE="${2:-}"; shift 2 ;;
    --label)    EXTRA_LABELS="${2:-}"; shift 2 ;;   # comma-separated
    --dry-run)  DRY_RUN="true"; shift ;;
    --hostname) HOSTNAME="${2:-github.com}"; shift 2 ;;
    *) echo "Warning: unknown arg '$1' ignored" >&2; shift ;;
  esac
done

OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

api(){
  if [[ "$HOSTNAME" == "github.com" ]]; then
    gh api "$@"
  else
    gh api --hostname "$HOSTNAME" "$@"
  fi
}

say(){ echo "$@"; }

# --- Load and sanity-check config
[[ -f "$CONFIG" ]] || { echo "Error: config file not found: $CONFIG"; exit 1; }
jq -e . "$CONFIG" >/dev/null 2>&1 || { echo "Error: config is not valid JSON"; exit 1; }

MCOUNT="$(jq -r '.milestones | length' "$CONFIG")"
[[ "$MCOUNT" != "null" && "$MCOUNT" -gt 0 ]] || { echo "Error: config has no milestones"; exit 1; }

say "Repo: $REPO"
say "Milestones in config: $MCOUNT"
[[ "$DRY_RUN" == "true" ]] && say "(dry run) will not POST to GitHub"

# --- Labels helpers (list existing, ensure missing get created)
EXISTING_LABELS_JSON="[]"

refresh_labels(){
  # paginate labels (max 100 per page)
  local page=1 all="[]"
  while : ; do
    local chunk
    chunk="$(api -X GET "/repos/$OWNER/$NAME/labels?per_page=100&page=$page" 2>/dev/null || echo '[]')"
    # stop if empty
    if [[ "$(echo "$chunk" | jq 'length')" -eq 0 ]]; then break; fi
    all="$(jq -c --argjson a "$all" --argjson b "$chunk" '$a + $b' <<< '{}')" 2>/dev/null || all="$(jq -c '. + []' <<<"$all")"
    # simpler: concat via jq:
    all="$(jq -c --argjson b "$chunk" '. + $b' <<<"$all")"
    page=$((page+1))
  done
  EXISTING_LABELS_JSON="$all"
}

label_exists(){
  local name="$1"
  echo "$EXISTING_LABELS_JSON" | jq -e --arg n "$name" '.[] | select(.name==$n)' >/dev/null
}

# choose a deterministic color (hex without '#') for unknown labels
color_for_label(){
  local label_lower
  label_lower="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  case "$label_lower" in
    infra) echo "4b5563" ;;       # gray-600
    adr) echo "2563eb" ;;         # blue-600
    ci) echo "22c55e" ;;          # green-500
    client) echo "9333ea" ;;      # purple-600
    agent) echo "0891b2" ;;       # cyan-600
    mcp|tools) echo "d97706" ;;   # amber-600
    hub) echo "7c3aed" ;;         # violet-600
    sync) echo "f59e0b" ;;        # amber-500
    embeddings) echo "0ea5e9" ;;  # sky-600
    automation) echo "ef4444" ;;  # red-500
    security|privacy) echo "111827" ;; # almost black
    voice) echo "e11d48" ;;       # rose-600
    *) echo "ededed" ;;           # light gray default
  esac
}

ensure_label(){
  local name="$1"
  [[ -n "$name" ]] || return 0
  if label_exists "$name"; then
    return 0
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY: would create label '$name'"
    return 0
  fi
  local color; color="$(color_for_label "$name")"
  api -X POST "/repos/$OWNER/$NAME/labels" \
      -f name="$name" \
      -f color="$color" \
      -f description="Created by milestone-issues bootstrap" >/dev/null || {
        echo "Warning: failed to create label '$name' (may already exist or insufficient perms)"; return 0;
      }
  # refresh cache
  refresh_labels
}

ensure_labels_csv(){
  local csv="$1"
  IFS=',' read -r -a arr <<< "$csv"
  for raw in "${arr[@]}"; do
    # trim whitespace
    local n="$(echo "$raw" | awk '{$1=$1;print}')"
    [[ -n "$n" ]] && ensure_label "$n"
  done
}

refresh_labels

# --- Milestones: fetch existing to reuse numbers
EXISTING_MS="$(api -X GET "/repos/$OWNER/$NAME/milestones?state=all" 2>/dev/null || echo '[]')"

milestone_number_for_title(){
  local title="$1"
  echo "$EXISTING_MS" | jq -r --arg t "$title" '.[] | select(.title==$t) | .number' | head -n1
}

create_milestone(){
  local title="$1" desc="$2" due="$3"

  if [[ -z "$title" ]]; then
    echo "Error: milestone title is empty"; return 1
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY: create milestone '$title' due=$due"
    echo "0"; return 0
  fi

  # https://docs.github.com/rest/issues/milestones#create-a-milestone
  if [[ -n "$due" && "$due" != "null" ]]; then
    api -X POST "/repos/$OWNER/$NAME/milestones" \
      -f title="$title" -f description="$desc" -f due_on="$due" \
      | jq -r '.number'
  else
    api -X POST "/repos/$OWNER/$NAME/milestones" \
      -f title="$title" -f description="$desc" \
      | jq -r '.number'
  fi
}

create_issue(){
  local title="$1" body="$2" labels_csv="$3" ms_number="$4" ms_title="$5"

  # Merge issue labels + global EXTRA_LABELS
  local merged="$labels_csv"
  if [[ -n "$EXTRA_LABELS" ]]; then
    if [[ -n "$merged" ]]; then merged="$merged,$EXTRA_LABELS"; else merged="$EXTRA_LABELS"; fi
  fi

  # Ensure labels exist before creating the issue
  if [[ -n "$merged" ]]; then ensure_labels_csv "$merged"; fi

  local args=(-R "$REPO" -t "$title" -b "$body")
  if [[ -n "$merged" ]]; then args+=(-l "$merged"); fi
  if [[ -n "$ASSIGNEE" ]]; then args+=(-a "$ASSIGNEE"); fi
  
  # Try using milestone title first, fall back to number if that fails
  if [[ "$ms_number" != "0" && "$ms_number" != "" ]]; then
    if [[ -n "$ms_title" ]]; then
      args+=(-m "$ms_title")
    else
      args+=(-m "$ms_number")
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY: gh issue create ${args[*]}"
  else
    gh issue create "${args[@]}" >/dev/null
    echo "Created issue: $title"
  fi
}

# --- Iterate milestones
for idx in $(jq -r '.milestones | to_entries[] | .key' "$CONFIG"); do
  MTITLE="$(jq -r ".milestones[$idx].title" "$CONFIG")"
  MDESC="$(jq -r ".milestones[$idx].description // \"\"" "$CONFIG")"
  MDUE="$(jq -r ".milestones[$idx].due_on // empty" "$CONFIG")"
  say "Processing milestone: $MTITLE"

  NUM="$(milestone_number_for_title "$MTITLE")"
  if [[ -z "$NUM" ]]; then
    say "  Milestone does not exist; creating…"
    NUM="$(create_milestone "$MTITLE" "$MDESC" "$MDUE")"
    [[ "$NUM" == "0" ]] && say "  (dry run) milestone '$MTITLE' would be created"
    # refresh list so later lookups see it
    EXISTING_MS="$(api -X GET "/repos/$OWNER/$NAME/milestones?state=all" 2>/dev/null || echo '[]')"
  else
    say "  Milestone exists (#$NUM); will reuse"
  fi

  ICOUNT="$(jq -r ".milestones[$idx].issues | length" "$CONFIG")"
  if [[ "$ICOUNT" == "null" || "$ICOUNT" -eq 0 ]]; then
    say "  No issues listed."
    continue
  fi

  for j in $(jq -r ".milestones[$idx].issues | to_entries[] | .key" "$CONFIG"); do
    ITITLE="$(jq -r ".milestones[$idx].issues[$j].title" "$CONFIG")"
    IBODY="$(jq -r ".milestones[$idx].issues[$j].body // \"\"" "$CONFIG")"

    TASKS="$(jq -r ".milestones[$idx].issues[$j].tasks // empty" "$CONFIG")"
    if [[ -n "$TASKS" && "$TASKS" != "null" ]]; then
      CHECKS="$(echo "$TASKS" | jq -r '.[] | "- [ ] " + .' )"
      IBODY="$IBODY"$'\n\n'"### Tasks"$'\n'"$CHECKS"
    fi

    ILABELS="$(jq -r ".milestones[$idx].issues[$j].labels // [] | join(\",\")" "$CONFIG")"
    create_issue "$ITITLE" "$IBODY" "$ILABELS" "$NUM" "$MTITLE"
  done
done

say "Done."