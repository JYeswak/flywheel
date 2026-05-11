#!/usr/bin/env bash
# tests/adversarial-orch-self-audit-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/adversarial-orch-self-audit-probe.sh
# (partial→passing fillin by bead flywheel-1hshd.1 — wave-4-general-1).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/adversarial-orch-self-audit-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# ===== Bash NEW canonical surfaces =====

"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples" and (.examples | length >= 5)' >/dev/null && pass "--examples emits canonical envelope (length >= 5)" || fail "--examples envelope"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null && pass "doctor emits canonical envelope" || fail "doctor envelope"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health emits canonical envelope" || fail "health envelope"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run emits canonical envelope" || fail "repair --dry-run envelope"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
if [[ "$rc" -eq 3 ]]; then pass "repair --apply without --idempotency-key returns rc=3"; else fail "repair --apply rc=$rc (expected 3)"; fi
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate emits canonical envelope" || fail "validate envelope"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit emits canonical envelope" || fail "audit envelope"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why <id> emits canonical envelope" || fail "why envelope"
"$SCRIPT" help repair 2>/dev/null | grep -q 'topic:' && pass "help repair returns topic header" || fail "help topic"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart emits canonical envelope" || fail "quickstart envelope"

# ===== BACKWARD-COMPAT — legacy dash-flag surfaces preserved =====

if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "adversarial-orch-self-audit-probe.v1" and .mode == "info"' >/dev/null; then
  pass "BACKWARD-COMPAT --info: legacy shape preserved"
else fail "--info backward-compat"; fi

if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "adversarial-orch-self-audit-probe.v1" and has("properties")' >/dev/null; then
  pass "BACKWARD-COMPAT --schema: legacy shape with properties preserved"
else fail "--schema backward-compat"; fi

if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.mode == "doctor" and .reads_only == true and .step_4o_compliance == "preserved"' >/dev/null; then
  pass "BACKWARD-COMPAT --doctor: legacy reads_only + step_4o_compliance preserved"
else fail "--doctor backward-compat"; fi

if "$SCRIPT" --health --json 2>/dev/null | jq -e '.mode == "doctor"' >/dev/null; then
  pass "BACKWARD-COMPAT --health: aliases to --doctor as before"
else fail "--health backward-compat"; fi

# ===== fillin-specific (flywheel-1hshd.1) =====

if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "jq_on_path")) and (any(.name == "dispatch_log_readable")) and (any(.name == "evidence_dir_readable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. jq + dispatch_log + evidence_dir"
else fail "doctor substrate probes"; fi

# --schema is owned by legacy python; repair surface schema is checked
# indirectly via the repair envelope shape itself in Test 17 below.
# Legacy --schema returns JSON-Schema with properties; verify that holds.
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '.properties | has("lookback_hours") and has("punt_phrase_count")' >/dev/null; then
  pass "--schema legacy JSON-Schema properties intact"
else fail "--schema legacy properties"; fi

if "$SCRIPT" repair --scope dispatch-log-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "dispatch-log-prime" and (.status != "todo") and has("dispatch_log") and has("present") and has("row_count")' >/dev/null; then
  pass "repair --scope dispatch-log-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

if "$SCRIPT" validate --row-json='{"schema_version":"adversarial-orch-self-audit-probe.v1","lookback_hours":24,"punt_phrase_count":0,"mission_drift_count":0}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces probe-output row schema (4 required fields)"
else fail "validate row schema"; fi

if "$SCRIPT" validate --dispatch-log 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "dispatch-log" and has("dispatch_log") and has("present") and has("row_count")' >/dev/null; then
  pass "validate --dispatch-log probes dispatch-log.jsonl (surface-specific)"
else fail "validate dispatch-log subject"; fi

if "$SCRIPT" validate --evidence-dir 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "evidence-dir" and has("evidence_dir") and has("present") and has("subdir_count")' >/dev/null; then
  pass "validate --evidence-dir counts evidence subdirs (surface-specific)"
else fail "validate evidence-dir subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
