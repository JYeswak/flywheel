#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/wire-or-explain-ranker.py"
FIXTURE="$ROOT/tests/fixtures/wire-or-explain-ranker/ledger.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-ranker.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

bash -n "$0" && pass "test_syntax"
python3 -m py_compile "$BIN" && pass "python_syntax"
"$BIN" --help >/dev/null && pass "help_exits"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.surface == "The Zest Sorter" and .class_weights.state.unwired == 80 and (.weight_notes | length) >= 4' "info_documents_weights"
"$BIN" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "wire-or-explain-ranker/schema/v1" and (.top_slices | index("actionability"))' "schema_surface"
"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.surface == "The Zest Sorter"' "quickstart_surface"
"$BIN" completion bash >"$TMP/completion.bash"
rg -q 'wire-or-explain-ranker.py' "$TMP/completion.bash" && pass "completion_bash"

"$BIN" rank --ledger "$FIXTURE" --now "2026-05-05T00:00:00Z" --br-ready "$TMP/missing-ready.json" --json >"$TMP/rank.json"
assert_jq "$TMP/rank.json" '.schema_version == "wire-or-explain-ranker/v1" and .surface == "The Zest Sorter" and .status == "pass"' "rank_schema_surface"
assert_jq "$TMP/rank.json" '.summary.total_rows == 9 and .summary.unresolved_count == 7 and (.unresolved | length) == 7' "full_unresolved_list"
assert_jq "$TMP/rank.json" '.top.oldest[0].identity_key == "oldest-row"' "top_oldest"
assert_jq "$TMP/rank.json" '.top.downstream_cost[0].identity_key == "downstream-row"' "top_downstream_cost"
assert_jq "$TMP/rank.json" '.top.blocking_scope[0].identity_key == "fleet-cross"' "top_blocking_scope"
assert_jq "$TMP/rank.json" '.top.actionability[0].identity_key == "fleet-cross"' "top_actionability"
assert_jq "$TMP/rank.json" '.unresolved[] | select(.identity_key == "skill-backlog" and .route.action == "route_to_skillos" and .route.target == "skillos")' "skill_candidate_backlog_routes_without_separate_system"
assert_jq "$TMP/rank.json" '([.unresolved[].identity_key] | index("local-hard")) < ([.unresolved[].identity_key] | index("cross-nonfleet"))' "local_hard_outranks_cross_nonfleet"
assert_jq "$TMP/rank.json" '([.unresolved[].identity_key] | index("fleet-cross")) < ([.unresolved[].identity_key] | index("local-hard"))' "fleet_cross_can_outrank_local"
assert_jq "$TMP/rank.json" '.br_ready_context.status == "missing"' "br_ready_optional_missing"

"$BIN" why skill-backlog --ledger "$FIXTURE" --now "2026-05-05T00:00:00Z" --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.found == true and .row.route.action == "route_to_skillos"' "why_skill_backlog"

"$BIN" doctor --ledger "$FIXTURE" --now "2026-05-05T00:00:00Z" --stale-hours -1 --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .unresolved_count == 7 and (.top_actions | length) == 5' "doctor_passes_with_ranked_actions"

set +e
"$BIN" doctor --ledger "$TMP/missing-ledger.jsonl" --json >"$TMP/missing-doctor.json"
missing_rc=$?
set -e
if [[ "$missing_rc" == "1" ]]; then pass "missing_ledger_nonzero"; else fail "missing_ledger_nonzero"; fi
assert_jq "$TMP/missing-doctor.json" '.status == "error" and .errors[0].reason_code == "ledger_missing"' "missing_ledger_doctor_error"

tail -n 1 "$ROOT/.flywheel/wire-or-explain-ranker/README.md" | grep -qx 'Part of the Yuzu Method framework by ZestStream.' \
  && pass "readme_yuzu_footer" || fail "readme_yuzu_footer"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAILURES %s/%s\n' "$fail_count" "$((pass_count + fail_count))" >&2
  exit 1
fi

printf 'PASS wire-or-explain-ranker %s checks\n' "$pass_count"
