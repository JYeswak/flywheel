#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-drill-sacrificial-live.sh"

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -x "$SCRIPT" ]]; then
  pass "recovery-drill-sacrificial-live.sh executable"
else
  fail "recovery-drill-sacrificial-live.sh executable"
fi

if bash -n "$SCRIPT"; then
  pass "recovery-drill-sacrificial-live.sh syntax"
else
  fail "recovery-drill-sacrificial-live.sh syntax"
fi

if "$SCRIPT" --help | rg -q -- '--apply'; then
  pass "help documents required apply gate"
else
  fail "help documents required apply gate"
fi

if "$SCRIPT" --json >/tmp/recovery-drill-no-apply.out 2>/tmp/recovery-drill-no-apply.err; then
  fail "script refuses no-apply invocation"
else
  rc=$?
  if [[ "$rc" -eq 2 ]] && rg -q -- '--apply is required' /tmp/recovery-drill-no-apply.err; then
    pass "script refuses no-apply invocation"
  else
    fail "script refuses no-apply invocation"
  fi
fi

if rg -Fq 'DRILL_D3_KEEP_PANE=1' "$SCRIPT"; then
  pass "D3 drill keeps sacrificial pane scoped"
else
  fail "D3 drill keeps sacrificial pane scoped"
fi

if rg -Fq 'session-scoped-sacrificial-topology' "$SCRIPT"; then
  pass "topology probe is session-scoped"
else
  fail "topology probe is session-scoped"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"

