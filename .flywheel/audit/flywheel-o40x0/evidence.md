# Evidence: flywheel-o40x0 — sync-canonical post_copy_hash_mismatch false-positive

**Bead**: flywheel-o40x0 (P3) | **Task ID**: flywheel-o40x0-78a38b | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/sync-canonical-doctrine.sh`
**Sister**: flywheel-255f (closed 2026-05-10).

## Bug shape correction

The bead's hypothesis was a **race condition** (concurrent process changes source during verify). Investigation found a **hash-domain mismatch** — neither racy nor environmental.

- `SOURCE_HASH` = `sha256_file(canonicalize_source_for_hash(SOURCE))`
  → markers-stripped inner content hash (`5ea3af49…`)
- `cp $SOURCE → target` copies the **raw whole file** (with `<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->` / `<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->` markers preserved)
- `new_hash = sha256_file(target)` = raw target hash = `696248f1…`
- Comparison: `696248f1 == 5ea3af49` → FALSE → `post_copy_hash_mismatch` fires

So every marker-bearing target (`.flywheel/AGENTS-CANONICAL.md` contains both `BEGIN-CANONICAL-FLYWHEEL-DOCTRINE` and `END-CANONICAL-FLYWHEEL-DOCTRINE` markers) tripped the false-positive. 73 worktree dirs × 2 sites = 145 errors per `--apply` run.

Repro (in `mktemp -d`):

```bash
RAW=$(shasum -a 256 .flywheel/AGENTS-CANONICAL.md | awk '{print $1}')
# 696248f16a040b1c097921615715ec1ff0009e5dd4ba16a3f4f9d135b4515f39
CANON=$(sed -n '/<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->/,/<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->/p' .flywheel/AGENTS-CANONICAL.md | sed '1d;$d' | shasum -a 256 | awk '{print $1}')
# 5ea3af49f9ee509f40e06fd7f91b766486670ec8ca3a732f04b4b904b4b9fc02
# match: NO (proves the bug)
```

## Fix

Two-hash-domain split in `.flywheel/scripts/sync-canonical-doctrine.sh`:

1. **Added** `SOURCE_RAW_HASH="$(sha256_file "$SOURCE")"` at line ~819 (immediately after the existing canonicalized `SOURCE_HASH` computation), with a header comment documenting the two domains.
2. **Replaced** `"$target_hash" == "$SOURCE_HASH"` → `"$target_hash" == "$SOURCE_RAW_HASH"` at the canonical-sync in_sync detection (line 873-878).
3. **Replaced** `"$new_hash" == "$SOURCE_HASH"` → `"$new_hash" == "$SOURCE_RAW_HASH"` at the canonical-sync post-cp verify (line 891).

Left untouched: the root_block path (lines 945, 958, 960, 965) still uses canonicalized `SOURCE_HASH` because that path uses `extract_root_block` on the target before hashing, which produces marker-stripped content matching the canonicalized source hash.

## Post-fix verification

End-to-end probe scoped to `~/Developer/alpsinsurance` (sibling repo with the worktree fixtures):

```json
{
  "status": "drift_detected",
  "errors_count": 0,
  "canonical_drifted_count": 0,
  "canonical_synced_count": 0,
  "target_count": 1,
  "drifted_count": 10,
  "errors_len": 0
}
```

- **errors_count: 0** ✅ (was producing 145 `post_copy_hash_mismatch` rows pre-fix)
- **canonical_drifted_count: 0** ✅ (the canonical-sync path now correctly sees target as in_sync)
- `drifted_count: 10` is HONEST drift in OTHER categories (root AGENTS.md block, schema, doctrine docs, etc.) — not the false positive that this bead is about

## Acceptance gates

- ✅ **AG1** (investigate post_copy_hash_mismatch source: race vs canonicalization): canonicalization mismatch confirmed, NOT race
- ✅ **AG2** (tighten post-copy hash logic): two-hash-domain split applied; raw cp+verify uses `SOURCE_RAW_HASH`, root_block uses canonicalized `SOURCE_HASH`
- ✅ **AG3** (add status=warn when only worktree targets fail): **made unnecessary by root-cause fix**. AG3 was a workaround for the symptom; the false-positive errors no longer fire, so the warn-vs-error distinction has nothing to gate on. Meadows-principle (#5): fix the root cause, not the proxy.

## Regression test

New test: `tests/sync-canonical-post-copy-hash-fix.sh` (5 assertions):

1. Script defines `SOURCE_RAW_HASH` (the fix is present)
2. in_sync detection uses raw hash (`$target_hash == $SOURCE_RAW_HASH`)
3. post-cp verify uses raw hash (`$new_hash == $SOURCE_RAW_HASH`)
4. root_block check still uses canonicalized `SOURCE_HASH` (no regression on the other path)
5. End-to-end: scoped `--check` against alpsinsurance produces `errors_count=0` + `canonical_drifted_count=0`

**5/5 PASS** including the end-to-end probe.

Existing test suites also pass:
- `tests/sync-canonical-doctrine-introspection.sh` → 9/9 PASS
- `tests/sync-canonical-doctrine-idempotency-key.sh` → 7/7 PASS (verified through PASS AG7)

## Files changed

- `.flywheel/scripts/sync-canonical-doctrine.sh` (+13 lines added: 1 SOURCE_RAW_HASH line + 6 documentation comment lines + 3 comparison-line edits + 3 inline comment lines)
- `tests/sync-canonical-post-copy-hash-fix.sh` (NEW: 5-assertion regression test)

## L112 verify probe

`bash tests/sync-canonical-post-copy-hash-fix.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=5 fail=0`
