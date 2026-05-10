#!/usr/bin/env bash
# tests/blocker-fail-escalator.sh
# Integration regression for the blocker-discipline FAIL escalation hook
# (.flywheel/scripts/blocker-fail-escalator.sh).
#
# Bead: flywheel-ukbej. Sister regression to nbgp6's auto-close test.
# Acceptance: simulate blocker with consistently-failing AC, verify Nth
# consecutive failure triggers escalation row + agent-mail attempt, schema
# correct per blocker-discipline.md.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK="$ROOT/.flywheel/scripts/blocker-fail-escalator.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t blocker-fail-escalator.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && find "$TMPDIR_TEST" -mindepth 1 -delete 2>/dev/null; rmdir "$TMPDIR_TEST" 2>/dev/null' EXIT

# All tests use --skip-agent-mail so they don't depend on a live agent-mail server
export BLOCKER_FAIL_ESCALATOR_SKIP_AGENT_MAIL=1

# Test 1: bash -n
if bash -n "$HOOK" 2>/dev/null; then pass "hook syntax"; else fail "hook syntax"; fi

# Test 2: --info envelope
if "$HOOK" --info | jq -e '.schema_version == "blocker-fail-escalator/v1" and .threshold_n == 4 and (.modes | type == "array") and (.escalation_row_fields | length) >= 13' >/dev/null; then
  pass "--info envelope shape"
else fail "--info"; fi

# Test 3: --schema has envelope + escalation_row definitions
if "$HOOK" --schema | jq -e '."$defs".envelope and ."$defs".escalation_row' >/dev/null; then
  pass "--schema defines envelope + escalation_row"
else fail "--schema defs"; fi

# Test 4: --examples >=4 items
if "$HOOK" --examples | jq -e '.examples | length >= 4' >/dev/null; then
  pass "--examples >=4 items"
else fail "--examples"; fi

# Test 5: missing --blocker-file → rc=2
"$HOOK" check --json >/dev/null 2>&1
if [[ $? -eq 2 ]]; then pass "check without --blocker-file → rc=2"; else fail "rc"; fi

# Test 6: missing file → rc=3
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/nope.json" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "error"' >/dev/null; then
  pass "missing blocker file → rc=3"
else fail "missing file rc=$rc"; fi

# Test 7: AC passes → not_escalated_ac_passed (counter resets)
cat > "$TMPDIR_TEST/passing.json" <<'EOF'
{"blocker_id":"int-pass","acceptance_condition":"echo OK","status":"open","last_verified_at":"2026-05-09T00:00:00Z"}
EOF
COUNTER_DIR="$TMPDIR_TEST/counters"
ELOG="$TMPDIR_TEST/escalations.jsonl"
# Seed counter to 2 so we can verify reset
mkdir -p "$COUNTER_DIR"
jq -nc '{counter:2,last_fail_at:"2026-05-09T00:00:00Z",last_fail_state_hash:null}' >"$COUNTER_DIR/int-pass.json"
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/passing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "not_escalated_ac_passed" and .ac_passes_now == true and .consecutive_fail_count == 0 and .previous_consecutive_fail_count == 2' >/dev/null; then
  pass "AC passes → not_escalated_ac_passed + counter reset (was 2, now 0)"
else fail "AC pass: $(printf '%s' "$out" | jq -c '{status, ac_passes_now, consecutive_fail_count, previous_consecutive_fail_count}')"; fi

# Test 8: AC fails below threshold → not_escalated_below_threshold + counter incremented
cat > "$TMPDIR_TEST/failing.json" <<'EOF'
{"blocker_id":"int-fail","acceptance_condition":"false","status":"open","last_verified_at":"2026-05-09T00:00:00Z"}
EOF
# Counter starts at 0; threshold=4. First fail: counter→1.
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "not_escalated_below_threshold" and .consecutive_fail_count == 1 and .threshold_n == 4' >/dev/null; then
  pass "AC fail #1 (below threshold) → counter 0→1, no escalation, no row"
else fail "fail #1: $(printf '%s' "$out" | jq -c '{status, consecutive_fail_count, threshold_n}')"; fi
[[ ! -e "$ELOG" ]] && pass "no escalation row appended on below-threshold fail" || fail "row appended too early"

# Test 9: Two more fails — counter 1→2→3, still below threshold=4
"$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json >/dev/null 2>&1
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "not_escalated_below_threshold" and .consecutive_fail_count == 3' >/dev/null; then
  pass "counter increments across consecutive fails (3rd fail = counter 3)"
else fail "3rd fail: $(printf '%s' "$out" | jq -c '{status, consecutive_fail_count}')"; fi

# Test 10: 4th fail hits threshold=4 → escalated + row appended
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "escalated" and .consecutive_fail_count == 4 and .threshold_n == 4 and .agent_mail_status == "skipped_flag"' >/dev/null; then
  pass "AC fail #4 at threshold → escalated, agent_mail=skipped_flag"
else fail "4th fail: $(printf '%s' "$out" | jq -c '{status, consecutive_fail_count, agent_mail_status}')"; fi

# Test 11: escalations.jsonl row matches DOCTRINE schema (10 doctrine fields + 3 escalator extensions)
row="$(tail -1 "$ELOG")"
if printf '%s' "$row" | jq -e '
  .schema_version == "blocker-escalation/v1"
  and .event == "blocker_ac_failed_escalated"
  and .blocker_id == "int-fail"
  and .ac_command == "false"
  and (.ac_stdout | type == "string")
  and .ac_exit_code == 1
  and (.live_probe_at | type == "string")
  and .previous_last_verified_at == "2026-05-09T00:00:00Z"
  and (.delta_seconds | type == "number") and .delta_seconds > 0
  and (.auto_closer | type == "string")
  and .consecutive_fail_count == 4
  and .threshold_n == 4
  and .agent_mail_status == "skipped_flag"
' >/dev/null; then
  pass "escalation row matches doctrine schema + 3 extensions (consecutive_fail_count, threshold_n, agent_mail_status)"
else fail "row: $row"; fi

# Test 12: ac_state_hash present (cross-orch replay-verify link)
if printf '%s' "$row" | jq -e '.ac_state_hash != null and (.ac_state_hash | test("^[0-9a-f]{64}$"))' >/dev/null; then
  pass "ac_state_hash 64-hex present"
else fail "ac_state_hash: $(printf '%s' "$row" | jq -r .ac_state_hash)"; fi

# Test 13: counter reset to 0 after escalation
counter_after="$(jq -r '.counter' "$COUNTER_DIR/int-fail.json")"
if [[ "$counter_after" -eq 0 ]]; then
  pass "counter reset to 0 after escalation"
else fail "counter after escalation: $counter_after"; fi

# Test 14: 5th fail starts a fresh streak — back to not_escalated_below_threshold
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "not_escalated_below_threshold" and .consecutive_fail_count == 1' >/dev/null; then
  pass "post-escalation: fresh streak starts at counter=1"
else fail "fresh streak: $(printf '%s' "$out" | jq -c '{status, consecutive_fail_count}')"; fi
# Should still be only 1 row in escalations.jsonl
row_count="$(wc -l < "$ELOG" | tr -d ' ')"
if [[ "$row_count" -eq 1 ]]; then
  pass "still only 1 escalation row after fresh-streak start"
else fail "row count: $row_count"; fi

# Test 15: dry-run does NOT mutate counter or write row
mkdir -p "$TMPDIR_TEST/dry-counters"
DRY_ELOG="$TMPDIR_TEST/dry-escalations.jsonl"
"$HOOK" check --blocker-file "$TMPDIR_TEST/failing.json" --counter-dir "$TMPDIR_TEST/dry-counters" --escalations-log "$DRY_ELOG" --threshold-n 1 --json 2>/dev/null >/dev/null
if [[ ! -e "$DRY_ELOG" ]] && [[ ! -e "$TMPDIR_TEST/dry-counters/int-fail.json" ]]; then
  pass "dry-run: no row, no counter file"
else fail "dry-run mutated state"; fi

# Test 16: AC pure MISMATCH (impure predicate) → ac_pure_mismatch + rc=1
cat > "$TMPDIR_TEST/impure.json" <<'EOF'
{"blocker_id":"int-impure","acceptance_condition":"echo $RANDOM","status":"open"}
EOF
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/impure.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 1 ]] && printf '%s' "$out" | jq -e '.status == "ac_pure_mismatch" and .ac_verdict == "MISMATCH"' >/dev/null; then
  pass "impure AC → ac_pure_mismatch rc=1"
else fail "impure rc=$rc: $(printf '%s' "$out" | jq -c '{status, ac_verdict}')"; fi

# Test 17: per-blocker threshold override from ac_check_interval_ticks
cat > "$TMPDIR_TEST/override.json" <<'EOF'
{"blocker_id":"int-override","acceptance_condition":"false","status":"open","ac_check_interval_ticks":2}
EOF
"$HOOK" check --blocker-file "$TMPDIR_TEST/override.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 99 --apply --json >/dev/null 2>&1
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/override.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --threshold-n 99 --apply --json 2>/dev/null)"
# Per-blocker n=2 should win over CLI --threshold-n=99
if printf '%s' "$out" | jq -e '.status == "escalated" and .threshold_n == 2 and .consecutive_fail_count == 2' >/dev/null; then
  pass "per-blocker ac_check_interval_ticks override (n=2 wins over CLI --threshold-n=99)"
else fail "override: $(printf '%s' "$out" | jq -c '{status, threshold_n, consecutive_fail_count}')"; fi

# Test 18: already-closed blocker → error rc=3
cat > "$TMPDIR_TEST/closed.json" <<'EOF'
{"blocker_id":"int-closed","acceptance_condition":"false","status":"closed"}
EOF
out="$("$HOOK" check --blocker-file "$TMPDIR_TEST/closed.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "error" and .blocker_status == "closed"' >/dev/null; then
  pass "closed blocker → rc=3 error"
else fail "closed: rc=$rc, $(printf '%s' "$out" | jq -c '{status, blocker_status}')"; fi

# Test 19: scan mode — mixed verdicts
SCANDIR="$TMPDIR_TEST/scan"; mkdir -p "$SCANDIR"
SCAN_ELOG="$TMPDIR_TEST/scan-escalations.jsonl"
SCAN_COUNTERS="$TMPDIR_TEST/scan-counters"
cat > "$SCANDIR/a-pass.json" <<'EOF'
{"blocker_id":"scan-pass","acceptance_condition":"true","status":"open"}
EOF
cat > "$SCANDIR/b-fail.json" <<'EOF'
{"blocker_id":"scan-fail-below","acceptance_condition":"false","status":"open"}
EOF
cat > "$SCANDIR/c-fail-threshold.json" <<'EOF'
{"blocker_id":"scan-fail-at-threshold","acceptance_condition":"false","status":"open","ac_check_interval_ticks":1}
EOF
out="$("$HOOK" scan --blockers-dir "$SCANDIR" --counter-dir "$SCAN_COUNTERS" --escalations-log "$SCAN_ELOG" --threshold-n 4 --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .total == 3
  and ((.results | map(.status) | sort) == ["escalated","not_escalated_ac_passed","not_escalated_below_threshold"])
' >/dev/null; then
  pass "scan mode: 3 blockers → 1 escalated + 1 passed + 1 below-threshold"
else fail "scan: $(printf '%s' "$out" | jq -c '{total, statuses: [.results[].status]}')"; fi

# Test 20: scan on missing dir → rc=3 not_initialized
"$HOOK" scan --blockers-dir "$TMPDIR_TEST/no-such-dir" --json >/dev/null 2>&1
if [[ $? -eq 3 ]]; then pass "scan missing dir → rc=3"; else fail "scan missing"; fi

# Test 21: BLOCKER_FAIL_ESCALATOR_THRESHOLD_N env override
cat > "$TMPDIR_TEST/env-thresh.json" <<'EOF'
{"blocker_id":"env-thresh","acceptance_condition":"false","status":"open"}
EOF
out="$(BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=1 "$HOOK" check --blocker-file "$TMPDIR_TEST/env-thresh.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "escalated" and .threshold_n == 1 and .consecutive_fail_count == 1' >/dev/null; then
  pass "BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=1 env override → immediate escalation on first fail"
else fail "env threshold: $(printf '%s' "$out" | jq -c '{status, threshold_n}')"; fi

# Test 22: multiline AC stdout captured exactly
cat > "$TMPDIR_TEST/multiline.json" <<'EOF'
{"blocker_id":"multiline","acceptance_condition":"echo l1 >&2; echo l2 >&2; false","status":"open"}
EOF
BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=1 "$HOOK" check --blocker-file "$TMPDIR_TEST/multiline.json" --counter-dir "$COUNTER_DIR" --escalations-log "$ELOG" --apply --json >/dev/null 2>&1
last_row="$(tail -1 "$ELOG")"
ac_stdout_captured="$(printf '%s' "$last_row" | jq -r .ac_stdout)"
if [[ "$ac_stdout_captured" == $'l1\nl2' ]]; then
  pass "multiline stderr (via 2>&1 in live probe) captured exactly"
else fail "multiline ac_stdout: $(printf '%q' "$ac_stdout_captured")"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
