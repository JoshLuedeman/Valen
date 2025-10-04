#!/usr/bin/env bash
# Populate a GitHub Project (Projects v2) with repo issues and set the "Status" field.
# Deterministic owner resolution (user vs org), Bash-3 compatible, robust JSON guards.
#
# Usage:
#   ./scripts/project-populate.sh <owner/repo> <project_number> [status_default]
#                                 [--owner-type user|org] [--hostname github.com] [--debug]
#
set -euo pipefail

need(){ command -v "$1" >/dev/null || { echo "Error: $1 not found"; exit 1; }; }
need gh; need jq

# ---------------------------
# Positional parsing
# ---------------------------
REPO="${1:-}"; PROJ_NUM="${2:-}"
if [[ -z "$REPO" || -z "$PROJ_NUM" ]]; then
  echo "Usage: $0 <owner/repo> <project_number> [status_default] [--owner-type user|org] [--hostname github.com] [--debug]"
  exit 1
fi
shift 2

# Optional 3rd positional: default status (only if not a flag)
DEFAULT_STATUS_ARG=""
if [[ "${1:-}" != "" && "${1#--}" == "$1" ]]; then
  DEFAULT_STATUS_ARG="$1"
  shift
fi

# ---------------------------
# Flags
# ---------------------------
OWNER_TYPE=""   # "", "user", or "org"
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

OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

say(){ echo "$@"; }
dbg(){ [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $*" || true; }

say "Using host: $HOSTNAME"
say "Repo: $OWNER/$NAME"
say "Project number: $PROJ_NUM"

gh_api(){
  if [[ "$HOSTNAME" == "github.com" ]]; then
    gh api graphql -f query="$1" "${@:2}"
  else
    gh api --hostname "$HOSTNAME" graphql -f query="$1" "${@:2}"
  fi
}

# ---- Owner resolvers
resolve_user(){ gh_api 'query($login:String!){ user(login:$login){ id login } }' -f login="$1"; }
resolve_org(){  gh_api 'query($login:String!){ organization(login:$login){ id login } }' -f login="$1"; }
viewer(){       gh_api 'query{ viewer{ id login } }'; }

OWNER_SCOPE=""   # USER or ORG
OWNER_ID=""

say "Resolving owner '$OWNER' as ${OWNER_TYPE:-user|org}…"
if [[ "$OWNER_TYPE" == "org" ]]; then
  R="$(resolve_org "$OWNER")"; dbg "ORG lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.organization.id // empty')"
  [[ -n "$OWNER_ID" ]] || { echo "Error: org '$OWNER' not found or token lacks read:org"; exit 1; }
  OWNER_SCOPE="ORG"
elif [[ "$OWNER_TYPE" == "user" ]]; then
  R="$(resolve_user "$OWNER")"; dbg "USER lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.user.id // empty')"
  if [[ -z "$OWNER_ID" ]]; then
    RV="$(viewer)"; dbg "VIEWER fallback: $RV"
    OWNER_ID="$(echo "$RV" | jq -r '.data.viewer.id // empty')"
    VLOGIN="$(echo "$RV" | jq -r '.data.viewer.login // empty')"
    [[ -n "$OWNER_ID" ]] || { echo "Error: could not resolve user or viewer id"; exit 1; }
    say "Warning: '$OWNER' did not resolve; using authenticated user '$VLOGIN' as owner."
    OWNER="$VLOGIN"
  fi
  OWNER_SCOPE="USER"
else
  R="$(resolve_user "$OWNER")"; dbg "USER lookup: $R"
  OWNER_ID="$(echo "$R" | jq -r '.data.user.id // empty')"
  if [[ -n "$OWNER_ID" ]]; then
    OWNER_SCOPE="USER"
  else
    R="$(resolve_org "$OWNER")"; dbg "ORG lookup: $R"
    OWNER_ID="$(echo "$R" | jq -r '.data.organization.id // empty')"
    if [[ -n "$OWNER_ID" ]]; then
      OWNER_SCOPE="ORG"
    else
      RV="$(viewer)"; dbg "VIEWER fallback: $RV"
      OWNER_ID="$(echo "$RV" | jq -r '.data.viewer.id // empty')"
      VLOGIN="$(echo "$RV" | jq -r '.data.viewer.login // empty')"
      [[ -n "$OWNER_ID" ]] || { echo "Error: could not resolve owner or viewer id"; exit 1; }
      say "Warning: '$OWNER' did not resolve; using authenticated user '$VLOGIN' as owner."
      OWNER_SCOPE="USER"; OWNER="$VLOGIN"
    fi
  fi
fi
say "Resolved owner scope: $OWNER_SCOPE"

# ---- Fetch project (separate queries for USER vs ORG)
if [[ "$OWNER_SCOPE" == "USER" ]]; then
  PJ_Q='query($owner:String!,$number:Int!){
    user(login:$owner){ projectV2(number:$number){ id number title
      fields(first:50){ nodes{
        __typename
        ... on ProjectV2FieldCommon { name }
        ... on ProjectV2SingleSelectField { id name options { id name } }
      }} } }
  }'
  PJ_RES="$(gh_api "$PJ_Q" -f owner="$OWNER" -F number="$PROJ_NUM")"
  PROJECT_ID="$(echo "$PJ_RES" | jq -r '.data.user.projectV2.id // empty')"
  PROJECT_TITLE="$(echo "$PJ_RES" | jq -r '.data.user.projectV2.title // empty')"
else
  PJ_Q='query($owner:String!,$number:Int!){
    organization(login:$owner){ projectV2(number:$number){ id number title
      fields(first:50){ nodes{
        __typename
        ... on ProjectV2FieldCommon { name }
        ... on ProjectV2SingleSelectField { id name options { id name } }
      }} } }
  }'
  PJ_RES="$(gh_api "$PJ_Q" -f owner="$OWNER" -F number="$PROJ_NUM")"
  PROJECT_ID="$(echo "$PJ_RES" | jq -r '.data.organization.projectV2.id // empty')"
  PROJECT_TITLE="$(echo "$PJ_RES" | jq -r '.data.organization.projectV2.title // empty')"
fi

[[ -n "$PROJECT_ID" ]] || { echo "Error: Could not find project #$PROJ_NUM for owner '$OWNER'"; exit 1; }
say "Project: $PROJECT_TITLE"

# Portable jq (no `objects`): walk JSON and pick first object with name=="Status"
STATUS_FIELD_JSON="$(echo "$PJ_RES" | jq -c '.. | select(type=="object") | select(has("name")) | select(.name=="Status")' | head -n1)"
[[ -n "$STATUS_FIELD_JSON" ]] || { echo "Error: Project is missing a 'Status' field. Run setup first."; exit 1; }
STATUS_FIELD_ID="$(echo "$STATUS_FIELD_JSON" | jq -r '.id // empty')"
[[ -n "$STATUS_FIELD_ID" ]] || { echo "Error: Could not read Status field id"; exit 1; }

# ---- Default status detection (Backlog vs Todo vs first option)
if [[ -n "$DEFAULT_STATUS_ARG" ]]; then
  DEFAULT_STATUS="$DEFAULT_STATUS_ARG"
else
  HAS_BACKLOG="$(echo "$STATUS_FIELD_JSON" | jq -r '[.options[]?.name] | index("Backlog") | tostring')"
  HAS_TODO="$(echo "$STATUS_FIELD_JSON" | jq -r '[.options[]?.name] | index("Todo") | tostring')"
  if [[ "$HAS_BACKLOG" != "null" && "$HAS_BACKLOG" != "" && "$HAS_BACKLOG" != "false" ]]; then
    DEFAULT_STATUS="Backlog"
  elif [[ "$HAS_TODO" != "null" && "$HAS_TODO" != "" && "$HAS_TODO" != "false" ]]; then
    DEFAULT_STATUS="Todo"
  else
    DEFAULT_STATUS="$(echo "$STATUS_FIELD_JSON" | jq -r '.options[0].name // "Backlog"')"
  fi
fi
say "Default Status: $DEFAULT_STATUS"

opt_id_for(){
  local name="$1"
  echo "$STATUS_FIELD_JSON" | jq -r --arg n "$name" '.options[]? | select(.name==$n) | .id // empty'
}
DEFAULT_OPT_ID="$(opt_id_for "$DEFAULT_STATUS")"

# ---- Handle missing status option
if [[ -z "$DEFAULT_OPT_ID" ]]; then
  say "Status option '$DEFAULT_STATUS' not found. Trying to create it..."
  
  create_status_option() {
    local name="$1" color="${2:-GRAY}" desc="${3:-}"
    
    # Try the primary mutation name first
    local Q1='mutation($projectId:ID!,$fieldId:ID!,$name:String!,$color:ProjectV2SingleSelectFieldOptionColor!,$desc:String!){
      createProjectV2SingleSelectFieldOption(input:{projectId:$projectId, fieldId:$fieldId, name:$name, color:$color, description:$desc}){
        projectV2SingleSelectFieldOption { id name }
      }
    }'
    
    set +e
    local result
    result="$(gh_api "$Q1" -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -f name="$name" -f color="$color" -f desc="$desc" 2>/dev/null)"
    local exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 && "$(echo "$result" | jq -r '.errors | length // 0')" == "0" ]]; then
      say "Created Status option: $name"
      return 0
    else
      dbg "Create mutation failed: $result"
      return 1
    fi
  }
  
  # Try to create the option, but fall back gracefully if it fails
  if create_status_option "$DEFAULT_STATUS" "GRAY" "Not yet committed"; then
    # Refresh the status field JSON to include the new option
    if [[ "$OWNER_SCOPE" == "USER" ]]; then
      PJ_RES="$(gh_api "$PJ_Q" -f owner="$OWNER" -F number="$PROJ_NUM")"
    else
      PJ_RES="$(gh_api "$PJ_Q" -f owner="$OWNER" -F number="$PROJ_NUM")"
    fi
    STATUS_FIELD_JSON="$(echo "$PJ_RES" | jq -c '.. | select(type=="object") | select(has("name")) | select(.name=="Status")' | head -n1)"
    DEFAULT_OPT_ID="$(opt_id_for "$DEFAULT_STATUS")"
  else
    # Creation failed, fall back to first available option
    say "Warning: Could not create '$DEFAULT_STATUS' option (API limitation). Using first available option instead."
    AVAILABLE_OPTIONS="$(echo "$STATUS_FIELD_JSON" | jq -r '.options[].name' | head -5 | tr '\n' ', ' | sed 's/,$//')"
    say "Available options: $AVAILABLE_OPTIONS"
    DEFAULT_STATUS="$(echo "$STATUS_FIELD_JSON" | jq -r '.options[0].name // "Todo"')"
    DEFAULT_OPT_ID="$(opt_id_for "$DEFAULT_STATUS")"
    say "Using fallback status: $DEFAULT_STATUS"
  fi
fi

[[ -n "$DEFAULT_OPT_ID" ]] || { echo "Error: Could not resolve default status '$DEFAULT_STATUS' option id"; exit 1; }

# ---- Label → Status mapping
status_for_labels(){
  local labels="$1"
  shopt -s nocasematch
  if [[ "$labels" =~ committed ]]; then echo "Committed"; return; fi
  if [[ "$labels" =~ in[[:space:]]progress ]]; then echo "In Progress"; return; fi
  if [[ "$labels" =~ review ]]; then echo "In Review"; return; fi
  if [[ "$labels" =~ done ]]; then echo "Done"; return; fi
  echo "$DEFAULT_STATUS"
}

# ---- Paginate open issues
END_CURSOR=""
HAS_NEXT="true"
ADDED=0

while [[ "$HAS_NEXT" == "true" ]]; do
  ISSUES_Q='
  query($owner:String!,$name:String!,$cursor:String){
    repository(owner:$owner,name:$name){
      issues(states:OPEN, first:100, after:$cursor){
        nodes{
          id number title
          labels(first:50){ nodes{ name } }
          projectItems(first:50){ nodes { id project { number } } }
        }
        pageInfo{ hasNextPage endCursor }
      }
    }
  }'
  if [[ -z "$END_CURSOR" ]]; then
    PAGE="$(gh_api "$ISSUES_Q" -f owner="$OWNER" -f name="$NAME")"
  else
    PAGE="$(gh_api "$ISSUES_Q" -f owner="$OWNER" -f name="$NAME" -F cursor="$END_CURSOR")"
  fi

  HAS_NEXT="$(echo "$PAGE" | jq -r '.data.repository.issues.pageInfo.hasNextPage // false')"
  END_CURSOR="$(echo "$PAGE" | jq -r '.data.repository.issues.pageInfo.endCursor // empty')"

  # Process issues in current process to preserve ADDED counter
  while IFS= read -r issue; do
    ISSUE_ID="$(echo "$issue"  | jq -r '.id // empty')"
    ISSUE_NUM="$(echo "$issue" | jq -r '.number // 0')"
    LABELS="$(echo "$issue" | jq -r '((.labels.nodes // []) | map(.name // "")) | join(",")')"

    STATUS_NAME="$(status_for_labels "$LABELS")"
    OPT_ID="$(opt_id_for "$STATUS_NAME")"
    if [[ -z "$OPT_ID" ]]; then STATUS_NAME="$DEFAULT_STATUS"; OPT_ID="$DEFAULT_OPT_ID"; fi

    ITEM_ID="$(echo "$issue" | jq -r --arg pn "$PROJ_NUM" '
      (.projectItems.nodes // [])[]? | select(.project.number == ($pn|tonumber)) | .id // empty
    ')"

    if [[ -z "$ITEM_ID" && -n "$ISSUE_ID" ]]; then
      ADD_MUT='mutation($projectId:ID!, $contentId:ID!){
        addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}){ item{ id } }
      }'
      ADD_RES="$(gh_api "$ADD_MUT" -f projectId="$PROJECT_ID" -f contentId="$ISSUE_ID" || true)"
      ITEM_ID="$(echo "$ADD_RES" | jq -r '.data.addProjectV2ItemById.item.id // empty')"
    fi

    if [[ -z "$ITEM_ID" ]]; then
      echo "Warning: Skipping issue #$ISSUE_NUM (no project item id)"; continue
    fi

    SET_MUT='mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optId:String!){
      updateProjectV2ItemFieldValue(input:{
        projectId:$projectId, itemId:$itemId, fieldId:$fieldId,
        value:{ singleSelectOptionId:$optId }
      }){ projectV2Item { id } }
    }'
    gh_api "$SET_MUT" -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$STATUS_FIELD_ID" -f optId="$OPT_ID" >/dev/null
    echo "Added/updated issue #$ISSUE_NUM → Status='$STATUS_NAME'"
    ADDED=$((ADDED+1))
  done < <(echo "$PAGE" | jq -c '.data.repository.issues.nodes[]? // empty')
done

say "Done. Processed $ADDED open issues from $OWNER/$NAME."