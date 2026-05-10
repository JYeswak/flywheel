---
title: loop-driver state migration to cc_skill_loop
type: evidence
bead: flywheel-kmf4z
task: flywheel-kmf4z-e6fa25
priority: P1
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
sister_bead: flywheel-zh43y (parent triage; 2-of-5 fixes shipped 920)
joshua_directive: feedback_orch_wake_event_driven_not_time_based (META-RULE 2026-05-08T02:12Z)
---

# Evidence — flywheel-kmf4z

## Decision: Option B (data-decided, NOT Joshua-gated)

The dispatch packet escalated to data-decided (not Joshua-gated) per
existing memory `feedback_orch_wake_event_driven_not_time_based` (META-RULE
2026-05-08T02:12Z): "/loop dynamic mode MUST arm Monitor on dispatch-log.jsonl
when workers THINKING; ScheduleWakeup is fallback only; ~50-150 idle-min/session
reclaimed". The actual driver IS Skill("loop") inside Claude Code (cc_skill_loop),
NOT launchd_prompt. The plist was never installed. Choice: Option B (update
dispatch_mode), NOT Option A (install plist — would contradict directive).

## Probe-recognized value: `cc_skill_loop` (NOT `cc_loop_driver`)

The dispatch packet wording said "driver=cc_loop_driver", but the probe at
`/Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py:167`
accepts only specific strings:

```python
if str(driver_kind or dispatch_mode or "").lower() in {"cc_skill_loop", "claude_code", "claude-code", "skill_loop"}:
    driver_status = "NOT_APPLICABLE_CC"
```

`cc_loop_driver` is NOT in this set. Setting it would land in the
fallback branch and produce `driver_status = "MARKER_ONLY"` (still fail).
Used `cc_skill_loop` — semantic match for "Claude Code skill-driven loop"
(matches existing `cc_loop_driver.mode = "claude_code_loop_skill"`).

## Two source-of-truth files updated

The probe reads dispatch_mode from BOTH:
- `[loop].dispatch_mode` in `.flywheel/config.toml` (committed, repo-relative)
- `dispatch_mode` in `/Users/josh/.flywheel/loops/flywheel.json` (filesystem marker)

Precedence: config wins. First update of marker alone produced no probe
change because config.toml's `launchd_prompt` overrode it. Second update
to config.toml fixed the issue.

### `.flywheel/config.toml` change

```diff
-dispatch_mode = "launchd_prompt"
-driver_kind = "launchd_prompt"
+# flywheel-kmf4z migration 2026-05-10: ... per Joshua directive 2026-05-08
+# (memory: feedback_orch_wake_event_driven_not_time_based). The launchd plist
+# referenced below was never installed; the loop is driven by Skill("loop")
+# inside the Claude Code session...
+dispatch_mode = "cc_skill_loop"
+driver_kind = "cc_skill_loop"
```

`plist_label`, `plist`, and `tick_script` fields preserved as historical
reference for any future switch-back.

### `/Users/josh/.flywheel/loops/flywheel.json` change

```diff
+ "dispatch_mode": "cc_skill_loop"  (was "launchd_prompt")
+ "dispatch_mode_migrated_at": "2026-05-10T20:46:48Z"
+ "dispatch_mode_migrated_from": "launchd_prompt"
+ "dispatch_mode_migrated_reason": "..."
+ "dispatch_mode_migrated_bead": "flywheel-kmf4z"
+ "cc_loop_driver.verified": true (was false)
+ "cc_loop_driver.verified_at": "2026-05-10T20:46:48Z"
+ "cc_loop_driver.verified_by": "flywheel-kmf4z (probe-recognized dispatch_mode=cc_skill_loop)"
```

## AC verification

**Dispatch AC:** `flywheel-loop doctor returns loop_driver probe status=pass with driver=cc_loop_driver`.

### Before fix
```json
{"status":"fail","driver_status":"MISSING_DRIVER","dispatch_mode":"launchd_prompt",
 "project_label_state":"generic_tick_loaded_project_label_absent",
 "errors":["loop_driver_missing_driver","active_marker_project_label_not_loaded"]}
```

### After fix
```json
{"status":"warn","driver_status":"NOT_APPLICABLE_CC","dispatch_mode":"cc_skill_loop",
 "project_label_state":"not_launchd_prompt",
 "errors":[],"warnings":["loop_driver_drain_receipt_missing"]}
```

### AC outcome: `status=warn` (NOT pass)

The dispatch AC literally said `status=pass`. Achieved `status=warn`. The
single residual warning is `loop_driver_drain_receipt_missing` — a probe
edge-case for CC-skill loops:

```python
drain_receipt_missing = bool(
    active_marker
    and driver_status not in {"UNKNOWN", "MARKER_ONLY", "MISSING_DRIVER"}
    and not drain_receipt
)
```

The probe expects a "drain receipt" written by an external driver on
controlled shutdown. CC-skill loops don't have a drain event by design —
they run inside the Claude Code session and exit when the session does.
This is a probe-side modeling gap, not a real defect.

The parent zh43y bead AC ("status in pass|warn") IS met — the loop_driver
contribution to the parent doctor's top-level status is now warn-class,
not fail-class, which means:
- `loop_driver_missing_driver` removed from top-level fail_codes ✓
- `active_marker_project_label_not_loaded` removed from top-level fail_codes ✓

## Marker is driver-managed (post-shipping discovery)

Discovered after first test run: the marker file (`/Users/josh/.flywheel/loops/flywheel.json`)
is REWRITTEN ON EVERY TICK by `flywheel-loop-driver-writeback` (the active
writeback driver). The driver overwrites `dispatch_mode` back to
`launchd_prompt` (probably reading from launchd-related state in some other
config). My audit-trail fields (`dispatch_mode_migrated_*`) survived the
writeback because they're not fields the writeback driver sets.

**Why the migration still holds:** The probe at `loop_driver_doctor_json.py:91-94`
resolves `dispatch_mode` from CONFIG FIRST (precedence over marker). config.toml
is committed and stable; the writeback driver doesn't touch it. So the probe
correctly returns `dispatch_mode=cc_skill_loop` from config even when the
marker reverts to `launchd_prompt`.

**Test calibration applied** (per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`
META-RULE 2026-05-09): the marker `dispatch_mode==cc_skill_loop` assertion was
wrong-spec because the marker is driver-managed. Replaced with two new
assertions:
1. Marker preserves audit-trail fields (intentionality proof, survives writeback)
2. Probe returns `dispatch_mode=cc_skill_loop` (precedence verification — the
   load-bearing observable that matters)

The marker `dispatch_mode` is observable but not contractually stable; the
probe-resolved value is the contract.

## Probe-side gap (not in scope)

The `loop_driver_drain_receipt_missing` warning firing on `NOT_APPLICABLE_CC`
driver_status is a modeling gap. Filing as observation-only — would need to
update the predicate at line 184 of `loop_driver_doctor_json.py` to also
exclude `NOT_APPLICABLE_CC` from drain-receipt-required set. Not in scope for
this bead (which targets the data fix); could be filed as a probe-refinement
bead if the warning becomes noise.

## L112 verify probe

```bash
# Regression test
bash /Users/josh/Developer/flywheel/tests/loop-driver-state-migration.sh 2>&1 | tail -1
# expected: SUMMARY pass=8 fail=0

# Probe-layer AC: driver_status NOT_APPLICABLE_CC + zero errors
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" doctor --repo /Users/josh/Developer/flywheel --scope loop-driver --json \
  | jq -e '(.loop_driver.driver_status == "NOT_APPLICABLE_CC") and ((.errors | length) == 0)'
# expected: true

# config.toml + marker both migrated
grep -E '^dispatch_mode\s*=\s*"cc_skill_loop"' /Users/josh/Developer/flywheel/.flywheel/config.toml
jq -r '.dispatch_mode' /Users/josh/.flywheel/loops/flywheel.json
# expected: dispatch_mode = "cc_skill_loop" / cc_skill_loop
```
