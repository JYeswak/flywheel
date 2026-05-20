#!/usr/bin/env bash
# tests/worktree-reaper-smoke.sh — Bead flywheel-awn6w
# Verifies: dirty worktree refused, clean+stale reaped, JSON envelope shape, sanity gate.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worktree-reaper.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Syntax
if bash -n "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

# Build fixture: a fake ~/Developer with one repo and two worktrees
FIX=$(mktemp -d -t wt-reaper-smoke.XXXXXX)
trap 'rm -rf "$FIX"' EXIT

DEV="$FIX/Developer"
mkdir -p "$DEV"
REPO="$DEV/demo-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b main
git -C "$REPO" config user.email "smoke@test"
git -C "$REPO" config user.name "smoke"
echo "seed" > "$REPO/README"
git -C "$REPO" add README
git -C "$REPO" commit -q -m "seed"

# WT-A: clean + stale (old commit date)
WT_A="$DEV/wt-clean-stale"
git -C "$REPO" worktree add -q -b feat-stale "$WT_A" >/dev/null
# backdate commit to 30 days ago
OLD_TS=$(date -u -v-30d +%s 2>/dev/null || date -u -d '30 days ago' +%s)
GIT_COMMITTER_DATE="@$OLD_TS +0000" GIT_AUTHOR_DATE="@$OLD_TS +0000" \
  git -C "$WT_A" commit -q --allow-empty --date "@$OLD_TS" -m "stale work" \
  --amend --no-edit --reset-author 2>/dev/null || \
  GIT_COMMITTER_DATE="@$OLD_TS" GIT_AUTHOR_DATE="@$OLD_TS" git -C "$WT_A" commit -q --allow-empty -m "stale" || true
# Force commit object date by amending
GIT_COMMITTER_DATE="@$OLD_TS" git -C "$WT_A" commit -q --amend --no-edit --date="@$OLD_TS" 2>/dev/null || true

# WT-B: dirty (uncommitted changes)
WT_B="$DEV/wt-dirty"
git -C "$REPO" worktree add -q -b feat-dirty "$WT_B" >/dev/null
echo "uncommitted" > "$WT_B/scratch.txt"

# Dry-run
OUT=$("$SCRIPT" --developer-dir "$DEV" --dry-run --json --min-age-days 14 2>/dev/null)
echo "$OUT" | jq -e '.schema == "worktree_reaper.v1"' >/dev/null && pass "json envelope schema" || fail "json envelope schema"
echo "$OUT" | jq -e '.repos_scanned == 1' >/dev/null && pass "scanned 1 repo" || fail "scanned 1 repo (got $(echo "$OUT" | jq .repos_scanned))"
echo "$OUT" | jq -e '.worktrees_found >= 3' >/dev/null && pass "found >=3 worktrees (primary + 2)" || fail "worktrees_found"
# Dirty must be in skipped with uncommitted-changes reason
echo "$OUT" | jq -e '.worktrees_skipped | map(select(.reason == "uncommitted-changes")) | length == 1' >/dev/null \
  && pass "dirty worktree refused with uncommitted-changes reason" || fail "dirty refusal"
# Stale clean must be planned for reap (worktrees_reaped == 1 in dry-run)
echo "$OUT" | jq -e '.planned_reap_count == 1' >/dev/null \
  && pass "stale+clean worktree planned for reap" || fail "stale planned ($(echo "$OUT" | jq .planned_reap_count))"
echo "$OUT" | jq -e '.dashboard_line | test("worktree-reaper")' >/dev/null && pass "dashboard_line present" || fail "dashboard_line"

# Apply mode
OUT2=$("$SCRIPT" --developer-dir "$DEV" --apply --json --min-age-days 14 2>/dev/null)
echo "$OUT2" | jq -e '.worktrees_reaped == 1' >/dev/null && pass "apply mode reaped 1 worktree" || fail "apply reap count"
# Dirty worktree must still exist on disk
[[ -d "$WT_B" ]] && pass "dirty worktree preserved on disk" || fail "dirty worktree deleted (UNSAFE)"
[[ ! -d "$WT_A" ]] && pass "stale worktree removed from disk" || fail "stale worktree still on disk"

# Sanity gate: low max-per-run, build 3 stale worktrees and require gate trip
REPO2="$DEV/demo-repo2"
mkdir -p "$REPO2" && git -C "$REPO2" init -q -b main
git -C "$REPO2" config user.email a@b && git -C "$REPO2" config user.name x
echo s > "$REPO2/R" && git -C "$REPO2" add R && git -C "$REPO2" commit -q -m s
for i in 1 2 3; do
  git -C "$REPO2" worktree add -q -b "stale-$i" "$DEV/wt-many-$i" >/dev/null
  GIT_COMMITTER_DATE="@$OLD_TS" git -C "$DEV/wt-many-$i" commit -q --amend --no-edit --date="@$OLD_TS" 2>/dev/null || true
done
OUT3=$("$SCRIPT" --developer-dir "$DEV" --apply --json --min-age-days 14 --max-per-run 1 2>/dev/null) || true
echo "$OUT3" | jq -e '.status == "sanity-gate-tripped"' >/dev/null \
  && pass "sanity gate trips on >max-per-run" || fail "sanity gate (status=$(echo "$OUT3" | jq -r .status))"

echo ""
echo "=== smoke: $pass_count pass / $fail_count fail ==="
exit $(( fail_count > 0 ? 1 : 0 ))
