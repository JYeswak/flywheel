#!/usr/bin/env bash
# tests/blocker-auto-close.sh
# Integration regression for the blocker-discipline auto-close hook
# (.flywheel/scripts/blocker-auto-close.sh).
#
# Bead: flywheel-nbgp6. Acceptance: integration test simulates blocker
# with passing AC, verifies auto-close + escalations.jsonl row matches
# the doctrine schema (blocker-discipline.md "Live-probe evidence shape").

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK="$ROOT/.flywheel/scripts/blocker-auto-close.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t blocker-auto-close.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && find "$TMPDIR_TEST" -mindepth 1 -delete 2>/dev/null; rmdir "$TMPDIR_TEST" 2>/dev/null' EXIT

# Test 1: bash -n
if bash -n "$HOOK" 2>/dev/null; then pass "hook syntax"; else fail "hook syntax"; fi

# Test 2: --info envelope shape
out="$("$HOOK" --info 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .schema_version == "blocker-auto-close/v1"
  and .escalation_schema == "blocker-escalation/v1"
  and (.modes | type == "array")
  and (.escalation_row_fields | length) >= 10
  and (.exit_codes | has("0") and has("1") and has("2") and has("3"))
' >/dev/null; then
  pass "--info carries required fields"
else fail "--info shape: $(printf '%s' "$out" | jq -c .)"; fi

# Test 3: --examples returns array
if "$HOOK" --examples 2>/dev/null | jq -e '.examples | type == "array" and length >= 3' >/dev/null; then
  pass "--examples returns >=3 examples"
else fail "--examples"; fi

# Test 4: --schema has envelope + escalation_row definitions
if "$HOOK" --schema 2>/dev/null | jq -e '."$defs".envelope and ."$defs".escalation_row' >/dev/null; then
  pass "--schema has envelope + escalation_row defs"
else fail "--schema defs"; fi

# Test 5: close with no --blocker-file → rc=2 usage
"$HOOK" close --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "close without --blocker-file → rc=2"
else fail "close without --blocker-file rc=$rc"; fi

# Test 6: close on missing file → rc=3 (not-applicable)
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/nope.json" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "error" and (.reason | test("not readable"))' >/dev/null; then
  pass "close on missing file → rc=3 + error envelope"
else fail "close missing file rc=$rc: $(printf '%s' "$out" | jq -c .)"; fi

# Test 7: close on malformed JSON → rc=3
printf 'not json\n' > "$TMPDIR_TEST/bad.json"
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/bad.json" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "error" and (.reason | test("not valid JSON"))' >/dev/null; then
  pass "close on malformed JSON → rc=3 + error envelope"
else fail "close malformed rc=$rc: $(printf '%s' "$out" | jq -c .)"; fi

# Test 8: blocker missing acceptance_condition → rc=3
cat > "$TMPDIR_TEST/no-ac.json" <<'EOF'
{"blocker_id":"no-ac","status":"open"}
EOF
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/no-ac.json" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "error" and (.reason | test("acceptance_condition"))' >/dev/null; then
  pass "blocker without acceptance_condition → rc=3"
else fail "no-ac rc=$rc: $(printf '%s' "$out" | jq -c .)"; fi

# Test 9: dry-run on passing AC — emits planned_escalation_row but does NOT mutate
ELOG="$TMPDIR_TEST/escalations.jsonl"
cat > "$TMPDIR_TEST/passing.json" <<'EOF'
{"blocker_id":"int-test-pass","acceptance_condition":"echo READY","last_verified_at":"2026-05-09T00:00:00Z","status":"open"}
EOF
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/passing.json" --escalations-log "$ELOG" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 0 ]] \
   && printf '%s' "$out" | jq -e '.status == "dry_run" and .would_close == true and .ac_verdict == "PASS" and .ac_passes_now == true' >/dev/null \
   && [[ ! -e "$ELOG" ]] \
   && [[ "$(jq -r '.status' "$TMPDIR_TEST/passing.json")" == "open" ]]; then
  pass "dry-run on passing AC: would_close=true, no escalations.jsonl, blocker unmutated"
else fail "dry-run: rc=$rc, log_exists=$([[ -e "$ELOG" ]] && echo y || echo n), blocker_status=$(jq -r '.status' "$TMPDIR_TEST/passing.json")"; fi

# Test 10: --apply on passing AC — writes row + mutates blocker file
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/passing.json" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 0 ]] && printf '%s' "$out" | jq -e '.status == "closed" and (.closed_at | type == "string")' >/dev/null; then
  pass "--apply on passing AC: status=closed + closed_at set"
else fail "--apply rc=$rc: $(printf '%s' "$out" | jq -c '{status, closed_at}')"; fi

# Test 11: escalations.jsonl row matches DOCTRINE schema (all 10 required fields per blocker-discipline.md)
row="$(tail -1 "$ELOG")"
if printf '%s' "$row" | jq -e '
  .schema_version == "blocker-escalation/v1"
  and (.ts | type == "string")
  and .event == "blocker_auto_closed"
  and .blocker_id == "int-test-pass"
  and .ac_command == "echo READY"
  and .ac_stdout == "READY"
  and .ac_exit_code == 0
  and (.live_probe_at | type == "string")
  and .previous_last_verified_at == "2026-05-09T00:00:00Z"
  and (.delta_seconds | type == "number")
  and .delta_seconds > 0
  and (.auto_closer | type == "string")
' >/dev/null; then
  pass "escalations.jsonl row matches doctrine schema (10/10 required fields)"
else fail "escalations row: $row"; fi

# Test 12: ac_state_hash field surfaced (bonus over doctrine — links back to flywheel_replay_verify telemetry)
if printf '%s' "$row" | jq -e '.ac_state_hash != null and (.ac_state_hash | test("^[0-9a-f]{64}$"))' >/dev/null; then
  pass "ac_state_hash bonus field: 64-hex (cross-orch replay-verify link)"
else fail "ac_state_hash: $(printf '%s' "$row" | jq -r .ac_state_hash)"; fi

# Test 13: blocker file mutated with status=closed + audit metadata + embedded evidence
b="$(cat "$TMPDIR_TEST/passing.json")"
if printf '%s' "$b" | jq -e '
  .status == "closed"
  and (.closed_at | type == "string")
  and .closed_by != null
  and .closed_reason == "ac_passed_auto_close_hook"
  and .live_probe_evidence.event == "blocker_auto_closed"
  and .live_probe_evidence.blocker_id == "int-test-pass"
' >/dev/null; then
  pass "blocker file mutated: status=closed + audit metadata + embedded live_probe_evidence"
else fail "blocker mutation: $(printf '%s' "$b" | jq -c '{status, closed_at, closed_by, closed_reason}')"; fi

# Test 14: idempotency — second --apply on already-closed blocker returns not_closed_already_closed + rc=3
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/passing.json" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "not_closed_already_closed"' >/dev/null; then
  pass "idempotency: re-apply on closed blocker → not_closed_already_closed rc=3"
else fail "idempotency rc=$rc: $(printf '%s' "$out" | jq -c .)"; fi

# Test 15: no duplicate row appended on idempotent re-apply
row_count_after="$(wc -l < "$ELOG" | tr -d ' ')"
if [[ "$row_count_after" -eq 1 ]]; then
  pass "idempotency: no duplicate escalation row (still 1)"
else fail "idempotency: row count after re-apply = $row_count_after (expected 1)"; fi

# Test 16: AC fails (false) — returns not_closed_ac_failed + rc=1; NO mutation
cat > "$TMPDIR_TEST/failing.json" <<'EOF'
{"blocker_id":"int-test-fail","acceptance_condition":"false","status":"open"}
EOF
out="$("$HOOK" close --blocker-file "$TMPDIR_TEST/failing.json" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 1 ]] \
   && printf '%s' "$out" | jq -e '.status == "not_closed_ac_failed" and .ac_passes_now == false' >/dev/null \
   && [[ "$(jq -r '.status' "$TMPDIR_TEST/failing.json")" == "open" ]] \
   && [[ "$(wc -l < "$ELOG" | tr -d ' ')" -eq 1 ]]; then
  pass "AC fails → rc=1 + status=not_closed_ac_failed + no mutation + no new row"
else fail "AC fails: rc=$rc, blocker_status=$(jq -r '.status' "$TMPDIR_TEST/failing.json"), row_count=$(wc -l < "$ELOG")"; fi

# Test 17: AUTO_CLOSER_ID env var propagates into escalation row
cat > "$TMPDIR_TEST/closer-id.json" <<'EOF'
{"blocker_id":"closer-test","acceptance_condition":"true","status":"open"}
EOF
out="$(BLOCKER_AUTO_CLOSE_CLOSER_ID="orch:flywheel:1" "$HOOK" close --blocker-file "$TMPDIR_TEST/closer-id.json" --escalations-log "$ELOG" --apply --json 2>/dev/null)"
last_row="$(tail -1 "$ELOG")"
if printf '%s' "$last_row" | jq -e '.auto_closer == "orch:flywheel:1"' >/dev/null; then
  pass "AUTO_CLOSER_ID env propagates to escalation row"
else fail "auto_closer: $(printf '%s' "$last_row" | jq -r .auto_closer)"; fi

# Test 18: scan mode — multiple blockers, mixed verdicts
SCANDIR="$TMPDIR_TEST/scan"
mkdir -p "$SCANDIR"
ELOG2="$TMPDIR_TEST/scan-escalations.jsonl"
cat > "$SCANDIR/a.json" <<'EOF'
{"blocker_id":"scan-a","acceptance_condition":"true","status":"open"}
EOF
cat > "$SCANDIR/b.json" <<'EOF'
{"blocker_id":"scan-b","acceptance_condition":"false","status":"open"}
EOF
cat > "$SCANDIR/c.json" <<'EOF'
{"blocker_id":"scan-c","acceptance_condition":"true","status":"closed"}
EOF
out="$("$HOOK" scan --blockers-dir "$SCANDIR" --escalations-log "$ELOG2" --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .total == 3
  and .closed == 1
  and .not_closed == 2
  and .errors == 0
  and (.results | length) == 3
' >/dev/null; then
  pass "scan mode: 3 blockers → 1 closed, 2 not_closed (1 ac_failed + 1 already_closed)"
else fail "scan: $(printf '%s' "$out" | jq -c '{total, closed, not_closed, errors}')"; fi

# Test 19: scan on missing dir → not_initialized + rc=3
out="$("$HOOK" scan --blockers-dir "$TMPDIR_TEST/no-such-dir" --json 2>/dev/null)"
rc=$?
if [[ "$rc" -eq 3 ]] && printf '%s' "$out" | jq -e '.status == "not_initialized"' >/dev/null; then
  pass "scan on missing dir → rc=3 + not_initialized"
else fail "scan missing dir rc=$rc: $(printf '%s' "$out" | jq -c .)"; fi

# Test 20: live_probe captures the EXACT command stdout (not just rc).
# This is load-bearing — the doctrine says "the live probe's stdout MUST be appended"
cat > "$TMPDIR_TEST/multiline-stdout.json" <<'EOF'
{"blocker_id":"multiline","acceptance_condition":"echo line1; echo line2","status":"open"}
EOF
"$HOOK" close --blocker-file "$TMPDIR_TEST/multiline-stdout.json" --escalations-log "$ELOG" --apply --json >/dev/null 2>&1
last_row="$(tail -1 "$ELOG")"
ac_stdout_in_row="$(printf '%s' "$last_row" | jq -r .ac_stdout)"
if [[ "$ac_stdout_in_row" == $'line1\nline2' ]]; then
  pass "live_probe captures multiline stdout exactly"
else fail "ac_stdout captured: $(printf '%s' "$ac_stdout_in_row")"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
