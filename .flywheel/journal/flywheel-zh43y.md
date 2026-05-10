---
bead: flywheel-zh43y
title: doctor non-identity failures triage + 2-of-5 fix
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped (partial-fix; 3-of-5 deferred to new beads)
priority: P1
mission_fitness: direct
sister_bead: flywheel-e5f2f
---

# Journey: flywheel-zh43y

## What Joshua asked for

5 unrelated probe failures still drove `flywheel-loop doctor --json` to
top-level `status=fail` after e5f2f's identity probe fix. Triage each;
fix what's tractable; document blocked items.

## What I shipped

**2 of 5 probe failures fixed inline:**

1. **#4 memory_health (FAIL→WARN)**: 3 memory files in
   `~/.claude/projects/-Users-josh-Developer-flywheel/memory/` lacked YAML
   frontmatter (`name`, `description`, `type` keys). Added proper
   frontmatter to all 3. `mem memory doctor` now reports WARN (was FAIL).
   The gate at `lib/portable/core.d/part-02-portable_doctor.sh:704-709`
   only flips top-level on `FAIL`; WARN passes.

2. **#5 validation_receipts_schema_invalid_count (8→0)**: Archived 8 pre-v1
   schema receipts (May 3-8 files violating `artifact_checks_not_array`,
   `failure_missing_failure_class`, `recovery_hint_missing`) to
   `.flywheel/validation-receipts/.archive-pre-v1-schema/` with a README
   explaining the move. Active dir count = 0; gate clears.

**3 of 5 deferred to new beads (require Joshua-directive):**

- **#1 + #3 (loop_driver MISSING_DRIVER)** → bead `flywheel-kmf4z`. Loop
  state file says `dispatch_mode=launchd_prompt` but the referenced plist
  doesn't exist; the writeback driver IS the actual mechanism (last_tick
  fresh). Fix paths: (A) install plist; (B) update dispatch_mode. Both
  mutate operationally load-bearing state; need Joshua call.
- **#2 (beads leakage_count=253)** → bead `flywheel-wz5rh`. 286 JSONL rows
  have `source_repo='flywheel'` (basename) instead of absolute path. This
  is one specific FM within the existing `project_bead_isolation_plan`
  initiative. Per `feedback_beads_jsonl_writes_via_br_only` META-RULE,
  cannot manually edit JSONL — needs canonical bulk-update path that `br`
  doesn't currently expose.

## Investigation arc

1. Re-ran `flywheel-loop doctor --json` (60s budget; took ~5min).
2. Extracted all 5 fail_codes + their detail blocks.
3. Found gate logic for each in `lib/portable/core.d/part-02-portable_doctor.sh`:
   - beads_db_health_status=fail → fail (line 696)
   - memory_health_status=FAIL → fail (line 704)
   - loop_driver MISSING_DRIVER → fail (line 1241)
   - validation_receipts_schema_invalid_count > 0 → fail (line 930)
4. For #4: ran `mem memory doctor --project ... --json` to find the 3
   specific FAIL files; inspected each; saw all 3 missing required
   frontmatter keys (`name`, `description`, `type`).
5. For #5: ran `parse.sh` against each of 14 receipts in active dir;
   found 8 fail with 3 distinct error codes; categorized as pre-v1 schema
   debt; archived to sibling dir.
6. For #1+#3: traced `loop_driver_doctor_json.py` to find what determines
   MISSING_DRIVER. Found dispatch_mode=launchd_prompt + plist not loaded.
   Cross-referenced with loop state file: cc_loop_driver block was added
   2026-05-08 by Joshua but dispatch_mode wasn't migrated.
7. For #2: `sqlite3 .beads/beads.db "SELECT source_repo, COUNT(*) GROUP BY source_repo"`
   showed 1386 rows with absolute path, 253 rows with `flywheel` basename.
   JSONL had 286 basename rows. Identified as bead-isolation FM; deferred.

## Files touched

- **Memory frontmatter (3 files in ~/.claude/projects/...)** — added YAML frontmatter
- **`.flywheel/validation-receipts/.archive-pre-v1-schema/`** — created with README + 8 receipts moved
- **`tests/doctor-non-identity-failures-fixes.sh`** (NEW, 11 tests, 100% pass)
- **`.flywheel/audit/flywheel-zh43y/`** — evidence + smoke + test-run + this journey
- **Beads filed** — `flywheel-kmf4z` (loop driver) + `flywheel-wz5rh` (source_repo)

## AC honest assessment

Dispatch AC literally: `flywheel-loop doctor --json returns status in (pass, warn)`.

**Top-level status: still `fail`.** 5 → 3 fail_codes (40% reduction).
Identity probe contribution is `pass` (e5f2f); memory + validation
receipts now pass; loop_driver + beads still fail and are filed as new
beads with full context.

The dispatch text noted "this unblocks skillos AC fully (they have drift==0
already; need status not fail)" — the identity-related skillos AC was
already met by e5f2f. The residual top-level fail is no longer about
identity; it's about loop driver state and beads leakage, both of which
needed Joshua-directive operator work to resolve.

## Mission fitness

Class: **direct**. Bug fix on the canonical doctor probe surface; reduces
fail-codes from 5 to 3 and routes the residual 3 to actionable beads.

## Notable

- mem doctor schema_fail just means "missing required frontmatter keys" —
  the 3 files had non-issues content but the schema validator gate flipped
  on metadata absence.
- The validation receipts archive pattern (`.archive-pre-v1-schema/`)
  could become a canonical primitive: `flywheel-loop repair --scope
  archive-pre-v1-receipts`. Filing that as a skill-discovery NOTE rather
  than a new bead since the manual archive is a one-shot.
- The 8 archived receipts had three distinct schema violations; could
  have written individual fixes instead of bulk-archive, but archive
  preserves history without trying to retroactively conform old data
  to a new contract.
