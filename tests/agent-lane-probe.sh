#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/agent-lane-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-agent-lane-probe-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

mkdir -p "$TMP/bin" "$TMP/receipts"
printf '#!/usr/bin/env bash\nexit 0\n' >"$TMP/bin/claude"
printf '#!/usr/bin/env bash\nexit 0\n' >"$TMP/bin/codex"
chmod +x "$TMP/bin/claude" "$TMP/bin/codex"

cat >"$TMP/receipts/gemini.json" <<'JSON'
{
  "schema_version": "flywheel.agent_lane_runtime_receipt.v0",
  "id": "gemini",
  "agent": "Gemini CLI",
  "generated_at": "2026-05-13T12:00:00Z",
  "status": "pass",
  "runtime_proven": true,
  "support_scope": "isolated",
  "command": "scripts/journey-smoke.sh --matrix gemini --receipt-dir receipts/agent-lanes --json",
  "private_state_scan": {"status": "pass"},
  "journey_stages": [
    {"name": "preflight", "status": "pass"},
    {"name": "init", "status": "pass"},
    {"name": "doctor", "status": "pass"},
    {"name": "tick", "status": "pass"},
    {"name": "dispatch_or_simulate", "status": "pass"},
    {"name": "closeout", "status": "pass"},
    {"name": "inspect_next_action", "status": "pass"}
  ]
}
JSON
cat >"$TMP/receipts/codex.json" <<'JSON'
{
  "schema_version": "flywheel.agent_lane_blocker_receipt.v0",
  "id": "codex",
  "agent": "Codex CLI",
  "generated_at": "2026-05-13T12:00:00Z",
  "status": "blocked",
  "runtime_proven": false,
  "support_copy_allowed": false,
  "support_scope": "blocked",
  "command": "scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json",
  "blocker_class": "isolated_runtime_receipt_missing",
  "blocker_reason": "Codex CLI is installed, but no isolated first-run runtime receipt exists.",
  "next_action": "Run the lane journey in an isolated public export and replace this blocker with a runtime receipt only if every stage passes.",
  "private_state_scan": {"status": "not_run"}
}
JSON
cat >"$TMP/receipts/openclaw.json" <<'JSON'
{
  "schema_version": "flywheel.agent_lane_runtime_receipt.v0",
  "id": "openclaw",
  "agent": "OpenClaw",
  "generated_at": "2026-05-13T12:00:00Z",
  "status": "pass",
  "runtime_proven": true,
  "support_scope": "isolated",
  "command": "scripts/journey-smoke.sh --matrix openclaw --receipt-dir receipts/agent-lanes --json",
  "private_state_scan": {"status": "pass"},
  "journey_stages": [
    {"name": "preflight", "status": "pass"},
    {"name": "init", "status": "pass"},
    {"name": "doctor", "status": "pass"},
    {"name": "tick", "status": "pass"},
    {"name": "dispatch_or_simulate", "status": "pass"},
    {"name": "closeout", "status": "fail"},
    {"name": "inspect_next_action", "status": "pass"}
  ]
}
JSON

if bash -n "$SCRIPT" && "$SCRIPT" --help >/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

run_capture "$TMP/probe.json" "$TMP/probe.err" env PATH="$TMP/bin:/usr/bin:/bin" "$SCRIPT" --receipt-dir "$TMP/receipts" --json
probe_rc=$?
if [[ "$probe_rc" -eq 0 ]] && jq -e '
  .schema_version == "flywheel.agent_lane_probe.v0"
  and .status == "pass"
  and .summary.lanes == 4
  and .summary.cli_present == 2
  and .summary.runtime_proven == 1
  and .summary.blocked_receipts == 1
' "$TMP/probe.json" >/dev/null; then
  pass "probe envelope"
else
  fail "probe envelope rc=${probe_rc}"
fi

if jq -e '
  [.rows[] | select(.id == "claude" and .cli_present == true and .runtime_proven == false and .support_copy_allowed == false and .evidence == "cli_presence_only")]
  | length == 1
' "$TMP/probe.json" >/dev/null; then
  pass "cli presence is not support proof"
else
  fail "cli presence is not support proof"
fi

if jq -e '
  .rows[]
  | select(.id == "codex")
  | .runtime_proven == false
    and .support_copy_allowed == false
    and .public_status == "compatibility-target"
    and .evidence == "blocker_receipt"
    and .blocked_by_receipt == true
    and .blocker.blocker_class == "isolated_runtime_receipt_missing"
' "$TMP/probe.json" >/dev/null; then
  pass "blocked receipt names blocker without support copy"
else
  fail "blocked receipt names blocker without support copy"
fi

if jq -e '
  .rows[]
  | select(.id == "gemini")
  | .runtime_proven == true
    and .support_copy_allowed == true
    and .public_status == "runtime-proven"
    and .evidence == "runtime_receipt"
' "$TMP/probe.json" >/dev/null; then
  pass "valid runtime receipt permits support copy"
else
  fail "valid runtime receipt permits support copy"
fi

if jq -e '
  .rows[]
  | select(.id == "openclaw")
  | .runtime_proven == false
    and .support_copy_allowed == false
    and .public_status == "compatibility-target"
' "$TMP/probe.json" >/dev/null; then
  pass "invalid runtime receipt remains compatibility target"
else
  fail "failed-stage runtime receipt remains compatibility target"
fi

cat >"$TMP/receipts/gemini.json" <<'JSON'
{
  "schema_version": "flywheel.agent_lane_runtime_receipt.v0",
  "id": "gemini",
  "agent": "Gemini CLI",
  "generated_at": "2026-05-13T12:00:00Z",
  "status": "pass",
  "runtime_proven": true,
  "support_scope": "isolated",
  "command": "scripts/journey-smoke.sh --matrix gemini --receipt-dir receipts/agent-lanes --json",
  "private_state_scan": {"status": "pass", "findings": []},
  "journey_stages": [
    {"name": "preflight", "status": "pass"},
    {"name": "init", "status": "pass"},
    {"name": "doctor", "status": "pass"},
    {"name": "tick", "status": "pass"},
    {"name": "dispatch_or_simulate", "status": "pass"},
    {"name": "closeout", "status": "pass"},
    {"name": "inspect_next_action", "status": "pass"},
    {"name": "closeout", "status": "fail"}
  ]
}
JSON
run_capture "$TMP/duplicate-stage.json" "$TMP/duplicate-stage.err" env PATH="$TMP/bin:/usr/bin:/bin" "$SCRIPT" --receipt-dir "$TMP/receipts" --json
duplicate_stage_rc=$?
if [[ "$duplicate_stage_rc" -eq 0 ]] && jq -e '
  .rows[]
  | select(.id == "gemini")
  | .runtime_proven == false
    and .support_copy_allowed == false
    and .public_status == "compatibility-target"
' "$TMP/duplicate-stage.json" >/dev/null; then
  pass "duplicate conflicting runtime stage does not permit support copy"
else
  fail "duplicate conflicting runtime stage does not permit support copy rc=${duplicate_stage_rc}"
fi

cat >"$TMP/receipts/gemini.json" <<'JSON'
{
  "schema_version": "flywheel.agent_lane_runtime_receipt.v0",
  "id": "gemini",
  "agent": "Gemini CLI",
  "generated_at": "2026-05-13T12:00:00Z",
  "status": "pass",
  "runtime_proven": true,
  "support_scope": "isolated",
  "command": "scripts/journey-smoke.sh --matrix gemini --receipt-dir receipts/agent-lanes --json",
  "private_state_scan": {
    "status": "pass",
    "findings": [{"path": ".flywheel/private-state.json"}]
  },
  "journey_stages": [
    {"name": "preflight", "status": "pass"},
    {"name": "init", "status": "pass"},
    {"name": "doctor", "status": "pass"},
    {"name": "tick", "status": "pass"},
    {"name": "dispatch_or_simulate", "status": "pass"},
    {"name": "closeout", "status": "pass"},
    {"name": "inspect_next_action", "status": "pass"}
  ]
}
JSON
run_capture "$TMP/private-findings.json" "$TMP/private-findings.err" env PATH="$TMP/bin:/usr/bin:/bin" "$SCRIPT" --receipt-dir "$TMP/receipts" --json
private_findings_rc=$?
if [[ "$private_findings_rc" -eq 0 ]] && jq -e '
  .rows[]
  | select(.id == "gemini")
  | .runtime_proven == false
    and .support_copy_allowed == false
    and .public_status == "compatibility-target"
' "$TMP/private-findings.json" >/dev/null; then
  pass "private-state findings do not permit support copy"
else
  fail "private-state findings do not permit support copy rc=${private_findings_rc}"
fi

cat >"$TMP/receipts/claude.json" <<'JSON'
{"id":"claude","status":"pass","runtime_proven":true}
JSON
run_capture "$TMP/weak.json" "$TMP/weak.err" env PATH="$TMP/bin:/usr/bin:/bin" "$SCRIPT" --receipt-dir "$TMP/receipts" --json
weak_rc=$?
if [[ "$weak_rc" -eq 0 ]] && jq -e '
  .rows[]
  | select(.id == "claude")
  | .runtime_proven == false
    and .support_copy_allowed == false
    and .public_status == "compatibility-target"
    and .evidence == "cli_presence_only"
' "$TMP/weak.json" >/dev/null; then
  pass "weak runtime receipt does not permit support copy"
else
  fail "weak runtime receipt does not permit support copy rc=${weak_rc}"
fi

run_capture "$TMP/missing.out" "$TMP/missing.err" "$SCRIPT" --receipt-dir "$TMP/receipts"
missing_rc=$?
if [[ "$missing_rc" -eq 64 ]] && rg -q -- "--json is required" "$TMP/missing.err"; then
  pass "json mode required"
else
  fail "json mode required rc=${missing_rc}"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
