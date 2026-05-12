#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bleed-ledger-watch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bleed-ledger-watch.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

write_row() {
  local ledger="$1" ts="$2" session="$3" repo="$4" bead="$5"
  jq -nc \
    --arg ts "$ts" \
    --arg session "$session" \
    --arg repo_path "$repo" \
    --arg bead "$bead" \
    '{ts:$ts,kind:"cross_repo_bleed",session:$session,repo_path:$repo_path,observed_bead_id:$bead,expected_prefix:"flywheel-"}' >>"$ledger"
}

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --schema --json | jq -e '.fields | index("bleed_event_count_24h")' >/dev/null && pass "schema_fields"
"$SCRIPT" --info --json | jq -e '.name == "bleed-ledger-watch.sh"' >/dev/null && pass "info_json"
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 3' >/dev/null && pass "examples_json"

empty="$TMP/empty.jsonl"
: >"$empty"
"$SCRIPT" --doctor --json --ledger "$empty" --now "2026-05-08T22:00:00Z" >"$TMP/empty.json"
assert_jq "$TMP/empty.json" '.status == "pass" and .bleed_event_count_24h == 0 and .bleed_session_top == null and .fix_bead_action.action == "noop"' "empty_ledger_passes"

rows="$TMP/rows.jsonl"
write_row "$rows" "2026-05-08T21:30:00Z" flywheel /Users/josh/Developer/flywheel flywheel-alpha
write_row "$rows" "2026-05-08T21:40:00Z" flywheel /Users/josh/Developer/flywheel flywheel-beta
write_row "$rows" "2026-05-08T21:45:00Z" skillos /Users/josh/Developer/skillos skillos-alpha
write_row "$rows" "2026-05-06T21:45:00Z" old /Users/josh/Developer/old old-alpha
set +e
"$SCRIPT" --doctor --json --ledger "$rows" --now "2026-05-08T22:00:00Z" >"$TMP/rows.json"
rc=$?
set -e
[[ "$rc" -eq 1 ]] && pass "n_row_ledger_exits_1" || fail "n_row_ledger_exits_1 rc=$rc"
assert_jq "$TMP/rows.json" '.status == "fail" and .bleed_event_count_24h == 3 and .bleed_session_top.value == "flywheel" and .bleed_session_top.count == 2 and .bleed_repo_top.value == "/Users/josh/Developer/flywheel" and .fix_bead_action.action == "would_create"' "n_row_ledger_counts_and_top"

malformed="$TMP/malformed.jsonl"
printf '%s\n' 'not-json' >>"$malformed"
"$SCRIPT" --doctor --json --ledger "$malformed" --now "2026-05-08T22:00:00Z" >"$TMP/malformed.json"
assert_jq "$TMP/malformed.json" '.status == "warn" and .bleed_event_count_24h == 0 and (.bleed_warnings[] | select(.code == "malformed_row"))' "malformed_row_warns"

printf 'PASS cases=3 assertions=%s failures=0\n' "$pass_count"
