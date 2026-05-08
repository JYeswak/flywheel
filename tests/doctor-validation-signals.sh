#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-validation-signals.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

make_repo() {
  local repo="$TMP/repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime/flywheel-loop" \
    "$repo/.flywheel/validation-schema/v1" "$repo/.flywheel/validation-receipts" \
    "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  cp "$ROOT/.flywheel/scripts/validate-callback.py" "$repo/.flywheel/scripts/validate-callback.py"
  cp "$ROOT/.flywheel/scripts/ticks-punted-probe.sh" "$repo/.flywheel/scripts/ticks-punted-probe.sh"
  cp "$ROOT/.flywheel/scripts/closed-bead-artifact-scan.py" "$repo/.flywheel/scripts/closed-bead-artifact-scan.py"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  chmod +x "$repo/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/scripts/ticks-punted-probe.sh" "$repo/.flywheel/scripts/closed-bead-artifact-scan.py"
  printf 'validation_receipt_schema_v1\t.flywheel/validation-schema/v1/schema.json\tflywheel-bc7c\tpresent\n' >"$repo/.flywheel/canonical-paths.txt"
  printf 'missing_surface\t.flywheel/missing-surface.txt\tflywheel-zgo3\tfixture missing path\n' >>"$repo/.flywheel/canonical-paths.txt"
  python3 - "$repo" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1])
receipts = repo / ".flywheel/validation-receipts"
base = {
    "schema_version": "validation-receipt/v1",
    "dispatch_id": "b04-fixture",
    "callback_ref": {
        "transport": "manual_fixture",
        "session": "flywheel",
        "pane": 3,
        "kind": "DONE",
        "received_at": "2026-05-03T23:50:00Z",
        "raw_ref": "DONE b04-fixture evidence=fixture",
    },
    "status": "pass",
    "failure_classes": [],
    "evidence": [{"type": "path", "ref": ".flywheel/validation-schema/v1/schema.json"}],
    "artifact_checks": [{"artifact_id": "schema", "path": ".flywheel/validation-schema/v1/schema.json", "status": "exists"}],
    "runtime_context": {
        "agent_context": {"status": "responsive", "probe_ref": "fixture://agent", "resolved_tools": ["ntm"]},
        "orchestrator_shell_context": {"status": "responsive", "probe_ref": "fixture://orch", "resolved_tools": ["ntm"]},
        "timeout": False,
        "context_drift": False,
    },
    "bead_actions": [{"action": "no_bead_reason", "reason": "fixture receipt only no issue observed"}],
    "learn_route": {"route": "ignore", "reason": "fixture positive receipt"},
    "chain_blocker": {"next_phase": None, "capacity_available": False, "chain_blocked_reason": None},
}

(receipts / "01-pass.json").write_text(json.dumps(base))

failed = dict(base)
failed["dispatch_id"] = "b04-failed"
failed["status"] = "fail"
failed["failure_classes"] = ["artifact_missing"]
failed["artifact_checks"] = [{"artifact_id": "missing", "path": "missing-artifact.md", "status": "missing"}]
failed["learn_route"] = {"route": "review", "reason": "fixture failed validation"}
(receipts / "02-fail.json").write_text(json.dumps(failed))

drift = dict(base)
drift["dispatch_id"] = "b04-drift"
drift["status"] = "fail"
drift["failure_classes"] = ["context_drift"]
drift["runtime_context"] = dict(base["runtime_context"])
drift["runtime_context"]["context_drift"] = True
drift["learn_route"] = {"route": "review", "reason": "fixture context drift"}
(receipts / "03-drift.json").write_text(json.dumps(drift))

unrouted = dict(base)
unrouted["dispatch_id"] = "b04-unrouted"
unrouted["learn_route"] = {"route": "unknown", "reason": "fixture invalid route"}
(receipts / "04-unrouted-invalid.json").write_text(json.dumps(unrouted))
(receipts / "05-invalid-json.json").write_text("{not-json")

(repo / ".flywheel/runtime/flywheel-loop/last_run.json").write_text(json.dumps({
    "validation_summary": {"callbacks_unvalidated_count": 1, "failed_count": 1}
}))
(repo / ".flywheel/dispatch-log.jsonl").write_text("\n".join([
    json.dumps({"event": "callback_validation_reaper_gate", "result": {"action": "skipped", "reason": "callback_not_found"}}),
    json.dumps({"event": "callback_validation_reaper_gate", "result": {"action": "validated", "result": {"status": "fail"}}}),
    json.dumps({"event": "l70_chain_decision", "chain_required": True, "chained": False, "chain_blocked_reason": ""}),
]) + "\n")
(repo / ".beads/issues.jsonl").write_text(json.dumps({
    "id": "flywheel-b04-fixture",
    "status": "closed",
    "close_reason": "DONE evidence=missing-closed-artifact.md"
}) + "\n")
PY
  printf '%s\n' "$repo"
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

repo="$(make_repo)"
storage_fixture="$TMP/storage-healthy.json"
tmp_entry_root="$TMP/private-tmp-ok"
mkdir -p "$tmp_entry_root"
jq -nc '{
  disk_total_gb:926,
  disk_free_gb:400,
  disk_free_pct:43,
  developer_dir_gb:328,
  local_state_gb:2.1,
  stale_baks_count:0,
  stale_baks_size_mb:0,
  qdrant_volumes_size_mb:217,
  tmp_dispatch_artifacts_count:0
}' >"$storage_fixture"
out="$TMP/doctor.json"
strict_out="$TMP/doctor-strict.json"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_TMP_ENTRY_ROOT="$tmp_entry_root" FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" "$BIN" doctor --repo "$repo" --json >"$out" 2>"$TMP/doctor.err" || true
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_TMP_ENTRY_ROOT="$tmp_entry_root" FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" "$BIN" doctor --strict --repo "$repo" --json >"$strict_out" 2>"$TMP/doctor-strict.err" && strict_rc=0 || strict_rc=$?

assert_jq "$out" '.callbacks_unvalidated_count == 1' "B04_AG1 callbacks_unvalidated_count"
assert_jq "$out" '.callbacks_validated_with_failures_count >= 1' "B04_AG2 callbacks_validated_with_failures_count"
assert_jq "$out" '.ticks_punted_count == 1' "B04_AG3 ticks_punted_count"
assert_jq "$out" '.surfaces_unwired_count == 1' "B04_AG4 surfaces_unwired_count"
assert_jq "$out" '.closed_bead_artifact_missing_count == 1' "B04_AG5 closed_bead_artifact_missing_count"
assert_jq "$out" '.closed_bead_reopen_candidates_count == 1 and (.callback_validation.closed_bead_reopen_scan.candidates | length) == 1' "B07 doctor field closed_bead_reopen_candidates_count"
assert_jq "$out" '.validation_receipts_schema_invalid_count >= 1 and .agent_context_probe_drift_count == 1 and .validation_events_unrouted_count == 1' "B04_AG6 secondary validation signals"
assert_jq "$out" '(.callback_validation.signals | length) >= 8 and all(.callback_validation.signals[]; has("producer") and has("measurement") and has("consumer") and has("promotion_path"))' "B04_AG7 L60 signal metadata"
assert_jq "$out" '.storage.status == "ok" and .storage.disk_free_pct == 43 and .storage.stale_baks_count == 0 and .storage.tmp_entry_count == 0 and .storage.tmp_entry_count_status == "ok"' "B13 storage doctor field"
assert_jq "$out" 'has("storage_override") and .storage_override_active_count == 0 and (.storage_override_expiring_in_min == null)' "B13 storage override doctor fields"
if [[ "$strict_rc" -ne 0 ]] && jq -e '.status == "fail" and any(.errors[]?; .code == "callbacks_unvalidated_count")' "$strict_out" >/dev/null; then
  pass "B04_AG8 strict fails on unvalidated callbacks"
else
  fail "B04_AG8 strict fails on unvalidated callbacks"
  jq . "$strict_out" || true
fi
assert_jq "$out" 'has("callback_validation") and has("callbacks_unvalidated_count") and has("validation_receipts_schema_invalid_count") and (.callback_validation | has("signals"))' "B04_AG9 stable doctor JSON fields"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
