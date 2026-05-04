#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validate-callback.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

run_json() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  local rc=0
  "$BIN" validate-callback --repo "$ROOT" "$@" --json >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

make_fixtures() {
  printf 'proof\n' >"$TMP/evidence.md"
  python3 - "$TMP" <<'PY'
import json
import sys
from pathlib import Path

tmp = Path(sys.argv[1])
base = {
    "callback_ref": {
        "transport": "manual_fixture",
        "session": "flywheel",
        "pane": 4,
        "kind": "DONE",
        "received_at": "2026-05-03T23:30:00Z",
        "raw_ref": "DONE fixture",
    },
    "evidence": [{"type": "path", "ref": str(tmp / "evidence.md")}],
    "artifact_paths": [{"artifact_id": "evidence", "path": str(tmp / "evidence.md")}],
    "bead_actions": [{"action": "none"}],
}
(tmp / "valid-done-callback.json").write_text(json.dumps(base))
missing = dict(base)
missing["artifact_paths"] = [{"artifact_id": "missing", "path": str(tmp / "missing.md")}]
(tmp / "missing-artifact-callback.json").write_text(json.dumps(missing))
timeout = dict(base)
timeout["timeout"] = True
timeout["agent_status"] = "unresponsive"
timeout["artifact_paths"] = []
(tmp / "runtime-timeout-callback.json").write_text(json.dumps(timeout))
(tmp / "invalid-callback.json").write_text("{not-json")
PY
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

make_fixtures

schema_out="$(run_json schema --schema)"
assert_jq "$schema_out" '.command == "flywheel-loop validate-callback" and .read_only_default == true' "B03_AG1 command surface schema"

examples_out="$(run_json examples --examples)"
assert_jq "$examples_out" '(.examples | length) >= 4' "B03_AG2 examples surface"

missing_out="$(run_json missing --dispatch-id b03-missing --callback-ref "$TMP/missing-artifact-callback.json")"
missing_rc="$(cat "$TMP/missing.rc")"
if [[ "$missing_rc" != "0" ]]; then
  pass "B03_AG3 missing artifact exits non-zero"
else
  fail "B03_AG3 missing artifact exits non-zero"
fi
assert_jq "$missing_out" '.status == "fail" and .failure_class == "artifact_missing" and .summary_allowed == false and .integration_allowed == false' "B03_AG3 missing artifact receipt"
assert_jq "$missing_out" '.remediation_required == true and .remediation_present == false' "B03_AG7 failed callback requires remediation before summary"

timeout_out="$(run_json timeout --dispatch-id b03-timeout --callback-ref "$TMP/runtime-timeout-callback.json")"
timeout_rc="$(cat "$TMP/timeout.rc")"
if [[ "$timeout_rc" == "3" ]]; then
  pass "B03_AG4 runtime timeout exits unknown"
else
  fail "B03_AG4 runtime timeout exits unknown"
fi
assert_jq "$timeout_out" '.status == "unknown" and .failure_class == "runtime_unresponsive"' "B03_AG4 runtime timeout class"

valid_out="$(run_json valid --dispatch-id b03-valid --callback-ref "$TMP/valid-done-callback.json")"
assert_jq "$valid_out" '.status == "pass" and (.validation_receipt.evidence | length) == 1 and .schema_valid == true' "B03_AG5 valid DONE records typed evidence"

l61_missing_out="$(run_json l61-missing --dispatch-id l61-missing --task-description "ship canonical L-rule josh_request_id=null" --callback-ref "DONE l61-missing evidence=$TMP/evidence.md josh_request_id=null")"
assert_jq "$l61_missing_out" '.status == "fail" and (.failure_classes | index("orch_callback_missing_l61_fields")) and (.meta.l61_missing_fields | index("agents_md_updated")) and (.meta.l61_missing_fields | index("readme_updated"))' "L61 missing ecosystem callback fields fail validation"

l61_no_reason_out="$(run_json l61-no-reason --dispatch-id l61-no-reason --task-description "doctrine update josh_request_id=null" --callback-ref "DONE l61-no-reason evidence=$TMP/evidence.md josh_request_id=null agents_md_updated=yes readme_updated=no")"
assert_jq "$l61_no_reason_out" '.status == "fail" and (.failure_classes | index("orch_callback_missing_l61_fields")) and (.meta.l61_missing_fields | index("no_touch_reason"))' "L61 no-touch reason required when ecosystem field is no"

l61_valid_out="$(run_json l61-valid --dispatch-id l61-valid --task-description "skill ship josh_request_id=null" --callback-ref "DONE l61-valid evidence=$TMP/evidence.md josh_request_id=null agents_md_updated=yes readme_updated=no no_touch_reason=README-not-user-facing")"
assert_jq "$l61_valid_out" '.status == "pass" and .meta.l61_required == true and .schema_valid == true' "L61 ecosystem callback fields pass validation"

jr_dispatch_missing_out="$(run_json jr-dispatch-missing --dispatch-id jr-dispatch-missing --task-description "ordinary dispatch without request id" --callback-ref "DONE jr-dispatch-missing evidence=$TMP/evidence.md josh_request_id=null no_bead_reason=not-needed")"
assert_jq "$jr_dispatch_missing_out" '.status == "fail" and (.failure_classes | index("dispatch_missing_josh_request_id")) and .meta.josh_request_id_required == true' "sur0 dispatch missing josh_request_id fails validation"

jr_callback_missing_out="$(run_json jr-callback-missing --dispatch-id jr-callback-missing --task-description "ordinary dispatch josh_request_id=jr-test-001" --callback-ref "DONE jr-callback-missing evidence=$TMP/evidence.md no_bead_reason=not-needed")"
assert_jq "$jr_callback_missing_out" '.status == "fail" and (.failure_classes | index("callback_missing_josh_request_id")) and .meta.dispatch_josh_request_id == "jr-test-001"' "sur0 callback missing josh_request_id fails validation"

jr_callback_mismatch_out="$(run_json jr-callback-mismatch --dispatch-id jr-callback-mismatch --task-description "ordinary dispatch josh_request_id=jr-test-001" --callback-ref "DONE jr-callback-mismatch evidence=$TMP/evidence.md josh_request_id=jr-test-002 no_bead_reason=not-needed")"
assert_jq "$jr_callback_mismatch_out" '.status == "fail" and (.failure_classes | index("callback_josh_request_id_mismatch")) and .meta.callback_josh_request_id == "jr-test-002"' "sur0 callback mismatched josh_request_id fails validation"

jr_valid_out="$(run_json jr-valid --dispatch-id jr-valid --task-description "ordinary dispatch josh_request_id=jr-test-001" --callback-ref "DONE jr-valid evidence=$TMP/evidence.md josh_request_id=jr-test-001")"
assert_jq "$jr_valid_out" '.status == "pass" and .meta.dispatch_josh_request_id == "jr-test-001" and .meta.callback_josh_request_id == "jr-test-001"' "sur0 matching josh_request_id passes validation"

invalid_out="$(run_json invalid --dispatch-id b03-invalid --callback-ref "$TMP/invalid-callback.json")"
assert_jq "$invalid_out" '.status == "fail" and (.failure_classes | index("validation_receipt_schema_invalid"))' "B03 audit amendment invalid callback receipt"

receipt_out="$(run_json write --dispatch-id b03-write --callback-ref "$TMP/valid-done-callback.json" --write-receipt --receipt-dir "$TMP/receipts")"
receipt_path="$(jq -r '.receipt_path' "$receipt_out")"
if [[ -f "$receipt_path" ]]; then
  pass "B03_AG6 receipt ledger write"
else
  fail "B03_AG6 receipt ledger write"
fi

why_out="$(run_json why --why "$receipt_path")"
assert_jq "$why_out" '.status == "pass" and (.gates | length) >= 4' "B03_AG8 why explains receipt"

echo
echo "Summary: $pass_count passed, $fail_count failed"
[[ "$fail_count" -eq 0 ]]
