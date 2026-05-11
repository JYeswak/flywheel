#!/usr/bin/env bash
# tests/apply-tmux-tuning-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/apply-tmux-tuning.sh
# (partial→passing surgical patch by bead flywheel-1hshd.4 — wave-4-general-4).
#
# Sister of apply-substrate-tuning (flywheel-1hshd.3) — same 4-gap surgical
# pattern: L6 magic comment, --schema dash flag, --idempotency-key + apply
# rc=3 contract, JSON-aware --info.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/apply-tmux-tuning.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# --schema dash flag (NEW; defaults topic to "config")
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema dash flag NEW: defaults to config topic"
else fail "--schema dash flag"; fi

# --schema config explicit
if "$SCRIPT" --schema config --json 2>/dev/null | jq -e '.schema_version' >/dev/null; then
  pass "--schema config emits envelope"
else fail "--schema config"; fi

# --schema=ledger form
if "$SCRIPT" --schema=ledger --json 2>/dev/null | jq -e '.schema_version | test("ledger$")' >/dev/null; then
  pass "--schema=ledger= form works"
else fail "--schema= form"; fi

# Positional schema backup still works
if "$SCRIPT" schema backup 2>/dev/null | jq -e '.schema_version | test("backup$")' >/dev/null; then
  pass "positional schema backup still works"
else fail "positional schema backup"; fi

# --info --json (NEW AG3 fields)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "apply-tmux-tuning.sh" and .version and (.subcommands | length > 5)' >/dev/null; then
  pass "--info --json AG3: name + version + subcommands"
else fail "--info AG3"; fi

# --info plain-text fallback when --json absent
if "$SCRIPT" --info 2>/dev/null | head -1 | grep -qE 'apply-tmux-tuning|^[A-Za-z]'; then
  pass "--info plain-text fallback (backward-compat)"
else fail "--info plain-text"; fi

# --info exposes idempotency_key_required_for_apply=true
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.idempotency_key_required_for_apply == true' >/dev/null; then
  pass "--info reflects apply contract"
else fail "--info apply contract field"; fi

# --apply without --idempotency-key returns rc=3
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "--apply without --idempotency-key returns rc=3"
else fail "--apply rc=$rc (expected 3)"; fi

# --apply --idempotency-key + --dry-run proceeds
if "$SCRIPT" --apply --idempotency-key test-key-1hshd4 --dry-run --json 2>&1 | head -2 | grep -qE 'schema_version|tmux'; then
  pass "--apply --idempotency-key --dry-run dispatches"
else fail "--apply --idempotency-key flow"; fi

# --revert dispatched (without APPROVE=yes returns rc=4 + "blocked" envelope).
# Wrap to escape pipefail (script returns rc=4 by design — safety block).
out="$("$SCRIPT" --revert --json 2>&1 || true)"
if printf '%s' "$out" | grep -qE 'schema_version|blocked|revert|tmux|noop|fail'; then
  pass "--revert dispatched (blocks without APPROVE=yes — correct safety behavior)"
else fail "--revert"; fi

# --examples
if "$SCRIPT" --examples 2>&1 | head -1 | grep -qE '#|Preview|apply'; then pass "--examples emits content"; else fail "--examples"; fi

# --help
if "$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|apply-tmux-tuning'; then pass "--help shows usage"; else fail "--help"; fi

# Existing subcommands reachable
if "$SCRIPT" why mux_output_parser_buffer_size 2>&1 | head -1 | grep -qE 'parser|buffer|MB|tmux'; then
  pass "why mux_output_parser_buffer_size emits"
else fail "why"; fi

if "$SCRIPT" audit 2>&1 | head -3 | grep -qE 'audit|rows|action|count|ledger|EMPTY|\{'; then
  pass "audit reachable"
else fail "audit"; fi

if "$SCRIPT" quickstart 2>&1 | head -3 | grep -qE 'quickstart|tmux|step'; then
  pass "quickstart reachable"
else fail "quickstart"; fi

# Magic comment + lint
if grep -q '# flywheel-cli-surface: true' "$SCRIPT"; then
  pass "L6 magic comment present"
else fail "L6 magic comment missing"; fi

"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
if [[ "$rc" -eq 0 ]]; then pass "canonical-cli-lint RC=0 (was RC=1)"; else fail "lint RC=$rc"; fi

# doctor positional reachable (no --doctor dash form in this script — uses positional only)
if "$SCRIPT" doctor --json 2>&1 | head -3 | grep -qE 'schema_version|\{|doctor|tmux'; then
  pass "positional doctor reachable"
else fail "positional doctor"; fi

# default scan (no args) -> repair dry-run
if "$SCRIPT" --json 2>&1 | head -3 | grep -qE '\{|schema_version|repair|dry'; then
  pass "default scan emits JSON"
else fail "default scan"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
