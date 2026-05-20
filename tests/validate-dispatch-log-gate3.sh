#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/scripts/validate-dispatch-log-gate3.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-gate3.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 2>/dev/null || true
  fi
}

bash -n "$BIN" && pass "script_syntax" || fail "script_syntax"

good_log="$TMP/good.jsonl"
cat >"$good_log" <<'JSONL'
{"event":"skillos_handoff_sent","status":"sent","task_id":"handoff-no-dispatch"}
{"event":"dispatch_sent","status":"in_progress","task_id":"worker-in-flight","task_file":"/tmp/worker-in-flight.md","pane":2}
{"event":"dispatch_status","status":"pending","task_id":"worker-pending","task_file":"/tmp/worker-pending.md","pane":3}
{"event":"dispatch_completed","status":"completed","task_id":"worker-done","task_file":"/tmp/worker-done.md","pane":2,"callback_received_at":"2026-05-19T04:20:00Z"}
{"event":"dispatch_completed","status":"complete","task_id":"worker-done-alias","task_file":"/tmp/worker-done-alias.md","pane":3,"cb_received_at":"2026-05-19T04:21:00Z"}
{legacy-malformed-json
JSONL

good_out="$TMP/good.json"
bash "$BIN" --log "$good_log" --json >"$good_out" \
  && pass "lenient_allows_non_terminal_missing_callbacks" \
  || fail "lenient_allows_non_terminal_missing_callbacks"
assert_jq "$good_out" '.status == "PASS"' "lenient/status_pass"
assert_jq "$good_out" '.terminal_rows == 2 and .terminal_missing_callback == 0' "lenient/terminal_rows_clean"
assert_jq "$good_out" '.terminal_callback_compliance_pct == 100' "lenient/terminal_compliance_100"
assert_jq "$good_out" '.intermediate_without_callback_allowed == 2' "lenient/intermediate_allowed"
assert_jq "$good_out" '.non_dispatch_rows_ignored == 1' "lenient/non_dispatch_ignored"
assert_jq "$good_out" '.malformed_rows_ignored == 1' "lenient/malformed_ignored"

set +e
bash "$BIN" --log "$good_log" --strict --json >"$TMP/strict.json"
strict_rc=$?
set -e
[[ "$strict_rc" -eq 1 ]] && pass "strict_fails_missing_intermediate_callbacks" || fail "strict_fails_missing_intermediate_callbacks rc=$strict_rc"
assert_jq "$TMP/strict.json" '.strict_missing_callback == 2 and .terminal_missing_callback == 0' "strict/intermediate_only"

bad_log="$TMP/bad.jsonl"
cat >"$bad_log" <<'JSONL'
{"event":"dispatch_completed","status":"completed","task_id":"worker-missing-callback","task_file":"/tmp/worker-missing-callback.md","pane":4}
JSONL

set +e
bash "$BIN" --log "$bad_log" --json >"$TMP/bad.json"
bad_rc=$?
set -e
[[ "$bad_rc" -eq 1 ]] && pass "lenient_blocks_completed_without_callback" || fail "lenient_blocks_completed_without_callback rc=$bad_rc"
assert_jq "$TMP/bad.json" '.status == "FAIL" and .terminal_missing_callback == 1' "lenient/completed_missing_callback_violation"

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] || exit 1
