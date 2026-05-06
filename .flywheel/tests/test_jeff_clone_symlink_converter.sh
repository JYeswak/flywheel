#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-clone-symlink-converter.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-clone-converter-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

ROOT_BASE="$TMP/root"
CORPUS_BASE="$TMP/root/jeff-corpus"
BACKUPS="$TMP/backups"
pass_count=0
mkdir -p "$ROOT_BASE" "$CORPUS_BASE" "$BACKUPS"

pass() { pass_count=$((pass_count + 1)); printf 'ok %02d - %s\n' "$pass_count" "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

tree_hash() {
  (cd "$1" && find . -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done) | shasum -a 256 | awk '{print $1}'
}

git_config() {
  git -C "$1" config user.email fixture@example.test
  git -C "$1" config user.name "Fixture"
}

commit_file() {
  local repo="$1" file="$2" text="$3" msg="$4"
  printf '%s\n' "$text" >"$repo/$file"
  git -C "$repo" add "$file"
  GIT_AUTHOR_DATE=2026-01-01T00:00:00Z GIT_COMMITTER_DATE=2026-01-01T00:00:00Z \
    git -C "$repo" commit -q -m "$msg"
}

make_pair() {
  local name="$1" root corpus origin
  root="$ROOT_BASE/$name"
  corpus="$CORPUS_BASE/$name"
  origin="https://example.test/$name.git"
  mkdir -p "$root"
  git -C "$root" init -q
  git_config "$root"
  commit_file "$root" README.md "$name" "init $name"
  git -C "$root" remote add origin "$origin"
  git clone -q "$root" "$corpus"
  git_config "$corpus"
  git -C "$corpus" remote set-url origin "$origin"
}

run_converter() {
  local name="$1" mode="$2" out="$3"; shift 3
  JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" \
    bash "$SCRIPT" --pair "$name" --mode "$mode" --backup-dir "$BACKUPS" --json "$@" >"$out"
}

expect_rc() {
  local expected="$1" label="$2"; shift 2
  local out="$TMP/$label.out" err="$TMP/$label.err" rc
  set +e
  "$@" >"$out" 2>"$err"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected" ]] || fail "$label rc=$rc expected=$expected stderr=$(cat "$err") stdout=$(cat "$out")"
  printf '%s\n' "$out"
}

command -v jq >/dev/null 2>&1 || fail "missing jq"
[[ -x "$SCRIPT" ]] || fail "script not executable"
bash "$SCRIPT" --info | jq -e '.schema_version == "jeff-clone-symlink-receipt/v1"' >/dev/null
pass "info emits schema"

make_pair dryrun
run_converter dryrun dry-run "$TMP/dryrun.json"
jq -e '.status == "dry_run" and .would_convert == true and .canonical_side == "corpus"' "$TMP/dryrun.json" >/dev/null
[[ -d "$ROOT_BASE/dryrun" && ! -L "$ROOT_BASE/dryrun" ]]
pass "same-origin tied dry-run prints plan"

make_pair applyok
before_hash="$(tree_hash "$ROOT_BASE/applyok")"
run_converter applyok apply "$TMP/applyok.json"
jq -e '.status == "applied" and .post_state.symlink == true and (.byte_counts.archive_member_bytes >= .byte_counts.original_file_bytes)' "$TMP/applyok.json" >/dev/null
[[ -L "$ROOT_BASE/applyok" && -f "$(jq -r '.backup_path' "$TMP/applyok.json")" && -f "$(jq -r '.receipt_path' "$TMP/applyok.json")" ]]
pass "same-origin tied apply succeeds"

rm "$ROOT_BASE/applyok"
tar -xzf "$(jq -r '.backup_path' "$TMP/applyok.json")" -C "$ROOT_BASE"
[[ "$(tree_hash "$ROOT_BASE/applyok")" == "$before_hash" ]]
JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" \
  bash "$SCRIPT" --pair applyok --mode apply --backup-dir "$TMP/reapply" --json >"$TMP/reapply.json"
[[ -L "$ROOT_BASE/applyok" ]]
pass "backup restore matches original tree and reapplies symlink"

make_pair diverged
commit_file "$CORPUS_BASE/diverged" EXTRA.md corpus-new "corpus diverges"
out="$(expect_rc 2 diverged env JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" bash "$SCRIPT" --pair diverged --mode dry-run --backup-dir "$BACKUPS" --json)"
jq -e '.status == "safety_check_failed" and .reason == "commit_mismatch"' "$out" >/dev/null
pass "diverged commits refuse exit 2"

make_pair origins
git -C "$CORPUS_BASE/origins" remote set-url origin https://example.test/other.git
out="$(expect_rc 2 origins env JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" bash "$SCRIPT" --pair origins --mode dry-run --backup-dir "$BACKUPS" --json)"
jq -e '.reason == "origin_mismatch"' "$out" >/dev/null
pass "different origins refuse exit 2"

make_pair dirty
printf 'scratch\n' >"$ROOT_BASE/dirty/scratch.txt"
out="$(expect_rc 2 dirty env JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" bash "$SCRIPT" --pair dirty --mode dry-run --backup-dir "$BACKUPS" --json)"
jq -e '.reason == "root_dirty"' "$out" >/dev/null
pass "dirty working tree refuses exit 2"

make_pair mismatch
out="$(expect_rc 1 mismatch env JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" JEFF_CLONE_FORCE_BYTE_MISMATCH=1 bash "$SCRIPT" --pair mismatch --mode apply --backup-dir "$BACKUPS" --json)"
jq -e '.status == "verify_failed" and .reason == "backup_byte_count_mismatch"' "$out" >/dev/null
[[ -d "$ROOT_BASE/mismatch" && ! -L "$ROOT_BASE/mismatch" ]]
pass "backup byte-count mismatch refuses exit 1"

make_pair symlinked
mv "$ROOT_BASE/symlinked" "$ROOT_BASE/symlinked.real"
ln -s "$CORPUS_BASE/symlinked" "$ROOT_BASE/symlinked"
out="$(expect_rc 2 symlinked env JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" bash "$SCRIPT" --pair symlinked --mode dry-run --backup-dir "$BACKUPS" --json)"
jq -e '.reason == "noncanonical_already_symlink"' "$out" >/dev/null
pass "symlink already exists refuses exit 2"

make_pair rootcanon
JEFF_CLONE_ROOT_BASE="$ROOT_BASE" JEFF_CLONE_CORPUS_BASE="$CORPUS_BASE" \
  bash "$SCRIPT" --pair rootcanon --canonical-side root --mode apply --backup-dir "$BACKUPS" --json >"$TMP/rootcanon.json"
jq -e '.status == "applied" and .canonical_side == "root"' "$TMP/rootcanon.json" >/dev/null
[[ -L "$CORPUS_BASE/rootcanon" ]]
pass "canonical-side root converts corpus side"

out="$(expect_rc 3 invalid bash "$SCRIPT" --mode dry-run --json)"
jq -e '.status == "invalid_args"' "$out" >/dev/null
pass "invalid args exit 3"

[[ "$pass_count" -ge 10 ]] || fail "expected at least 10 cases"
printf 'PASS: %d jeff-clone symlink converter cases\n' "$pass_count"
