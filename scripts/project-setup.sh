#!/usr/bin/env bash
# Create or configure a GitHub Projects v2 board with a "Status" field.
# No sed tricks; passes JSON options via GraphQL variable (-F).
# Bash-3 compatible. Uses gh api graphql.
#
# Usage:
#   ./scripts/project-setup.sh <owner|owner/repo> ["Valen Roadmap"] [--owner-type user|org] [--hostname github.com] [--debug]
#
set -euo pipefail

need() { command -v "$1" >/dev/null || { echo "Error: $1 not found"; exit 1; }; }
need gh
need jq

OWNER_ARG="${1:-}"
if [[ -z "${OWNER_ARG}" ]]; then
  echo "Usage: $0 <owner|owner/repo> [\"Valen Roadmap\"] [--owner-type user|org] [--hostname github.com] [--debug]"
  exit 1
fi
shift

TITLE="Valen Roadmap"
if [[ "${1:-}" != "" && "${1#--}" == "$1" ]]; then
  TITLE="$1"
  shift
fi

OWNER_TYPE=""     # "", "user", or "org"
HOSTNAME="github.com"
DEBUG="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner-type) OWNER_TYPE="${2:-}"; shift 2 ;;
    --hostname)   HOSTNAME="${2:-github.com}"; shift 2 ;;
    --debug)      DEBUG="true"; shift ;;
    *)            echo "Warning: unknown arg '$1' ignored" >&2; shift ;;
  esac
done

OWNER="${OWNER_ARG%%/*}"
say() { echo "$@"; }
dbg() { [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $*" || true; }

say "Using GitHub host: $HOSTNAME"
if [[ "$HOSTNAME" == "github.com" ]]; then gh auth status || true
else gh auth status --hostname "$HOSTNAME" || true
fi

gh_api() {
  if [[ "$HOSTNAME" == "github.com" ]]; then
    gh api graphql -f query="$1" "${@:2}"
  else
    gh api --hostname "$HOSTNAME" graphql -f query="$1" "${@:2}"
  fi
}

# --- Owner resolution helpers
resolve_user_id() { gh_api 'query($login:String!){ user(login:$login){ id login } }' -f login="$1"; }
resolve_org_id()  { gh_api 'query($login:String!){ organization(login:$login){ id login } }' -f login="$1"; }
viewer_id()       { gh_api 'query{ viewer{ id login } }'; }

OWNER_ID=""; RESOLVED_KIND=""
say "Resolving owner '$OWNER' as ${OWNER_TYPE:-user|org}…"
if [[ "$OWNER_TYPE" == "org" ]]; then
  R="$(resolve_org_id "$OWNER")"; dbg "ORG lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.organization.id // empty')"
  [[ -n "$OWNER_ID" ]] || { echo "Error: org '$OWNER' not found or token lacks read:org"; exit 1; }
  RESOLVED_KIND="ORG"
elif [[ "$OWNER_TYPE" == "user" ]]; then
  R="$(resolve_user_id "$OWNER")"; dbg "USER lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.user.id // empty')"
  if [[ -z "$OWNER_ID" ]]; then
    RV="$(viewer_id)"; dbg "VIEWER fallback: $RV"
    OWNER_ID="$(echo "$RV" | jq -r '.data.viewer.id // empty')"
    VLOGIN="$(echo "$RV" | jq -r '.data.viewer.login // empty')"
    [[ -n "$OWNER_ID" ]] || { echo "Error: could not resolve user or viewer id"; exit 1; }
    say "Warning: '$OWNER' did not resolve; using authenticated user '$VLOGIN' as owner."
  fi
  RESOLVED_KIND="USER"
else
  R="$(resolve_user_id "$OWNER")"; dbg "USER lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.user.id // empty')"
  if [[ -n "$OWNER_ID" ]]; then
    RESOLVED_KIND="USER"
  else
    R="$(resolve_org_id "$OWNER")"; dbg "ORG lookup: $R"
    OWNER_ID="$(echo "$R" | jq -r '.data.organization.id // empty')"
    if [[ -n "$OWNER_ID" ]]; then
      RESOLVED_KIND="ORG"
    else
      RV="$(viewer_id)"; dbg "VIEWER fallback: $RV"
      OWNER_ID="$(echo "$RV" | jq -r '.data.viewer.id // empty')"
      VLOGIN="$(echo "$RV" | jq -r '.data.viewer.login // empty')"
      [[ -n "$OWNER_ID" ]] || { echo "Error: could not resolve owner or viewer id"; exit 1; }
      say "Warning: '$OWNER' did not resolve; using authenticated user '$VLOGIN' as owner."
      RESOLVED_KIND="USER"
    fi
  fi
fi
say "Resolved owner kind: $RESOLVED_KIND"

# --- Create Project
CREATE_Q='
mutation($ownerId:ID!, $title:String!){
  createProjectV2(input:{ ownerId:$ownerId, title:$title }){
    projectV2{ id number title }
  }
}'
CP="$(gh_api "$CREATE_Q" -f ownerId="$OWNER_ID" -f title="$TITLE")" || { echo "Error: project creation failed"; echo "$CP"; exit 1; }
dbg "CREATE project: $CP"
PROJECT_ID="$(echo "$CP" | jq -r '.data.createProjectV2.projectV2.id // empty')"
PROJECT_NUMBER="$(echo "$CP" | jq -r '.data.createProjectV2.projectV2.number // empty')"
[[ -n "$PROJECT_ID" ]] || { echo "Error: missing project id"; echo "$CP"; exit 1; }
say "Project created: #$PROJECT_NUMBER — $TITLE"

# --- Find Status field
FIELDS_Q='
query($projectId:ID!){
  node(id:$projectId){
    ... on ProjectV2 {
      fields(first:50){
        nodes{
          __typename
          ... on ProjectV2FieldCommon { name }
          ... on ProjectV2SingleSelectField { id name options { id name } }
        }
      }
    }
  }
}'
FIELDS_RES="$(gh_api "$FIELDS_Q" -f projectId="$PROJECT_ID")"
dbg "FIELDS: $FIELDS_RES"
STATUS_FIELD_ID="$(echo "$FIELDS_RES" | jq -r '.data.node.fields.nodes[]? | select(.name=="Status") | .id // empty')"
[[ -n "$STATUS_FIELD_ID" ]] || { echo "Error: could not locate built-in Status field"; exit 1; }

# Desired options (JSON array, passed as a variable)
DESIRED='[
  {"name":"Backlog","color":"GRAY","description":"Not yet committed"},
  {"name":"Committed","color":"BLUE","description":"Planned and accepted"},
  {"name":"In Progress","color":"GREEN","description":"Being actively worked"},
  {"name":"In Review","color":"YELLOW","description":"Awaiting review/QA"},
  {"name":"Done","color":"PURPLE","description":"Completed"}
]'

# --- Attempt 1: Replace-all (if host supports the mutation)
REPLACE_Q='
mutation($projectId:ID!, $fieldId:ID!, $opts:[ProjectV2SingleSelectFieldOptionInput!]!){
  updateProjectV2SingleSelectField(input:{
    projectId:$projectId, fieldId:$fieldId, options:$opts
  }){
    projectV2SingleSelectField{ id name }
  }
}'
REPLACE_OK="false"
set +e
RF="$(gh_api "$REPLACE_Q" -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -F opts="$DESIRED" 2>/dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 && "$(echo "$RF" | jq -r '.errors | length // 0')" == "0" ]]; then
  REPLACE_OK="true"
  dbg "Replaced options via updateProjectV2SingleSelectField"
else
  dbg "Replace-all failed or unsupported on this host; falling back to per-option creation."
fi

# --- Attempt 2: Create any missing options one-by-one
if [[ "$REPLACE_OK" != "true" ]]; then
  # cache existing names from the latest fetch
  EXISTING_JSON="$(echo "$FIELDS_RES" | jq -c '.data.node.fields.nodes[]? | select(.name=="Status") | .options | map(.name)')"
  has_opt() {
    local name="$1"
    echo "$EXISTING_JSON" | jq -e --arg n "$name" 'index($n)' >/dev/null
  }
  create_opt() {
    local name="$1" color="$2" desc="$3"
    local Q1='mutation($projectId:ID!,$fieldId:ID!,$name:String!,$color:ProjectV2SingleSelectFieldOptionColor!,$desc:String!){
      createProjectV2SingleSelectFieldOption(input:{projectId:$projectId, fieldId:$fieldId, name:$name, color:$color, description:$desc}){
        projectV2SingleSelectFieldOption { id name }
      }
    }'
    local Q2='mutation($projectId:ID!,$fieldId:ID!,$name:String!,$color:ProjectV2SingleSelectFieldOptionColor!,$desc:String!){
      projectV2SingleSelectFieldOptionCreate(input:{projectId:$projectId, fieldId:$fieldId, name:$name, color:$color, description:$desc}){
        projectV2SingleSelectFieldOption { id name }
      }
    }'
    set +e
    L="$(gh_api "$Q1" -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -f name="$name" -f color="$color" -f desc="$desc" 2>/dev/null)"
    E=$?
    set -e
    if [[ $E -ne 0 || "$(echo "$L" | jq -r '.errors | length // 0')" != "0" ]]; then
      dbg "First create mutation failed; trying alternate name…"
      set +e
      L="$(gh_api "$Q2" -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -f name="$name" -f color="$color" -f desc="$desc" 2>/dev/null)"
      E=$?
      set -e
      if [[ $E -ne 0 || "$(echo "$L" | jq -r '.errors | length // 0')" != "0" ]]; then
        echo "Warning: could not create Status option '$name' (host API may not support creation)."
        dbg "Create error payload: $L"
        return 1
      fi
    fi
    dbg "Created option '$name'"
    # refresh EXISTING_JSON to include the new one
    EXISTING_JSON="$(echo "$EXISTING_JSON" | jq --arg n "$name" '. + [$n]')"
    return 0
  }

  echo "$DESIRED" | jq -c '.[]' | while read -r opt; do
    name="$(echo "$opt" | jq -r '.name')"
    color="$(echo "$opt" | jq -r '.color')"
    desc="$(echo "$opt" | jq -r '.description')"
    if has_opt "$name"; then
      dbg "Option '$name' already exists; skipping."
    else
      create_opt "$name" "$color" "$desc" || true
    fi
  done
fi

# Determine default status to suggest for population
DEFAULT_STATUS="Backlog"
if ! echo "$DESIRED" | jq -e 'map(.name) | index("Backlog")' >/dev/null; then
  DEFAULT_STATUS="Todo"
fi

say "Done. Project #$PROJECT_NUMBER is ready.
Status options are configured where supported. Populate with:
  ./scripts/project-populate.sh ${OWNER}/${OWNER_ARG#*/} $PROJECT_NUMBER $DEFAULT_STATUS ${HOSTNAME:+--hostname $HOSTNAME}
"