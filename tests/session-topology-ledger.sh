#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/topology-gap-probe.sh"
LIVE_TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/session-topology-ledger.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

bash -n "$PROBE" && pass "topology probe syntax" || fail "topology probe syntax"

if test -f "$LIVE_TOPOLOGY"; then
  pass "live session-topology.jsonl exists"
else
  fail "live session-topology.jsonl exists"
fi

jq -s 'group_by(.session) | map(max_by(.effective_at))' "$LIVE_TOPOLOGY" >"$TMP/live-latest.json" \
  && pass "live latest-wins jq succeeds" || fail "live latest-wins jq succeeds"

"$PROBE" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '(.required_fields | index("session")) and (.required_fields | index("callback_pane")) and (.required_fields | index("registered_by")) and .latest_wins_jq == "group_by(.session) | map(max_by(.effective_at))"' \
  "schema documents required fields and latest-wins jq"
assert_jq "$TMP/schema.json" \
  '.prior_all_in_one_implementation == "flywheel-31p" and (.conformance_role | test("schema/latest-wins/bootstrap"))' \
  "schema references flywheel-31p conformance-hardening role"

"$PROBE" --examples --json >"$TMP/examples.json"
jq -c '.rows[]' "$TMP/examples.json" >"$TMP/bootstrap.jsonl"
assert_jq "$TMP/examples.json" \
  '([.rows[].session] | sort) == (["{session}","clutterfreespaces","flywheel","{session}","{capability-control-plane}","vrtx","zeststream-v2","zesttube"] | sort)' \
  "bootstrap fixture covers plan sessions"

"$PROBE" --topology "$TMP/bootstrap.jsonl" --strict --json >"$TMP/bootstrap-probe.json"
assert_jq "$TMP/bootstrap-probe.json" \
  '.status == "pass" and .latest_session_count == 8 and .missing_required_fields_count == 0 and .missing_plan_sessions == []' \
  "bootstrap fixture passes schema and plan coverage"

{
  jq -nc '{session:"dupe",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2],worker_kinds:{"2":"codex"},shell_panes:[0],human_pane:0,expected_pane_count:3,effective_at:"2026-05-01T00:00:00Z",registered_by:"fixture",notes:"old row"}'
  jq -nc '{session:"dupe",orchestrator_pane:4,orchestrator_kind:"codex",callback_pane:4,worker_panes:[5],worker_kinds:{"5":"codex"},shell_panes:[0],human_pane:0,expected_pane_count:6,effective_at:"2026-05-02T00:00:00Z",registered_by:"fixture",notes:"new row"}'
} >"$TMP/repeated.jsonl"

jq -s 'group_by(.session) | map(max_by(.effective_at))' "$TMP/repeated.jsonl" >"$TMP/repeated-latest.json"
assert_jq "$TMP/repeated-latest.json" \
  'length == 1 and .[0].session == "dupe" and .[0].orchestrator_pane == 4 and .[0].notes == "new row"' \
  "repeated rows resolve newest effective_at"

"$PROBE" --topology "$TMP/repeated.jsonl" --json >"$TMP/repeated-probe.json"
assert_jq "$TMP/repeated-probe.json" \
  '.latest_wins_probe_passed == true and .latest_session_count == 1 and (.latest_sessions | index("dupe"))' \
  "probe reports latest-wins receipt"

jq -nc '{session:"broken",orchestrator_pane:1,effective_at:"2026-05-01T00:00:00Z"}' >"$TMP/malformed.jsonl"
if "$PROBE" --topology "$TMP/malformed.jsonl" --strict --json >"$TMP/malformed-probe.json"; then
  fail "strict malformed topology fails"
else
  pass "strict malformed topology fails"
fi
assert_jq "$TMP/malformed-probe.json" \
  '.status == "fail" and .latest_missing_required_fields_count == 1 and (.latest_missing_required_fields[0].missing_fields | index("callback_pane")) and (.latest_missing_required_fields[0].missing_fields | index("registered_by"))' \
  "probe reports missing required fields"

"$PROBE" --topology "$LIVE_TOPOLOGY" --json >"$TMP/live-probe.json"
assert_jq "$TMP/live-probe.json" \
  '.latest_wins_probe_passed == true and .latest_session_count >= 1 and (.required_fields | index("notes"))' \
  "live probe emits doctor-consumable receipt"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL session-topology-ledger tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS session-topology-ledger tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
