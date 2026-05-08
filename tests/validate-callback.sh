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
correctness = dict(base)
correctness["status"] = "fail"
correctness["failure_classes"] = ["l112_verify_failed"]
correctness["bead_actions"] = [{"action": "no_bead_reason", "reason": "fixture correctness regression routed"}]
(tmp / "correctness-callback.json").write_text(json.dumps(correctness))
clean_reservation = dict(base)
clean_reservation["agent_mail_thread"] = "thread-clean-001"
clean_reservation["identity_name"] = "CloudyMill"
clean_reservation["files_reserved"] = ["README.md"]
clean_reservation["files_released"] = ["README.md"]
(tmp / "clean-reservation-callback.json").write_text(json.dumps(clean_reservation))
missing_release = dict(base)
missing_release["agent_mail"] = {
    "agent_mail_thread": "thread-missing-release-001",
    "identity_name": "CloudyMill",
    "files_reserved": ["AGENTS.md"],
    "files_released": [],
}
missing_release["bead_actions"] = [{"action": "no_bead_reason", "reason": "fixture missing release routed to worker correction"}]
(tmp / "missing-release-callback.json").write_text(json.dumps(missing_release))
conflict = dict(base)
conflict["agent_mail"] = {
    "agent_mail_thread": "thread-conflict-001",
    "identity_name": "CloudyMill",
    "files_reserved": ["AGENTS.md"],
    "files_released": [],
    "reservation_conflicts": ["holder=OtherPane:path=AGENTS.md"],
}
conflict["bead_actions"] = [{"action": "no_bead_reason", "reason": "fixture conflict evidence routed to orchestrator"}]
(tmp / "reservation-conflict-callback.json").write_text(json.dumps(conflict))
expired = dict(base)
expired["agent_mail"] = {
    "agent_mail_thread": "thread-expired-001",
    "identity_name": "CloudyMill",
    "files_reserved": ["README.md"],
    "files_released": [],
    "reservation_state": "expired",
}
expired["bead_actions"] = [{"action": "no_bead_reason", "reason": "fixture expired reservation routed to re-reserve"}]
(tmp / "expired-reservation-callback.json").write_text(json.dumps(expired))
force_released = dict(base)
force_released["agent_mail"] = {
    "agent_mail_thread": "thread-force-release-001",
    "identity_name": "CloudyMill",
    "files_reserved": ["README.md"],
    "files_released": [],
    "reservation_state": "force-released",
}
(tmp / "force-released-callback.json").write_text(json.dumps(force_released))
no_edit = dict(base)
no_edit["files_reserved"] = "NONE_NO_EDITS"
no_edit["files_released"] = "NONE_NO_EDITS"
(tmp / "no-edit-callback.json").write_text(json.dumps(no_edit))
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
assert_jq "$schema_out" '.command == "flywheel-loop validate-callback" and .read_only_default == true and (.agent_mail_receipt_fields | index("reservation_conflicts")) and (.reservation_lifecycle_states | index("force-released"))' "B03_AG1 command surface schema"

examples_out="$(run_json examples --examples)"
assert_jq "$examples_out" '(.examples | length) >= 4' "B03_AG2 examples surface"

missing_out="$(run_json missing --dispatch-id b03-missing --callback-ref "$TMP/missing-artifact-callback.json")"
missing_rc="$(cat "$TMP/missing.rc")"
if [[ "$missing_rc" != "0" ]]; then
  pass "B03_AG3 missing artifact exits non-zero"
else
  fail "B03_AG3 missing artifact exits non-zero"
fi
assert_jq "$missing_out" '.status == "fail" and .failure_class == "missing_artifact" and .retry_policy == "manual" and .summary_allowed == false and .integration_allowed == false' "B03_AG3 missing artifact receipt"
assert_jq "$missing_out" '.remediation_required == true and .remediation_present == false' "B03_AG7 failed callback requires remediation before summary"

timeout_out="$(run_json timeout --dispatch-id b03-timeout --callback-ref "$TMP/runtime-timeout-callback.json")"
timeout_rc="$(cat "$TMP/timeout.rc")"
if [[ "$timeout_rc" == "3" ]]; then
  pass "B03_AG4 runtime timeout exits unknown"
else
  fail "B03_AG4 runtime timeout exits unknown"
fi
assert_jq "$timeout_out" '.status == "unknown" and .failure_class == "transient" and .retry_policy == "exponential"' "B03_AG4 runtime timeout class"

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
assert_jq "$invalid_out" '.status == "fail" and (.failure_classes | index("validation_receipt_schema_invalid")) and .failure_class == "invalid_callback" and .retry_policy != "exponential"' "B03 audit amendment invalid callback receipt"

correctness_out="$(run_json correctness --dispatch-id b03-correctness --callback-ref "$TMP/correctness-callback.json")"
assert_jq "$correctness_out" '.status == "fail" and .failure_class == "correctness" and .retry_policy == "permanent"' "correctness regression is permanent not flake"

clean_reservation_out="$(run_json clean-reservation --dispatch-id f2bm-clean --callback-ref "$TMP/clean-reservation-callback.json")"
assert_jq "$clean_reservation_out" '.status == "pass" and .validation_receipt.agent_mail.agent_mail_thread == "thread-clean-001" and .validation_receipt.agent_mail.identity_name == "CloudyMill" and .validation_receipt.agent_mail.files_reserved == ["README.md"] and .validation_receipt.agent_mail.files_released == ["README.md"] and .validation_receipt.agent_mail.reservation_conflicts == [] and .validation_receipt.agent_mail.reservation_lifecycle.state == "released"' "f2bm clean reservation lifecycle passes"

missing_release_out="$(run_json missing-release --dispatch-id f2bm-missing-release --callback-ref "$TMP/missing-release-callback.json")"
assert_jq "$missing_release_out" '.status == "fail" and (.failure_classes | index("reservation_missing_release")) and .validation_receipt.agent_mail.reservation_lifecycle.state == "reservation_succeeded"' "f2bm missing release blocks validation"

reservation_conflict_out="$(run_json reservation-conflict --dispatch-id f2bm-conflict --callback-ref "$TMP/reservation-conflict-callback.json")"
assert_jq "$reservation_conflict_out" '.status == "fail" and (.failure_classes | index("reservation_conflict")) and .validation_receipt.agent_mail.reservation_lifecycle.state == "conflict" and (.validation_receipt.agent_mail.reservation_conflicts | length) == 1' "f2bm reservation conflict blocks validation"

expired_reservation_out="$(run_json expired-reservation --dispatch-id f2bm-expired --callback-ref "$TMP/expired-reservation-callback.json")"
assert_jq "$expired_reservation_out" '.status == "fail" and (.failure_classes | index("reservation_expired")) and .validation_receipt.agent_mail.reservation_lifecycle.state == "expired"' "f2bm expired reservation blocks validation"

force_released_out="$(run_json force-released --dispatch-id f2bm-force-released --callback-ref "$TMP/force-released-callback.json")"
assert_jq "$force_released_out" '.status == "pass" and .validation_receipt.agent_mail.reservation_lifecycle.state == "force-released"' "f2bm force-released reservation is distinguished"

no_edit_out="$(run_json no-edit --dispatch-id f2bm-no-edit --callback-ref "$TMP/no-edit-callback.json")"
assert_jq "$no_edit_out" '.status == "pass" and .validation_receipt.agent_mail.reservation_lifecycle.state == "no_reservation_required" and .validation_receipt.agent_mail.files_reserved == ["NONE_NO_EDITS"]' "f2bm no-edit dispatch records no reservation required"

raw_callback_out="$(run_json raw-callback --dispatch-id f2bm-raw --callback-ref "DONE f2bm evidence=$TMP/evidence.md josh_request_id=null agent_mail_thread=thread-raw-001 identity_name=CloudyMill files_reserved=README.md files_released=README.md reservation_conflicts=none no_bead_reason=raw-callback-fixture-routed")"
assert_jq "$raw_callback_out" '.status == "pass" and .validation_receipt.agent_mail.agent_mail_thread == "thread-raw-001" and .validation_receipt.agent_mail.identity_name == "CloudyMill" and .validation_receipt.agent_mail.reservation_lifecycle.state == "released"' "f2bm raw worker callback fields parse without tokens"

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
