---
schema_version: jsm-import-ready-patch/v1
skill: .flywheel
skill_status: unmanaged
paired_with: ~/.claude/skills/.flywheel/bin/flywheel-loop
bead: flywheel-oxzyr.2.5
---

# JSM-Import-Ready Patch — flywheel-oxzyr.2.5

Per `feedback_cross_repo_consumer_vs_mutator_distinction.md` META-RULE 2026-05-11
(N=2: file_length_doctor_json + 8p6fz.1 watchdog): `.flywheel` skill is
**unmanaged** (no jsm-managed marker), so cross-repo edits to its substrate
require the **paired-jsm-import-patch** pattern: direct mutation + this artifact.

This patch documents the FM-8 detect/fix function + dispatcher intercept added
to `~/.claude/skills/.flywheel/bin/flywheel-loop` (skill substrate).

## Target

- **File:** `~/.claude/skills/.flywheel/bin/flywheel-loop`
- **Skill:** `.flywheel`
- **Skill status:** unmanaged
- **Skill source-of-truth:** `~/.claude/skills/.flywheel/` (sibling of `~/Developer/flywheel`)
- **Mutator pattern:** direct edit + paired-jsm-import-ready patch

## Change classes

### A. Dispatcher intercept addition

Inside the `doctor)` case in `_flywheel_loop_main()` (or equivalent dispatch),
**after** the existing `fm5` and `fm10` intercepts and **before** delegation
to `portable_doctor`, add:

```bash
# FM-8 detect/fix intercept (flywheel-oxzyr.2.5 — dispatch-during-input-deaf)
if [[ "${1:-}" == "fm8" ]]; then
    shift
    _flywheel_loop_fm8_detect_fix "$@"
    exit $?
fi
```

**Routing contract:**
- `doctor fm8` → `_flywheel_loop_fm8_detect_fix`
- `doctor <other-arg>` → existing route (portable_doctor or fm5/fm10 handler)
- `doctor` (no subarg) → existing route (portable_doctor)

Backwards-compatible: NO regression to existing `doctor`, `doctor fm5`, or
`doctor fm10` invocations.

### B. New function: `_flywheel_loop_fm8_detect_fix()`

Inserted in the chokepoint module (between `# ====== BEGIN doctor-mode chokepoint`
and `# ====== END doctor-mode chokepoint` markers), AFTER
`_flywheel_loop_fm10_detect_fix()`.

**Surface:**
```
flywheel-loop doctor fm8 \
  --dispatch <json-row> \
  --validation-tail <file-path> \
  [--dry-run | --apply] \
  [--json]
  [--help|-h]
```

**Schema:** `fm8-detect-fix/v1` (declared in JSON output)

**Exit codes:**
- 0 — clean (not INPUT-DEAF)
- 1 — INPUT-DEAF detected + retracted + quarantined + fuckup-logged (apply mode)
- 2 — usage error
- 3 — INPUT-DEAF detected (dry-run mode)

**Class:** dispatch-during-input-deaf (Shape B spec-extractor over-extracts)

**Detect predicate:**
- Dispatch row has `chevron_visible=true` for the target pane
- AND no `input-acknowledged|input_ack|prompt-accepted` signal present in the
  validation-tail file
→ Pane was input-deaf when dispatch landed (Shape B per `feedback_chevron_visible_does_not_mean_submits_work.md`)

**Fix (triple-ledger write on apply mode):**

1. **Retraction row** appended to `${FM8_RETRACTIONS:-~/.local/state/flywheel/fm8-retractions.jsonl}`:
   ```json
   {
     "pane": "<pane>",
     "dispatch_ts": "<from dispatch row>",
     "retraction_ts": "<now>",
     "applied": false,
     "retraction_reason": "dispatch_during_input_deaf"
   }
   ```

2. **Quarantine row** appended to `${FM8_QUARANTINE:-~/.local/state/flywheel/fm8-quarantine.jsonl}`:
   ```json
   {
     "pane": "<pane>",
     "quarantine_ts": "<now>",
     "state": "quarantined-input-deaf"
   }
   ```

3. **Fuckup-log row** appended to `${FM8_FUCKUP_LOG:-~/.local/state/flywheel/fuckup-log.jsonl}`:
   ```json
   {
     "schema_version": "flywheel.fuckup.v1",
     "ts": "<now>",
     "class": "dispatch-during-input-deaf",
     "severity": "high",
     "pane": "<pane>",
     "dispatch_ts": "<from dispatch row>",
     "source_bead": "flywheel-oxzyr.2.5"
   }
   ```

**Why triple-ledger (heavier than .2.3's single retraction):**
Shape B input-deaf class needs orch-notification (fuckup-log severity=high) plus
a state machine entry (quarantine) so subsequent dispatch attempts to the same
pane can short-circuit. .2.3's FM-5/FM-10 are pure audit-only retraction; this
extends that pattern.

**Configurable paths (env-var overrides):**
- `FM8_RETRACTIONS` — defaults to `~/.local/state/flywheel/fm8-retractions.jsonl`
- `FM8_QUARANTINE` — defaults to `~/.local/state/flywheel/fm8-quarantine.jsonl`
- `FM8_FUCKUP_LOG` — defaults to `~/.local/state/flywheel/fuckup-log.jsonl`

## Verification

```bash
# Schema declared
grep -q 'fm8-detect-fix/v1' ~/.claude/skills/.flywheel/bin/flywheel-loop

# Function defined
grep -q '^_flywheel_loop_fm8_detect_fix()' ~/.claude/skills/.flywheel/bin/flywheel-loop

# Intercept routes
grep -q '_flywheel_loop_fm8_detect_fix "\$@"' ~/.claude/skills/.flywheel/bin/flywheel-loop

# Syntax valid
bash -n ~/.claude/skills/.flywheel/bin/flywheel-loop

# Round-trip: positive case
~/.claude/skills/.flywheel/bin/flywheel-loop doctor fm8 \
  --dispatch '{"pane":"test:0.1","chevron_visible":true,"dispatch_ts":"2026-05-11T22:00:00Z"}' \
  --validation-tail /tmp/empty-tail.txt \
  --apply --json
# Expected: rc=1, "detected":true, all 3 ledgers populated

# Round-trip: negative case (input-ack present)
echo "input-acknowledged" > /tmp/ack-tail.txt
~/.claude/skills/.flywheel/bin/flywheel-loop doctor fm8 \
  --dispatch '{"pane":"test:0.1","chevron_visible":true,"dispatch_ts":"2026-05-11T22:00:00Z"}' \
  --validation-tail /tmp/ack-tail.txt \
  --dry-run --json
# Expected: rc=0, "detected":false
```

## JSM import readiness

If `.flywheel` skill moves to **jsm-managed=patch-artifact** (per 2xdi.60.1):

1. Patch artifact at this path is import-ready
2. `jsm patch import --skill .flywheel --artifact .flywheel/audit/flywheel-oxzyr.2.5/jsm-import-ready-patch.md` would apply the function + intercept
3. No additional translation required

Until then: direct mutation has shipped + verified; this artifact preserves
the paired-jsm-import-patch contract.

## Cross-repo wire-or-explain ledger entry

`{"bead":"flywheel-oxzyr.2.5","skill":".flywheel","status":"unmanaged","mutator":"direct+paired-patch","verified":true}`
