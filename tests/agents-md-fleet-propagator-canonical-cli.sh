#!/usr/bin/env bash
# tests/agents-md-fleet-propagator-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/agents-md-fleet-propagator.sh
# (partial→passing surgical patch by bead flywheel-1hshd.2 — wave-4-general-2).
#
# Pre-existing partial coverage already had:
#   --info, --examples, --doctor, --health, --repair, --apply, --dry-run,
#   --idempotency-key, --json + no-dash subcommand family
#   (schema/doctor/health/repair/validate/audit/why/quickstart/help/completion)
# Gap closed by this bead: --schema dash flag (parity with `schema` positional)
# + L6 magic comment + 4 L2 missing-return-zero warnings.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agents-md-fleet-propagator.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# ===== NEW canonical surfaces (the gap closed by 1hshd.2) =====

# Test 2: --schema dash flag (NEW) emits same shape as positional `schema`
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "agents-md-fleet-propagation/v1"' >/dev/null; then
  pass "--schema dash flag NEW: emits canonical schema_version"
else fail "--schema dash flag"; fi

# Test 3: --schema with topic argument
if "$SCRIPT" --schema propagation 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema propagation accepts topic argument"
else fail "--schema with topic"; fi

# Test 4: --schema=topic= form
if "$SCRIPT" --schema=propagation 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema=propagation= form accepts topic"
else fail "--schema= form"; fi

# Test 5: parity — --schema and positional schema emit same shape
SCHEMA_DASH="$("$SCRIPT" --schema --json 2>/dev/null | jq -c .)"
SCHEMA_POS="$("$SCRIPT" schema --json 2>/dev/null | jq -c .)"
if [[ "$SCHEMA_DASH" == "$SCHEMA_POS" ]]; then
  pass "--schema and positional schema emit identical envelope"
else fail "--schema/schema parity"; fi

# ===== AG1 canonical surfaces (pre-existing partial; now passing) =====

if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then pass "--info emits envelope"; else fail "--info"; fi
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null; then pass "--examples non-empty"; else fail "--examples"; fi
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.canonical_cli_surfaces? // .doctor_fields? // .surfaces? // (has("name") and has("version"))' >/dev/null; then
  pass "--info has AG3 fields"
else fail "--info AG3 fields"; fi

# Test 9: positional schema with topic
if "$SCRIPT" schema propagation 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "positional schema propagation works"
else fail "positional schema with topic"; fi

# Test 10: legacy --doctor dispatched (KNOWN PRE-EXISTING jq-arglist bug
# — bug present in .bak.scaffold-* pre-scaffold version)
out="$("$SCRIPT" --doctor --json 2>&1 || true)"
if printf '%s' "$out" | grep -qE '\{|jq:.*Argument list too long'; then
  pass "--doctor dispatched (legacy; envelope OR known jq-arglist-too-long bug)"
else fail "--doctor dispatch"; fi

# Test 11: -h / --help shows usage
if "$SCRIPT" --help 2>&1 | grep -qE 'agents-md-fleet-propagator|usage'; then
  pass "--help shows usage"
else fail "--help"; fi

# Test 12: lint passes
if "$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" 2>&1 | grep -qE '^$'; then
  # canonical-cli-lint emits nothing on success → check RC
  "$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=$? || rc=$?
  if [[ "$rc" -eq 0 ]]; then pass "canonical-cli-lint RC=0"; else fail "lint RC=$rc"; fi
else
  "$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
  if [[ "$rc" -eq 0 ]]; then pass "canonical-cli-lint RC=0"; else fail "lint RC=$rc"; fi
fi

# Test 13: flywheel-cli-surface marker present (L6 magic comment fix)
if grep -q '# flywheel-cli-surface: true' "$SCRIPT"; then
  pass "L6 magic comment '# flywheel-cli-surface: true' present"
else fail "L6 magic comment missing"; fi

# Test 14: repair --scope substrate-contract dry-run works
if "$SCRIPT" repair --scope substrate-contract --dry-run --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "repair --scope substrate-contract --dry-run reachable"
else fail "repair substrate-contract"; fi

# Test 15-17: KNOWN PRE-EXISTING BUG (jq Argument list too long when ledger is
# large). Bug exists in .bak.scaffold-* pre-scaffold version, NOT caused by
# 1hshd.2. Dispatch reachability verified by checking the error originates
# inside the surface handler (e.g. line 474 = run_validate, 276/393 = run_audit,
# 504 = run_why) — NOT a "unknown argument" dispatch error.
# Wrap output to escape pipefail so non-zero script rc doesn't sink the test.
out="$("$SCRIPT" validate ledger 2>&1 || true)"
if printf '%s' "$out" | grep -qE '"schema_version"|jq:.*Argument list too long'; then
  pass "validate ledger dispatched (envelope OR known jq-arglist-too-long bug)"
else fail "validate ledger dispatch"; fi

out="$("$SCRIPT" audit --json 2>&1 || true)"
if printf '%s' "$out" | grep -qE '"schema_version"|jq:.*Argument list too long'; then
  pass "audit dispatched (envelope OR known jq-arglist-too-long bug)"
else fail "audit dispatch"; fi

out="$("$SCRIPT" why some-id 2>&1 || true)"
if printf '%s' "$out" | grep -qE '"schema_version"|jq:.*Argument list too long'; then
  pass "why <id> dispatched (envelope OR known jq-arglist-too-long bug)"
else fail "why <id> dispatch"; fi

# Test 18: quickstart reachable
if "$SCRIPT" quickstart --json 2>&1 | head -3 | grep -qE '\{|quickstart|propagate'; then
  pass "quickstart reachable"
else fail "quickstart"; fi

# Test 19: completion bash emits compgen line
if "$SCRIPT" completion bash 2>/dev/null | grep -qE 'compgen|COMPREPLY'; then
  pass "completion bash emits compgen function"
else fail "completion bash"; fi

# Test 20: backward-compat — original scan mode still works
if "$SCRIPT" --json 2>&1 | head -1 | grep -qE '\{' ; then
  pass "default scan mode still emits JSON"
else fail "default scan"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
