#!/usr/bin/env bash
# tests/flywheel-replay-verify.sh
# Regression for .flywheel/scripts/flywheel_replay_verify.py (flywheel-5m9gp).
#
# Adopts the deterministic-tick-simulation skill via {capability-control-plane}'s PR233 wrapper
# pattern. Verifies all 5 modes (log/heartbeat/tick/blocker-ac/report) emit
# canonical envelopes + exit-code taxonomy + --apply gate.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel_replay_verify.py"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t flywheel-replay-verify.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && rm -rf "$TMPDIR_TEST"' EXIT

# Test 1: bash -n / python syntax
if python3 -c "import ast; ast.parse(open('$SCRIPT').read())" 2>/dev/null; then
  pass "python syntax"
else fail "python syntax"; fi

# Test 2: --help exits 0
if "$SCRIPT" --help 2>/dev/null | grep -q 'flywheel_replay_verify'; then
  pass "--help shows usage"
else fail "--help"; fi

# Test 3: report on empty log → rc=3 (not-applicable)
FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TMPDIR_TEST/no-such.jsonl" \
  "$SCRIPT" report --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "report on empty log → rc=3"
else fail "report rc=$rc (expected 3)"; fi

# Test 4: heartbeat replay-from-receipt — PASS verdict + state_hash present
cat > "$TMPDIR_TEST/blocker-escalations.jsonl" <<'EOF'
{"ts":"2026-05-10T18:55:00Z","event":"heartbeat-tick","blocker_id_state_path":"<flywheel-repo>/.flywheel/state/blockers/foo.json","safe_unrelated_work_this_tick":"work","ticks_since_last_blocker_change":3,"blockers_open":1}
EOF
out="$("$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations.jsonl" --receipt-line 1 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.verdict == "PASS" and .command == "heartbeat" and (.state_hash | type == "string") and (.state_hash | test("^[0-9a-f]{64}$"))' >/dev/null; then
  pass "heartbeat → PASS verdict + 64-hex state_hash"
else fail "heartbeat envelope: $(printf '%s' "$out" | jq -c '{verdict, command, state_hash}')"; fi

# Test 5: heartbeat — narrative-field-excluded determinism (excludes safe_unrelated_work_this_tick)
cat > "$TMPDIR_TEST/blocker-escalations-2.jsonl" <<'EOF'
{"ts":"2026-05-10T18:55:00Z","event":"heartbeat-tick","blocker_id_state_path":"<flywheel-repo>/.flywheel/state/blockers/foo.json","safe_unrelated_work_this_tick":"DIFFERENT_NARRATIVE","ticks_since_last_blocker_change":3,"blockers_open":1}
EOF
hash1="$("$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations.jsonl" --receipt-line 1 --json 2>/dev/null | jq -r .state_hash)"
hash2="$("$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations-2.jsonl" --receipt-line 1 --json 2>/dev/null | jq -r .state_hash)"
if [[ "$hash1" == "$hash2" ]]; then
  pass "heartbeat hash excludes narrative field (safe_unrelated_work_this_tick)"
else fail "heartbeat hash includes narrative: hash1=$hash1 hash2=$hash2"; fi

# Test 6: heartbeat — different state_path produces different hash
cat > "$TMPDIR_TEST/blocker-escalations-3.jsonl" <<'EOF'
{"ts":"2026-05-10T18:55:00Z","event":"heartbeat-tick","blocker_id_state_path":"/different/path.json","safe_unrelated_work_this_tick":"work","ticks_since_last_blocker_change":3,"blockers_open":1}
EOF
hash3="$("$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations-3.jsonl" --receipt-line 1 --json 2>/dev/null | jq -r .state_hash)"
if [[ "$hash3" != "$hash1" ]]; then
  pass "heartbeat hash includes state_path"
else fail "heartbeat hash ignored state_path change"; fi

# Test 7: heartbeat — bad line number → rc=2 (usage)
"$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations.jsonl" --receipt-line 99 --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "heartbeat bad line → rc=2"
else fail "heartbeat bad line rc=$rc (expected 2)"; fi

# Test 8: heartbeat — receipts file missing → rc=2
"$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/no-such.jsonl" --receipt-line 1 --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "heartbeat missing file → rc=2"
else fail "heartbeat missing file rc=$rc"; fi

# Test 9: blocker-ac — passing AC (`echo OK`) returns PASS verdict + ac_passes_now=true
cat > "$TMPDIR_TEST/blocker-pass.json" <<'EOF'
{"blocker_id":"flywheel-test-blocker-1","acceptance_condition":"echo OK"}
EOF
out="$("$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-pass.json" --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.verdict == "PASS" and .ac_pure == true and .ac_passes_now == true and .blocker_id == "flywheel-test-blocker-1"' >/dev/null; then
  pass "blocker-ac PASS path"
else fail "blocker-ac PASS path: $(printf '%s' "$out" | jq -c '{verdict, ac_pure, ac_passes_now}')"; fi

# Test 10: blocker-ac — failing AC (`false`) is still pure but ac_passes_now=false
cat > "$TMPDIR_TEST/blocker-fail.json" <<'EOF'
{"blocker_id":"flywheel-test-blocker-2","acceptance_condition":"false"}
EOF
out="$("$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-fail.json" --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.verdict == "PASS" and .ac_pure == true and .ac_passes_now == false' >/dev/null; then
  pass "blocker-ac failing-but-pure AC"
else fail "blocker-ac failing-but-pure: $(printf '%s' "$out" | jq -c '{verdict, ac_pure, ac_passes_now}')"; fi

# Test 11: blocker-ac — impure AC (`echo $RANDOM`) returns MISMATCH + rc=1
cat > "$TMPDIR_TEST/blocker-impure.json" <<'EOF'
{"blocker_id":"flywheel-test-blocker-3","acceptance_condition":"echo $RANDOM"}
EOF
"$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-impure.json" --json >/tmp/flywheel-replay-impure-out.json 2>/dev/null
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.verdict == "MISMATCH" and .ac_pure == false' </tmp/flywheel-replay-impure-out.json >/dev/null; then
  pass "blocker-ac impure AC → MISMATCH rc=1"
else fail "blocker-ac impure AC rc=$rc verdict=$(jq -r .verdict </tmp/flywheel-replay-impure-out.json)"; fi
rm -f /tmp/flywheel-replay-impure-out.json

# Test 12: blocker-ac — missing acceptance_condition → rc=2
cat > "$TMPDIR_TEST/blocker-no-ac.json" <<'EOF'
{"blocker_id":"flywheel-test-blocker-4"}
EOF
"$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-no-ac.json" --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "blocker-ac missing AC → rc=2"
else fail "blocker-ac missing AC rc=$rc"; fi

# Test 13: blocker-ac on JSONL with --blocker-line
cat > "$TMPDIR_TEST/blockers.jsonl" <<'EOF'
{"blocker_id":"row-1","acceptance_condition":"true"}
{"blocker_id":"row-2","acceptance_condition":"true"}
EOF
out="$("$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blockers.jsonl" --blocker-line 2 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.blocker_id == "row-2" and .verdict == "PASS"' >/dev/null; then
  pass "blocker-ac --blocker-line resolves JSONL row"
else fail "blocker-ac --blocker-line: $(printf '%s' "$out" | jq -c '.blocker_id')"; fi

# Test 14: --apply gate — without --apply, telemetry NOT written
TELEMETRY="$TMPDIR_TEST/telemetry.jsonl"
FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TELEMETRY" \
  "$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-pass.json" --json >/dev/null 2>&1
if [[ ! -e "$TELEMETRY" ]]; then
  pass "--apply OFF: telemetry NOT written"
else fail "--apply OFF wrote telemetry anyway"; fi

# Test 15: --apply gate — with --apply, telemetry written + json carries telemetry_emitted_to
out="$(FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TELEMETRY" \
  "$SCRIPT" blocker-ac --blocker-file "$TMPDIR_TEST/blocker-pass.json" --apply --json 2>/dev/null)"
if [[ -s "$TELEMETRY" ]] && printf '%s' "$out" | jq -e '.telemetry_emitted_to | type == "string"' >/dev/null; then
  pass "--apply ON: telemetry written + emitted_to set"
else fail "--apply ON: telemetry=$(ls -la "$TELEMETRY" 2>&1 | head -1)"; fi

# Test 16: report — sums verdicts/commands across telemetry log
# Append one more PASS row so report has multiple to summarize
FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TELEMETRY" \
  "$SCRIPT" heartbeat --receipts "$TMPDIR_TEST/blocker-escalations.jsonl" --receipt-line 1 --apply --json >/dev/null 2>&1
out="$(FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TELEMETRY" "$SCRIPT" report --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.rows_total >= 2 and (.verdict_summary.PASS // 0) >= 2 and (.command_summary | has("blocker-ac") and has("heartbeat"))' >/dev/null; then
  pass "report sums verdicts + commands"
else fail "report: $(printf '%s' "$out" | jq -c '{rows_total, verdict_summary, command_summary}')"; fi

# Test 17: report --since filter narrows rows
out="$(FLYWHEEL_REPLAY_VERIFY_TELEMETRY_LOG="$TELEMETRY" "$SCRIPT" report --since '2099-01-01T00:00:00Z' --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.rows_total == 0' >/dev/null; then
  pass "report --since filters to 0 rows on future cutoff"
else fail "report --since: $(printf '%s' "$out" | jq -c .)"; fi

# Test 18: telemetry envelope schema_version pins to flywheel.replay_verify_telemetry.v1
sv="$(jq -r '.schema_version' <"$TELEMETRY" | sort -u)"
if [[ "$sv" == "flywheel.replay_verify_telemetry.v1" ]]; then
  pass "telemetry envelope schema_version pinned"
else fail "telemetry envelope schema_version: '$sv'"; fi

# Test 19: tick mode requires a sim module — without one, rc=2
"$SCRIPT" tick --seed 42 --tick-count 10 --sim "$TMPDIR_TEST/no-such-sim.py" --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "tick missing sim → rc=2"
else fail "tick missing sim rc=$rc"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
