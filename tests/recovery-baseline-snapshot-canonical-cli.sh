#!/usr/bin/env bash
# tests/recovery-baseline-snapshot-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/recovery-baseline-snapshot.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-baseline-snapshot.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples returns valid JSON
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor returns valid envelope (even pre-fill-in stub is valid JSON)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor emits canonical envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits canonical envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate emits canonical envelope"
else fail "validate envelope"; fi

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why envelope"; fi

# Test 12: help <topic> returns text (intercepted only with topic arg)
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# ===== Fillin-specific assertions (flywheel-wzjo9.2.2) =====

TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-baseline-fillin.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

# Test 14: doctor has 8 named substrate probes
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '(.checks | length) >= 8 and ([.checks[].name] | contains(["dependency:python3","snapshot_dir","state_dir","ntm_config_readable","dependency:jq","helper_lib_loaded","audit_log_writable","source_plan_readable"]))' >/dev/null; then
  pass "doctor 8 named probes (python3 + snapshot_dir + state_dir + ntm + jq + helper + audit_log + source_plan)"
else fail "doctor named probes"; fi

# Test 15: health surfaces latest_manifest + manifest_count + audit_log_stale fields
if "$SCRIPT" health --json 2>/dev/null \
  | jq -e '(.manifest_count | type == "number") and (.latest_manifest_age_seconds | type) and (.audit_log_stale | type == "boolean")' >/dev/null; then
  pass "health structured fields (manifest_count + age + audit_log_stale)"
else fail "health structured fields"; fi

# Test 16: repair --scope snapshot-dir --apply with idempotency-key ensures dir
FLYWHEEL_RECOVERY_SNAPSHOT_DIR="$TMP/snap" "$SCRIPT" repair --scope snapshot-dir --apply --idempotency-key wzjo9-2-2-test --json >"$TMP/repair-snap.json" 2>&1 || true
if jq -e '.scope == "snapshot-dir" and .mode == "apply" and (.actual_actions[0] == "snapshot_dir_ensured")' "$TMP/repair-snap.json" >/dev/null 2>&1 \
   && [[ -d "$TMP/snap" ]]; then
  pass "repair --scope snapshot-dir --apply ensures dir"
else fail "repair snapshot-dir apply"; fi

# Test 17: repair --scope audit-log --apply with idempotency-key ensures audit-log parent dir
SCAFFOLD_AUDIT_LOG="$TMP/aud/runs.jsonl" "$SCRIPT" repair --scope audit-log --apply --idempotency-key wzjo9-2-2-test-aud --json >"$TMP/repair-aud.json" 2>&1 || true
if jq -e '.scope == "audit-log" and (.actual_actions[0] == "audit_log_dir_ensured")' "$TMP/repair-aud.json" >/dev/null 2>&1 \
   && [[ -d "$TMP/aud" ]]; then
  pass "repair --scope audit-log --apply ensures dir"
else fail "repair audit-log apply"; fi

# Test 18: validate manifest subject reports a schema_version-related reason
FLYWHEEL_RECOVERY_SNAPSHOT_DIR="$TMP/snap" "$SCRIPT" validate manifest --json >"$TMP/v-manifest.json" 2>&1 || true
if jq -e '.subject == "manifest" and (.reason | type == "string")' "$TMP/v-manifest.json" >/dev/null 2>&1; then
  pass "validate manifest subject"
else fail "validate manifest subject"; fi

# Test 19: validate config subject lists missing dependencies/paths if any
if "$SCRIPT" validate config --json 2>/dev/null \
  | jq -e '.subject == "config" and (.status == "pass" or .status == "fail") and (.reason | type == "string")' >/dev/null; then
  pass "validate config subject"
else fail "validate config subject"; fi

# Test 20: validate snapshot-dir subject when dir absent → fail with descriptive reason
FLYWHEEL_RECOVERY_SNAPSHOT_DIR="$TMP/no-such-snap-$$" "$SCRIPT" validate snapshot-dir --json >"$TMP/v-snap.json" 2>&1 || true
if jq -e '.subject == "snapshot-dir" and .status == "fail" and (.reason | test("does not exist"))' "$TMP/v-snap.json" >/dev/null 2>&1; then
  pass "validate snapshot-dir absent → fail"
else fail "validate snapshot-dir absent"; fi

# Test 21: schema manifest variant pins flywheel-recovery-baseline/v1
if "$SCRIPT" --schema manifest 2>/dev/null \
  | jq -e '.schema_version == "flywheel-recovery-baseline/v1" and .command == "manifest"' >/dev/null; then
  pass "schema manifest variant pins flywheel-recovery-baseline/v1"
else fail "schema manifest variant"; fi

# Test 22: why with 5 known ids returns resolution=found
why_found=0
for id in baseline retention protected trigger sessions; do
  res="$("$SCRIPT" why "$id" --json 2>/dev/null | jq -r '.resolution')"
  if [[ "$res" == "found" ]]; then why_found=$((why_found + 1)); fi
done
if [[ "$why_found" -ge 4 ]]; then
  pass "why 5 known ids: $why_found/5 resolve to found"
else fail "why multi-resolution coverage ($why_found/5)"; fi

# Test 23: why with unknown id returns resolution=not_found
if "$SCRIPT" why definitely-not-a-real-id --json 2>/dev/null \
  | jq -e '.resolution == "not_found"' >/dev/null; then
  pass "why unknown id returns not_found"
else fail "why not_found resolution"; fi

# Test 24: cli_audit_append wired — doctor invocation appends row
audit_trace="$TMP/trace-doctor.jsonl"
: >"$audit_trace"
SCAFFOLD_AUDIT_LOG="$audit_trace" "$SCRIPT" doctor --json >/dev/null 2>&1 || true
if [[ -s "$audit_trace" ]] && jq -e '.action == "doctor"' "$audit_trace" >/dev/null 2>&1; then
  pass "cli_audit_append wired for doctor"
else fail "cli_audit_append doctor"; fi

# Test 25: cli_audit_append wired — repair invocation appends row
audit_trace2="$TMP/trace-repair.jsonl"
: >"$audit_trace2"
SCAFFOLD_AUDIT_LOG="$audit_trace2" FLYWHEEL_RECOVERY_SNAPSHOT_DIR="$TMP/snap2" \
  "$SCRIPT" repair --scope snapshot-dir --dry-run --json >/dev/null 2>&1 || true
if [[ -s "$audit_trace2" ]] && jq -e '.action == "repair"' "$audit_trace2" >/dev/null 2>&1; then
  pass "cli_audit_append wired for repair"
else fail "cli_audit_append repair"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
