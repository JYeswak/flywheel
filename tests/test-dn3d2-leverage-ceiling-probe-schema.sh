#!/usr/bin/env bash
# tests/test-dn3d2-leverage-ceiling-probe-schema.sh
#
# Regression test for flywheel-dn3d2 (leverage-ceiling-probe ts:null
# regression). Bead's AG1+AG2 were resolved by upstream migration on
# 2026-05-09 (commit 3eaa0147): the probe migrated from emitting `ts`
# to emitting `observed_at`. This test ships AG3 as forward-protection:
# every probe-emitted row must carry a non-null ISO8601 `observed_at`,
# and every live JSONL row must satisfy `(.ts != null) OR
# (.observed_at != null)` (legacy-or-current schema bridge).
#
# Historical broken rows (the 6 with ts:null AND no observed_at) are
# accepted up to a fixed cap; any new occurrence (>6) is a regression.
set -euo pipefail

REPO="${REPO:-<flywheel-repo>}"
PROBE="${PROBE:-$REPO/.flywheel/scripts/leverage-ceiling-probe.sh}"
LEDGER="${LEDGER:-$HOME/.local/state/flywheel/leverage-ceiling.jsonl}"
HISTORICAL_BROKEN_CAP="${HISTORICAL_BROKEN_CAP:-6}"

[[ -x "$PROBE" ]] || { echo "FAIL probe missing or not executable: $PROBE" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Probe syntax-clean
bash -n "$PROBE" && pass "probe syntax-clean" || fail "bash -n failed"

# 2. Canonical-CLI introspection (existing surface; no new auth needed)
for flag in --info --schema --examples; do
  out=$("$PROBE" "$flag" 2>&1) || fail "$flag exited non-zero"
  [[ -n "$out" ]] || fail "$flag emitted no content"
done
pass "canonical-CLI flags --info/--schema/--examples emit content"

# 3. --schema declares observed_at-bearing fields (ledger_jsonl true)
"$PROBE" --info | jq -e '.ledger_jsonl == true' >/dev/null \
  || fail "--info should claim ledger_jsonl:true"
pass "--info claims ledger_jsonl:true"

# 4. Live probe emits observed_at (the current canonical timestamp field)
# Use isolated LEDGER so we don't pollute production; verify stdout payload.
TEST_LEDGER="$(mktemp -t dn3d2-probe-ledger.XXXXXX)"
trap 'rm -f "$TEST_LEDGER"' EXIT
LEVERAGE_CEILING_LEDGER="$TEST_LEDGER" "$PROBE" --json > /tmp/dn3d2-probe-out.json 2>&1
PAYLOAD=$(cat /tmp/dn3d2-probe-out.json)
echo "$PAYLOAD" | jq -e '.observed_at | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")' >/dev/null \
  || fail "probe stdout missing valid ISO8601 observed_at: $PAYLOAD"
pass "probe stdout emits ISO8601 observed_at"

# 5. Probe ledger append carries observed_at (round-trip through fw_jsonl_append_validated or fallback)
LAST=$(tail -1 "$TEST_LEDGER" 2>/dev/null)
[[ -n "$LAST" ]] || fail "test ledger empty after probe run"
echo "$LAST" | jq -e '.observed_at | type == "string"' >/dev/null \
  || fail "appended row missing observed_at: $LAST"
pass "appended row carries non-null observed_at"

# 6. Live ledger schema-bridge invariant: every row has ts!=null OR observed_at!=null
#    (Allows the historical 6 ts:null rows that have no observed_at — legacy schema artifacts.)
if [[ -f "$LEDGER" ]]; then
  TOTAL=$(wc -l <"$LEDGER" | tr -d ' ')
  GOOD=$(jq -c 'select((.ts // null) != null or (.observed_at // null) != null)' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')
  BROKEN=$((TOTAL - GOOD))
  if (( BROKEN > HISTORICAL_BROKEN_CAP )); then
    fail "live ledger has $BROKEN rows missing both ts and observed_at (cap=$HISTORICAL_BROKEN_CAP); regression detected"
  fi
  pass "live ledger schema-bridge invariant holds (broken=$BROKEN <= cap=$HISTORICAL_BROKEN_CAP, good=$GOOD/$TOTAL)"
else
  pass "live ledger absent (skipped historical-cap check)"
fi

# 7. Forward-protection: any NEW row appended through the current probe MUST have observed_at non-null
# Add 3 more rows via the probe and verify all have observed_at
for i in 1 2 3; do
  LEVERAGE_CEILING_LEDGER="$TEST_LEDGER" "$PROBE" --json >/dev/null 2>&1
done
APPENDED_GOOD=$(jq -c 'select(.observed_at != null)' "$TEST_LEDGER" 2>/dev/null | wc -l | tr -d ' ')
APPENDED_TOTAL=$(wc -l <"$TEST_LEDGER" | tr -d ' ')
[[ "$APPENDED_GOOD" -eq "$APPENDED_TOTAL" ]] \
  || fail "appended rows missing observed_at: $((APPENDED_TOTAL - APPENDED_GOOD)) of $APPENDED_TOTAL"
pass "every probe-appended row carries non-null observed_at ($APPENDED_GOOD/$APPENDED_TOTAL)"

printf 'flywheel-dn3d2 leverage-ceiling-probe schema test passed (7 assertions)\n'
