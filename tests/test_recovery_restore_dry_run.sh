#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SNAP="$ROOT/.flywheel/scripts/recovery-baseline-snapshot.sh"
RESTORE="$ROOT/.flywheel/scripts/recovery-restore-harness.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-restore-dry.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

sessions=(flywheel {session} clutterfreespaces {session} {capability-control-plane} vrtx zeststream-v2 {proof-product})
mkdir -p "$TMP/repos" "$TMP/state" "$TMP/snaps" "$TMP/launch"
repo_json="$TMP/repo-map.json"; jq -nc '{}' >"$repo_json"
printf '[session_paths]\n' >"$TMP/ntm.toml"
for session in "${sessions[@]}"; do
  repo="$TMP/repos/$session"
  mkdir -p "$repo/.beads" "$repo/.flywheel"
  printf '{"id":"%s"}\n' "$session" >"$repo/.beads/issues.jsonl"
  printf '{"session":"%s"}\n' "$session" >"$repo/.flywheel/dispatch-log.jsonl"
  printf 'mission\n' >"$repo/.flywheel/MISSION.md"; printf 'goal\n' >"$repo/.flywheel/GOAL.md"; printf 'state\n' >"$repo/.flywheel/STATE.md"
  printf '<?xml version="1.0"?><plist version="1.0"><dict><key>Label</key><string>com.zeststream.%s.watcher</string></dict></plist>\n' "$session" >"$TMP/launch/com.zeststream.$session.watcher.plist"
  jq --arg s "$session" --arg r "$repo" '. + {($s): $r}' "$repo_json" >"$TMP/r.json"; mv "$TMP/r.json" "$repo_json"
  printf '"%s" = "%s"\n' "$session" "$repo" >>"$TMP/ntm.toml"
done
FLYWHEEL_RECOVERY_REPO_MAP_JSON="$(cat "$repo_json")" FLYWHEEL_RECOVERY_NOW="2026-05-07T03:00:00Z" "$SNAP" --snapshot-dir "$TMP/snaps" --state-dir "$TMP/state" --ntm-config "$TMP/ntm.toml" --launchagents-dir "$TMP/launch" --json >"$TMP/snap.json"

bash -n "$RESTORE" && pass "script_syntax" || fail "script_syntax"
manifest_before="$(shasum "$(jq -r '.paths.manifest' "$TMP/snap.json")" | awk '{print $1}')"
tarball_before="$(shasum "$(jq -r '.paths.tarball' "$TMP/snap.json")" | awk '{print $1}')"
"$RESTORE" --manifest "$(jq -r '.paths.manifest' "$TMP/snap.json")" --restore-root "$TMP/restore-root" --receipt-dir "$TMP/receipts" --json >"$TMP/plan.json"
manifest_after="$(shasum "$(jq -r '.paths.manifest' "$TMP/snap.json")" | awk '{print $1}')"
tarball_after="$(shasum "$(jq -r '.paths.tarball' "$TMP/snap.json")" | awk '{print $1}')"
[[ "$manifest_before" == "$manifest_after" && "$tarball_before" == "$tarball_after" ]] && pass "dry_run_no_snapshot_mutation" || fail "dry_run_no_snapshot_mutation"
assert_jq "$TMP/plan.json" '.status=="planned" and .mode=="dry-run" and (.actions|length)==8 and (.protected_sessions_restore_blocked|length)==2' "dry_run_plan_shape"
[[ ! -e "$TMP/restore-root" ]] && pass "restore_root_not_created" || fail "restore_root_not_created"
[[ ! -e "$TMP/receipts" ]] && pass "receipt_dir_not_created" || fail "receipt_dir_not_created"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 5 ]]
