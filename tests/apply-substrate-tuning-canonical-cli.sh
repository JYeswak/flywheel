#!/usr/bin/env bash
# tests/apply-substrate-tuning-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/apply-substrate-tuning.sh
# (partial→passing patch by bead flywheel-1hshd.3 — wave-4-general-3).
#
# Pre-existing partial coverage already had:
#   --info, --examples, --doctor, --health, --repair, --apply, --dry-run,
#   --revert, --json + no-dash subcommand family
# Gaps closed: --schema dash flag, --idempotency-key + apply contract rc=3,
# JSON-aware --info, L6 magic comment.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/apply-substrate-tuning.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# ===== Tests 2-7: NEW canonical surfaces (the gaps closed by 1hshd.3) =====

# --schema dash flag
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "substrate-tuning.v1"' >/dev/null; then
  pass "--schema dash flag NEW: emits canonical schema_version"
else fail "--schema dash flag"; fi

# --schema receipt explicit topic
if "$SCRIPT" --schema receipt 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema receipt accepts explicit topic"
else fail "--schema receipt"; fi

# --schema=topic= form
if "$SCRIPT" --schema=tuning 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema=tuning= form accepts topic"
else fail "--schema= form"; fi

# --info now emits JSON when --json given (was plain-text pre-scaffold)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "apply-substrate-tuning.sh" and .version and (.subcommands | length > 5)' >/dev/null; then
  pass "--info --json NEW: AG3 fields .name/.version/.subcommands"
else fail "--info AG3 fields"; fi

# --info backward-compat: still emits plain text when --json absent
if "$SCRIPT" --info 2>/dev/null | head -1 | grep -qE 'apply-substrate-tuning\.v|^[A-Za-z]'; then
  pass "--info plain-text fallback when --json absent (backward-compat)"
else fail "--info plain-text fallback"; fi

# --apply without --idempotency-key returns rc=3 (NEW apply contract)
out="$("$SCRIPT" --apply --json 2>&1 || true)"
rc="$?"
out="$("$SCRIPT" --apply --json 2>/dev/null; echo "RC=$?")"
if printf '%s' "$out" | grep -q "RC=3"; then
  pass "--apply without --idempotency-key returns rc=3 (canonical apply contract)"
else fail "--apply rc=3 ($out)"; fi

# Apply with --idempotency-key + --dry-run proceeds (no mutation due to --dry-run)
if "$SCRIPT" --apply --idempotency-key test-key-1hshd3 --dry-run --json 2>&1 | head -3 | grep -qE 'schema_version|substrate-tuning'; then
  pass "--apply --idempotency-key --dry-run proceeds to dispatch"
else fail "--apply --idempotency-key flow"; fi

# ===== AG1 canonical surfaces (existing) =====

if "$SCRIPT" --examples 2>&1 | head -1 | grep -qE 'Probe|apply|#'; then pass "--examples emits content"; else fail "--examples"; fi
if "$SCRIPT" --help 2>&1 | head -1 | grep -qE 'usage:|apply-substrate'; then pass "--help shows usage"; else fail "--help"; fi

# ===== Existing no-dash subcommands reachable =====

if "$SCRIPT" schema receipt 2>&1 | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "positional schema receipt reachable"
else fail "positional schema receipt"; fi

if "$SCRIPT" why scrollback_lines 2>&1 | head -1 | grep -qE 'scrollback|512GB'; then
  pass "why scrollback_lines emits explanation"
else fail "why scrollback_lines"; fi

# Audit reachable (may emit JSON or content)
if "$SCRIPT" audit 2>&1 | head -3 | grep -qE '\{|action|count|EMPTY|ledger'; then
  pass "audit reachable"
else fail "audit"; fi

# ===== Lint + magic comment =====

if "$SCRIPT" --info --json 2>/dev/null | jq -e '.idempotency_key_required_for_apply == true' >/dev/null; then
  pass "--info exposes idempotency_key_required_for_apply=true"
else fail "--info idempotency_key field"; fi

if grep -q '# flywheel-cli-surface: true' "$SCRIPT"; then
  pass "L6 magic comment '# flywheel-cli-surface: true' present"
else fail "L6 magic comment missing"; fi

"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
if [[ "$rc" -eq 0 ]]; then pass "canonical-cli-lint RC=0 (was RC=1 pre-scaffold)"; else fail "lint RC=$rc"; fi

# ===== Backward-compat — doctor dispatched =====

if "$SCRIPT" --doctor 2>&1 | head -3 | grep -qE 'doctor|drift|wezterm|substrate'; then
  pass "--doctor backward-compat dispatched"
else fail "--doctor backward-compat"; fi

if "$SCRIPT" --doctor --json 2>&1 | head -3 | grep -qE 'schema_version|doctor|\{'; then
  pass "--doctor --json backward-compat emits content"
else fail "--doctor --json"; fi

# ===== --revert surface intact =====

if "$SCRIPT" --revert --dry-run --json 2>&1 | head -3 | grep -qE 'revert|substrate|schema'; then
  pass "--revert --dry-run dispatched"
else fail "--revert"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
