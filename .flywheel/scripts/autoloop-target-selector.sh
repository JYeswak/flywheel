#!/usr/bin/env bash
# .flywheel/scripts/autoloop-target-selector.sh
# Topology-driven autoloop target selector. Bead flywheel-se3h.9.
#
# Reads ~/.local/state/flywheel/session-topology.jsonl (or fixture override),
# returns the eligible-for-autoloop sessions and the set of skipped sessions
# with structured reasons. Read-only: no live dispatch, no client-session
# sends. Selector "fails closed" — sessions with orchestrator_pane=null,
# missing topology row, or session_status not in the allowed list are
# refused.
#
# Usage:
#   autoloop-target-selector.sh --info
#   autoloop-target-selector.sh --doctor [--json]
#   autoloop-target-selector.sh --apply [--json] [--topology=PATH]
#                               [--allowed-status=LIST]
set -euo pipefail

VERSION="0.1.0"
SCHEMA_VERSION="autoloop-target-selector.v1"
DEFAULT_TOPOLOGY="${AUTOLOOP_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
DEFAULT_ALLOWED_STATUS="${AUTOLOOP_ALLOWED_STATUS:-live,live_corrected}"

mode="apply"
emit_json=0
topology_path=""
allowed_status=""

usage() {
  cat <<EOF
autoloop-target-selector.sh — topology-driven autoloop session selector

Schema:  $SCHEMA_VERSION
Version: $VERSION

Modes (canonical-cli-scoping triad):
  --info                print this help and exit 0
  --schema              print emit schema (one line)
  --examples            print invocation examples
  --doctor              probe topology source health (--json supported)
  --apply               run the selection (read-only; emits eligible/skipped)

Options:
  --topology=<path>     override topology jsonl (fixture mode)
  --allowed-status=<csv> session_status values that are eligible
                         (default: $DEFAULT_ALLOWED_STATUS; "null"
                         status means topology refresh has not stamped
                         status yet — defaults to NOT eligible unless
                         "null" is added to the allowed list)
  --json                emit machine-readable JSON envelope
  --version             print version and exit 0

Exit codes:
  0  success (eligible_count >= 0)
  1  internal error
  2  bad argument or missing topology source
  3  topology source has zero rows (cold start)

Eligibility rule (a session is eligible iff ALL hold):
  - latest topology row has orchestrator_pane != null
  - latest topology row has callback_pane != null
  - latest topology row session_status is in --allowed-status list

Skip-reason classes (carried into receipt):
  - missing_orchestrator_pane
  - missing_callback_pane
  - status_not_allowed:<observed_status>
  - missing_topology_row     (session referenced but no row in jsonl)

Sources:
  primary: $DEFAULT_TOPOLOGY  (override via --topology=PATH or
                                AUTOLOOP_TOPOLOGY env)
EOF
}

examples() {
  cat <<'EOF'
# Default current-state run:
autoloop-target-selector.sh --apply --json

# Fixture mode (test isolation):
autoloop-target-selector.sh --apply --topology=/tmp/fixture-topology.jsonl --json

# Wider allow-list (rare; e.g. include null-status sessions for diagnostic only):
autoloop-target-selector.sh --apply --allowed-status=live,live_corrected,null --json

# Doctor probe (source health, latest ts, row count):
autoloop-target-selector.sh --doctor --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info|-h|--help) usage; exit 0 ;;
    --schema)
      printf '{"schema_version":"%s","keys":["schema_version","ts","topology_path","allowed_status","total_sessions","eligible_count","eligible","skipped_count","skipped"]}\n' "$SCHEMA_VERSION"
      exit 0 ;;
    --examples)            examples; exit 0 ;;
    --version)             printf '%s\n' "$VERSION"; exit 0 ;;
    --doctor)              mode="doctor" ;;
    --apply)               mode="apply" ;;
    --json)                emit_json=1 ;;
    --topology=*)          topology_path="${1#--topology=}" ;;
    --allowed-status=*)    allowed_status="${1#--allowed-status=}" ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

[[ -z "$topology_path" ]] && topology_path="$DEFAULT_TOPOLOGY"
[[ -z "$allowed_status" ]] && allowed_status="$DEFAULT_ALLOWED_STATUS"

iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
err() { printf '%s\n' "$*" >&2; }
require() { command -v "$1" >/dev/null || { err "missing dependency: $1"; exit 2; }; }
require jq

# Read latest-row-per-session into a JSON array (sorted by session for deterministic output)
latest_per_session() {
  local path="$1"
  if [[ ! -s "$path" ]]; then
    printf '[]'
    return 0
  fi
  jq -cs '
    map(select(.session != null))
    | group_by(.session)
    | map(max_by(.effective_at // ""))
    | sort_by(.session)
  ' "$path"
}

# Allowed-status as JSON array
allowed_status_json() {
  printf '%s' "$allowed_status" \
    | tr ',' '\n' \
    | jq -R -s 'split("\n") | map(select(length > 0))'
}

doctor() {
  local present=false rows=0 latest_ts="null"
  if [[ -s "$topology_path" ]]; then
    present=true
    rows="$(wc -l <"$topology_path" | tr -d ' ')"
    latest_ts="$(jq -s -r 'map(.effective_at // "") | max // "null"' "$topology_path" 2>/dev/null || echo null)"
  fi
  local sessions
  sessions="$(latest_per_session "$topology_path" | jq 'length')"
  if [[ "$emit_json" == 1 ]]; then
    jq -nc \
      --arg schema "autoloop-target-selector-doctor.v1" \
      --arg ts "$(iso)" \
      --arg path "$topology_path" \
      --argjson present "$present" \
      --argjson rows "$rows" \
      --arg latest "$latest_ts" \
      --argjson sessions "$sessions" \
      '{schema_version:$schema,ts:$ts,topology_path:$path,topology_present:$present,topology_rows:$rows,topology_latest_ts:$latest,distinct_sessions:$sessions}'
  else
    printf 'topology=%s present=%s rows=%d sessions=%s latest=%s\n' \
      "$topology_path" "$present" "$rows" "$sessions" "$latest_ts"
  fi
  $present || exit 2
  exit 0
}

apply() {
  if [[ ! -s "$topology_path" ]]; then
    err "topology source missing or empty: $topology_path"
    exit 2
  fi
  local rows allowed_arr
  rows="$(latest_per_session "$topology_path")"
  allowed_arr="$(allowed_status_json)"
  local total_sessions
  total_sessions="$(jq 'length' <<<"$rows")"
  if [[ "$total_sessions" -eq 0 ]]; then
    err "topology has zero rows after filtering"
    exit 3
  fi

  # Compute eligibility per session, emit envelope
  local envelope
  envelope="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso)" \
    --arg path "$topology_path" \
    --argjson rows "$rows" \
    --argjson allowed "$allowed_arr" '
    def classify:
      . as $row
      | ($row.session_status // "null" | tostring) as $s
      | ($allowed | map(tostring)) as $aw
      | {
          session: ($row.session // "<unknown>"),
          orchestrator_pane: ($row.orchestrator_pane // null),
          callback_pane: ($row.callback_pane // null),
          session_status: ($row.session_status // null),
          effective_at: ($row.effective_at // null),
          reasons: (
            []
            + (if ($row.orchestrator_pane // null) == null then ["missing_orchestrator_pane"] else [] end)
            + (if ($row.callback_pane // null)     == null then ["missing_callback_pane"]     else [] end)
            + (if ($aw | index($s)) == null then ["status_not_allowed:" + $s] else [] end)
          )
        };
    ($rows | map(classify)) as $classified
    | ($classified | map(select((.reasons | length) == 0) | .session)) as $eligible
    | ($classified | map(select((.reasons | length) > 0))) as $skipped
    | {
        schema_version: $schema,
        ts: $ts,
        topology_path: $path,
        allowed_status: $allowed,
        total_sessions: ($classified | length),
        eligible_count: ($eligible | length),
        eligible: $eligible,
        skipped_count: ($skipped | length),
        skipped: ($skipped | map({session, session_status, orchestrator_pane, callback_pane, reasons})),
      }
  ')"

  if [[ "$emit_json" == 1 ]]; then
    printf '%s\n' "$envelope"
  else
    printf 'eligible=%s/%s skipped=%s\n' \
      "$(jq -r '.eligible_count' <<<"$envelope")" \
      "$(jq -r '.total_sessions' <<<"$envelope")" \
      "$(jq -r '.skipped_count' <<<"$envelope")"
    printf '\nELIGIBLE:\n'
    jq -r '.eligible[]? | "  - " + .' <<<"$envelope"
    printf '\nSKIPPED:\n'
    jq -r '.skipped[]? | "  - " + .session + " (status=" + (.session_status|tostring) + ") reasons=" + (.reasons | join(","))' <<<"$envelope"
  fi
}

case "$mode" in
  doctor) doctor ;;
  apply)  apply ;;
  *)      err "unknown mode: $mode"; exit 2 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
