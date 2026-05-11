#!/usr/bin/env bash
# tests/orch-worker-identity-manifest-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/orch-worker-identity-manifest.sh
# (filled-in by bead flywheel-5ke66.14 — wave-2-general-14).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-worker-identity-manifest.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Tests 1-13: AG1 canonical envelopes
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi
"$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null && pass "--info emits canonical envelope" || fail "--info envelope"
"$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null && pass "--schema emits canonical envelope" || fail "--schema envelope"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null && pass "--examples emits canonical envelope" || fail "--examples envelope"
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

# ===== fillin-specific + backward-compat (flywheel-5ke66.14) =====

# Test 14: BACKWARD-COMPAT — --info preserves .dry_run_supported + .apply_supported + .no_raw_tokens
# (existing tests/orch-worker-identity-manifest.sh:51)
if "$SCRIPT" --info --json 2>/dev/null \
  | jq -e '.dry_run_supported == true and .apply_supported == true and .no_raw_tokens == true' >/dev/null; then
  pass "--info backward-compat: dry_run/apply/no_raw_tokens all true"
else fail "--info backward-compat shape"; fi

# Test 15: BACKWARD-COMPAT — --schema preserves .properties.workers.type == array + schema_version const
# (existing tests/orch-worker-identity-manifest.sh:55)
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '.properties.workers.type == "array" and .properties.schema_version.const == "orch-worker-identity/v1"' >/dev/null; then
  pass "--schema backward-compat: workers.type=array + schema_version.const"
else fail "--schema backward-compat shape"; fi

# Test 16: BACKWARD-COMPAT — --examples preserves .examples | length >= 3
# (existing tests/orch-worker-identity-manifest.sh:53)
if "$SCRIPT" --examples --json 2>/dev/null \
  | jq -e '.examples | length >= 3' >/dev/null; then
  pass "--examples backward-compat: length >= 3"
else fail "--examples backward-compat length"; fi

# Test 17: doctor 5+ probes
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "python3_on_path")) and (any(.name == "loop_dir_readable")) and (any(.name == "topology_readable")) and (any(.name == "out_dir_writable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. python3 + loop_dir + topology + out_dir"
else fail "doctor substrate probes"; fi

# Test 18: repair out-dir-prime non-stub
if "$SCRIPT" repair --scope out-dir-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "out-dir-prime" and (.status != "todo") and has("out_dir") and has("present") and has("manifest_count")' >/dev/null; then
  pass "repair --scope out-dir-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

# Test 19: validate --row-json with manifest schema (6 required fields)
if "$SCRIPT" validate --row-json='{"schema_version":"orch-worker-identity/v1","session":"flywheel","generated_at":"2026-05-11T00:00:00Z","orchestrator":{},"workers":[],"validation":{}}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces manifest row schema (6 required fields)"
else fail "validate row schema"; fi

# Test 20: validate --manifests probes out-dir
if "$SCRIPT" validate --manifests 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "manifests" and has("out_dir") and has("present") and has("manifest_count") and has("sessions")' >/dev/null; then
  pass "validate --manifests probes out-dir (surface-specific)"
else fail "validate manifests subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
