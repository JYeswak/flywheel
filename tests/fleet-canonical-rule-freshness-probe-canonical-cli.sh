#!/usr/bin/env bash
# tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-canonical-rule-freshness-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (NUANCED-PARTIAL-BYPASS — emits text
# purpose description, NOT canonical JSON envelope; calibrated per
# feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
if "$SCRIPT" --info 2>/dev/null | grep -q 'fleet-canonical-rule-freshness-probe'; then
  pass "--info emits native text purpose description (NUANCED-PARTIAL-BYPASS)"
else fail "--info native text"; fi

# Test 3: --schema native PASSTHRU envelope (raw JSON-Schema for per-session
# row format, NOT scaffold canonical envelope)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.type == "object" and (.properties | has("status"))' >/dev/null; then
  pass "--schema emits native raw JSON-Schema for per-session row (NUANCED-PARTIAL-BYPASS)"
else fail "--schema native JSON-Schema"; fi

# Test 4: --examples scaffold envelope (NOT bypassed — scaffold owns this
# because native errors with rc=64 unknown-arg)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits scaffold envelope (NOT bypassed — native errors on this flag)"
else fail "--examples scaffold envelope"; fi

# Test 5: doctor scaffold envelope (>=5 named probes per AG3)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (calibrated to real scope)
if "$SCRIPT" repair --scope canonical_index_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope canonical_index_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope canonical_index_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/5ke66-8-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-8-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-8-test9.json

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

# ---------- fillin-specific assertions (6 added per worker-tick contract) ----------
# This surface is wzjo9.1.7 NUANCED-PARTIAL-BYPASS: --info/--schema route to
# native; --examples + verbs route to scaffold. Fourth wzjo9.1.7 variant
# (after NO-BYPASS / PARTIAL-BYPASS / BYPASS-ALL).

# Test 14: NUANCED-PARTIAL-BYPASS contract is annotated in the script
if grep -q 'NUANCED-PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates NUANCED-PARTIAL-BYPASS variant (discoverable via grep)"
else fail "NUANCED-PARTIAL-BYPASS annotation missing"; fi

# Test 15: BOTH bypass directions correct — --info to native (text) AND
# --examples to scaffold (canonical envelope) — dual-direction fidelity check
INFO_NATIVE=0; EXAMPLES_SCAFFOLD=0
if "$SCRIPT" --info 2>/dev/null | grep -q 'fleet-canonical-rule-freshness-probe' \
   && ! "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version' >/dev/null 2>&1; then
  INFO_NATIVE=1
fi
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.schema_version and .command == "examples"' >/dev/null; then
  EXAMPLES_SCAFFOLD=1
fi
if [[ "$INFO_NATIVE" -eq 1 && "$EXAMPLES_SCAFFOLD" -eq 1 ]]; then
  pass "NUANCED bypass dual-direction: --info goes native (text, no schema_version), --examples goes scaffold (canonical envelope)"
else fail "NUANCED bypass dual-direction (info_native=$INFO_NATIVE examples_scaffold=$EXAMPLES_SCAFFOLD)"; fi

# Test 16: validate status-value accepts each of native --schema's enum
# (fresh|stale|missing — these are the LOAD-BEARING values the script emits)
ALL_OK=1
for V in fresh stale missing; do
  if ! "$SCRIPT" validate status-value "$V" 2>/dev/null \
       | jq -e --arg v "$V" '.subject == "status-value" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate status-value accepts all 3 native enum values (fresh/stale/missing)"
else fail "validate status-value full-enum sweep"; fi

# Test 17: validate status-value REJECTS unknown enum value (rc=1)
"$SCRIPT" validate status-value "expired" >/tmp/5ke66-8-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/5ke66-8-test17.json >/dev/null 2>&1; then
  pass "validate status-value rejects 'expired' (not in enum) with rc=1"
else fail "validate status-value reject rc=$rc"; fi
rm -f /tmp/5ke66-8-test17.json

# Test 18: doctor probes load-bearing stat command (BSD %m + GNU %Y forms)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '.checks[] | select(.name == "stat_available") | .detail | contains("BSD") and contains("GNU")' >/dev/null; then
  pass "doctor stat_available probe annotates BSD + GNU mtime form fallback"
else fail "doctor stat probe annotation"; fi

# Test 19: backward-compat — native default-run (no args, --json) still emits
# per-session staleness rows for the SESSIONS array.
# (Use file capture instead of `| head -1 | jq` because pipefail + SIGPIPE
# would mask success when head closes the pipe early on the producer side.)
TMP_JSONL="$(mktemp -t freshness-probe-test19-XXXXXX)"
"$SCRIPT" --json >"$TMP_JSONL" 2>/dev/null
if [[ -s "$TMP_JSONL" ]] && head -1 "$TMP_JSONL" | jq -e '.session and .status' >/dev/null 2>&1; then
  pass "backward-compat: native default-run still emits per-session staleness rows"
else fail "backward-compat default-run"; fi
rm -f "$TMP_JSONL"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
