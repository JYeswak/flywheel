#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-loop-revive.py"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d -t n1rh.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

loops="$TMP/loops"
receipts="$TMP/receipts"
repo_ok="$TMP/repos/ok"
repo_blocked="$TMP/repos/blocked"
mkdir -p "$loops" "$receipts" "$repo_ok/.flywheel" "$repo_blocked/.flywheel"
touch "$repo_ok/.flywheel/ntm-setup.sh"
chmod +x "$repo_ok/.flywheel/ntm-setup.sh"

jq -nc --arg repo "$repo_ok" '{
  schema_version:"flywheel-loop-state/v1",
  project:"ok-loop",
  repo:$repo,
  session:"ok-loop",
  tier:"active_normal",
  interval:"30m",
  active:true,
  started_at:"2026-05-08T00:00:00Z",
  auto_revive_on_reboot:true,
  driver:{mode:"launchd_prompt",verified:false}
}' >"$loops/ok-loop.json"

jq -nc --arg repo "$repo_blocked" '{
  schema_version:"flywheel-loop-state/v1",
  project:"blocked-loop",
  repo:$repo,
  session:"blocked-loop",
  tier:"active_high",
  interval:"5m",
  active:true,
  started_at:"2026-05-08T00:01:00Z",
  auto_revive_on_reboot:true
}' >"$loops/blocked-loop.json"

jq -nc --arg repo "$TMP/repos/noauto" '{
  project:"noauto-loop",
  repo:$repo,
  active:true,
  started_at:"2026-05-08T00:01:00Z",
  auto_revive_on_reboot:false
}' >"$loops/noauto-loop.json"

jq -nc --arg repo "$TMP/repos/inactive" '{
  project:"inactive-loop",
  repo:$repo,
  active:false,
  auto_revive_on_reboot:true
}' >"$loops/inactive-loop.json"

python3 "$SCRIPT" \
  --loops-dir "$loops" \
  --receipt-dir "$receipts" \
  --boot-time "2026-05-08T01:00:00Z" \
  --dry-run \
  --write-receipt \
  --json >"$TMP/dry-run.json"

jq -e '
  .schema_version == "flywheel-loop-revive/v1"
  and .dry_run == true
  and .candidate_count == 2
  and ([.candidates[].project] | sort == ["blocked-loop","ok-loop"])
  and (.selected[] | select(.project == "blocked-loop" and .action == "revive_blocked" and .missing_datum == "session_setup_path"))
  and (.selected[] | select(.project == "ok-loop" and .action == "revive_candidate" and (.planned_loop_start | contains("/flywheel:loop start"))))
  and .notification.dry_run == true
  and .notification.would_notify == true
  and .receipt_path != null
' "$TMP/dry-run.json" >/dev/null

python3 "$SCRIPT" \
  --loops-dir "$loops" \
  --receipt-dir "$receipts" \
  --project ok-loop \
  --boot-time "2026-05-08T01:00:00Z" \
  --apply \
  --simulate-rehydrate \
  --idempotency-key n1rh-fixture \
  --json >"$TMP/apply.json"

jq -e '
  .status == "applied"
  and .applied_actions[0].rehydrate_mode == "simulated"
  and (.applied_actions[0].planned_loop_start | contains("/flywheel:loop start"))
  and .applied_actions[0].resulting_loop_state.state_marker_not_driver == true
' "$TMP/apply.json" >/dev/null

empty="$TMP/empty-loops"
mkdir -p "$empty"
python3 "$SCRIPT" --loops-dir "$empty" --dry-run --json >"$TMP/empty.json"
jq -e '.candidate_count == 0 and .notification.would_notify == false and .notification.reason == "routine_successful_check_no_notify"' "$TMP/empty.json" >/dev/null

"$LOOP_BIN" revive --loops-dir "$loops" --project ok-loop --boot-time "2026-05-08T01:00:00Z" --dry-run --json >"$TMP/bin.json"
jq -e '.selected_count == 1 and .selected[0].project == "ok-loop"' "$TMP/bin.json" >/dev/null

plutil -lint "$ROOT/.flywheel/launchd/com.zeststream.flywheel-loop-revive.plist" >/dev/null

rg -n "auto_revive_on_reboot|revive|keepalive|RunAtLoad|loops/.*json" \
  "$HOME/.claude/commands/flywheel/revive.md" \
  "$HOME/.claude/commands/flywheel/loop.md" \
  "$ROOT/.flywheel/scripts" \
  "$ROOT/tests" >/dev/null

echo "flywheel loop revive reboot survival fixture passes"
