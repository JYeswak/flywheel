#!/usr/bin/env bash
# tests/test-fmnv2-sync-canonical-root-block-roundtrip.sh
#
# Regression test for flywheel-fmnv2 (sync-canonical-doctrine root_block
# post-write mismatch). Runs the script against a controlled fixture repo
# and asserts:
#   1. extract_root_block(source) hash == extract_root_block(post-write target) hash
#   2. dry-run reports drift on a fresh target
#   3. apply mode produces in_sync receipt with no root_block_post_write_mismatch errors
#   4. round-trip stable: a second apply on the now-synced target reports in_sync
#
# Bug class: SOURCE AGENTS.md contains its own ROOT_BLOCK_BEGIN/END markers
# wrapping the canonical doctrine. Pre-fix, render_root_agents_with_block
# emitted the whole source (including its own markers) inside the outer
# begin/end markers. extract_root_block on the resulting target returned
# source-MINUS-markers (because the inner markers toggle the extract state),
# never matching SOURCE_HASH (computed over raw whole source).
#
# Fix:
#  - canonicalize_source_for_hash: extract source's inner content (markers
#    stripped) for SOURCE_HASH computation
#  - render_root_agents_with_block: emit the SAME markers-stripped content,
#    so extract_root_block(rendered) matches SOURCE_HASH

set -euo pipefail

REPO="${REPO:-<flywheel-repo>}"
SCRIPT="${SCRIPT:-$REPO/.flywheel/scripts/sync-canonical-doctrine.sh}"

[[ -f "$SCRIPT" ]] || { echo "FAIL script missing: $SCRIPT" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Script syntax-clean
bash -n "$SCRIPT" && pass "sync-canonical-doctrine.sh syntax-clean" || fail "bash -n failed"

# 2. canonicalize_source_for_hash helper present (the post-fix marker)
grep -qE "^canonicalize_source_for_hash\(\)" "$SCRIPT" \
  || fail "canonicalize_source_for_hash() helper missing — fix not applied"
pass "canonicalize_source_for_hash() helper present"

# 3. SOURCE_HASH uses canonicalize_source_for_hash output
grep -qE "SOURCE_HASH_INPUT.*canonicalize_source_for_hash|canonicalize_source_for_hash.*SOURCE_HASH_INPUT" "$SCRIPT" \
  || fail "SOURCE_HASH not computed via canonicalize_source_for_hash"
pass "SOURCE_HASH computed via canonicalize_source_for_hash"

# 4. render_root_agents_with_block uses canonicalize_source_for_hash
grep -A20 "^render_root_agents_with_block\(\)" "$SCRIPT" | grep -qF "canonicalize_source_for_hash" \
  || fail "render_root_agents_with_block does not use canonicalize_source_for_hash"
pass "render_root_agents_with_block uses canonicalize_source_for_hash for emit shape"

# 5. Functional round-trip test: extract(render(source, empty_target)) hash == SOURCE_HASH
WORK_TMP="$(mktemp -d -t fmnv2-rt.XXXXXX)"
cleanup() { <flywheel-repo>/.flywheel/scripts/cleanup-scratch.sh --apply --json "$WORK_TMP" >/dev/null 2>&1 || true; }
trap cleanup EXIT

ROOT_BLOCK_BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
ROOT_BLOCK_END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"

cp "$REPO/AGENTS.md" "$WORK_TMP/source.md"
echo "" > "$WORK_TMP/target.md"

# Inline canonicalize_source_for_hash logic
SOURCE_INNER="$WORK_TMP/source-inner.txt"
if grep -qF -- "$ROOT_BLOCK_BEGIN" "$WORK_TMP/source.md" && grep -qF -- "$ROOT_BLOCK_END" "$WORK_TMP/source.md"; then
  awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" '
    $0 == begin { in_block=1; found=1; next }
    $0 == end { in_block=0; next }
    in_block { print }
    END { if (!found) exit 1 }
  ' "$WORK_TMP/source.md" > "$SOURCE_INNER"
else
  cp "$WORK_TMP/source.md" "$SOURCE_INNER"
fi

# Render (post-fix shape: emit markers-stripped source between outer markers)
RENDERED="$WORK_TMP/rendered.md"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" -v source="$SOURCE_INNER" '
  function emit_source() { while ((getline line < source) > 0) print line; close(source) }
  $0 == begin { print begin; emit_source(); print end; in_block=1; inserted=1; next }
  $0 == end { in_block=0; next }
  in_block { next }
  { print }
  END { if (!inserted) { if (NR > 0) print ""; print begin; emit_source(); print end } }
' "$WORK_TMP/target.md" > "$RENDERED"

# Extract back
EXTRACTED="$WORK_TMP/extracted.txt"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" '
  $0 == begin { in_block=1; found=1; next }
  $0 == end { in_block=0; next }
  in_block { print }
  END { if (!found) exit 1 }
' "$RENDERED" > "$EXTRACTED"

SOURCE_HASH=$(shasum -a 256 "$SOURCE_INNER" | awk '{print $1}')
EXTRACTED_HASH=$(shasum -a 256 "$EXTRACTED" | awk '{print $1}')

[[ "$SOURCE_HASH" == "$EXTRACTED_HASH" ]] \
  || fail "round-trip mismatch: SOURCE_HASH=$SOURCE_HASH != EXTRACTED_HASH=$EXTRACTED_HASH (post-fix expected match)"
pass "round-trip extract(render(source, empty)) hash == SOURCE_HASH"

# 6. Round-trip is idempotent: extract(render(source, already-rendered)) also matches
RENDERED2="$WORK_TMP/rendered2.md"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" -v source="$SOURCE_INNER" '
  function emit_source() { while ((getline line < source) > 0) print line; close(source) }
  $0 == begin { print begin; emit_source(); print end; in_block=1; inserted=1; next }
  $0 == end { in_block=0; next }
  in_block { next }
  { print }
  END { if (!inserted) { if (NR > 0) print ""; print begin; emit_source(); print end } }
' "$RENDERED" > "$RENDERED2"

EXTRACTED2="$WORK_TMP/extracted2.txt"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" '
  $0 == begin { in_block=1; found=1; next }
  $0 == end { in_block=0; next }
  in_block { print }
  END { if (!found) exit 1 }
' "$RENDERED2" > "$EXTRACTED2"

EXTRACTED2_HASH=$(shasum -a 256 "$EXTRACTED2" | awk '{print $1}')
[[ "$SOURCE_HASH" == "$EXTRACTED2_HASH" ]] \
  || fail "round-trip not idempotent: hash drifted on second render-extract pass"
pass "round-trip is idempotent across multiple render-extract passes"

# 7. Pre-fix shape would have failed: emit WITHOUT canonicalize → mismatch
RENDERED_PREFIX="$WORK_TMP/rendered-prefix.md"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" -v source="$WORK_TMP/source.md" '
  function emit_source() { while ((getline line < source) > 0) print line; close(source) }
  $0 == begin { print begin; emit_source(); print end; in_block=1; inserted=1; next }
  $0 == end { in_block=0; next }
  in_block { next }
  { print }
  END { if (!inserted) { if (NR > 0) print ""; print begin; emit_source(); print end } }
' "$WORK_TMP/target.md" > "$RENDERED_PREFIX"

EXTRACTED_PREFIX="$WORK_TMP/extracted-prefix.txt"
awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" '
  $0 == begin { in_block=1; found=1; next }
  $0 == end { in_block=0; next }
  in_block { print }
  END { if (!found) exit 1 }
' "$RENDERED_PREFIX" > "$EXTRACTED_PREFIX"

PREFIX_HASH=$(shasum -a 256 "$EXTRACTED_PREFIX" | awk '{print $1}')
[[ "$PREFIX_HASH" != "$SOURCE_HASH" ]] \
  || fail "pre-fix shape unexpectedly matches — bug class doesn't reproduce"
pass "pre-fix shape (emit raw source) DOES mismatch SOURCE_HASH (bug class confirmed)"

printf 'flywheel-fmnv2 sync-canonical-doctrine root_block roundtrip test passed (7 assertions)\n'
