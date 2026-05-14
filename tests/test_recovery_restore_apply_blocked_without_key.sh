#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SNAP="$ROOT/.flywheel/scripts/recovery-baseline-snapshot.sh"
RESTORE="$ROOT/.flywheel/scripts/recovery-restore-harness.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-restore-key.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

mkdir -p "$TMP/repos/flywheel/.beads" "$TMP/repos/flywheel/.flywheel" "$TMP/snaps" "$TMP/state" "$TMP/launch"
printf '{"id":"fixture"}\n' >"$TMP/repos/flywheel/.beads/issues.jsonl"
printf '{}\n' >"$TMP/repos/flywheel/.flywheel/dispatch-log.jsonl"
printf 'm\n' >"$TMP/repos/flywheel/.flywheel/MISSION.md"; printf 'g\n' >"$TMP/repos/flywheel/.flywheel/GOAL.md"; printf 's\n' >"$TMP/repos/flywheel/.flywheel/STATE.md"
for session in flywheel {session} clutterfreespaces {session} {capability-control-plane} vrtx zeststream-v2 {proof-product}; do
  repo="$TMP/repos/$session"; mkdir -p "$repo/.beads" "$repo/.flywheel"
  printf '{"id":"%s"}\n' "$session" >"$repo/.beads/issues.jsonl"
  printf '{}\n' >"$repo/.flywheel/dispatch-log.jsonl"
  printf 'm\n' >"$repo/.flywheel/MISSION.md"; printf 'g\n' >"$repo/.flywheel/GOAL.md"; printf 's\n' >"$repo/.flywheel/STATE.md"
  printf '<?xml version="1.0"?><plist version="1.0"><dict><key>Label</key><string>com.zeststream.%s.watcher</string></dict></plist>\n' "$session" >"$TMP/launch/com.zeststream.$session.watcher.plist"
done
repo_map="$(jq -nc --arg root "$TMP/repos" '{flywheel:($root+"/flywheel"),{session}:($root+"/{session}"),clutterfreespaces:($root+"/clutterfreespaces"),{session}:($root+"/{session}"),{capability-control-plane}:($root+"/{capability-control-plane}"),vrtx:($root+"/vrtx"),"zeststream-v2":($root+"/zeststream-v2"),"{proof-product}":($root+"/{proof-product}")}')"
FLYWHEEL_RECOVERY_REPO_MAP_JSON="$repo_map" FLYWHEEL_RECOVERY_NOW="2026-05-07T03:00:00Z" "$SNAP" --snapshot-dir "$TMP/snaps" --state-dir "$TMP/state" --ntm-config "$TMP/missing.toml" --launchagents-dir "$TMP/launch" --json >"$TMP/snap.json"

set +e
FLYWHEEL_RECOVERY_RESTORE_APPROVAL=JOSHUA_APPROVED "$RESTORE" --apply --manifest "$(jq -r '.paths.manifest' "$TMP/snap.json")" --restore-root "$TMP/restore-root" --receipt-dir "$TMP/receipts" --json >"$TMP/out.json"
rc=$?
set -e
[[ "$rc" == "2" ]] && pass "apply_without_key_rejected_rc" || fail "apply_without_key_rejected_rc=$rc"
jq -e '.status=="rejected" and .error=="--apply requires --idempotency-key"' "$TMP/out.json" >/dev/null && pass "apply_without_key_rejected_json" || fail "apply_without_key_rejected_json"
[[ ! -e "$TMP/receipts" ]] && pass "no_receipt_written" || fail "no_receipt_written"
[[ ! -e "$TMP/restore-root" ]] && pass "no_restore_mutation" || fail "no_restore_mutation"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
