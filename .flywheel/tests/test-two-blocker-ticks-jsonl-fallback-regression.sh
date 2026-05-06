#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/two-blocker-ticks-escalator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/two-blocker-jsonl-fallback.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/.beads"
: >"$repo/.flywheel/dispatch-log.jsonl"
: >"$repo/.beads/issues.jsonl"

dispatch_row() {
  local task="$1" expected="$2"
  jq -nc --arg task "$task" --arg expected "$expected" \
    '{ts:"2026-05-05T23:55:00Z",event:"manual_dispatch",task_id:$task,bead_id:$task,callback_expected_by:$expected,callback_received_at:null,to:"flywheel:3-codex"}' >>"$repo/.flywheel/dispatch-log.jsonl"
}

closed_issue() {
  local id="$1" title="$2" task="${3:-}"
  if [[ -n "$task" ]]; then
    jq -nc --arg id "$id" --arg title "$title" --arg task "$task" \
      '{id:$id,title:$title,status:"closed",priority:0,created_at:"2026-05-06T00:10:00Z",updated_at:"2026-05-06T00:10:00Z",closed_at:"2026-05-06T00:10:00Z",original_blocker_task_id:$task,close_reason:"fixture JSONL fallback close"}' >>"$repo/.beads/issues.jsonl"
  else
    jq -nc --arg id "$id" --arg title "$title" \
      '{id:$id,title:$title,status:"closed",priority:0,created_at:"2026-05-06T00:10:00Z",updated_at:"2026-05-06T00:10:00Z",closed_at:"2026-05-06T00:10:00Z",close_reason:"fixture JSONL fallback close"}' >>"$repo/.beads/issues.jsonl"
  fi
}

run_probe() {
  TWO_BLOCKER_TICKS_STATE="$TMP/state.json" \
  TWO_BLOCKER_TICKS_LEDGER="$TMP/ledger.jsonl" \
  TWO_BLOCKER_TICKS_COORDINATION_LOG="$TMP/coordination.jsonl" \
  TWO_BLOCKER_TICKS_NOW="2026-05-06T02:00:00Z" \
    "$SCRIPT" check --repo "$repo" --json >"$TMP/out.json"
}

for task in \
  advisory-rules-gap-audit-2026-05-05 \
  br-db-wedge-repair-2026-05-05 \
  phase2-p2-12-audit-publishability-2026-05-05 \
  watcher-launchd-enable-2026-05-05; do
  dispatch_row "$task" "2026-05-06T00:30:00Z"
done

cat >"$TMP/state.json" <<'JSON'
{
  "advisory-rules-gap-audit-2026-05-05": {"consecutive_tick_count": 2, "last_seen_tick_key": "tick5m:old"},
  "br-db-wedge-repair-2026-05-05": {"consecutive_tick_count": 2, "last_seen_tick_key": "tick5m:old"},
  "phase2-p2-12-audit-publishability-2026-05-05": {"consecutive_tick_count": 2, "last_seen_tick_key": "tick5m:old"},
  "watcher-launchd-enable-2026-05-05": {"consecutive_tick_count": 2, "last_seen_tick_key": "tick5m:old"}
}
JSON

closed_issue "flywheel-advisory-gaps-77e2" "Advisory-rules gap audit (socraticode-backed)"
closed_issue "flywheel-escalate-9beb9b99" "escalate-blocker-br-db-wedge-repair-2026-05-05-via-flywheel-plan" "br-db-wedge-repair-2026-05-05"
closed_issue "flywheel-p2-12" "phase2-p2-12-audit-publishability"
closed_issue "flywheel-2jvz2" "watcher-launchd-enable"

run_probe

if jq -e '.signal == "GREEN" and .blocked_count == 0 and (.closed_via_issues | length) == 4' "$TMP/out.json" >/dev/null; then
  pass "jsonl_fallback_closed_dispatches_are_green"
else
  jq . "$TMP/out.json" >&2 || true
  fail "jsonl_fallback_closed_dispatches_are_green"
fi

if jq -e '. == {}' "$TMP/state.json" >/dev/null; then
  pass "stale_blocker_state_cleared"
else
  jq . "$TMP/state.json" >&2 || true
  fail "stale_blocker_state_cleared"
fi

callback_repo="$TMP/callback-repo"
mkdir -p "$callback_repo/.flywheel" "$callback_repo/.beads"
jq -nc '{ts:"2026-05-06T00:00:00Z",event:"manual_dispatch",task_id:"callback-path",bead_id:"callback-path",callback_expected_by:"2026-05-06T00:05:00Z",callback_received_at:null}' >"$callback_repo/.flywheel/dispatch-log.jsonl"
jq -nc '{ts:"2026-05-06T00:06:00Z",event:"callback_received",task_id:"callback-path",bead_id:"callback-path",callback_expected_by:"2026-05-06T00:05:00Z",callback_received_at:"2026-05-06T00:06:00Z"}' >>"$callback_repo/.flywheel/dispatch-log.jsonl"
: >"$callback_repo/.beads/issues.jsonl"
TWO_BLOCKER_TICKS_STATE="$TMP/callback-state.json" \
TWO_BLOCKER_TICKS_LEDGER="$TMP/callback-ledger.jsonl" \
TWO_BLOCKER_TICKS_COORDINATION_LOG="$TMP/callback-coordination.jsonl" \
TWO_BLOCKER_TICKS_NOW="2026-05-06T02:00:00Z" \
  "$SCRIPT" check --repo "$callback_repo" --json >"$TMP/callback-out.json"

if jq -e '.signal == "GREEN" and .blocked_count == 0 and (.closed_via_issues | length) == 0' "$TMP/callback-out.json" >/dev/null; then
  pass "dispatch_log_callback_path_still_green"
else
  jq . "$TMP/callback-out.json" >&2 || true
  fail "dispatch_log_callback_path_still_green"
fi

printf 'PASS cases=3 failures=0\n'
