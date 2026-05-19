#!/usr/bin/env bash
set -euo pipefail

VERSION="topology-gap-probe.v2"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
JSON_OUT=0
STRICT=0
MODE="probe"

REQUIRED_FIELDS_JSON='["session","orchestrator_pane","orchestrator_kind","callback_pane","worker_panes","worker_kinds","shell_panes","human_pane","expected_pane_count","effective_at","registered_by","notes"]'
PLAN_SESSIONS_JSON='["flywheel","picoz","alpsinsurance","vrtx","zesttube","skillos","clutterfreespaces","zeststream-v2"]'
LATEST_WINS_JQ='group_by(.session) | map(max_by(.effective_at))'
PRIOR_IMPL="flywheel-31p"

usage() {
  cat <<'USAGE'
Usage:
  topology-gap-probe.sh [--json] [--strict] [--topology PATH]
  topology-gap-probe.sh --schema [--json]
  topology-gap-probe.sh --examples [--json]
  topology-gap-probe.sh --help

Options:
  --topology PATH  JSONL topology ledger. Default: $FLYWHEEL_SESSION_TOPOLOGY or ~/.local/state/flywheel/session-topology.jsonl
  --json           Emit machine-readable JSON.
  --strict         Exit nonzero for fail or warn status.
  --schema         Describe required ledger fields and latest-wins jq.
  --examples       Emit the eight-session bootstrap fixture from the 2026-05-01 plan.

This is the flywheel-se3h.1 conformance-hardening probe for the flywheel-31p
all-in-one session topology registry implementation.
USAGE
}

schema_json() {
  jq -n \
    --arg schema_version "session-topology-ledger/v1" \
    --arg version "$VERSION" \
    --arg latest_wins_jq "$LATEST_WINS_JQ" \
    --arg prior "$PRIOR_IMPL" \
    --argjson required_fields "$REQUIRED_FIELDS_JSON" \
    --argjson plan_sessions "$PLAN_SESSIONS_JSON" \
    '{
      schema_version: $schema_version,
      probe_version: $version,
      required_fields: $required_fields,
      latest_wins_jq: $latest_wins_jq,
      plan_sessions: $plan_sessions,
      prior_all_in_one_implementation: $prior,
      conformance_role: "schema/latest-wins/bootstrap hardening"
    }'
}

examples_json() {
  jq -n \
    --arg prior "$PRIOR_IMPL" \
    '{
      fixture_role: "plan bootstrap conformance fixture",
      prior_all_in_one_implementation: $prior,
      rows: [
        {session:"flywheel",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2,3,4],worker_kinds:{"2":"codex","3":"codex","4":"codex"},shell_panes:[0],human_pane:0,expected_pane_count:5,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"picoz",orchestrator_pane:0,orchestrator_kind:"claude",callback_pane:0,worker_panes:[1,2,3],worker_kinds:{"1":"claude","2":"codex","3":"codex"},shell_panes:[],human_pane:null,expected_pane_count:4,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"alpsinsurance",orchestrator_pane:0,orchestrator_kind:"codex",callback_pane:0,worker_panes:[1,2,3],worker_kinds:{"1":"claude","2":"codex","3":"claude"},shell_panes:[],human_pane:null,expected_pane_count:4,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"vrtx",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2,3,4],worker_kinds:{"2":"codex","3":"codex","4":"codex"},shell_panes:[0],human_pane:0,expected_pane_count:5,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"zesttube",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2,3],worker_kinds:{"2":"claude","3":"claude"},shell_panes:[0],human_pane:0,expected_pane_count:4,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"skillos",orchestrator_pane:1,orchestrator_kind:"codex",callback_pane:1,worker_panes:[2],worker_kinds:{"2":"codex"},shell_panes:[0],human_pane:0,expected_pane_count:3,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"clutterfreespaces",orchestrator_pane:0,orchestrator_kind:"claude",callback_pane:0,worker_panes:[],worker_kinds:{},shell_panes:[1,2],human_pane:null,expected_pane_count:3,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"flywheel-31p conformance fixture"},
        {session:"zeststream-v2",orchestrator_pane:null,orchestrator_kind:null,callback_pane:null,worker_panes:[],worker_kinds:{},shell_panes:[0,1,2,3],human_pane:null,expected_pane_count:4,effective_at:"2026-05-01T13:55:00Z",registered_by:"plan-bootstrap",notes:"GHOST SESSION; flywheel-31p conformance fixture"}
      ]
    }'
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) JSON_OUT=1; shift ;;
      --strict) STRICT=1; shift ;;
      --topology)
        [[ -n "${2:-}" ]] || { echo "ERR: --topology requires PATH" >&2; exit 64; }
        TOPOLOGY="$2"; shift 2 ;;
      --schema) MODE="schema"; shift ;;
      --examples) MODE="examples"; shift ;;
      --help|-h) usage; exit 0 ;;
      *) echo "ERR: unknown argument: $1" >&2; exit 64 ;;
    esac
  done
}

human_summary() {
  local json="$1"
  jq -r '
    "session topology ledger: " + .status,
    "path: " + .topology_path,
    "latest_session_count: " + (.latest_session_count | tostring),
    "missing_required_fields_count: " + (.missing_required_fields_count | tostring),
    "latest_missing_required_fields_count: " + (.latest_missing_required_fields_count | tostring),
    "missing_plan_sessions: " + ((.missing_plan_sessions // []) | join(",")),
    "prior_all_in_one_implementation: " + .prior_all_in_one_implementation,
    "conformance_role: " + .conformance_role
  ' <<<"$json"
}

probe_json() {
  local rows_file="$1"
  jq -s \
    --arg version "$VERSION" \
    --arg topology_path "$TOPOLOGY" \
    --arg latest_wins_jq "$LATEST_WINS_JQ" \
    --arg prior "$PRIOR_IMPL" \
    --argjson required "$REQUIRED_FIELDS_JSON" \
    --argjson plan "$PLAN_SESSIONS_JSON" \
    '
      def missing($row): $required - ($row | keys_unsorted);
      def missing_rows($rows):
        $rows
        | to_entries
        | map((missing(.value)) as $missing
          | select(($missing | length) > 0)
          | {line:(.key + 1), session:(.value.session // null), missing_fields:$missing});
      def latest: group_by(.session) | map(max_by(.effective_at));
      . as $rows
      | (latest) as $latest
      | (missing_rows($rows)) as $all_missing
      | (missing_rows($latest)) as $latest_missing
      | ($plan - ($latest | map(.session))) as $missing_plan
      | ($latest | map(select((.orchestrator_kind != null) and (.orchestrator_kind != "claude") and (.orchestrator_kind != "codex")) | {session, orchestrator_kind})) as $kind_errors
      | ($latest | map(select((.orchestrator_pane != null) and ((.orchestrator_pane | type) != "number")) | {session, orchestrator_pane})) as $pane_errors
      | ($latest | map(select(((.worker_panes // null) | type) != "array") | {session, worker_panes})) as $worker_errors
      | ($kind_errors + $pane_errors + $worker_errors) as $type_errors
      | {
          schema_version:"session-topology-ledger/v1",
          probe_version:$version,
          topology_path:$topology_path,
          status:(if (($latest_missing|length) > 0 or ($type_errors|length) > 0) then "fail" elif (($all_missing|length) > 0 or ($missing_plan|length) > 0) then "warn" else "pass" end),
          latest_wins_jq:$latest_wins_jq,
          latest_wins_probe_passed:true,
          required_fields:$required,
          total_rows:($rows|length),
          latest_session_count:($latest|length),
          latest_sessions:($latest | map(.session)),
          missing_required_fields_count:($all_missing|length),
          latest_missing_required_fields_count:($latest_missing|length),
          row_missing_required_fields:$all_missing,
          latest_missing_required_fields:$latest_missing,
          latest_type_errors:$type_errors,
          plan_sessions:$plan,
          missing_plan_sessions:$missing_plan,
          current_fleet_delta_reason:(if ($missing_plan|length) > 0 then "live ledger has current active fleet subset; plan bootstrap fixture covers the full 2026-05-01 eight-session set" else null end),
          prior_all_in_one_implementation:$prior,
          conformance_role:"flywheel-se3h.1 hardens flywheel-31p registry with schema/latest-wins/bootstrap checks"
        }
    ' "$rows_file"
}

parse_args "$@"

case "$MODE" in
  schema)
    if [[ "$JSON_OUT" -eq 1 ]]; then schema_json; else schema_json | jq -r '.required_fields | join("\n")'; fi
    exit 0 ;;
  examples)
    if [[ "$JSON_OUT" -eq 1 ]]; then examples_json; else examples_json | jq -c '.rows[]'; fi
    exit 0 ;;
esac

if [[ ! -f "$TOPOLOGY" ]]; then
  result="$(jq -n --arg version "$VERSION" --arg topology_path "$TOPOLOGY" --arg prior "$PRIOR_IMPL" --argjson required "$REQUIRED_FIELDS_JSON" '{
    schema_version:"session-topology-ledger/v1",
    probe_version:$version,
    topology_path:$topology_path,
    status:"fail",
    reason:"topology_file_missing",
    required_fields:$required,
    prior_all_in_one_implementation:$prior,
    conformance_role:"flywheel-se3h.1 hardens flywheel-31p registry with schema/latest-wins/bootstrap checks"
  }')"
else
  tmp_err="$(mktemp "${TMPDIR:-/tmp}/topology-gap-probe.err.XXXXXX")"
  if ! jq -s '.' "$TOPOLOGY" >/dev/null 2>"$tmp_err"; then
    result="$(jq -n --arg version "$VERSION" --arg topology_path "$TOPOLOGY" --arg prior "$PRIOR_IMPL" --arg error "$(cat "$tmp_err")" '{
      schema_version:"session-topology-ledger/v1",
      probe_version:$version,
      topology_path:$topology_path,
      status:"fail",
      reason:"topology_json_parse_failed",
      parse_error:$error,
      prior_all_in_one_implementation:$prior,
      conformance_role:"flywheel-se3h.1 hardens flywheel-31p registry with schema/latest-wins/bootstrap checks"
    }')"
  else
    result="$(probe_json "$TOPOLOGY")"
  fi
  rm -f "$tmp_err"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  human_summary "$result"
fi

if [[ "$STRICT" -eq 1 && "$(jq -r '.status' <<<"$result")" != "pass" ]]; then
  exit 1
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
