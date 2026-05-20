#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
SYNC="$ROOT/.flywheel/scripts/git-main-sync.sh"
INSTALLER="$ROOT/.flywheel/scripts/install-git-main-sync-launchd.sh"
FLEET="$ROOT/.flywheel/scripts/git-main-sync-fleet-rollout.sh"
TMP=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

ok() {
  printf 'ok - %s\n' "$1"
  PASS=$((PASS + 1))
}

not_ok() {
  printf 'not ok - %s\n' "$1" >&2
  FAIL=$((FAIL + 1))
}

assert_eq() {
  local got=$1
  local want=$2
  local label=$3
  if [[ $got == "$want" ]]; then ok "$label"; else not_ok "$label got=$got want=$want"; fi
}

json_field() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
value = data
for part in sys.argv[2].split("."):
    value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

json_has_keys() {
  python3 - "$1" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
required = {"schema", "outcome", "branch", "local_ahead", "remote_ahead", "fetched_refs", "rebase_applied"}
missing = sorted(required - set(data))
if missing:
    raise SystemExit("missing " + ",".join(missing))
PY
}

setup_fixture() {
  local name=$1
  local base="$TMP/$name"
  local remote="$base/remote.git"
  local seed="$base/seed"
  local work="$base/work"
  mkdir -p "$base"
  git init --bare "$remote" >/dev/null
  git init -b main "$seed" >/dev/null
  git -C "$seed" config user.email test@example.com
  git -C "$seed" config user.name "Test User"
  printf 'base\n' > "$seed/tracked.txt"
  git -C "$seed" add tracked.txt
  git -C "$seed" commit -m "base" >/dev/null
  git -C "$seed" remote add origin "$remote"
  git -C "$seed" push -u origin main >/dev/null
  git --git-dir="$remote" symbolic-ref HEAD refs/heads/main
  git clone "$remote" "$work" >/dev/null 2>&1
  git -C "$work" config user.email test@example.com
  git -C "$work" config user.name "Test User"
  printf '%s\n' "$seed:$work"
}

remote_commit() {
  local seed=$1
  local label=$2
  printf '%s\n' "$label" >> "$seed/remote.txt"
  git -C "$seed" add remote.txt
  git -C "$seed" commit -m "$label" >/dev/null
  git -C "$seed" push origin main >/dev/null
}

fixture=$(setup_fixture clean)
seed=${fixture%%:*}
work=${fixture#*:}
remote_commit "$seed" "remote-clean"
out=$("$SYNC" --repo "$work" --apply --json)
json_has_keys "$out" && ok "JSON envelope shape"
assert_eq "$(json_field "$out" schema)" "git_main_sync.v1" "schema is git_main_sync.v1"
assert_eq "$(json_field "$out" outcome)" "synced" "clean-tree-sync outcome"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$(git -C "$seed" rev-parse HEAD)" "clean-tree-sync updated HEAD"

fixture=$(setup_fixture dirty)
seed=${fixture%%:*}
work=${fixture#*:}
remote_commit "$seed" "remote-dirty"
printf 'local-dirty\n' >> "$work/tracked.txt"
out=$("$SYNC" --repo "$work" --apply --json)
assert_eq "$(json_field "$out" outcome)" "synced" "dirty-tree-autostash outcome"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$(git -C "$seed" rev-parse HEAD)" "dirty-tree-autostash updated HEAD"
if grep -q "local-dirty" "$work/tracked.txt"; then ok "dirty-tree-autostash restored local edit"; else not_ok "dirty-tree-autostash restored local edit"; fi

fixture=$(setup_fixture feature)
seed=${fixture%%:*}
work=${fixture#*:}
git -C "$work" switch -c feat/demo >/dev/null
feature_head=$(git -C "$work" rev-parse HEAD)
remote_commit "$seed" "remote-feature"
out=$("$SYNC" --repo "$work" --apply --json)
assert_eq "$(json_field "$out" outcome)" "fetched" "feature-branch-no-touch outcome"
assert_eq "$(json_field "$out" rebase_applied)" "false" "feature-branch-no-touch no rebase"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$feature_head" "feature-branch-no-touch HEAD unchanged"

fixture=$(setup_fixture detached)
seed=${fixture%%:*}
work=${fixture#*:}
remote_commit "$seed" "remote-detached"
git -C "$work" switch --detach HEAD >/dev/null
detached_head=$(git -C "$work" rev-parse HEAD)
out=$("$SYNC" --repo "$work" --apply --json)
assert_eq "$(json_field "$out" outcome)" "skipped" "detached-HEAD-skip outcome"
assert_eq "$(json_field "$out" reason)" "conflict-recovery-in-progress" "detached-HEAD-skip reason"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$detached_head" "detached-HEAD-skip no mutation"

fixture=$(setup_fixture dryrun)
seed=${fixture%%:*}
work=${fixture#*:}
origin_before=$(git -C "$work" rev-parse origin/main)
head_before=$(git -C "$work" rev-parse HEAD)
remote_commit "$seed" "remote-dryrun"
out=$("$SYNC" --repo "$work" --dry-run --json)
assert_eq "$(json_field "$out" outcome)" "dry-run" "dry-run outcome"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$head_before" "dry-run-no-mutation HEAD unchanged"
assert_eq "$(git -C "$work" rev-parse origin/main)" "$origin_before" "dry-run-no-mutation did not fetch"

launch_dir="$TMP/launchagents"
state_dir="$TMP/state"
out=$(GIT_MAIN_SYNC_LAUNCH_AGENTS_DIR="$launch_dir" GIT_MAIN_SYNC_STATE_DIR="$state_dir" "$INSTALLER" --repo "$work" --dry-run --json)
assert_eq "$(json_field "$out" schema)" "git_main_sync_launchd.v1" "installer dry-run schema"
assert_eq "$(json_field "$out" outcome)" "dry-run" "installer dry-run outcome"
if [[ ! -e "$launch_dir" ]]; then ok "installer dry-run wrote no LaunchAgents dir"; else not_ok "installer dry-run wrote no LaunchAgents dir"; fi

out=$(GIT_MAIN_SYNC_LAUNCH_AGENTS_DIR="$launch_dir" GIT_MAIN_SYNC_STATE_DIR="$state_dir" GIT_MAIN_SYNC_REPOS="fixture:$work;missing:$TMP/nope" "$FLEET" --dry-run --json)
assert_eq "$(json_field "$out" schema)" "git_main_sync_fleet_rollout.v1" "fleet dry-run schema"
assert_eq "$(json_field "$out" picoz_excluded)" "true" "fleet dry-run excludes picoz"

printf 'SUMMARY pass=%s fail=%s\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
