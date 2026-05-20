#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/runtime-doctrine-separation-migrate.sh"
FLEET="$ROOT/.flywheel/scripts/runtime-doctrine-separation-fleet-rollout.sh"
TMP="$(mktemp -d)"
ASSERTIONS=0

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

assert_eq() {
  local got="$1" expected="$2" label="$3"
  ASSERTIONS=$((ASSERTIONS + 1))
  if [[ "$got" != "$expected" ]]; then
    printf 'ASSERTION FAILED: %s\nexpected: %s\ngot: %s\n' "$label" "$expected" "$got" >&2
    exit 1
  fi
}

assert_file() {
  local path="$1" label="$2"
  ASSERTIONS=$((ASSERTIONS + 1))
  if [[ ! -e "$path" ]]; then
    printf 'ASSERTION FAILED: %s\nmissing: %s\n' "$label" "$path" >&2
    exit 1
  fi
}

assert_symlink() {
  local path="$1" label="$2"
  ASSERTIONS=$((ASSERTIONS + 1))
  if [[ ! -L "$path" ]]; then
    printf 'ASSERTION FAILED: %s\nnot symlink: %s\n' "$label" "$path" >&2
    exit 1
  fi
}

git_init_repo() {
  local repo="$1"
  git init -q "$repo"
  git -C "$repo" config user.email "runtime-doctrine-test@example.com"
  git -C "$repo" config user.name "Runtime Doctrine Test"
  printf 'seed\n' >"$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "seed"
}

HOME="$TMP/home"
export HOME
mkdir -p "$HOME"

REPO="$TMP/repo"
git_init_repo "$REPO"
mkdir -p "$REPO/.flywheel/runtime" "$REPO/.flywheel/doctrine"
printf '{"tick":1}\n' >"$REPO/.flywheel/runtime/X.jsonl"
printf '# Doctrine\n' >"$REPO/.flywheel/doctrine/Y.md"
git -C "$REPO" add .flywheel/runtime/X.jsonl .flywheel/doctrine/Y.md
git -C "$REPO" commit -q -m "tracked flywheel state"

APPLY_OUT="$("$SCRIPT" --repo "$REPO" --apply --json)"
TARGET="$HOME/.local/state/flywheel/$(basename "$REPO")/runtime"

assert_file "$TARGET/X.jsonl" "runtime copied to local state"
assert_file "$REPO/.flywheel/doctrine/Y.md" "doctrine remains in repo"
assert_symlink "$REPO/.flywheel/runtime" "runtime replaced by symlink"
assert_eq "$(readlink "$REPO/.flywheel/runtime")" "$TARGET" "symlink target points correctly"
assert_eq "$(grep -c '^/.flywheel/runtime$' "$REPO/.gitignore")" "1" ".gitignore updated once"
assert_eq "$(git -C "$REPO" ls-files .flywheel/runtime/X.jsonl | wc -l | tr -d ' ')" "0" "cached-untrack removed runtime path"
assert_eq "$(git -C "$REPO" ls-files .flywheel/doctrine/Y.md | wc -l | tr -d ' ')" "1" "doctrine remains tracked"
assert_file "$(jq -r '.backup_path' <<<"$APPLY_OUT")" "backup tarball created"

SECOND="$("$SCRIPT" --repo "$REPO" --apply --json)"
THIRD="$("$SCRIPT" --repo "$REPO" --apply --json)"
assert_eq "$(jq -r '.runtime_migrated | length' <<<"$SECOND")" "0" "re-run already migrated produces no migration"
assert_eq "$(grep -c '^/.flywheel/runtime$' "$REPO/.gitignore")" "1" ".gitignore update idempotent"
assert_eq "$(jq -S 'del(.ts)' <<<"$SECOND")" "$(jq -S 'del(.ts)' <<<"$THIRD")" "idempotent rerun envelope stable except ts"

PRIVATE_REPO="$TMP/private-repo"
git_init_repo "$PRIVATE_REPO"
mkdir -p "$PRIVATE_REPO/.flywheel/private" "$PRIVATE_REPO/.flywheel/runtime"
printf 'secret\n' >"$PRIVATE_REPO/.flywheel/private/token.txt"
printf '{"tick":1}\n' >"$PRIVATE_REPO/.flywheel/runtime/X.jsonl"
git -C "$PRIVATE_REPO" add .flywheel/private/token.txt .flywheel/runtime/X.jsonl
git -C "$PRIVATE_REPO" commit -q -m "tracked private"
PRIVATE_OUT="$("$SCRIPT" --repo "$PRIVATE_REPO" --apply --json)"
assert_eq "$(jq -r '.outcome' <<<"$PRIVATE_OUT")" "incident" "tracked private file produces incident"
if [[ -L "$PRIVATE_REPO/.flywheel/runtime" ]]; then
  private_runtime_is_symlink=0
else
  private_runtime_is_symlink=1
fi
assert_eq "$private_runtime_is_symlink" "1" "incident refuses mutation"

MIXED_REPO="$TMP/mixed-repo"
git_init_repo "$MIXED_REPO"
mkdir -p "$MIXED_REPO/.flywheel/validation"
printf '{"snapshot":true}\n' >"$MIXED_REPO/.flywheel/validation/snapshot.json"
git -C "$MIXED_REPO" add .flywheel/validation/snapshot.json
git -C "$MIXED_REPO" commit -q -m "tracked validation"
MIXED_OUT="$("$SCRIPT" --repo "$MIXED_REPO" --dry-run --json)"
assert_eq "$(jq -r '.outcome' <<<"$MIXED_OUT")" "mixed-needs-operator" "mixed validation class surfaces operator review"
assert_eq "$(git -C "$MIXED_REPO" ls-files .flywheel/validation/snapshot.json | wc -l | tr -d ' ')" "1" "mixed class not mutated"

REPORT="$TMP/fleet-report.md"
FLEET_OUT="$("$FLEET" --dry-run --repo "$REPO" --repo "$MIXED_REPO" --report "$REPORT" --json)"
assert_file "$REPORT" "fleet dry-run report written"
assert_eq "$(jq -r '.repos | length' <<<"$FLEET_OUT")" "2" "fleet dry-run reports requested repos"

printf 'PASS runtime-doctrine-separation-smoke assertions=%s\n' "$ASSERTIONS"
