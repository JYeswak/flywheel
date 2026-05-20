#!/usr/bin/env bash
# tests/stash-archiver-smoke.sh — Smoke test for .flywheel/scripts/stash-archiver.sh
#
# Builds a tmp repo with 3 stashes:
#   - One FRESH (age 0 days)            → must be KEPT
#   - Two STALE (commit-date back-dated >max_age) → must be ARCHIVED to .patch
# Then verifies the archived patches are `git apply --check` clean (restorable).
#
# Also exercises the exempt prefix (scratch:) → exempt stash stays unless past hard-cap.
#
# Exits 0 on full pass; nonzero on any assert miss.

set -euo pipefail

SCRIPT="${SCRIPT_UNDER_TEST:-$(cd "$(dirname "$0")/.." && pwd)/.flywheel/scripts/stash-archiver.sh}"
[[ -x "$SCRIPT" ]] || { echo "script not executable: $SCRIPT" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq required" >&2; exit 2; }

WORKDIR=$(mktemp -d -t stash-archiver-smoke.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT
DEVDIR="$WORKDIR/Developer"
mkdir -p "$DEVDIR"
REPO="$DEVDIR/sample-repo"
mkdir -p "$REPO"

pass=0
fail=0
assert() {
  local label="$1" cond="$2"
  if eval "$cond"; then
    echo "PASS: $label"
    pass=$((pass + 1))
  else
    echo "FAIL: $label  (cond: $cond)" >&2
    fail=$((fail + 1))
  fi
}

jq_field() {
  # Args: json-string field
  printf '%s' "$1" | jq -r "$2"
}

# --- Build fixture repo with 3 stashes ---
#
# Build stashes from scratch with controlled commit dates so age-detection is deterministic.
# We construct stash commits manually with GIT_*_DATE then `git stash store` to register them
# in refs/stash + its reflog. Order matters: each `stash store` puts the new entry at stash@{0},
# shifting prior entries down. So we store in this order to end up with:
#   stash@{0} = fresh-wip-keep-me        (today)
#   stash@{1} = scratch: temp-investigation  (60 days ago)
#   stash@{2} = stale-work-one           (60 days ago)
# i.e. store stale-work-one first, then scratch, then fresh last.

build_stash_commit() {
  # echo a stash-shaped commit sha. Args: repo file-contents message iso-date
  local repo="$1" content="$2" msg="$3" iso="$4"
  (
    cd "$repo"
    # Base commit (parent #1)
    local base; base=$(git rev-parse HEAD)
    # Build a tree containing the modified file
    local tmpfile; tmpfile=$(mktemp)
    printf '%s' "$content" > "$tmpfile"
    local blob; blob=$(git hash-object -w "$tmpfile")
    rm -f "$tmpfile"
    local tree; tree=$(printf '100644 blob %s\tfile.txt\n' "$blob" | git mktree)
    # Build an "index" commit (parent #2) — stash requires at least i and w commits
    local i_sha
    i_sha=$(GIT_AUTHOR_DATE="$iso" GIT_COMMITTER_DATE="$iso" \
      git commit-tree "$tree" -p "$base" -m "index on stash-fixture: $msg")
    # Working-tree commit (the stash commit itself)
    GIT_AUTHOR_DATE="$iso" GIT_COMMITTER_DATE="$iso" \
      git commit-tree "$tree" -p "$base" -p "$i_sha" -m "WIP on stash-fixture: $msg"
  )
}

(
  cd "$REPO"
  git init -q -b stash-fixture
  git config user.email "smoke@test.local"
  git config user.name "smoke"
  echo "base" > file.txt
  git add file.txt
  git commit -q -m "base"
)

STALE_ISO=$(python3 -c "import datetime; print((datetime.datetime.utcnow() - datetime.timedelta(days=60)).strftime('%Y-%m-%dT%H:%M:%SZ'))")
FRESH_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

stale1_sha=$(build_stash_commit "$REPO" "stale-1 change" "stale-work-one" "$STALE_ISO")
(cd "$REPO" && git stash store -q -m "stale-work-one" "$stale1_sha")

stale2_sha=$(build_stash_commit "$REPO" "stale-2 change" "scratch: temp-investigation" "$STALE_ISO")
(cd "$REPO" && git stash store -q -m "scratch: temp-investigation" "$stale2_sha")

fresh_sha=$(build_stash_commit "$REPO" "fresh change" "fresh-wip-keep-me" "$FRESH_ISO")
(cd "$REPO" && git stash store -q -m "fresh-wip-keep-me" "$fresh_sha")

# Sanity: still 3 stashes
n=$(cd "$REPO" && git stash list | wc -l | tr -d ' ')
assert "fixture has 3 stashes" "[[ $n -eq 3 ]]"

# --- Test 1: --dry-run does not mutate ---
out=$("$SCRIPT" --dry-run --json --developer-dir "$DEVDIR" --max-age-days 30 --hard-cap-days 90 2>/dev/null)
schema=$(jq_field "$out" '.schema_version')
archived=$(jq_field "$out" '.stashes_archived')
assert "dry-run JSON well-formed" "[[ '$schema' == 'stash_archiver.v1' ]]"
# scratch: exempt; only stale-work-one is past max_age (60>30) and not exempt
assert "dry-run reports 1 would-archive (stale + non-exempt)" "[[ '$archived' == '1' ]]"
post_n=$(cd "$REPO" && git stash list | wc -l | tr -d ' ')
assert "dry-run did not mutate stashes" "[[ $post_n -eq 3 ]]"

# --- Test 2: --apply archives the stale non-exempt one, keeps fresh + exempt ---
out=$("$SCRIPT" --apply --json --developer-dir "$DEVDIR" --max-age-days 30 --hard-cap-days 90 2>/dev/null)
status=$(jq_field "$out" '.status')
archived=$(jq_field "$out" '.stashes_archived')
assert "apply status ok" "[[ '$status' == 'ok' ]]"
assert "apply archived 1" "[[ '$archived' == '1' ]]"
post_n=$(cd "$REPO" && git stash list | wc -l | tr -d ' ')
assert "stash count down to 2 after apply" "[[ $post_n -eq 2 ]]"

# Patch file exists and is non-empty
patches=("$REPO"/.flywheel/stash-archive/*.patch)
assert "archive .patch file exists" "[[ -s '${patches[0]}' ]]"

# Patch is `git apply --check` clean (restorable). Apply --check needs the patch
# to be applicable to current tree; reset to base first.
(
  cd "$REPO"
  git checkout -q -- file.txt
  git apply --check "${patches[0]}"
) && apply_ok=1 || apply_ok=0
assert "archived patch is git-apply-restorable" "[[ $apply_ok -eq 1 ]]"

# .gitignore wired
assert ".gitignore contains stash-archive entry" "grep -qxF '.flywheel/stash-archive/' '$REPO/.gitignore'"

# --- Test 3: exempt past hard_cap is archived ---
out=$("$SCRIPT" --apply --json --developer-dir "$DEVDIR" --max-age-days 30 --hard-cap-days 30 2>/dev/null)
# Now hard_cap=30, the scratch: stash at 60d crosses it
archived=$(jq_field "$out" '.stashes_archived')
assert "exempt past hard_cap archived" "[[ '$archived' == '1' ]]"
post_n=$(cd "$REPO" && git stash list | wc -l | tr -d ' ')
assert "only fresh stash remains" "[[ $post_n -eq 1 ]]"

# --- Final ---
echo ""
echo "=== smoke result: pass=$pass fail=$fail ==="
[[ $fail -eq 0 ]] || exit 1
exit 0
