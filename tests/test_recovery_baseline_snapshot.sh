#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-baseline-snapshot.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-baseline-test.XXXXXX")"
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
mkdir -p "$TMP/repos" "$TMP/state" "$TMP/snapshots" "$TMP/LaunchAgents" "$TMP/tokens"
repo_json="$TMP/repo-map.json"
jq -nc '{ }' >"$repo_json"
for session in "${sessions[@]}"; do
  repo="$TMP/repos/$session"
  mkdir -p "$repo/.beads" "$repo/.flywheel" "$TMP/LaunchAgents"
  printf '{"id":"%s-1","status":"in_progress"}\n' "$session" >"$repo/.beads/issues.jsonl"
  printf '{"session":"%s","dispatch_id":"d1"}\n' "$session" >"$repo/.flywheel/dispatch-log.jsonl"
  printf '# %s mission\n' "$session" >"$repo/.flywheel/MISSION.md"
  printf '# %s goal\n' "$session" >"$repo/.flywheel/GOAL.md"
  printf '# %s state\n' "$session" >"$repo/.flywheel/STATE.md"
  cat >"$TMP/LaunchAgents/com.zeststream.$session.watcher.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>Label</key><string>com.zeststream.$session.watcher</string></dict></plist>
PLIST
  repo_json_next="$TMP/repo-map.next.json"
  jq --arg session "$session" --arg repo "$repo" '. + {($session): $repo}' "$repo_json" >"$repo_json_next"
  mv "$repo_json_next" "$repo_json"
  jq -nc --arg session "$session" --arg repo "$repo" --arg ts "2026-05-07T00:00:00Z" '{session:$session,repo_path:$repo,effective_at:$ts}' >>"$TMP/state/session-topology.jsonl"
  jq -nc --arg session "$session" --arg repo "$repo" '{session:$session,repo_path:$repo}' >>"$TMP/state/team-roster.jsonl"
done
printf 'fixture-secret-token\n' >"$TMP/tokens/EmeraldDeer.token"
printf '[session_paths]\n' >"$TMP/ntm.toml"
for session in "${sessions[@]}"; do
  printf '"%s" = "%s"\n' "$session" "$TMP/repos/$session" >>"$TMP/ntm.toml"
done

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
FLYWHEEL_RECOVERY_REPO_MAP_JSON="$(cat "$repo_json")" \
FLYWHEEL_RECOVERY_NOW="2026-05-07T03:00:00Z" \
  "$SCRIPT" \
  --trigger manual \
  --snapshot-dir "$TMP/snapshots" \
  --state-dir "$TMP/state" \
  --ntm-config "$TMP/ntm.toml" \
  --launchagents-dir "$TMP/LaunchAgents" \
  --agent-mail-token-dir "$TMP/tokens" \
  --json >"$TMP/out.json"

manifest="$(jq -r '.paths.manifest' "$TMP/out.json")"
tarball="$(jq -r '.paths.tarball' "$TMP/out.json")"
[[ -s "$manifest" ]] && pass "manifest_written" || fail "manifest_written"
[[ -s "$tarball" ]] && pass "tarball_written" || fail "tarball_written"
assert_jq "$manifest" '.schema_version=="flywheel-recovery-baseline/v1" and .source_plan==".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md" and (.sessions|length)==8' "manifest_shape_source_plan_sessions"
assert_jq "$manifest" '([.sessions[].session] | sort) == (["{session}","clutterfreespaces","flywheel","{proof-product}","{session}","{capability-control-plane}","vrtx","zeststream-v2"] | sort)' "all_8_sessions_classified"
assert_jq "$manifest" 'all(.sessions[]; has("checkpoint_ready") and (.checkpoint_ready|type=="boolean"))' "checkpoint_ready_boolean"
assert_jq "$manifest" '.excluded_sessions[0].session=="zesttube" and (.protected_sessions_restore_blocked|sort)==(["{session}","{session}"]|sort)' "zesttube_excluded_protected_policy"
if ! grep -R "fixture-secret-token" "$manifest" "$TMP/snapshots"/*.tar.gz >/dev/null 2>&1; then pass "agent_mail_token_value_not_copied"; else fail "agent_mail_token_value_not_copied"; fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 7 ]]
