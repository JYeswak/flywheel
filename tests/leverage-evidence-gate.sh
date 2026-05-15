#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/leverage-evidence-gate.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; fi
}

if python3 -m py_compile "$SCRIPT"; then
  pass "script py_compile"
else
  fail "script py_compile"
fi

cat >"$TMP/waiting.jsonl" <<'JSONL'
{"success":true,"ts":"2026-05-01T00:00:00Z","leverage_ceiling_score":500,"binding_constraint":"accounts"}
{"success":true,"observed_at":"2026-05-02T00:00:00Z","leverage_ceiling_score":250,"binding_constraint":"machines"}
{"success":false,"observed_at":"2026-05-03T00:00:00Z","leverage_ceiling_score":1000,"binding_constraint":"none"}
{"success":true,"created_at":"2026-05-04T00:00:00Z","leverage_ceiling_score":750,"binding_constraint":"tokens"}
not-json
JSONL

if "$SCRIPT" --ledger "$TMP/waiting.jsonl" --required-days 4 --generated-at "2026-05-15T00:00:00Z" --json >"$TMP/waiting.out.json"; then
  fail "waiting gate should exit non-zero"
else
  pass "waiting gate exits non-zero"
fi
assert_jq "$TMP/waiting.out.json" '.status == "waiting_for_evidence" and .distinct_day_count == 3 and .missing_distinct_days == 1 and .invalid_row_count == 1' "waiting gate counts mixed timestamp rows"

cat >"$TMP/ready.jsonl" <<'JSONL'
{"success":true,"ts":"2026-05-01T00:00:00Z","leverage_ceiling_score":500,"binding_constraint":"accounts"}
{"success":true,"observed_at":"2026-05-02T00:00:00Z","leverage_ceiling_score":250,"binding_constraint":"machines"}
{"success":true,"created_at":"2026-05-03T00:00:00Z","leverage_ceiling_score":100,"binding_constraint":"machines"}
{"success":true,"timestamp":"2026-05-04T00:00:00Z","leverage_ceiling_score":900,"binding_constraint":"none"}
JSONL

"$SCRIPT" --ledger "$TMP/ready.jsonl" --required-days 4 --generated-at "2026-05-15T00:00:00Z" --json >"$TMP/ready.out.json"
assert_jq "$TMP/ready.out.json" '.status == "ready" and .distinct_day_count == 4 and (.unblocks | index("flywheel-h17x")) and .next_action == "author_h17x_axiom_and_then_xhdg_refill_rule"' "ready gate exposes unblock action"
assert_jq "$TMP/ready.out.json" '.binding_counts.machines == 2 and .score_min == 100 and .score_max == 900 and .score_avg == 437.5' "ready gate summarizes scores and bindings"

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
