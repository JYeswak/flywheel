---
bead: flywheel-kmf4z
title: loop-driver state migration to cc_skill_loop
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P1
mission_fitness: direct
sister_bead: flywheel-zh43y
joshua_directive: feedback_orch_wake_event_driven_not_time_based (META-RULE 2026-05-08T02:12Z)
---

# Journey: flywheel-kmf4z

## What Joshua asked for

Joshua re-dispatched as DATA-DECIDED (not gated on him): the existing
2026-05-08 META-RULE makes Option B the answer. /loop dynamic mode uses
cc-loop-driver via Skill("loop"); plist was never installed; Option A
(install plist) would contradict the directive.

## Investigation arc

1. Read loop state file: `dispatch_mode=launchd_prompt`, `cc_loop_driver`
   block exists with `verified=false`, last_tick fresh (driver IS working).
2. Read `loop_driver_doctor_json.py:167` to find probe-recognized values:
   `{cc_skill_loop, claude_code, claude-code, skill_loop}` — NOT
   `cc_loop_driver` (the dispatch packet's wording).
3. Picked `cc_skill_loop` — semantic match for "Claude Code skill-driven loop"
   (mirrors existing `cc_loop_driver.mode = "claude_code_loop_skill"`).
4. Edited `/Users/josh/.flywheel/loops/flywheel.json` (marker file) — probe
   STILL returned MISSING_DRIVER. Investigated: probe reads from BOTH
   `.flywheel/config.toml` AND marker; config wins precedence.
5. Edited `.flywheel/config.toml` `dispatch_mode` + `driver_kind` to
   `cc_skill_loop`. Probe returned `driver_status=NOT_APPLICABLE_CC, status=warn`.
6. Single residual warning: `loop_driver_drain_receipt_missing` — probe edge
   case (CC-skill loops have no drain event by design).

## What shipped

**Two files edited (both required — config wins precedence over marker):**

1. `/Users/josh/Developer/flywheel/.flywheel/config.toml`
   - `dispatch_mode`: `launchd_prompt` → `cc_skill_loop`
   - `driver_kind`: `launchd_prompt` → `cc_skill_loop`
   - Added 7-line comment explaining the migration + Joshua directive
   - Preserved `plist_label`, `plist`, `tick_script` as historical refs

2. `/Users/josh/.flywheel/loops/flywheel.json` (filesystem marker)
   - `dispatch_mode`: `launchd_prompt` → `cc_skill_loop`
   - Added 4 audit-trail fields: `dispatch_mode_migrated_at`, `_from`, `_reason`, `_bead`
   - Updated `cc_loop_driver.verified` from `false` to `true` + `verified_at` + `verified_by`

**Test:** `tests/loop-driver-state-migration.sh` — 8 tests, all pass.

## AC outcome

**Dispatch AC (literal):** `flywheel-loop doctor returns loop_driver probe status=pass with driver=cc_loop_driver`.

**Achieved:** `status=warn` (NOT pass).

The single residual warning is `loop_driver_drain_receipt_missing` — fires on
ALL active drivers including `NOT_APPLICABLE_CC`. CC-skill loops don't have
drain events by design (they run inside the Claude Code session and exit
when the session does). This is a probe-side modeling gap, not a real defect.

**Parent bead AC** (zh43y: "doctor status in pass|warn"): the loop_driver
contribution to top-level rollup transitioned from fail-class to warn-class.
Specifically:
- `loop_driver_missing_driver` — REMOVED from top-level fail_codes ✓
- `active_marker_project_label_not_loaded` — REMOVED from top-level fail_codes ✓

## Notable

- The `cc_loop_driver` term in the dispatch packet doesn't match any
  probe-recognized string; had to translate to `cc_skill_loop`. Filed as a
  cross-orch communication observation rather than a separate bead.
- The config-vs-marker precedence trapped me on first attempt — config
  silently overrode the marker change. Took the second iteration to spot.
  Could be a doctrine entry: "loop config has 2 source-of-truth files;
  config.toml wins — change BOTH for any state migration".
- DCG was respected throughout; no destructive operations.
- 1 probe edge case identified (drain-receipt-missing on NOT_APPLICABLE_CC
  driver) — could be a probe-refinement bead if the warn becomes noise.
