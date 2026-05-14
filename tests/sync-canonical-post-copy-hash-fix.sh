#!/usr/bin/env bash
# Regression test for flywheel-o40x0:
# post_copy_hash_mismatch false-positive when SOURCE has BEGIN/END canonical
# markers and target is bit-for-bit identical to source.
#
# Before fix: SOURCE_HASH was the markers-stripped (canonicalized) sha256;
# raw post-cp target sha256 never matched it, triggering false-positive
# errors for every marker-bearing target. Fix: maintain SOURCE_RAW_HASH for
# raw-file cp+verify path, leaving SOURCE_HASH for the root_block extract
# path that genuinely needs canonicalization.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-post-copy-hash-fix.XXXXXX")"
trap 'find "$TMP" -depth -type f -exec rm -f {} \; 2>/dev/null; find "$TMP" -depth -type d -exec rmdir {} \; 2>/dev/null' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: script defines SOURCE_RAW_HASH alongside SOURCE_HASH (literal-string
# check; tests/pane-capture-provenance.sh pattern).
if grep -q '^SOURCE_RAW_HASH=' "$SCRIPT"; then
  pass "script defines SOURCE_RAW_HASH (raw whole-file hash for cp+verify path)"
else
  fail "SOURCE_RAW_HASH not defined; the o40x0 fix is missing"
fi

# Test 2: canonical-sync in_sync check uses SOURCE_RAW_HASH (raw vs raw).
if grep -q '\$target_hash" == "\$SOURCE_RAW_HASH' "$SCRIPT"; then
  pass "in_sync detection compares raw target hash against SOURCE_RAW_HASH"
else
  fail "in_sync still compares against canonicalized SOURCE_HASH (false-positive bug)"
fi

# Test 3: canonical-sync post-cp verify uses SOURCE_RAW_HASH.
if grep -q '\$new_hash" == "\$SOURCE_RAW_HASH' "$SCRIPT"; then
  pass "post-cp verify compares raw target hash against SOURCE_RAW_HASH"
else
  fail "post-cp verify still compares against canonicalized SOURCE_HASH (post_copy_hash_mismatch false positive)"
fi

# Test 4: root_block path still uses SOURCE_HASH (the canonicalized hash) so
# the root_block_post_write_mismatch contract is preserved.
if grep -q 'block_hash" == "\$SOURCE_HASH' "$SCRIPT"; then
  pass "root_block check still uses canonicalized SOURCE_HASH (extract_root_block path preserved)"
else
  fail "root_block check lost SOURCE_HASH reference; canonicalization-aware path broken"
fi

# Test 5: end-to-end: scoped --check against a sibling repo with worktree-style
# targets produces canonical_drifted_count=0 + errors_count=0 (was 145 errors
# pre-fix). Use {session} if present; otherwise skip with reason.
ALPS=$HOME/Developer/{session}
if [[ -d "$ALPS/.flywheel" ]]; then
  out="$TMP/check-receipt.json"
  if timeout 90 "$SCRIPT" --check --json --root "$ALPS" >"$out" 2>"$TMP/check.err"; then
    :
  fi
  if jq -e '.errors_count == 0 and .canonical_drifted_count == 0' "$out" >/dev/null 2>&1; then
    pass "end-to-end: scoped --check against {session} reports 0 canonical errors + 0 canonical_drifted (was 145 errors pre-fix)"
  else
    canonical_errors="$(jq -r '[.errors[] | select(.code == "post_copy_hash_mismatch")] | length' "$out" 2>/dev/null || echo "?")"
    fail "end-to-end check still reports canonical errors (post_copy_hash_mismatch count=$canonical_errors)"
    head -c 400 "$out" >&2
  fi
else
  pass "end-to-end: {session} fixture not present locally — skipping live probe (test 5 is skipped, not failed)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
