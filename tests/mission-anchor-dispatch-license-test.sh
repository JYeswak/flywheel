#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${MISSION_LICENSE_BIN:-$ROOT/.flywheel/scripts/mission-anchor-dispatch-license.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-license-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

assert_rc() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label rc=$actual expected=$expected"; fi
}

make_repo() {
  local dir
  dir="$(mktemp -d "$TMP/repo.XXXXXX")"
  mkdir -p "$dir/.flywheel"
  printf '%s\n' "$dir"
}

write_mission() {
  local repo="$1" status="${2:-locked}"
  cat >"$repo/.flywheel/MISSION.md" <<EOF
# Fixture Mission

schema_version: 1
status: $status

## Section 3 - Phase Ladder

| phase | gate_criterion | status_as_of_2026_05_05 |
|---|---|---|
| P1 | baseline complete | COMPLETE |
| P2 | current gate | OPEN |
| P3 | next prep | TODO |
| P4 | future infra | TODO |
| P5 | terminal | TODO |

## Section 4
EOF
}

run_emit() {
  local repo="$1" out="$2" ledger="$3" br_ready="${4:-[]}"
  MISSION_LICENSE_LEDGER="$ledger" MISSION_LICENSE_BR_READY_JSON="$br_ready" \
    bash "$BIN" --emit-list --repo "$repo" --json >"$out"
}

if bash -n "$BIN"; then pass "script_syntax"; else fail "script_syntax"; fi
if [[ "$(wc -l <"$BIN" | tr -d ' ')" -lt 500 ]]; then pass "script_under_500_lines"; else fail "script_under_500_lines"; fi

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "mission-anchor-dispatch-license" and (.refuse_gate_cite | test("mission-anchor-dispatch-preflight.sh:32-44"))' "info_json_refuse_gate_cite"
"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "mission-anchor-dispatch-license.emit-list.v1"' "schema_json"
"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 5' "examples_json"
"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.command == "quickstart" and (.steps | length) >= 5' "quickstart_json"
"$BIN" help emit-list --json >"$TMP/help.json"
assert_jq "$TMP/help.json" '.command == "help" and .topic == "emit-list"' "help_topic_json"
"$BIN" completion bash >"$TMP/completion.bash"
if rg -q 'complete -W' "$TMP/completion.bash"; then pass "completion_bash"; else fail "completion_bash"; fi

repo="$(make_repo)"
write_mission "$repo"
cat >"$repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"task_id":"current-low","phase_tag":"P2","ts":"2026-05-04T23:00:00Z","callback_received_at":null,"downstream_dep_count":2}
{"task_id":"current-high","phase_tag":"P2","ts":"2026-05-05T00:00:00Z","callback_received_at":null,"downstream_dep_count":10}
{"task_id":"next-high-old","phase_tag":"P3","ts":"2026-05-04T00:00:00Z","callback_received_at":null,"downstream_dep_count":10}
{"task_id":"future-filtered","phase_tag":"P4","ts":"2026-05-03T00:00:00Z","callback_received_at":null,"downstream_dep_count":99}
{"task_id":"done-filtered","phase_tag":"P2","ts":"2026-05-04T00:00:00Z","callback_received_at":"2026-05-05T00:00:00Z","downstream_dep_count":99}
{"task_id":"untagged-filtered","ts":"2026-05-04T00:00:00Z","callback_received_at":null,"downstream_dep_count":99}
JSONL
br_ready='[{"id":"br-p2-extra","phase_tag":"P2","created_at":"2026-05-05T00:30:00Z","downstream_dep_count":1}]'
ledger="$TMP/license-ledger.jsonl"
run_emit "$repo" "$TMP/emit.json" "$ledger" "$br_ready"
assert_jq "$TMP/emit.json" '.current_open_phase == "P2" and .mission_anchor_status == "filled"' "mission_section3_current_open_phase"
assert_jq "$TMP/emit.json" '.licensed_undispatched_count == 4 and ([.licensed_undispatched_full_list_sorted[].task_id] | index("future-filtered") | not) and ([.licensed_undispatched_full_list_sorted[].task_id] | index("done-filtered") | not)' "phase_filter_and_pending_filter"
assert_jq "$TMP/emit.json" '.licensed_undispatched_full_list_sorted[0].task_id == "current-high"' "pagerank_ranking_top_pick"
assert_jq "$TMP/emit.json" '(.licensed_undispatched_full_list_sorted[] | select(.task_id == "br-p2-extra")).source == "br-ready"' "br_ready_cross_reference"
if [[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]]; then pass "ledger_appended_once"; else fail "ledger_appended_once"; fi

run_emit "$repo" "$TMP/emit2.json" "$ledger" "$br_ready"
ids1="$(jq -c '[.licensed_undispatched_full_list_sorted[].task_id]' "$TMP/emit.json")"
ids2="$(jq -c '[.licensed_undispatched_full_list_sorted[].task_id]' "$TMP/emit2.json")"
if [[ "$ids1" == "$ids2" ]]; then pass "pagerank_order_deterministic"; else fail "pagerank_order_deterministic"; fi
if [[ "$(wc -l <"$ledger" | tr -d ' ')" == "2" ]]; then pass "ledger_appended_each_emit_call"; else fail "ledger_appended_each_emit_call"; fi

empty_repo="$(make_repo)"
set +e
MISSION_LICENSE_LEDGER="$TMP/missing-ledger.jsonl" MISSION_LICENSE_BR_READY_JSON='[]' \
  bash "$BIN" --emit-list --repo "$empty_repo" --json >"$TMP/missing.json" 2>"$TMP/missing.err"
rc=$?
set -e
assert_rc "$rc" 3 "missing_mission_exit_3"
assert_jq "$TMP/missing.json" '.mission_anchor_status == "missing" and (.message | test("mission anchor missing"))' "missing_mission_explicit_json"

unfilled_repo="$(make_repo)"
write_mission "$unfilled_repo" "needs_owner_review"
set +e
MISSION_LICENSE_LEDGER="$TMP/unfilled-ledger.jsonl" MISSION_LICENSE_BR_READY_JSON='[]' \
  bash "$BIN" --emit-list --repo "$unfilled_repo" --json >"$TMP/unfilled.json" 2>"$TMP/unfilled.err"
rc=$?
set -e
assert_rc "$rc" 3 "unfilled_mission_exit_3"
assert_jq "$TMP/unfilled.json" '.mission_anchor_status == "unfilled" and (.message | test("mission anchor unfilled"))' "unfilled_mission_explicit_json"

no_dispatch_repo="$(make_repo)"
write_mission "$no_dispatch_repo"
: >"$no_dispatch_repo/.flywheel/dispatch-log.jsonl"
run_emit "$no_dispatch_repo" "$TMP/no-dispatch.json" "$TMP/no-dispatch-ledger.jsonl" '[]'
assert_jq "$TMP/no-dispatch.json" '.licensed_undispatched_count == 0 and .current_open_phase == "P2"' "filled_no_dispatches_count_zero"

if "$BIN" doctor --help >/dev/null; then pass "doctor_help"; else fail "doctor_help"; fi
if "$BIN" health --help >/dev/null; then pass "health_help"; else fail "health_help"; fi
if "$BIN" completion --help >/dev/null; then pass "completion_help"; else fail "completion_help"; fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
