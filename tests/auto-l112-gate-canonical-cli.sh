#!/usr/bin/env bash
# tests/auto-l112-gate-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/auto-l112-gate.sh
# (partial→passing patch by bead flywheel-1hshd.5 — wave-4-general-5).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/auto-l112-gate.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# NEW: --schema dash flag
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema --json dash flag NEW"
else fail "--schema dash flag"; fi

# --schema=topic= form
if "$SCRIPT" --schema=gate --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema=gate= form"
else fail "--schema= form"; fi

# NEW: --info exposes AG3 subcommands
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and (.subcommands | length > 5)' >/dev/null; then
  pass "--info AG3: name + version + subcommands"
else fail "--info AG3"; fi

# --info exposes idempotency_key_required_for_apply
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.idempotency_key_required_for_apply == true' >/dev/null; then
  pass "--info reflects apply contract"
else fail "--info apply contract field"; fi

# NEW: --repair --apply without --idempotency-key returns rc=3
"$SCRIPT" --repair --apply --json >/dev/null 2>&1; rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "--repair --apply without --idempotency-key returns rc=3"
else fail "rc=$rc (expected 3)"; fi

# --repair --apply --idempotency-key proceeds
if "$SCRIPT" --repair --apply --idempotency-key test-key-1hshd5 --dry-run --json 2>/dev/null | jq -e '.command == "repair"' >/dev/null; then
  pass "--repair --apply --idempotency-key dispatches"
else fail "--repair --idempotency-key flow"; fi

# --examples
if "$SCRIPT" --examples 2>&1 | head -3 | grep -qE '#|gate|auto-l112'; then pass "--examples emits"; else fail "--examples"; fi

# Existing canonical surfaces
if "$SCRIPT" --doctor --json 2>&1 | head -3 | grep -qE 'schema_version|\{'; then
  pass "--doctor reachable"
else fail "--doctor"; fi

if "$SCRIPT" --health --json 2>&1 | head -3 | grep -qE 'schema_version|\{|health'; then
  pass "--health reachable"
else fail "--health"; fi

if "$SCRIPT" audit --json 2>&1 | head -3 | grep -qE 'schema_version|\{|audit'; then
  pass "audit reachable"
else fail "audit"; fi

if "$SCRIPT" quickstart 2>&1 | head -3 | grep -qE 'quickstart|gate|step'; then
  pass "quickstart reachable"
else fail "quickstart"; fi

# Magic comment + lint
if grep -q '# flywheel-cli-surface: true' "$SCRIPT"; then
  pass "L6 magic comment present"
else fail "L6 magic comment missing"; fi

"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
if [[ "$rc" -eq 0 ]]; then pass "canonical-cli-lint RC=0"; else fail "lint RC=$rc"; fi

# Backward-compat: positional schema still works
if "$SCRIPT" schema gate 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "positional schema gate still works"
else fail "positional schema"; fi

# Why with id (existing — emits explanation text, not JSON)
if "$SCRIPT" why some-task-id 2>&1 | head -3 | grep -qE 'ledger|explanation|task_id|built-in'; then
  pass "why <id> reachable"
else fail "why"; fi

# Validate envelope rejects missing file (rc=2 by design)
out="$("$SCRIPT" validate envelope 2>&1 || true)"
if printf '%s' "$out" | head -3 | grep -qE 'envelope|file|ERR|requires'; then
  pass "validate envelope reachable (errors without --callback-envelope-file)"
else fail "validate envelope"; fi

# Help shows usage
if "$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage:|auto-l112'; then pass "--help shows usage"; else fail "--help"; fi

# Default gate mode requires task-id + envelope; without them errors gracefully
out="$("$SCRIPT" --task-id testid --json 2>&1 || true)"
if printf '%s' "$out" | grep -qE 'envelope|task|schema_version|ERR'; then
  pass "gate mode dispatched (errors gracefully without envelope)"
else fail "gate dispatch"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
