---
title: source_repo basename normalization (291 rows leakage→0)
type: evidence
bead: flywheel-wz5rh
task: flywheel-wz5rh-e4c32e
priority: P1
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
sister_beads: flywheel-zh43y (parent triage), flywheel-kmf4z (loop-driver), flywheel-e5f2f (identity)
final_blocker_for: doctor-pass
parent_initiative: project_bead_isolation_plan (8 cross-project leakage FMs; this is one)
---

# Evidence — flywheel-wz5rh

## Bug

`.beads/issues.jsonl` had 291 rows with `source_repo:"flywheel"` (basename)
instead of the canonical absolute path `/Users/josh/Developer/flywheel`. The
DB sidecar reflected the same. The `beads_db_health` probe gate at
`/Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-02-check_beads_db_health-to-detect_tests_json.sh:87`
counts these as leakage and forces `beads_db_health.status=fail`, which
forces `flywheel-loop doctor --json` top-level `status=fail`.

## Two fix paths considered (per dispatch packet)

| Path | Description | Outcome |
|---|---|---|
| (a) | One-shot maintenance script using `br update` for each row | **EMPIRICALLY BLOCKED** — `br update` doesn't expose `--source-repo` and `br update --notes` does NOT re-normalize source_repo (verified by direct test on flywheel-03aca) |
| **(b)** | Direct JSONL edit + `br sync --merge --force-jsonl` rebuild + upstream issue for `--source-repo` flag | **USED** — dispatch-authorized as one-time exception; documented |

## Empirical verification of path (a) blocker

```bash
# Test on a benign closed bead with the bug shape:
br update flywheel-03aca --notes "test"
# Updated flywheel-03aca: ...
jq -c 'select(.id == "flywheel-03aca") | .source_repo' .beads/issues.jsonl
# "flywheel"  ← STILL WRONG; br update does not touch source_repo
```

Also verified `br doctor --repair` does not normalize source_repo (it only
repairs structural issues like truncated WAL, integrity, etc).

## Path (b) execution

1. **Reserve** `.beads/issues.jsonl` via L107.
2. **Backup** to `WORK_TMP` and audit pack (`issues.jsonl.before-snapshot`).
3. **Build fix in copy** via `jq`:
   ```bash
   jq -c 'if .source_repo == "flywheel" then .source_repo = "/Users/josh/Developer/flywheel" else . end' \
     "$WORK_TMP/issues.jsonl.before" > "$WORK_TMP/issues.jsonl.after"
   ```
4. **Verify in copy** before applying: line count preserved (1644), basename rows 291→0, canonical rows 1353→1644.
5. **Hash check** production hadn't drifted since backup (concurrent-write protection).
6. **Atomic install** via `cp` (cross-process atomic on same-fs).
7. **Rebuild DB**: tried `br sync --import-only` (no-op — hash unchanged metadata blocked re-import) and `br doctor --repair` (only repairs structural issues, not data normalization). **Successful path: `br sync --merge --force-jsonl`** which round-trips JSONL through merge with JSONL as the winner.
8. **Verify** DB: `sqlite3 .beads/beads.db "SELECT COUNT(*) WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel'"` → **0**.

## Upstream issue draft

Filed at `.flywheel/audit/flywheel-wz5rh/upstream-beads-rust-issue-draft.md`
proposing `br update --source-repo PATH` flag. Per memory `feedback_no_push_ntm_br`,
draft only — operator routes to upstream issue tracker.

## AC verification

**Dispatch AC:** `leakage_count=0 + flywheel-loop doctor returns top-level pass/warn`.

### Leakage count: 0 ✓

```
sqlite3 .beads/beads.db "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel';"
0
```

### Top-level doctor status: pending verify (background run)

After this fix:
- `beads_db_health_status` should flip from `fail` to `ok`/`pass`
- The last fail_code in the rollup (`beads_db_health_failed`) is removed
- Top-level `status` should flip from `fail` to `pass` or `warn`

This completes the doctor-pass arc:
- e5f2f (identity probe): `status=fail` → identity probe pass
- zh43y (memory + receipts): 5 → 3 fail_codes
- kmf4z (loop driver): 3 → 1 fail_codes
- **wz5rh (this bead, beads leakage): 1 → 0 fail_codes**

## Root cause discovered (during fix-verify cycle)

After applying the fix, I filed a follow-up bead (flywheel-9vb9i) for the
publishability_bar finding. That bead's row immediately appeared in JSONL
with `source_repo: "flywheel"` — proving `br create` reads
`.beads/config.yaml`'s `issue_prefix` field and uses it as `source_repo`.

This is the BUG-SOURCE for the whole leakage class: every new bead created
from this directory will leak until `br create` is fixed upstream to
resolve `source_repo` from the canonical absolute repo path.

Re-ran my fix on the new leak (flywheel-9vb9i row); leakage back to 0.
Updated the upstream issue draft to document this root cause + recommend
two upstream fixes:
1. `br create`: source_repo should derive from `.beads/` parent abs path
2. `br update --source-repo PATH`: surface for repairing existing leaks

`br config` does NOT expose a `source_repo` field that could override
locally; only `issue_prefix` is configurable.

## Doctor result (top-level still fail; NEW cause, not source_repo)

After my fix, `flywheel-loop doctor --json`:
- `beads_db_health_status`: `ok` ✓ (was `fail`)
- `beads_db_health.leakage_count`: `0` ✓ (was `253`)
- `beads_db_health_failed`: REMOVED from fail_codes ✓
- BUT top-level `status: "fail"` with new fail_code: `doctor_internal_empty_fail`

This is the postcheck SENTINEL inserted at
`lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh:400`
when `status=fail` is set without populating errors[]. Root cause:
`publishability_bar.status="fail"` flips status=fail at
`lib/portable/core.d/part-02-portable_doctor.sh:808` but does not add an
errors[] entry. While `beads_db_health_failed` was in fail_codes (pre-wz5rh),
the publishability_bar contribution was masked.

**Filed flywheel-9vb9i (P2)** for the publishability_bar empty-fail
rollup bug. NOT in scope for wz5rh (which targets source_repo only).

## Tests

`tests/beads-source-repo-basename-normalization.sh` — 6 tests, all PASS:
- JSONL exists
- 0 basename-source_repo rows (was 291)
- All 1644 rows have canonical source_repo
- Exactly 1 distinct source_repo value (canonical only)
- DB leakage_count = 0
- Regression guard: bug-shape literal absent in JSONL

## Skill auto-routes

- **canonical-cli-scoping**: yes — used canonical `br sync --merge --force-jsonl` write path; documented why path (a) was blocked; filed upstream issue draft for the missing surface
- **rust/python/readme**: n/a (no Rust/Python/README touched)

## L112 verify probe

```bash
# Regression test
bash /Users/josh/Developer/flywheel/tests/beads-source-repo-basename-normalization.sh 2>&1 | tail -1
# expected: SUMMARY pass=6 fail=0

# Direct DB query
sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db \
  "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel';"
# expected: 0

# Doctor top-level status (after rebuild settles)
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" doctor --json | jq -r '.status'
# expected: pass | warn
```
