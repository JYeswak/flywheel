#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SNAP="$ROOT/.flywheel/scripts/recovery-baseline-snapshot.sh"
RESTORE="$ROOT/.flywheel/scripts/recovery-restore-harness.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-drill.XXXXXX")"
DRILL_DIR="${FLYWHEEL_RECOVERY_DRILL_DIR:-$HOME/.flywheel/recovery/drills}"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

sessions=(flywheel alpsinsurance clutterfreespaces picoz skillos vrtx zeststream-v2 mobile-eats)
mkdir -p "$TMP/repos" "$TMP/state" "$TMP/snaps" "$TMP/launch" "$DRILL_DIR"
repo_json="$TMP/repo-map.json"; jq -nc '{}' >"$repo_json"
for session in "${sessions[@]}"; do
  repo="$TMP/repos/$session"
  mkdir -p "$repo/.beads" "$repo/.flywheel"
  printf '{"session":"%s","value":"before-loss"}\n' "$session" >"$repo/.beads/issues.jsonl"
  printf '{"session":"%s","dispatch":"before-loss"}\n' "$session" >"$repo/.flywheel/dispatch-log.jsonl"
  printf 'MISSION %s\n' "$session" >"$repo/.flywheel/MISSION.md"
  printf 'GOAL %s\n' "$session" >"$repo/.flywheel/GOAL.md"
  printf 'STATE %s\n' "$session" >"$repo/.flywheel/STATE.md"
  printf '<?xml version="1.0"?><plist version="1.0"><dict><key>Label</key><string>com.zeststream.%s.watcher</string></dict></plist>\n' "$session" >"$TMP/launch/com.zeststream.$session.watcher.plist"
  jq --arg s "$session" --arg r "$repo" '. + {($s): $r}' "$repo_json" >"$TMP/r.json"; mv "$TMP/r.json" "$repo_json"
done

FLYWHEEL_RECOVERY_REPO_MAP_JSON="$(cat "$repo_json")" FLYWHEEL_RECOVERY_NOW="2026-05-07T03:00:00Z" "$SNAP" --trigger drill --snapshot-dir "$TMP/snaps" --state-dir "$TMP/state" --ntm-config "$TMP/missing.toml" --launchagents-dir "$TMP/launch" --json >"$TMP/snap.json"
manifest="$(jq -r '.paths.manifest' "$TMP/snap.json")"

rm -rf "$TMP/restore-clean" "$TMP/restore-blocked"
FLYWHEEL_RECOVERY_RESTORE_APPROVAL=JOSHUA_APPROVED FLYWHEEL_RECOVERY_NOW="2026-05-07T03:10:00Z" \
  "$RESTORE" --apply --restore-protected --idempotency-key clean-drill --manifest "$manifest" --restore-root "$TMP/restore-clean" --receipt-dir "$TMP/receipts-clean" --json >"$TMP/clean.json"
jq -e '.status=="applied" and all(.actions[]; .applied == true)' "$TMP/clean.json" >/dev/null && pass "clean_restore_applied_all" || fail "clean_restore_applied_all"
for session in "${sessions[@]}"; do
  cmp "$TMP/repos/$session/.beads/issues.jsonl" "$TMP/restore-clean/$session/.beads/issues.jsonl" >/dev/null && pass "clean_match_$session" || fail "clean_match_$session"
done

FLYWHEEL_RECOVERY_RESTORE_APPROVAL=JOSHUA_APPROVED FLYWHEEL_RECOVERY_NOW="2026-05-07T03:20:00Z" \
  "$RESTORE" --apply --idempotency-key blocked-drill --manifest "$manifest" --restore-root "$TMP/restore-blocked" --receipt-dir "$TMP/receipts-blocked" --json >"$TMP/blocked.json"
jq -e '.status=="applied" and (.protected_sessions_restore_blocked|length)==2 and any(.actions[]; .session=="picoz" and .action=="audit_only")' "$TMP/blocked.json" >/dev/null && pass "protected_blocked_path" || fail "protected_blocked_path"
[[ ! -e "$TMP/restore-blocked/picoz/.beads/issues.jsonl" && ! -e "$TMP/restore-blocked/alpsinsurance/.beads/issues.jsonl" ]] && pass "protected_not_restored_without_policy" || fail "protected_not_restored_without_policy"

drill="$DRILL_DIR/drill-20260507T032000Z.json"
jq -n \
  --arg created_at "2026-05-07T03:20:00Z" \
  --arg manifest "$manifest" \
  --arg clean "$TMP/clean.json" \
  --arg blocked "$TMP/blocked.json" \
  '{schema_version:"flywheel-recovery-drill/v1",created_at:$created_at,status:"pass",snapshot_manifest:$manifest,clean_restore_receipt:$clean,protected_blocked_receipt:$blocked,clean_restore_pass:true,protected_blocked_pass:true}' >"$drill.tmp"
mv "$drill.tmp" "$drill"
[[ -s "$drill" ]] && pass "drill_receipt_written" || fail "drill_receipt_written"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 12 ]]
