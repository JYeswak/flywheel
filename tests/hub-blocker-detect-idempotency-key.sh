#!/usr/bin/env bash
# Regression test for flywheel-mfy7u: --idempotency-key gate + per-bead replay
# on hub-blocker-detect.sh. Fifth 7axmt-followup. Uses stubbed BR_BIN to control
# the issue list + dependency graph deterministically.
#
# Surface exits 1 on RED signal (hub_blocker_count>0) regardless of --apply mode
# (it's a detector by design). Test wraps apply-path invocations with `|| true`
# and verifies receipt content directly.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/hub-blocker-detect.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/hub-blocker-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

export HUB_BLOCKER_AUDIT_LOG="$TMP/audit.jsonl"

# Stub BR_BIN: produces fixture beads, captures `br update --priority` calls into a side log.
cat >"$TMP/br-stub" <<'STUB'
#!/usr/bin/env bash
set -uo pipefail
ACTION="$1"; shift
case "$ACTION" in
  list)
    # Look at args for --json; emit the fixture.
    cat "$BR_STUB_LIST_FIXTURE"
    ;;
  dep)
    sub="$1"; shift
    case "$sub" in
      list) printf '[]'; ;;
      *) printf 'ERR: unknown br dep subcommand %s\n' "$sub" >&2; exit 64 ;;
    esac
    ;;
  update)
    bead_id="$1"; shift
    # Parse --priority N
    new_pri=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --priority) new_pri="$2"; shift 2 ;;
        --json) shift ;;
        *) shift ;;
      esac
    done
    printf '%s\t%s\n' "$bead_id" "$new_pri" >>"$BR_STUB_UPDATE_LOG"
    printf '{"id":"%s","priority":%s,"status":"ok"}\n' "$bead_id" "$new_pri"
    ;;
  label)
    sub="$1"; shift
    case "$sub" in
      add) printf '{"status":"ok"}\n' ;;
      *) printf 'ERR: unknown br label subcommand %s\n' "$sub" >&2; exit 64 ;;
    esac
    ;;
  *)
    printf 'ERR: unknown br action %s\n' "$ACTION" >&2; exit 64 ;;
esac
STUB
chmod +x "$TMP/br-stub"
export BR_BIN="$TMP/br-stub"
export BR_STUB_LIST_FIXTURE="$TMP/list-fixture.json"
export BR_STUB_UPDATE_LOG="$TMP/update.log"
: >"$BR_STUB_UPDATE_LOG"

# Fixture: 3 hub-blocker beads with dependency_count > THRESHOLD (default 3).
cat >"$BR_STUB_LIST_FIXTURE" <<'JSON'
[
  {"id":"flywheel-hub1","status":"open","priority":2,"dependency_count":5,"title":"hub1 fixture"},
  {"id":"flywheel-hub2","status":"open","priority":3,"dependency_count":4,"title":"hub2 fixture"},
  {"id":"flywheel-hub3","status":"open","priority":1,"dependency_count":7,"title":"hub3 fixture"},
  {"id":"flywheel-quiet","status":"open","priority":4,"dependency_count":1,"title":"quiet fixture"}
]
JSON

REPO="$TMP/repo"
mkdir -p "$REPO/.beads"  # surface checks $REPO/.beads/ exists before calling br list

# Test 1: --apply without --idempotency-key returns rc=3
set +e
"$SCRIPT" --apply --repo "$REPO" --json >"$TMP/refused.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key"))' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal shape correct"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value → rc=2
set +e
"$SCRIPT" --apply --idempotency-key 2>/dev/null
rc=$?
set +e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: dry-run (check) still works without key; detects 3 hub blockers from fixture
"$SCRIPT" check --repo "$REPO" --json >"$TMP/dry.json" 2>&1 || true

if jq -e '.hub_blocker_count == 3 and .signal == "RED"' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "AG3: dry-run detects 3 hub blockers from fixture (signal=RED)"
else fail "AG3: dry-run detection broken"; fi

# Test 4: --apply with key promotes all 3 hub blockers, writes 3 audit rows
# (surface exits 1 on RED; we tolerate that with || true and assert on the receipt)
"$SCRIPT" --apply --idempotency-key=ag4-fresh --repo "$REPO" --json >"$TMP/ag4.json" 2>&1 || true
if jq -e '.promoted_count == 3 and .replay_skipped_count == 0 and .idempotency_key == "ag4-fresh"' "$TMP/ag4.json" >/dev/null 2>&1; then
  pass "AG4: apply promotes 3 + writes audit rows + carries idempotency_key"
else fail "AG4: apply receipt malformed"; fi

audit_rows=$(jq -Rc 'fromjson? | select(.action == "br_update_priority")' "$HUB_BLOCKER_AUDIT_LOG" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$audit_rows" -eq 3 ]]; then
  pass "AG4.audit: 3 audit rows written (one per promoted bead)"
else fail "AG4.audit: audit row count $audit_rows != 3"; fi

# Test 5: re-run with same key → all 3 beads replay-skipped
"$SCRIPT" --apply --idempotency-key=ag4-fresh --repo "$REPO" --json >"$TMP/ag5.json" 2>&1 || true
if jq -e '.replay_skipped_count == 3 and .promoted_count == 0 and ([.replay_skipped_bead_ids | sort | .[]] | length == 3)' "$TMP/ag5.json" >/dev/null 2>&1; then
  pass "AG5: re-run with same key → all 3 beads replay-skipped"
else fail "AG5: replay-skip count wrong"; fi

# Test 6: per-bead row carries replay_skipped=true for skipped beads
if jq -e '[.hub_blockers[] | select(.replay_skipped == true)] | length == 3' "$TMP/ag5.json" >/dev/null 2>&1; then
  pass "AG6: per-bead row marks replay_skipped=true"
else fail "AG6: per-bead replay_skipped flag wrong"; fi

# Test 7: BR_BIN update should not have been called the second time (replay-skip honored)
update_calls=$(wc -l <"$BR_STUB_UPDATE_LOG" | tr -d ' ')
if [[ "$update_calls" -eq 3 ]]; then
  pass "AG7: br update called 3 times total (no extra calls on replay run)"
else fail "AG7: br update called $update_calls times (expected 3)"; fi

# Test 8: fresh key on same fixture → all 3 promoted (per-key scope)
"$SCRIPT" --apply --idempotency-key=ag8-different --repo "$REPO" --json >"$TMP/ag8.json" 2>&1 || true
if jq -e '.promoted_count == 3 and .replay_skipped_count == 0' "$TMP/ag8.json" >/dev/null 2>&1; then
  pass "AG8: fresh key → all 3 promoted again (no cross-key replay)"
else fail "AG8: fresh key incorrectly replayed"; fi

# Test 9: tolerant-parse — corrupt audit row doesn't break replay
cat >>"$HUB_BLOCKER_AUDIT_LOG" <<EOF
{this is not valid json}
EOF
"$SCRIPT" --apply --idempotency-key=ag4-fresh --repo "$REPO" --json >"$TMP/ag9.json" 2>&1 || true
if jq -e '.replay_skipped_count == 3' "$TMP/ag9.json" >/dev/null 2>&1; then
  pass "AG9: tolerant-parse survives corrupt audit row, replay still fires"
else fail "AG9: tolerant-parse broke"; fi

# Test 10: --help documents --idempotency-key + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -qE '^  3  '; then
  pass "AG10: --help documents --idempotency-key + exit code 3"
else fail "AG10: --help missing docs"; fi

# Test 11: --info envelope shows apply_requires
if "$SCRIPT" --info 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and .audit_log and (.exits | has("3"))' >/dev/null 2>&1; then
  pass "AG11: --info documents apply_requires + audit_log + exit 3"
else fail "AG11: --info missing fields"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
