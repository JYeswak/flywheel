#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stale-worktree-detector.sh"
INSTALLER="$ROOT/.flywheel/scripts/install-stale-worktree-detector-launchd.sh"
FLEET="$ROOT/.flywheel/scripts/stale-worktree-detector-fleet-rollout.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stale-worktree-detector.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf 'ok %d - %s\n' "$PASS" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'not ok %d - %s\n' "$((PASS + FAIL))" "$1" >&2; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    cat "$file" >&2
  fi
}

git_init_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email "fixture@example.test"
  git -C "$repo" config user.name "Fixture"
  printf 'root\n' >"$repo/README.md"
  git -C "$repo" add README.md
  GIT_AUTHOR_DATE="2026-05-01T00:00:00Z" GIT_COMMITTER_DATE="2026-05-01T00:00:00Z" \
    git -C "$repo" commit -q -m "initial"
}

repo="$TMP/repo"
remote="$TMP/origin.git"
rev_wt="/Users/josh/Developer/flywheel-aa-bbbbb-ccccc-000001"
case_root="/Users/josh/Developer/flywheel-xr6zb-smoke-$$"
detached_wt="$case_root-detached"
dirty_wt="$case_root-dirty"
first_dup="$case_root-dup-one"
second_dup="$case_root-dup-two"
local_only="$case_root-local-only"
rm -rf "$rev_wt" "$detached_wt" "$dirty_wt" "$first_dup" "$second_dup" "$local_only"
trap 'rm -rf "$TMP"; rm -rf "/Users/josh/Developer/flywheel-aa-bbbbb-ccccc-000001" "/Users/josh/Developer/flywheel-xr6zb-smoke-$$-detached" "/Users/josh/Developer/flywheel-xr6zb-smoke-$$-dirty" "/Users/josh/Developer/flywheel-xr6zb-smoke-$$-dup-one" "/Users/josh/Developer/flywheel-xr6zb-smoke-$$-dup-two" "/Users/josh/Developer/flywheel-xr6zb-smoke-$$-local-only"' EXIT
git_init_repo "$repo"
git init -q --bare "$remote"
git -C "$repo" remote add origin "$remote"
git -C "$repo" push -q -u origin main

tmp_wt="$TMP/tmp-disposable"
git -C "$repo" worktree add -q -b tmp-disposable "$tmp_wt" main

git -C "$repo" worktree add -q -b cleanup/merged-pushed "$rev_wt" main
git -C "$repo" push -q -u origin cleanup/merged-pushed
git -C "$repo" worktree remove -f "$rev_wt"
git -C "$repo" worktree add -q "$rev_wt" cleanup/merged-pushed

git -C "$repo" worktree add -q --detach "$detached_wt" main

git -C "$repo" worktree add -q -b dirty-branch "$dirty_wt" main
printf 'dirty\n' >"$dirty_wt/dirty.txt"

git -C "$repo" worktree add -q -b duplicate-branch "$first_dup" main
git -C "$repo" worktree add -q --force "$second_dup" duplicate-branch

git -C "$repo" worktree add -q -b local-only "$local_only" main

out="$TMP/out.json"
STALE_WORKTREE_DETECTOR_AUDIT_LOG="$TMP/audit.jsonl" \
  "$SCRIPT" --repo "$repo" --age-threshold-days 7 --dry-run --json >"$out"

assert_jq "$out" '.schema_version == "flywheel.stale_worktree_detector.v1"' "detector emits v1 schema"
assert_jq "$out" '.classified.DISPOSABLE[] | select(.branch == "tmp-disposable" and .route == "8iook")' "tmpdir routes to 8iook"
assert_jq "$out" '.classified.REVERSIBLE_RECIPE[] | select(.path == "'"$rev_wt"'" and .route == "daeqx" and .recipe == "git-worktree-remove-sibling-merged-pushed")' "merged pushed sibling routes to daeqx recipe"
assert_jq "$out" '.classified.PEER_REVIEW[] | select(.path == "'"$detached_wt"'" and (.context_check | contains("detached_or_missing_branch")))' "detached worktree routes peer review"
assert_jq "$out" '.classified.PEER_REVIEW[] | select(.path == "'"$dirty_wt"'" and (.context_check | contains("worktree_has_uncommitted_changes")))' "dirty worktree routes peer review"
assert_jq "$out" '.classified.PEER_REVIEW[] | select(.path == "'"$first_dup"'" and (.context_check | contains("multiple_worktrees_same_branch")))' "duplicate branch routes peer review"
assert_jq "$out" '.classified.PEER_REVIEW[] | select(.path == "'"$local_only"'" and .pushed_to_origin == false)' "non-tracking branch routes peer review"
assert_jq "$out" '.routing_table.status == "missing"' "missing zesttube routing table surfaced"

apply_out="$TMP/apply.json"
STALE_WORKTREE_DETECTOR_AUDIT_LOG="$TMP/apply-audit.jsonl" \
STALE_WORKTREE_DETECTOR_PEER_QUEUE="$TMP/peer.jsonl" \
  "$SCRIPT" --repo "$repo" --age-threshold-days 7 --apply --json >"$apply_out"
assert_jq "$apply_out" '.submissions >= 6' "apply writes routing submissions without cleanup"
if [[ -d $tmp_wt && -d $rev_wt ]]; then
  pass "apply mode does not remove worktrees"
else
  fail "apply mode does not remove worktrees"
fi

install_out="$TMP/install.json"
STALE_WORKTREE_DETECTOR_LAUNCH_AGENTS_DIR="$TMP/LaunchAgents" \
STALE_WORKTREE_DETECTOR_STATE_DIR="$TMP/state" \
  "$INSTALLER" --repo "$repo" --dry-run --json >"$install_out"
assert_jq "$install_out" '.outcome == "dry-run" and .interval_seconds == 21600' "installer dry-run plans 6h launchd cadence"

fleet_block="$TMP/fleet-block.json"
if "$FLEET" --apply --json >"$fleet_block" 2>/dev/null; then
  fail "fleet apply requires Joshua gate"
else
  assert_jq "$fleet_block" '.outcome == "blocked" and .reason == "missing-joshua-approved-gate"' "fleet apply blocked without Joshua approval"
fi

fleet_dry="$TMP/fleet-dry.json"
STALE_WORKTREE_DETECTOR_REPOS="fixture:$repo;missing:$TMP/missing" \
STALE_WORKTREE_DETECTOR_LAUNCH_AGENTS_DIR="$TMP/FleetLaunchAgents" \
STALE_WORKTREE_DETECTOR_STATE_DIR="$TMP/fleet-state" \
  "$FLEET" --dry-run --json >"$fleet_dry"
assert_jq "$fleet_dry" '.mode == "dry-run" and (.repos | length == 2)' "fleet dry-run reports planned repos"

printf 'SUMMARY pass=%s fail=%s\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
test "$PASS" -ge 12
