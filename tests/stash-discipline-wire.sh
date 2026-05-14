#!/usr/bin/env bash
# tests/stash-discipline-wire.sh
# End-to-end regression for git-stash-discipline doctrine wiring (flywheel-pynxp).
#
# Verifies:
# 1. stash-discipline-check.sh script (info/help/examples/json/check)
# 2. threshold classification (clean/notable/bead/halt)
# 3. STATE.md tagged-block update is idempotent
# 4. mission-fitness-callback-validator includes stash_count + decision=reject_stash_halt_threshold on N>=halt
# 5. flywheel-loop doctor includes stash_count for current repo

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stash-discipline-check.sh"
VALIDATOR="$ROOT/.flywheel/scripts/mission-fitness-callback-validator.sh"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Setup isolated tmp git repo so we can manipulate stash count.
TMPREPO="$(mktemp -d -t stash-discipline-wire.XXXXXX)"
trap 'rm -rf "$TMPREPO"' EXIT

(
  cd "$TMPREPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  printf 'a\n' > a.txt && git add a.txt && git commit -q -m init
) || { fail "tmp repo init"; exit 1; }

stash_n() {
  local n="$1"
  (
    cd "$TMPREPO" || exit
    git stash list 2>/dev/null | while read -r _line; do git stash drop -q stash@'{0}' 2>/dev/null; done
    # Drain entirely
    while [[ "$(git stash list 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]]; do
      git stash drop -q stash@'{0}' 2>/dev/null || break
    done
    for ((i=0; i<n; i++)); do
      printf 'edit %d\n' "$i" >> a.txt
      git stash push -q -m "test-stash-$i" 2>/dev/null
    done
  )
}

# Test 1: bash -n
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope
if "$SCRIPT" --info 2>/dev/null | jq -e '.version and .schema_version and .thresholds' >/dev/null; then
  pass "--info envelope"
else fail "--info envelope"; fi

# Test 3: --help exits 0
if "$SCRIPT" --help 2>/dev/null | grep -q 'usage:'; then
  pass "--help shows usage"
else fail "--help"; fi

# Test 4: --examples envelope
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | type == "array"' >/dev/null; then
  pass "--examples envelope"
else fail "--examples"; fi

# Test 5: clean repo (N=0) → class=clean rc=0
stash_n 0
if "$SCRIPT" --repo "$TMPREPO" --no-append --json | jq -e '.class == "clean" and .stash_count == 0 and .halt == false' >/dev/null; then
  pass "N=0 → clean"
else fail "N=0 classification"; fi

# Test 6: notable (N=2) → class=notable rc=0
stash_n 2
"$SCRIPT" --repo "$TMPREPO" --no-append --json >/tmp/stash-test-out.json
if jq -e '.class == "notable" and .stash_count == 2 and .halt == false' </tmp/stash-test-out.json >/dev/null; then
  pass "N=2 → notable"
else fail "N=2 classification"; fi

# Test 7: bead-class (N=5) → class=bead_filing_class rc=0
stash_n 5
"$SCRIPT" --repo "$TMPREPO" --no-append --json >/tmp/stash-test-out.json
if jq -e '.class == "bead_filing_class" and .stash_count == 5 and .bead_filing_required == true and .halt == false' </tmp/stash-test-out.json >/dev/null; then
  pass "N=5 → bead_filing_class"
else fail "N=5 classification"; fi

# Test 8: halt (N=10) → class=halt rc=1
stash_n 10
"$SCRIPT" --repo "$TMPREPO" --no-append --json >/tmp/stash-test-out.json
rc=$?
if jq -e '.class == "halt" and .halt == true and .stash_count == 10' </tmp/stash-test-out.json >/dev/null && [[ "$rc" -eq 1 ]]; then
  pass "N=10 → halt rc=1"
else fail "N=10 classification (rc=$rc)"; fi

# Test 9: --threshold-halt override (N=2 with halt=2 → halt)
stash_n 2
"$SCRIPT" --repo "$TMPREPO" --threshold-halt 2 --no-append --json >/tmp/stash-test-out.json
rc=$?
if jq -e '.class == "halt"' </tmp/stash-test-out.json >/dev/null && [[ "$rc" -eq 1 ]]; then
  pass "--threshold-halt override"
else fail "--threshold-halt override (rc=$rc)"; fi

# Test 10: not-a-git-repo → rc=3
NONREPO="$(mktemp -d)"
"$SCRIPT" --repo "$NONREPO" --no-append --json >/tmp/stash-test-out.json 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "not-a-git-repo → rc=3"
else fail "not-a-git-repo rc=$rc"; fi
rm -rf "$NONREPO"

# Test 11: snapshot append
SNAP_LOG="$(mktemp)"
stash_n 1
STASH_DISCIPLINE_SNAPSHOT_LOG="$SNAP_LOG" "$SCRIPT" --repo "$TMPREPO" --json >/dev/null
if [[ -s "$SNAP_LOG" ]] && jq -e '.stash_count == 1' "$SNAP_LOG" >/dev/null; then
  pass "snapshot append"
else fail "snapshot append"; fi
rm -f "$SNAP_LOG"

# Test 12: --no-append skips snapshot
SNAP_LOG="$(mktemp -u)"
STASH_DISCIPLINE_SNAPSHOT_LOG="$SNAP_LOG" "$SCRIPT" --repo "$TMPREPO" --no-append --json >/dev/null
if [[ ! -e "$SNAP_LOG" ]]; then
  pass "--no-append skips snapshot"
else fail "--no-append still wrote snapshot"; fi

# Test 13: STATE.md tagged-block update is idempotent
TMPSTATE="$(mktemp)"
cat > "$TMPSTATE" <<'EOF'
# Test State

## Some Section

Body.
EOF
stash_n 2
"$SCRIPT" --repo "$TMPREPO" --update-state-md "$TMPSTATE" --no-append --json >/dev/null
"$SCRIPT" --repo "$TMPREPO" --update-state-md "$TMPSTATE" --no-append --json >/dev/null
"$SCRIPT" --repo "$TMPREPO" --update-state-md "$TMPSTATE" --no-append --json >/dev/null
n_blocks="$(grep -c 'stash-snapshot:begin' "$TMPSTATE")"
if [[ "$n_blocks" -eq 1 ]]; then
  pass "STATE.md tagged-block idempotent (3 applies = 1 block)"
else fail "STATE.md tagged-block produced $n_blocks blocks"; fi
rm -f "$TMPSTATE"

# Test 14: validator includes stash_count + decision=accept on N=2 (no halt)
stash_n 2
DEC="$("$VALIDATOR" --repo "$TMPREPO" --callback "DONE x task_id=x mission_fitness=adjacent mission_fitness_evidence=test journey_entry_path=.flywheel/journal/x.md br_close_executed=yes" --apply --json 2>&1)"
if printf '%s' "$DEC" | jq -e '.stash_count == 2 and .stash_class == "notable" and .stash_halt == false and .decision == "accept"' >/dev/null; then
  pass "validator accept on N=2 with stash fields"
else fail "validator stash fields N=2: $(printf '%s' "$DEC" | jq -c '{decision, stash_count, stash_class, stash_halt}')"; fi

# Test 15: validator decision=reject_stash_halt_threshold when stash_halt=true
# We need to force halt — wrap stash-discipline-check by injecting a custom script via --threshold env? No: validator uses default 10. Use 10 stashes.
stash_n 10
DEC="$("$VALIDATOR" --repo "$TMPREPO" --callback "DONE x task_id=x mission_fitness=adjacent mission_fitness_evidence=test journey_entry_path=.flywheel/journal/x.md br_close_executed=yes" --apply --json 2>&1)"
if printf '%s' "$DEC" | jq -e '.decision == "reject_stash_halt_threshold" and .stash_halt == true and .stash_count == 10' >/dev/null; then
  pass "validator reject_stash_halt_threshold on N=10"
else fail "validator halt rejection: $(printf '%s' "$DEC" | jq -c '{decision, stash_count, stash_halt}')"; fi

# Test 16: BLOCKED callback (br_close_executed=not_applicable) skips stash check
stash_n 10
DEC="$("$VALIDATOR" --repo "$TMPREPO" --callback "BLOCKED x reason=foo need=bar mission_fitness=adjacent mission_fitness_evidence=test br_close_executed=not_applicable" --apply --json 2>&1)"
if printf '%s' "$DEC" | jq -e '(.stash_count == -1 or .stash_count == null) and .decision != "reject_stash_halt_threshold"' >/dev/null; then
  pass "BLOCKED callback skips stash check"
else fail "BLOCKED callback incorrectly stash-checked: $(printf '%s' "$DEC" | jq -c '{decision, stash_count}')"; fi

# Test 17: flywheel-loop doctor exposes stash_count for current repo
if [[ -x "$FLYWHEEL_LOOP" ]]; then
  DOC="$("$FLYWHEEL_LOOP" doctor --repo "$ROOT" --json 2>/dev/null)"
  if printf '%s' "$DOC" | jq -e 'has("stash_count") and has("stash_class") and has("stash_halt") and has("stash_thresholds")' >/dev/null; then
    pass "flywheel-loop doctor includes stash fields"
  else fail "flywheel-loop doctor stash fields"; fi
else
  fail "flywheel-loop executable missing: $FLYWHEEL_LOOP"
fi

# Cleanup tmp file
rm -f /tmp/stash-test-out.json

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
