#!/usr/bin/env bash
# tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/recovery-install-plist-clutterfreespaces.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-install-plist-clutterfreespaces.sh"

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

# ===== Fillin-specific assertions (flywheel-wzjo9.2.5) =====

TMP="$(mktemp -d "${TMPDIR:-/tmp}/ripc-fillin.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

# Test 14: doctor has 12 named substrate probes
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '(.checks | length) >= 12 and ([.checks[].name] | contains(["dependency:python3","dependency:jq","ntm_bin_executable","plutil_bin","launchctl_bin","plist_parent_writable","audit_script_readable","helper_lib_loaded","audit_log_writable"]))' >/dev/null; then
  pass "doctor 12 named probes (python3 + jq + ntm_bin + plutil + launchctl + plist_parent + audit_script + helper + audit_log)"
else fail "doctor named probes"; fi

# Test 15: health surfaces plist_installed + audit_log_stale + status fields
if "$SCRIPT" health --json 2>/dev/null \
  | jq -e '(.plist_installed | type == "boolean") and (.audit_log_stale | type == "boolean") and (.status | type == "string")' >/dev/null; then
  pass "health structured fields (plist_installed + audit_log_stale + status)"
else fail "health structured fields"; fi

# Test 16: repair --scope log-dir --apply with idempotency-key ensures dir
RIPC_LOG_DIR="$TMP/logs" "$SCRIPT" repair --scope log-dir --apply --idempotency-key wzjo9-2-5-test --json >"$TMP/r-log.json" 2>&1 || true
if jq -e '.scope == "log-dir" and .mode == "apply" and (.actual_actions[0] == "log_dir_ensured")' "$TMP/r-log.json" >/dev/null 2>&1 && [[ -d "$TMP/logs" ]]; then
  pass "repair --scope log-dir --apply ensures dir"
else fail "repair log-dir apply"; fi

# Test 17: repair --scope status-receipt-dir --apply ensures parent dir
RIPC_STATUS="$TMP/rcpt/status.json" "$SCRIPT" repair --scope status-receipt-dir --apply --idempotency-key wzjo9-2-5-rcpt --json >"$TMP/r-rcpt.json" 2>&1 || true
if jq -e '.scope == "status-receipt-dir" and (.actual_actions[0] == "status_receipt_dir_ensured")' "$TMP/r-rcpt.json" >/dev/null 2>&1 && [[ -d "$TMP/rcpt" ]]; then
  pass "repair --scope status-receipt-dir --apply ensures dir"
else fail "repair status-receipt-dir apply"; fi

# Test 18: validate plist subject when missing → fail with descriptive reason
RIPC_PLIST="$TMP/no-such.plist" "$SCRIPT" validate plist --json >"$TMP/v-plist.json" 2>&1 || true
if jq -e '.subject == "plist" and .status == "fail" and (.reason | test("does not exist"))' "$TMP/v-plist.json" >/dev/null 2>&1; then
  pass "validate plist missing → fail"
else fail "validate plist missing"; fi

# Test 19: validate audit-receipt absent → fail with descriptive reason
RIPC_AUDIT_RECEIPT="$TMP/no-such-audit.json" "$SCRIPT" validate audit-receipt --json >"$TMP/v-audit.json" 2>&1 || true
if jq -e '.subject == "audit-receipt" and .status == "fail" and (.reason | test("not readable"))' "$TMP/v-audit.json" >/dev/null 2>&1; then
  pass "validate audit-receipt missing → fail"
else fail "validate audit-receipt missing"; fi

# Test 20: validate audit-receipt with sufficient confidence → pass
cat >"$TMP/audit-ok.json" <<JSON
{"confidence_per_session":{"clutterfreespaces":85}}
JSON
RIPC_AUDIT_RECEIPT="$TMP/audit-ok.json" "$SCRIPT" validate audit-receipt --json >"$TMP/v-audit-ok.json" 2>&1 || true
if jq -e '.subject == "audit-receipt" and .status == "pass" and (.reason | test("85"))' "$TMP/v-audit-ok.json" >/dev/null 2>&1; then
  pass "validate audit-receipt sufficient confidence → pass"
else fail "validate audit-receipt confidence pass"; fi

# Test 21: validate config subject
if "$SCRIPT" validate config --json 2>/dev/null \
  | jq -e '.subject == "config" and (.status == "pass" or .status == "fail")' >/dev/null; then
  pass "validate config subject"
else fail "validate config subject"; fi

# Test 22: schema status variant pins recovery-session-watcher-install/v1
if "$SCRIPT" --schema status 2>/dev/null \
  | jq -e '.schema_version == "recovery-session-watcher-install/v1" and .command == "status"' >/dev/null; then
  pass "schema status variant pins recovery-session-watcher-install/v1"
else fail "schema status variant"; fi

# Test 23: why with 5 known ids returns resolution=found or unavailable
why_found=0
for id in label audit dry_run_pass watcher_race install_flow; do
  res="$("$SCRIPT" why "$id" --json 2>/dev/null | jq -r '.resolution')"
  if [[ "$res" == "found" || "$res" == "unavailable" ]]; then why_found=$((why_found + 1)); fi
done
if [[ "$why_found" -ge 4 ]]; then
  pass "why 5 known ids: $why_found/5 resolve"
else fail "why multi-resolution ($why_found/5)"; fi

# Test 24: why with unknown id returns not_found
if "$SCRIPT" why definitely-not-a-real-id --json 2>/dev/null \
  | jq -e '.resolution == "not_found"' >/dev/null; then
  pass "why unknown id returns not_found"
else fail "why not_found resolution"; fi

# Test 25: cli_audit_append wired — doctor
audit_trace="$TMP/trace-doctor.jsonl"
: >"$audit_trace"
SCAFFOLD_AUDIT_LOG="$audit_trace" "$SCRIPT" doctor --json >/dev/null 2>&1 || true
if [[ -s "$audit_trace" ]] && jq -e '.action == "doctor"' "$audit_trace" >/dev/null 2>&1; then
  pass "cli_audit_append wired for doctor"
else fail "cli_audit_append doctor"; fi

# Test 26: cli_audit_append wired — repair
audit_trace2="$TMP/trace-repair.jsonl"
: >"$audit_trace2"
SCAFFOLD_AUDIT_LOG="$audit_trace2" RIPC_LOG_DIR="$TMP/logs2" "$SCRIPT" repair --scope log-dir --dry-run --json >/dev/null 2>&1 || true
if [[ -s "$audit_trace2" ]] && jq -e '.action == "repair"' "$audit_trace2" >/dev/null 2>&1; then
  pass "cli_audit_append wired for repair"
else fail "cli_audit_append repair"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
