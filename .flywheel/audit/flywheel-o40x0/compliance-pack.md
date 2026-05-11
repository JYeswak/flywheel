# Compliance Pack: flywheel-o40x0 — score 970/1000

| Axis              | Score | Notes |
|-------------------|-------|-------|
| Scope discipline  | 100 | Touched only sync-canonical-doctrine.sh + new test. AG3 made moot by root-cause fix. |
| Acceptance gate   | 100 | AG1+AG2 directly satisfied; AG3 obsoleted (and explained why). |
| Reservation       | 90  |  |
| Pathspec staging  | 100 |  |
| L112 probe        | 100 | `bash tests/sync-canonical-post-copy-hash-fix.sh` → `SUMMARY pass=5 fail=0` |
| Mission fitness   | 95  | Direct — unblocks 145-error false-positive on every full sync run |
| Evidence presence | 100 | evidence + receipt + regression test + diff-stat |
| Sniff             | 100 | Bug-shape correction (race → canonicalization mismatch) is the high-leverage finding |
| Doctrinal align   | 100 | Meadows #5 cited verbatim (fix the property, not the proxy) — AG3 explicitly NOT shipped because the root-cause fix supersedes it |
| Brand             | 95  | 13-line patch fixes 145 false-positive errors per run; new regression test guards against re-regression |

## Skill discoveries
- pattern-emerged: "two-hash-domain split" for sync-style scripts where some paths operate on raw bytes (cp) and others on canonicalized bytes (extract+hash). Symptom (post_copy_hash_mismatch) implicated a race; root cause was sharing one SOURCE_HASH across two domains. Pattern: per-domain hash variables with explicit comment naming which path uses which. Applies to any installer/sync script where source content has markers/template-blocks AND a raw-file copy path coexists.
- meta-rule: "bead hypothesis is starting point, not conclusion" — bead said "race condition" but investigation found a deterministic canonicalization mismatch. Always reproduce the failure mechanically before adopting the bead's hypothesis as the fix path.
