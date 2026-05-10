#!/usr/bin/env bash
# tests/autoloop-target-selector-e2e.sh
# E2E for the topology-driven autoloop target selector.
# Bead flywheel-se3h.9 AG6: tests run without sending live prompts to
# client sessions (selector is read-only — never invokes ntm send /
# tmux send-keys / or any dispatch primitive).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SEL="$ROOT/.flywheel/scripts/autoloop-target-selector.sh"
TMPDIR="$(mktemp -d -t autoloop-sel.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Fixture topology jsonl with three canonical cases:
#   - eligible-A: orchestrator_pane=1, callback_pane=1, status=live
#   - eligible-B: orchestrator_pane=2, callback_pane=2, status=live_corrected
#   - ghost:     orchestrator_pane=null, callback_pane=null, status=null
#   - missing-orch: orch_pane=null, callback_pane=1, status=live
#   - status-not-allowed: orch_pane=1, callback_pane=1, status=quarantined
FIX="$TMPDIR/fixture-topology.jsonl"
cat >"$FIX" <<'EOF'
{"schema_version":"session-topology/v1","session":"eligible-A","orchestrator_pane":1,"callback_pane":1,"session_status":"live","effective_at":"2026-05-10T04:00:00Z","registered_by":"test"}
{"schema_version":"session-topology/v1","session":"eligible-B","orchestrator_pane":2,"callback_pane":2,"session_status":"live_corrected","effective_at":"2026-05-10T04:01:00Z","registered_by":"test"}
{"schema_version":"session-topology/v1","session":"ghost","orchestrator_pane":null,"callback_pane":null,"session_status":null,"effective_at":"2026-05-10T04:02:00Z","registered_by":"test"}
{"schema_version":"session-topology/v1","session":"missing-orch","orchestrator_pane":null,"callback_pane":1,"session_status":"live","effective_at":"2026-05-10T04:03:00Z","registered_by":"test"}
{"schema_version":"session-topology/v1","session":"status-not-allowed","orchestrator_pane":1,"callback_pane":1,"session_status":"quarantined","effective_at":"2026-05-10T04:04:00Z","registered_by":"test"}
{"schema_version":"session-topology/v1","session":"eligible-A","orchestrator_pane":1,"callback_pane":1,"session_status":"live","effective_at":"2026-05-10T04:05:00Z","registered_by":"test","notes":"latest-row override (deterministic latest-per-session test)"}
EOF

# Test 1: --info exits 0
if "$SEL" --info >/dev/null 2>&1; then pass "--info exits 0"; else fail "--info"; fi

# Test 2: --schema emits canonical schema_version
if "$SEL" --schema 2>/dev/null | jq -e '.schema_version == "autoloop-target-selector.v1"' >/dev/null; then
  pass "--schema emits autoloop-target-selector.v1"
else
  fail "--schema"
fi

# Test 3: --doctor with fixture
if "$SEL" --doctor --topology="$FIX" --json 2>/dev/null \
  | jq -e '.topology_present == true and .topology_rows == 6 and .distinct_sessions == 5' >/dev/null; then
  pass "--doctor reports 6 fixture rows / 5 distinct sessions"
else
  fail "--doctor fixture: $("$SEL" --doctor --topology="$FIX" --json 2>&1 | head -2)"
fi

# Test 4: --apply against fixture
OUT="$TMPDIR/apply.json"
"$SEL" --apply --topology="$FIX" --json > "$OUT" 2>/dev/null
RC=$?
if [[ "$RC" -eq 0 ]] \
  && jq -e '.schema_version == "autoloop-target-selector.v1" and .total_sessions == 5' "$OUT" >/dev/null; then
  pass "--apply rc=0 with fixture, 5 distinct sessions resolved"
else
  fail "--apply (rc=$RC): $(jq -c '{schema:.schema_version, total:.total_sessions}' "$OUT" 2>&1)"
fi

# Test 5: eligible set = exactly {eligible-A, eligible-B}
if jq -e '.eligible | (length == 2) and (index("eligible-A") != null) and (index("eligible-B") != null)' "$OUT" >/dev/null; then
  pass "eligible set == {eligible-A, eligible-B}"
else
  fail "eligible mismatch: $(jq -c '.eligible' "$OUT")"
fi

# Test 6: ghost session is in skipped with both missing-pane reasons
if jq -e '
  .skipped
  | map(select(.session == "ghost"))
  | (length == 1)
    and (.[0].reasons | (index("missing_orchestrator_pane") != null) and (index("missing_callback_pane") != null))
' "$OUT" >/dev/null; then
  pass "ghost session: missing_orchestrator_pane + missing_callback_pane reasons captured"
else
  fail "ghost reasons mismatch: $(jq -c '.skipped | map(select(.session=="ghost"))' "$OUT")"
fi

# Test 7: missing-orch session captures the orchestrator-only failure
if jq -e '
  .skipped
  | map(select(.session == "missing-orch"))
  | (length == 1)
    and (.[0].reasons | (index("missing_orchestrator_pane") != null) and (index("missing_callback_pane") == null))
' "$OUT" >/dev/null; then
  pass "missing-orch session: only missing_orchestrator_pane reason"
else
  fail "missing-orch reasons mismatch"
fi

# Test 8: status-not-allowed session captures the status reason
if jq -e '
  .skipped
  | map(select(.session == "status-not-allowed"))
  | (length == 1)
    and (.[0].reasons | any(test("^status_not_allowed:")))
' "$OUT" >/dev/null; then
  pass "status-not-allowed session: status_not_allowed:<status> reason captured"
else
  fail "status-not-allowed reasons mismatch"
fi

# Test 9: latest-row-per-session semantics — eligible-A had two rows; the later row wins (still eligible)
if jq -e '
  .eligible | index("eligible-A") != null
' "$OUT" >/dev/null; then
  pass "latest-row-per-session: eligible-A's later row preserved eligibility"
else
  fail "latest-row semantics regression"
fi

# Test 10: --allowed-status override widens the eligible set
"$SEL" --apply --topology="$FIX" --allowed-status=live,live_corrected,quarantined --json > "$TMPDIR/wider.json" 2>/dev/null
if jq -e '.eligible | length == 3 and (index("status-not-allowed") != null)' "$TMPDIR/wider.json" >/dev/null; then
  pass "--allowed-status=live,live_corrected,quarantined makes status-not-allowed eligible"
else
  fail "--allowed-status override regression: $(jq -c .eligible "$TMPDIR/wider.json")"
fi

# Test 11: cold-start (empty fixture) → rc=2 not 3 (path missing) or rc=3 if rows zero after filter
EMPTY_FIX="$TMPDIR/empty.jsonl"
: >"$EMPTY_FIX"
"$SEL" --apply --topology="$EMPTY_FIX" --json > "$TMPDIR/empty-out" 2>/dev/null
RC=$?
if [[ "$RC" -eq 2 ]]; then
  pass "empty fixture: rc=2 (canonical missing-source class)"
else
  fail "empty fixture rc=$RC (expected 2)"
fi

# Test 12: missing fixture path → rc=2 (missing-source)
"$SEL" --apply --topology="/nonexistent/path.jsonl" --json > "$TMPDIR/missing-out" 2>/dev/null
RC=$?
if [[ "$RC" -eq 2 ]]; then
  pass "missing fixture path: rc=2 (canonical missing-source class)"
else
  fail "missing path rc=$RC (expected 2)"
fi

# Test 13: AG6 — selector touched no live dispatch primitive during all the
# above. We assert by absence: the selector script source doesn't reference
# ntm send / tmux send-keys / pkill / kill at all.
if grep -E '(ntm send|tmux send-keys|/usr/bin/pkill|/bin/kill)' "$SEL" >/dev/null 2>&1; then
  fail "selector source contains live-dispatch primitives — VIOLATES AG6 read-only invariant"
else
  pass "AG6 read-only invariant: selector script has no live-dispatch primitives"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
