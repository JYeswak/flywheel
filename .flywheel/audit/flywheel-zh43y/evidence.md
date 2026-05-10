---
title: doctor non-identity failures triage + 2-of-5 fix
type: evidence
bead: flywheel-zh43y
task: flywheel-zh43y-4eb3a7
priority: P1
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
sister_bead: flywheel-e5f2f (identity-probe-only fix, just shipped 950)
---

# Evidence — flywheel-zh43y

## Investigation

After flywheel-e5f2f fixed the identity probe (status=pass drift=0), 5
unrelated probe failures still drove `flywheel-loop doctor --json` to
top-level `status=fail`. This bead investigates each, fixes what's
in-scope, and files beads for what requires Joshua-directive decisions.

## Triage table

| # | Code | Root cause | Disposition | Outcome |
|---|---|---|---|---|
| 1 | `active_marker_project_label_not_loaded` | Loop state file says `dispatch_mode=launchd_prompt` but plist `ai.zeststream.flywheel-flywheel-loop.plist` doesn't exist; the writeback driver is the actual mechanism | **Filed bead `flywheel-kmf4z`** — Joshua-directive on (A) install plist or (B) update dispatch_mode | DEFERRED |
| 2 | `beads_db_health_failed` | 286 JSONL rows have `source_repo='flywheel'` (basename) instead of absolute path; leakage_count=253 | **Filed bead `flywheel-wz5rh`** — subset of `project_bead_isolation_plan` initiative; needs canonical bulk-update path (br has no `--source-repo` flag) | DEFERRED |
| 3 | `loop_driver_missing_driver` | Same root as #1 | Same disposition as #1 (covered by `flywheel-kmf4z`) | DEFERRED (rolled into #1) |
| 4 | `memory_health_failed` | 3 memory files in `~/.claude/projects/-Users-josh-Developer-flywheel/memory/` lacked YAML frontmatter (missing `name`, `description`, `type` keys) | **Fixed inline** — added frontmatter to all 3 | ✓ FIXED |
| 5 | `validation_receipts_schema_invalid_count` | 8 receipts written before v1 schema finalization (May 3-8) violate `artifact_checks_not_array` / `failure_missing_failure_class` / `recovery_hint_missing` | **Fixed inline** — archived to `.archive-pre-v1-schema/` with README explaining (preserves history; clears active gate) | ✓ FIXED |

## Fix A (#4 memory_health) — frontmatter repair

3 files in `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`:
- `feedback_beads_rust_dep_add_post_rebuild_openread.md`
- `feedback_evidence_pack_replaces_four_lens.md` (had partial frontmatter; missing `name` + `description`)
- `feedback_regression_test_must_exercise_production_close_path.md`

Each got proper YAML frontmatter with `name`, `description`, `type` keys.

**Before:** `mem memory doctor` → status=FAIL, OK/WARN/FAIL=129/26/3

**After:** `mem memory doctor` → status=WARN, OK/WARN/FAIL=131/27/0

The remaining WARN (24 index-drift rows) is pre-existing churn, not a
gate-flipping condition. **`memory_health_status` flipped FAIL→WARN, which
satisfies the gate** at `lib/portable/core.d/part-02-portable_doctor.sh:704-709`
(WARN does not flip top-level status to fail).

## Fix B (#5 validation receipts) — archive pre-v1

8 receipts moved from `.flywheel/validation-receipts/` to
`.flywheel/validation-receipts/.archive-pre-v1-schema/` with a README
explaining the move. The receipts are NOT deleted — they're preserved as
historical evidence.

| Receipt | Failure code |
|---|---|
| `b03-reaper-done-6fe5ac9f1eee.json` | `recovery_hint_missing` |
| `flywheel_loop_20260504T043410Z-done-0ecf0cde2d4b.json` | `failure_missing_failure_class` |
| `flywheel-4vfa-onboarding-proof.json` | `artifact_checks_not_array` |
| `flywheel-ggld7-1a2b3b.json` | `artifact_checks_not_array` |
| `no-bead-cross-session-callback-closure-skillos-20260504T0400Z.json` | `artifact_checks_not_array` |
| `no-bead-flywheel_loop_20260504T005757Z.json` | `artifact_checks_not_array` |
| `no-bead-flywheel_loop_20260504T012826Z.json` | `artifact_checks_not_array` |
| `no-bead-flywheel_loop_20260504T015853Z.json` | `artifact_checks_not_array` |

**Before:** active dir has 8 schema-invalid receipts → gate at
`part-02-portable_doctor.sh:930` flips status=fail.

**After:** active dir has 0 schema-invalid receipts (6 valid).
**`validation_receipts_schema_invalid_count` is now 0** which satisfies
the gate (gate condition: `count > 0` → fail).

## Beads filed for the 3 deferred failures

- **`flywheel-kmf4z`** (P1 BUG) — covers #1 + #3 (loop driver state migration).
  Documents the dispatch_mode=launchd_prompt vs reality (writeback driver
  active) discrepancy. Lists two fix paths (A: install plist; B: update
  dispatch_mode) with the trade-offs. Cannot proceed without Joshua
  directive because mutating loop state file is operationally load-bearing.

- **`flywheel-wz5rh`** (P1 BUG) — covers #2 (source_repo basename).
  286 JSONL rows have basename instead of absolute path. Documented as
  one specific FM within the existing `project_bead_isolation_plan`
  initiative (memory). Cannot proceed without canonical bulk-update path
  because per memory `feedback_beads_jsonl_writes_via_br_only`, JSONL
  writes go through `br` only, and `br update` does not currently expose
  a `--source-repo` flag.

## AC honest assessment

**Dispatch AC:** `flywheel-loop doctor --json returns status in (pass, warn)`.

This bead achieves a **2-of-5 fix** (40%) at the probe-status level. The 3
remaining failures are filed as new beads with full diagnosis + proposed
fix paths, requiring Joshua directive or a coordinated multi-phase initiative
(bead-isolation cleanup).

**Identity probe contribution (from sister flywheel-e5f2f):** ✓ pass drift=0.
**Memory probe contribution (this bead):** ✓ FAIL→WARN (gate-clearing).
**Validation receipts (this bead):** ✓ count=0 (gate-clearing).
**Loop driver (deferred to flywheel-kmf4z):** still MISSING_DRIVER.
**Beads leakage (deferred to flywheel-wz5rh):** still 253.

**Top-level status: still `fail`** (because of the 2 deferred items). This
bead's commit honestly transitions doctor from `fail with 5 errors` →
`fail with 2 errors`. The skillos AC ("drift==0") was already met by
flywheel-e5f2f; the residual top-level fail does not block skillos.

## L112 verify probe

```bash
# Regression test for the 2 fixes
bash /Users/josh/Developer/flywheel/tests/doctor-non-identity-failures-fixes.sh 2>&1 | tail -1
# expected: SUMMARY pass=11 fail=0

# Memory probe AC
mem memory doctor 2>&1 | grep -E '^-Users-josh-Developer-flywheel\s+' | awk '{print $2}'
# expected: WARN (not FAIL)

# Validation receipts AC
ls /Users/josh/Developer/flywheel/.flywheel/validation-receipts/*.json | while read F; do
  bash /Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh "$F" >/dev/null 2>&1 || echo "INVALID: $F"
done
# expected: empty (no INVALID lines)
```

## Skill auto-routes

- **canonical-cli-scoping**: yes — used existing `mem memory doctor` and
  `parse.sh` canonical surfaces; archive dir follows convention
- **rust-best-practices**: n/a (no Rust)
- **python-best-practices**: n/a (no Python)
- **readme-writing**: n/a (archive README is one short note, not a
  public-facing README — uses standard quick-explain shape)
