#!/usr/bin/env bash
# dispatch-selector-open-child-prefilter.sh — pre-filter parent beads with
# open children or open rework siblings BEFORE dispatch
#
# Surfaced by INCIDENTS.md "parent-redispatched-before-open-child-complete"
# (2026-05-09) and tracked at flywheel-hm9ml. The close-time gate at
# .flywheel/scripts/validate-callback-before-close.sh:425 (open_child_blocks_close)
# IS in place, but it fires AFTER the worker has already done parent-research.
# This pre-filter catches the misroute at the SELECTION layer so worker time
# isn't wasted on parents whose acceptance gates depend on open children.
#
# Per INCIDENTS:
#   "Before dispatching a parent bead for closure verification, the selector
#    must check (a) `br dep tree <bead>` for open children — if any child is
#    `open` or `in_progress`, route the dispatch to the highest-priority open
#    child instead; (b) open rework beads via the heuristic
#    `br list --status open --search '<parent-bead-id>'` (rework beads
#    typically include the parent's id in their title)."
#
# Usage:
#   dispatch-selector-open-child-prefilter.sh BEAD_ID [--json]
#     Emit dispatchability decision for one bead.
#   dispatch-selector-open-child-prefilter.sh --filter-list [--json]
#     Read JSON array of bead objects from stdin; emit filtered list to stdout
#     where each row has `dispatchable: true|false` plus reason fields.
#   dispatch-selector-open-child-prefilter.sh --doctor [--json]
#     Self-check: br is callable, REPO is git, schema-output works.
#   dispatch-selector-open-child-prefilter.sh --schema | --info | --examples | --help
#
# Stable exit codes:
#   0 — ok (single-bead: dispatchable; filter-list: at least one row emitted)
#   1 — not dispatchable (single-bead mode only)
#   2 — config / env error (br missing, REPO not a git repo)
#   64 — usage error

set -euo pipefail

VERSION="dispatch-selector-open-child-prefilter.v1"
REPO="${REPO:-/Users/josh/Developer/flywheel}"
BR_BIN="${BR_BIN:-br}"
JSON_OUT=0
COMMAND=""
ARG_BEAD=""

usage() {
  cat <<'USAGE'
usage: dispatch-selector-open-child-prefilter.sh BEAD_ID [--json]
       dispatch-selector-open-child-prefilter.sh --filter-list [--json] < ready_beads.json
       dispatch-selector-open-child-prefilter.sh --doctor|--health|--info|--schema|--examples [--json]

Per-bead dispatchability:
  dispatchable=true  → no open children/rework; safe to dispatch as-is
  dispatchable=false → open children and/or rework; route to highest-priority
                       open dependent instead (`next_actionable` field)

Surfaced by INCIDENTS parent-redispatched-before-open-child-complete + flywheel-hm9ml.
USAGE
}

info_block() {
  cat <<'EOF'
This pre-filter solves the parent-redispatched-before-open-child-complete
trauma class (3 events on 2026-05-05) by checking dispatchability BEFORE the
worker spends time on parent-research.

Two checks:
  1. `br dep tree <bead>`  →  any child OPEN/IN_PROGRESS?
  2. `br list --status open --search <bead>` → any sibling rework with the
     parent's id in its title?

If either fires, the parent dispatch is preempted and the next-actionable
(highest-priority open child or rework) is named in the output.

The close-time `open_child_blocks_close` gate (validate-callback-before-close.sh:425)
remains as the safety net, but rarely fires when the selector pre-filter is wired.
EOF
}

schema_block() {
  cat <<'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "dispatch-selector-open-child-prefilter.decision",
  "type": "object",
  "required": ["bead", "dispatchable", "schema_version"],
  "properties": {
    "schema_version": {"type": "string", "const": "dispatch-selector-open-child-prefilter.v1"},
    "bead": {"type": "string", "description": "the parent bead-id evaluated"},
    "dispatchable": {"type": "boolean", "description": "true if no open children/rework; false if dispatch should be preempted"},
    "preemption_reason": {"type": ["string", "null"], "enum": ["open_child", "open_rework", "open_child_and_rework", null]},
    "open_children": {"type": "array", "items": {"type": "string"}, "description": "child bead-ids in OPEN/IN_PROGRESS state"},
    "open_rework": {"type": "array", "items": {"type": "string"}, "description": "rework bead-ids in OPEN state whose title contains the parent's id"},
    "next_actionable": {"type": ["string", "null"], "description": "highest-priority open child or rework to dispatch instead"},
    "ts": {"type": "string", "format": "date-time"}
  },
  "additionalProperties": true
}
EOF
}

examples_block() {
  cat <<'EOF'
# Single bead: is flywheel-useh dispatchable today?
dispatch-selector-open-child-prefilter.sh flywheel-useh --json

# Pre-filter the ready list before dispatch:
br ready --json \
  | dispatch-selector-open-child-prefilter.sh --filter-list --json \
  | jq -r '.[] | select(.dispatchable) | .bead' \
  | head -1
# → highest-priority dispatchable bead-id

# Self-check
dispatch-selector-open-child-prefilter.sh --doctor --json
EOF
}

emit_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg bead "$1" \
    --argjson dispatchable "$2" \
    --arg reason "${3:-null}" \
    --argjson open_children "${4:-[]}" \
    --argjson open_rework "${5:-[]}" \
    --arg next_actionable "${6:-null}" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
      {
        schema_version: $version,
        bead: $bead,
        dispatchable: $dispatchable,
        preemption_reason: (if $reason == "null" then null else $reason end),
        open_children: $open_children,
        open_rework: $open_rework,
        next_actionable: (if $next_actionable == "null" then null else $next_actionable end),
        ts: $ts
      }
    '
}

# Look up open children of a bead via `br dep tree`. Returns space-separated
# child IDs that are OPEN or IN_PROGRESS (not CLOSED/BLOCKED).
find_open_children() {
  local bead="$1" out children=""
  out="$(cd "$REPO" && "$BR_BIN" show "$bead" 2>/dev/null || true)"
  # Parse "Dependents:" section if present
  local section=""
  section=$(printf '%s\n' "$out" | awk '/^Dependents:/{flag=1; next} /^[A-Z][a-z]+:/{flag=0} flag' 2>/dev/null || true)
  if [[ -n "$section" ]]; then
    children=$(printf '%s\n' "$section" | grep -oE 'flywheel-[a-z0-9]+(\.[0-9]+)*' | grep -v "^${bead}$" | sort -u || true)
  fi
  local open_list=""
  for c in $children; do
    [[ -z "$c" ]] && continue
    local state=""
    state=$(cd "$REPO" && "$BR_BIN" show "$c" 2>/dev/null \
      | grep -oE '\[. (P[0-3]|--) · (OPEN|CLOSED|IN_PROGRESS|BLOCKED|READY)' \
      | grep -oE '(OPEN|IN_PROGRESS|BLOCKED|READY|CLOSED)' \
      | head -1 || true)
    if [[ "$state" == "OPEN" || "$state" == "IN_PROGRESS" ]]; then
      open_list+="$c "
    fi
  done
  printf '%s' "$open_list"
}

# Look up open rework siblings via title-search heuristic. Rework beads
# typically include the parent's id in the title.
find_open_rework() {
  local bead="$1" out
  out="$(cd "$REPO" && "$BR_BIN" list --status open --json 2>/dev/null || printf '[]')"
  set +e
  result=$(printf '%s' "$out" | jq -r --arg b "$bead" '
    if type == "array" then .
    elif type == "object" and ((.issues // null) | type) == "array" then .issues
    else [] end
    | map(select(
        (.id // "") != $b
        and ((.title // "") | contains($b))
      ))
    | .[].id
  ' 2>/dev/null)
  result=$(printf '%s\n' "$result" | grep -v "^${bead}$" 2>/dev/null | sort -u | tr '\n' ' ')
  set -e
  printf '%s' "$result"
}

# Single-bead evaluation: emit decision JSON to stdout, set rc=0|1.
evaluate_single() {
  local bead="$1"
  if [[ -z "$bead" ]]; then
    printf 'usage: dispatch-selector-open-child-prefilter.sh BEAD_ID\n' >&2
    return 64
  fi
  local children rework reason="null" next="null" dispatchable=true
  set +e
  children=$(find_open_children "$bead" 2>/dev/null)
  rework=$(find_open_rework "$bead" 2>/dev/null)
  set -e
  local children_json="[]" rework_json="[]"
  if [[ -n "${children// }" ]]; then
    children_json=$(printf '%s\n' $children | jq -R . 2>/dev/null | jq -s -c . 2>/dev/null) || children_json="[]"
  fi
  if [[ -n "${rework// }" ]]; then
    rework_json=$(printf '%s\n' $rework | jq -R . 2>/dev/null | jq -s -c . 2>/dev/null) || rework_json="[]"
  fi
  if [[ -n "${children// }" && -n "${rework// }" ]]; then
    dispatchable=false; reason="open_child_and_rework"
    next=$(printf '%s' "$children" | awk '{print $1}')
  elif [[ -n "${children// }" ]]; then
    dispatchable=false; reason="open_child"
    next=$(printf '%s' "$children" | awk '{print $1}')
  elif [[ -n "${rework// }" ]]; then
    dispatchable=false; reason="open_rework"
    next=$(printf '%s' "$rework" | awk '{print $1}')
  fi
  emit_json "$bead" "$dispatchable" "$reason" "$children_json" "$rework_json" "$next"
  if [[ "$dispatchable" == "true" ]]; then return 0; else return 1; fi
}

# Filter-list mode: read JSON array of bead objects from stdin, emit array of
# decisions on stdout (always rc=0 unless input is malformed).
filter_list() {
  local input
  input=$(cat)
  if ! printf '%s' "$input" | jq -e 'type == "array"' >/dev/null 2>&1; then
    printf '{"error":"input is not a JSON array"}\n' >&2
    return 64
  fi
  printf '['
  local first=1
  while IFS= read -r bead; do
    [[ -z "$bead" ]] && continue
    local row
    row=$(evaluate_single "$bead" 2>/dev/null || true)
    [[ -z "$row" ]] && continue
    if [[ "$first" -eq 1 ]]; then
      printf '%s' "$row"
      first=0
    else
      printf ',%s' "$row"
    fi
  done < <(printf '%s' "$input" | jq -r '.[].id // empty')
  printf ']\n'
}

doctor() {
  local checks_json='[]'
  local status="pass"
  local br_check="ok"
  if ! command -v "$BR_BIN" >/dev/null 2>&1; then
    br_check="missing"; status="fail"
  fi
  local repo_check="ok"
  if [[ ! -d "$REPO/.git" ]]; then
    repo_check="not_a_git_repo"; status="fail"
  fi
  jq -nc \
    --arg version "$VERSION" \
    --arg status "$status" \
    --arg br_check "$br_check" \
    --arg repo "$REPO" \
    --arg repo_check "$repo_check" '
      {
        schema_version: $version,
        status: $status,
        br_check: $br_check,
        repo: $repo,
        repo_check: $repo_check
      }
    '
  if [[ "$status" == "pass" ]]; then return 0; else return 2; fi
}

# Arg parser
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --filter-list) COMMAND="filter-list"; shift ;;
    --doctor|doctor|--health|health) COMMAND="doctor"; shift ;;
    --info|info) info_block; exit 0 ;;
    --schema|schema) schema_block; exit 0 ;;
    --examples|examples) examples_block; exit 0 ;;
    --help|-h|help) usage; exit 0 ;;
    --) shift; break ;;
    -*)
      printf 'unknown flag: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
    *)
      if [[ -z "$ARG_BEAD" ]]; then
        ARG_BEAD="$1"
      else
        printf 'unexpected positional: %s\n' "$1" >&2
        usage >&2
        exit 64
      fi
      shift
      ;;
  esac
done

# Pre-flight checks
if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  printf '{"error":"br_missing","br_bin":"%s"}\n' "$BR_BIN" >&2
  exit 2
fi
if [[ ! -d "$REPO/.git" ]]; then
  printf '{"error":"repo_not_git","repo":"%s"}\n' "$REPO" >&2
  exit 2
fi

case "$COMMAND" in
  doctor) doctor ;;
  filter-list) filter_list ;;
  "")
    if [[ -z "$ARG_BEAD" ]]; then
      usage >&2
      exit 64
    fi
    evaluate_single "$ARG_BEAD"
    ;;
  *)
    printf 'unknown command: %s\n' "$COMMAND" >&2
    exit 64
    ;;
esac
