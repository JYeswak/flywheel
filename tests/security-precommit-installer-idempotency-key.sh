#!/usr/bin/env bash
# Regression test for flywheel-j0xpa: --idempotency-key gate + whole-run replay-check
# on security-precommit-installer.sh. Third 7axmt-followup; reuses sister 8sx9w
# pair-pattern variant (whole-run, scoped per-repo).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/security-precommit-installer.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sec-precommit-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Isolated audit log + per-test git repo.
export SECURITY_PRECOMMIT_AUDIT_LOG="$TMP/audit.jsonl"
REPO_A="$TMP/repo-a"
REPO_B="$TMP/repo-b"
for r in "$REPO_A" "$REPO_B"; do
  git -C "$(mkdir -p "$r" && echo "$r")" init -q
  mkdir -p "$r/githooks"
  printf '#!/usr/bin/env bash\necho fixture\n' > "$r/githooks/pre-commit"
  chmod +x "$r/githooks/pre-commit"
done

# Test 1: install --apply without --idempotency-key returns rc=3
set +e
"$SCRIPT" install --apply --repo "$REPO_A" --json >"$TMP/refused.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: install --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key")) and .repo' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal shape correct + repo field present"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value → rc=2
set +e
"$SCRIPT" install --apply --idempotency-key 2>"$TMP/no-value.err"
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: install --dry-run still works without key
"$SCRIPT" install --dry-run --repo "$REPO_A" --json >"$TMP/dry.json" 2>&1
if jq -e '.status == "dry_run" and .dry_run == true' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "AG3: dry-run still works without key"
else fail "AG3: dry-run broken"; fi

# Test 4: dry-run with key carries idempotency_key in receipt
"$SCRIPT" install --dry-run --idempotency-key=ag4-dry --repo "$REPO_A" --json >"$TMP/dry-key.json" 2>&1
if jq -e '.idempotency_key == "ag4-dry"' "$TMP/dry-key.json" >/dev/null 2>&1; then
  pass "AG4: dry-run with key carries idempotency_key in receipt"
else fail "AG4: dry-run receipt missing idempotency_key"; fi

# Test 5: install --apply --idempotency-key=K succeeds + writes audit row
"$SCRIPT" install --apply --idempotency-key=ag5-fresh --repo "$REPO_A" --json >"$TMP/ag5.json" 2>&1
if jq -e '.status == "applied" and .idempotency_key == "ag5-fresh" and .repo' "$TMP/ag5.json" >/dev/null 2>&1; then
  pass "AG5: apply with key emits applied receipt with key + repo"
else fail "AG5: apply envelope malformed"; fi
if [[ -s "$SECURITY_PRECOMMIT_AUDIT_LOG" ]] && jq -e --arg k "ag5-fresh" '.idempotency_key == $k and .status == "applied"' "$SECURITY_PRECOMMIT_AUDIT_LOG" >/dev/null 2>&1; then
  pass "AG5.audit: audit log row written carrying key + status=applied"
else fail "AG5.audit: audit log missing or wrong shape"; fi

# Test 6: re-run with same key + same repo → replay (no-op exit 0)
"$SCRIPT" install --apply --idempotency-key=ag5-fresh --repo "$REPO_A" --json >"$TMP/ag6.json" 2>&1
if jq -e '.status == "replay" and .replay == true and .replay_for_idempotency_key == "ag5-fresh"' "$TMP/ag6.json" >/dev/null 2>&1; then
  pass "AG6: re-run with same key + repo → replay"
else fail "AG6: replay-check did not fire"; fi

# Test 7: same key, DIFFERENT repo → applies (per-repo scope)
"$SCRIPT" install --apply --idempotency-key=ag5-fresh --repo "$REPO_B" --json >"$TMP/ag7.json" 2>&1
if jq -e '.status == "applied" and .idempotency_key == "ag5-fresh" and (.repo | test("repo-b"))' "$TMP/ag7.json" >/dev/null 2>&1; then
  pass "AG7: same key, different repo → applies (per-repo scope honored)"
else fail "AG7: per-repo scope broken"; fi

# Test 8: fresh key + same repo → applies (new audit row, no replay)
"$SCRIPT" install --apply --idempotency-key=ag8-different --repo "$REPO_A" --json >"$TMP/ag8.json" 2>&1
if jq -e '.status == "applied" and (.replay // false) == false' "$TMP/ag8.json" >/dev/null 2>&1; then
  pass "AG8: fresh key on same repo → applies (no replay)"
else fail "AG8: fresh key incorrectly replayed"; fi

# Test 9: audit log has 3 applied rows (ag5 in repo-a, ag5 in repo-b, ag8 in repo-a)
applied_count=$(jq -Rc 'fromjson? | select(.status == "applied")' "$SECURITY_PRECOMMIT_AUDIT_LOG" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$applied_count" -eq 3 ]]; then
  pass "AG9: audit log has 3 applied rows (per-repo + per-key scoping verified)"
else fail "AG9: audit log row count $applied_count != 3"; fi

# Test 10: tolerant-parse — corrupt row in audit log doesn't break replay
cat >>"$SECURITY_PRECOMMIT_AUDIT_LOG" <<EOF
{this is not valid json but should not break the replay-check}
EOF
"$SCRIPT" install --apply --idempotency-key=ag5-fresh --repo "$REPO_A" --json >"$TMP/ag10.json" 2>&1
if jq -e '.status == "replay" and .replay == true' "$TMP/ag10.json" >/dev/null 2>&1; then
  pass "AG10: tolerant-parse survives corrupt audit row, replay still fires"
else fail "AG10: tolerant-parse broke"; fi

# Test 11: --info documents new fields
if "$SCRIPT" --info 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and .audit_log and (.exit_codes | has("3"))' >/dev/null 2>&1; then
  pass "AG11: --info documents apply_requires + audit_log + exit code 3"
else fail "AG11: --info missing fields"; fi

# Test 12: --help documents --idempotency-key + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -qE '^  3  '; then
  pass "AG12: --help documents --idempotency-key + exit code 3"
else fail "AG12: --help missing docs"; fi

# Test 13: schema command lists exit_codes including refused_no_idempotency_key
if "$SCRIPT" schema --repo "$REPO_A" 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and (.exit_codes | has("refused_no_idempotency_key"))' >/dev/null 2>&1; then
  pass "AG13: schema command lists refused_no_idempotency_key exit code"
else fail "AG13: schema missing exit code"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
