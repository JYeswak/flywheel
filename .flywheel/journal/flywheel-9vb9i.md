---
bead: flywheel-9vb9i
title: doctor postcheck loud-failure invariant for publishability_bar
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped (live runtime; .claude commit deferred per peer-orch in-flight)
priority: P2
mission_fitness: direct
sister_chain: e5f2f → zh43y → kmf4z → wz5rh → 9vb9i (this bead)
---

# Journey: flywheel-9vb9i

## What Joshua asked for

Final piece of the doctor-pass arc: fix the postcheck so status=fail
flips populate errors[] (loud-failure invariant).

Two paths offered: (A) fix publishability_bar predicate, (B) fix the
gate-without-error-emit pattern at line 808. Path (B) preferred —
substrate doctrine.

## Investigation arc

1. Read postcheck source at line 287-288 — found existing `publishability_bar_score_low`
   maybe() clause for the `score < 3` branch only.
2. Confirmed gate at `part-02-portable_doctor.sh:808` has TWO triggers
   (`score < 3` OR `status == "fail"`). Postcheck only handled one.
3. Inspected publishability_bar probe output — it ALREADY emits
   `{"errors":[{"code":"brand_voice_banned_words",...}]}`. Postcheck
   wasn't pulling them.
4. Surveyed sister probes: storage, jeff_corpus, daily_report, file_length,
   quality_bar_close_gate, agent_mail_fd_pressure ALL use the canonical
   `+ (.X.errors // [])` propagation pattern. publishability_bar was the
   outlier.
5. Decision: 3-line fix combining canonical sister-pattern + loud-failure
   invariant guard.

## What I shipped (live runtime)

`~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
+3 lines after the existing `publishability_bar_score_low` maybe() clause:

```diff
+ (.publishability_bar.errors // [])
+ maybe((.publishability_bar.status // "ok") == "fail" and ((.publishability_bar.errors // []) | length) == 0;
+     {code:"publishability_bar_status_failed_silent", ...})
```

**Belt-and-suspenders:**
- Sister-pattern propagation pulls publishability_bar's own errors[]
  (the natural case)
- Synth error if status=fail but errors[] empty (the bug-guard)

## Doctor result

Before fix: `fail_codes=["doctor_internal_empty_fail"]` (sentinel only)

After first attempt: `fail_codes=["beads_db_health_failed", "brand_voice_banned_words"]`
- The sentinel is GONE ✓
- A real publishability_bar error (`brand_voice_banned_words`) surfaces ✓
- BUT `beads_db_health_failed` was back — peer-orch had filed a new bead
  (flywheel-6kdnf) which leaked source_repo (the wz5rh upstream bug)

After re-fix of new leak via wz5rh recipe (jq + br sync --merge --force-jsonl):
- DB leakage_count: 1 → 0 again
- Final doctor result pending verification (background run)

## File-tree caveat (no .claude commit)

The entire `~/.claude/skills/.flywheel/lib/doctor.d/` directory is UNTRACKED
— peer-orch extracted the monolithic `lib/doctor.sh` into 3 modular files
(`part-01-...sh`, `part-02-...sh`, `part-03-...sh`) but hasn't committed.
The `lib/doctor.sh` shim that sources them IS tracked.

**I did NOT commit the .claude side.** The e5f2f surgical-commit pattern
cannot apply because the file is not in HEAD (cannot extract HEAD-version
to start from). Committing my edited part-01 would bring the WHOLE
peer-orch extraction (~28KB) into a single-bead commit.

The fix IS LIVE at runtime (probe sources the edited file via the shim).
Backup of pre-fix file preserved at
`.flywheel/audit/flywheel-9vb9i/postcheck.before` for re-application if
needed. Clean 3-line diff captured at `postcheck.diff` for replay against
HEAD-when-doctor.d-lands.

## Files touched

- **CODE FIX (live runtime, NOT committed in .claude)**: 
  `~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
  +3 lines
- **DATA FIX (re-applied wz5rh recipe)**: `.beads/issues.jsonl` 
  (1 row source_repo basename → canonical) + DB rebuild
- **TEST + EVIDENCE (committed in flywheel)**:
  - `tests/doctor-publishability-bar-loud-failure.sh` (NEW, 5 tests)
  - `.flywheel/audit/flywheel-9vb9i/evidence.md`
  - `.flywheel/audit/flywheel-9vb9i/compliance-pack.md`
  - `.flywheel/audit/flywheel-9vb9i/postcheck.before` (backup of pre-fix)
  - `.flywheel/audit/flywheel-9vb9i/postcheck.diff` (clean 3-line hunk)
  - `.flywheel/audit/flywheel-9vb9i/smoke-doctor-final.json` (final doctor result)
  - `.flywheel/journal/flywheel-9vb9i.md`

## Mission fitness

Class: **direct**. Final substrate piece in the doctor-pass arc. Pattern fix
applies beyond just publishability_bar — establishes the canonical
"every probe propagates its .errors[]" rule via documentation in evidence
+ regression test that asserts the canonical sister-pattern shape.

## Notable

- The publishability_bar issues (banned_words_count=2, public_repo=false)
  are content concerns, not substrate-rollup concerns. My fix surfaces
  the existing real error (`brand_voice_banned_words`) instead of the
  sentinel — the AC "fail_codes[] populated correctly when fail" is met,
  but top-level status remains "fail" until those content issues are
  addressed (out of scope for this bead).
- Peer-orch wrote `flywheel-6kdnf` between my wz5rh fix and this bead's
  doctor-verify step → re-introduced 1 leakage row. This confirms the
  wz5rh-noted churn pattern: every new bead leaks until upstream `br create`
  is fixed. Re-applied the wz5rh recipe and back to 0.
