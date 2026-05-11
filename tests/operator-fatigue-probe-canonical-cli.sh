#!/usr/bin/env bash
# tests/operator-fatigue-probe.sh
#
# Regression test for flywheel-2xdi.90: provide a receiver for
# operator-fatigue-probe.sh so it no longer appears in gap-hunt-probe's
# probe-without-receiver class.
#
# Asserts the probe's canonical-cli surface (--info / --schema / --doctor /
# --health / --json) returns stable JSON with schema_version=v1.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/operator-fatigue-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t operator-fatigue-probe.XXXXXX)"

# Test 1: syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "operator-fatigue-probe.v1"' >/dev/null; then
  pass "--info emits operator-fatigue-probe.v1 envelope"
else
  fail "--info envelope"
fi

# Test 3: --schema
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "operator-fatigue-probe.v1"' >/dev/null; then
  pass "--schema emits operator-fatigue-probe.v1 envelope"
else
  fail "--schema envelope"
fi

# Test 4: --doctor (canonical-cli triad)
if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "operator-fatigue-probe.v1"' >/dev/null; then
  pass "--doctor emits envelope (doctor triad)"
else
  fail "--doctor envelope"
fi

# Test 5: --health (canonical-cli triad)
if "$SCRIPT" --health --json 2>/dev/null | jq -e '.schema_version == "operator-fatigue-probe.v1"' >/dev/null; then
  pass "--health emits envelope (doctor triad)"
else
  fail "--health envelope"
fi

# Test 6: default --json run mode emits structured measurement (no notifications)
out="$("$SCRIPT" --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.schema_version == "operator-fatigue-probe.v1"' >/dev/null; then
  pass "default --json run mode emits operator-fatigue-probe.v1 measurement"
else
  fail "default --json run mode envelope"
fi

# Test 7: Step 4o anti-pattern preserved — no actual notification CALLS in code
# (the probe must be READ-ONLY; orchestrator decides what to do with the signal).
# Scopes to shell-call shape (after start-of-line whitespace), not word-in-comment.
if grep -qE '^[[:space:]]*(curl[[:space:]]+[^#]*pushover|/usr/bin/sendmail|osascript[[:space:]]+-e[[:space:]]+["'"'"']display|notify-send[[:space:]])' "$SCRIPT"; then
  fail "Step 4o anti-pattern: probe contains notification primitive"
else
  pass "Step 4o anti-pattern preserved (no notification call sites)"
fi

# Test 8: probe writes nothing to disk (READ-ONLY by design)
# Invoke with fixture log paths that don't exist; probe must not create them.
fixture_dispatch="$TMP/dispatch-log.jsonl"
fixture_fuckup="$TMP/fuckup-log.jsonl"
"$SCRIPT" --dispatch-log "$fixture_dispatch" --fuckup-log "$fixture_fuckup" --json >/dev/null 2>&1 || true
if [[ ! -e "$fixture_dispatch" && ! -e "$fixture_fuckup" ]]; then
  pass "READ-ONLY: probe did not create fixture log files"
else
  fail "READ-ONLY violation: probe wrote to fixture paths"
fi

# Test 9: missing-input strict-mode — probe must fail loudly (not silently)
# when its input log doesn't exist. Strict-mode is correct for a probe whose
# output drives orch decisions; silent degradation would risk under-reporting
# operator fatigue.
err="$("$SCRIPT" --dispatch-log /nonexistent/path.jsonl --fuckup-log /nonexistent/path.jsonl --json 2>&1 1>/dev/null || true)"
if printf '%s' "$err" | grep -qE 'ERR:.*not found'; then
  pass "strict-mode: missing-input path emits ERR message on stderr"
else
  fail "strict-mode: missing-input did NOT emit ERR on stderr"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
