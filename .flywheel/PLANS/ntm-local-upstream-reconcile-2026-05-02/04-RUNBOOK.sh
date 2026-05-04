#!/usr/bin/env bash
set -euo pipefail

# 2026-05-02 pre-flight review:
# - Classified all 63 local ntm commits in /tmp/ntm_runbook_63commit_review.md.
# - Keep 43/63 patch-unique commits: 8 bead-isolation, 33 productivity, 2 doctrine.
# - Drop 20/63 upstream-equivalent commits reported by git cherry -v origin/main HEAD.
# - NEEDS_JOSHUA=0; no scratch commits found.
# - Reasoning: preserve all patch-unique local safety/productivity/doctrine work while
#   avoiding duplicate replay of patches already present upstream.
REPO="/Users/josh/Developer/ntm"
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/ntm-reconcile-${TS}.log"
LOCAL_COMMITS=(
  95ed40e0 4a1353b8 f5ad8c56 4d04c339 3a4ffda8
  3422ab35 f5668396 05f9c763 b5504bc5 e302a821
  d888a417 0a81d94a 6ae17b28 d9c12b67 0d2fcfd3
  c23c9a86 0b32c183 9222ea4d 122a9c49 23a003d9
  a8de5db1 72a7ff25 01ffb0b8 5ae1a03c b8f9c3e7
  de4bd4d4 32a53103 8c5c92eb 41b8f6d1 6f4236da
  dd686a1b be51e676 0ba468ba a807747d 87a334a0
  687fd5f8 a3929486 e390b464 ccb68356 f199a69f
  98ec9aa4 8ac8bfee 5bbcaf7c
)
BIN="/tmp/ntm-reconcile-${TS}"
BACKUP_BRANCH="backup/pre-reconcile-main-${TS}"
VENDOR_BRANCH="vendor/upstream-main-${TS}"
LOCAL_BRANCH="local/bead-isolation-reconciled-${TS}"

exec > >(tee -a "$LOG") 2>&1

confirm() {
  local prompt="$1"
  read -r -p "Confirm: ${prompt} (y/N) " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

phase() {
  echo
  echo "===== $* ====="
}

rollback_hint() {
  cat <<EOF

Rollback hints:
  cd "$REPO"
  git cherry-pick --abort 2>/dev/null || true
  git switch "$BACKUP_BRANCH"
  install -m 755 "/tmp/ntm-installed-before-reconcile-${TS}" "$HOME/.local/bin/ntm" 2>/dev/null || true
  git stash list | head

Log: $LOG
EOF
}

trap rollback_hint ERR

phase "Preflight"
cd "$REPO"
[[ "$(git rev-parse --show-toplevel)" == "$REPO" ]] || die "Not in $REPO"
git status --short --untracked-files=all
git branch -vv
echo "HEAD=$(git rev-parse HEAD)"
echo "origin/main=$(git rev-parse origin/main)"
echo "merge-base=$(git merge-base HEAD origin/main)"
echo "ahead behind:"
git rev-list --left-right --count HEAD...origin/main

confirm "create backup bundle/diffs/untracked archive before any branch work" || die "cancelled"
git bundle create "/tmp/ntm-pre-reconcile-${TS}.bundle" --all
git diff > "/tmp/ntm-pre-reconcile-${TS}.tracked.diff"
git diff --cached > "/tmp/ntm-pre-reconcile-${TS}.staged.diff"
git ls-files --others --exclude-standard > "/tmp/ntm-pre-reconcile-${TS}.untracked.txt"
if [[ -s "/tmp/ntm-pre-reconcile-${TS}.untracked.txt" ]]; then
  tar -czf "/tmp/ntm-pre-reconcile-${TS}.untracked.tgz" -T "/tmp/ntm-pre-reconcile-${TS}.untracked.txt"
else
  : > "/tmp/ntm-pre-reconcile-${TS}.untracked.tgz"
fi

phase "Preserve current branch"
confirm "create $BACKUP_BRANCH at current HEAD" || die "cancelled"
git branch "$BACKUP_BRANCH" HEAD
git show --oneline -1 "$BACKUP_BRANCH"

phase "Stash dirty work"
if [[ -n "$(git status --porcelain)" ]]; then
  confirm "stash tracked and untracked work after archives were written" || die "cancelled"
  git stash push -u -m "pre-ntm-reconcile-${TS}"
else
  echo "Working tree already clean."
fi

phase "Fetch upstream"
confirm "fetch origin --prune" || die "cancelled"
git fetch origin --prune
git log --oneline -5 origin/main

phase "Create vendor branch"
confirm "create $VENDOR_BRANCH from origin/main" || die "cancelled"
git switch -c "$VENDOR_BRANCH" origin/main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "vendor branch is not origin/main"

phase "Create local overlay branch"
confirm "create $LOCAL_BRANCH from vendor branch" || die "cancelled"
git switch -c "$LOCAL_BRANCH"

phase "Confirm local overlay commit list"
echo "Review required before cherry-pick: /tmp/ntm_runbook_63commit_review.md"
echo "Kept commits: ${#LOCAL_COMMITS[@]} / 63"
echo "Dropped upstream duplicates: 20 / 63"
confirm "cherry-pick ${#LOCAL_COMMITS[@]} commits — review at /tmp/ntm_runbook_63commit_review.md first" || die "cancelled"

phase "Cherry-pick local overlay commits"
for c in "${LOCAL_COMMITS[@]}"; do
  confirm "cherry-pick $c onto $LOCAL_BRANCH" || die "cancelled"
  git cherry-pick -x "$c" || {
    echo "Conflict during $c."
    echo "Resolve manually, then run: git cherry-pick --continue"
    echo "Or abort with: git cherry-pick --abort && git switch $BACKUP_BRANCH"
    exit 2
  }
done

phase "Verify local invariants"
grep -R "BEADS_STRICT_LOCAL=1" -n internal/bv
if grep -R "func RunBrReal" -n internal/bv; then
  die "RunBrReal still present"
fi
grep -R "SourceRepo" -n internal/bv internal/cli/spawn.go internal/cli/spawn_recovery_test.go
grep -R "working_dir" -n internal/state internal/checkpoint

phase "Build candidate"
VERSION="$(git describe --tags --always --dirty 2>/dev/null || echo dev)"
COMMIT="$(git rev-parse --short HEAD)"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
go build -trimpath -ldflags "-s -w -X github.com/Dicklesworthstone/ntm/internal/cli.Version=${VERSION} -X github.com/Dicklesworthstone/ntm/internal/cli.Commit=${COMMIT} -X github.com/Dicklesworthstone/ntm/internal/cli.Date=${DATE} -X github.com/Dicklesworthstone/ntm/internal/cli.BuiltBy=manual-reconcile" -o "$BIN" ./cmd/ntm
"$BIN" version || true

phase "Test focused packages"
go test ./internal/bv ./internal/checkpoint ./internal/state ./internal/cli -count=1

phase "Config validation smoke"
if command -v jq >/dev/null 2>&1; then
  "$BIN" config validate --json | tee "/tmp/ntm-reconcile-${TS}.config-validate.json" | jq '.valid'
else
  "$BIN" config validate --json | tee "/tmp/ntm-reconcile-${TS}.config-validate.json"
fi

phase "Install candidate binary"
confirm "install candidate to ~/.local/bin/ntm after successful gates" || die "cancelled before install"
if [[ -x "$HOME/.local/bin/ntm" ]]; then
  cp "$HOME/.local/bin/ntm" "/tmp/ntm-installed-before-reconcile-${TS}"
fi
install -m 755 "$BIN" "$HOME/.local/bin/ntm"
"$HOME/.local/bin/ntm" version || true

phase "Optional Model B main normalization"
echo "Current daily branch is $LOCAL_BRANCH."
echo "Optional: preserve old main under local/pre-reconcile-main-${TS} and recreate main from origin/main."
if confirm "perform optional main normalization now"; then
  git switch "$LOCAL_BRANCH"
  git branch -m main "local/pre-reconcile-main-${TS}"
  git switch -c main origin/main
  git switch "$LOCAL_BRANCH"
fi

phase "Done"
echo "Reconcile candidate complete."
echo "Branch: $LOCAL_BRANCH"
echo "Bundle: /tmp/ntm-pre-reconcile-${TS}.bundle"
echo "Log: $LOG"
