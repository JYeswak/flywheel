# SkillOS Orchestrator Design Refresh

Bead: `flywheel-668a`
Dependent apply bead: `flywheel-hg2w`
Schema: `flywheel.skillos_orchestrator_design_refresh.v1`
Status: design_refreshed_parent_ready_to_close

## Why This Exists

`flywheel-668a` was filed on 2026-05-03 after the SkillOS mobile-eats-pattern
rollback. The original close evidence lived under `/tmp/skillos-orchestrator-DESIGN/`,
which is not durable enough for a bead that gates a follow-on apply bead.

This file replaces the missing `/tmp` design packet with a repo-local design
receipt and updates the diagnosis against the current loop-integrity probe.

## Original Finding

The May 3 finding was that SkillOS had a JSM payload but did not have enough
orchestration/reaper/fuckup-decision machinery to satisfy L60 loop integrity.

Original failed signals named in the bead:

- `pane_state_changed_since_last_tick`
- `fuckup_decisions_made_since_last_tick`

The temporary design packet reportedly compared three options:

- Option A: add a SkillOS-local CC orchestrator pane.
- Option B: write a `skillos-orchestrator.sh` helper/reaper.
- Option C: bridge through the Flywheel orchestrator cross-session path.

The historical recommendation was Option A because a local orchestrator pane
could own real callback reaping and real fuckup-decision processing.

## Current Probes

Bounded per-project command:

```bash
.flywheel/scripts/loop-integrity-signals.sh --project skillos --json
```

Observed on 2026-05-14T22:54Z:

```json
{
  "project": "skillos",
  "verdict": "LIMPING",
  "failed_signals": [
    "callback_receipt_fresh",
    "canonical_bridge_fresh"
  ],
  "passing_signals": [
    "marker_fresh"
  ]
}
```

Full gap-hunt doctor command:

```bash
.flywheel/scripts/gap-hunt-probe.sh --doctor --json
```

Observed on 2026-05-14T22:54Z:

```json
{
  "project": "skillos",
  "verdict": "DEAD",
  "failed_signals": [
    "ledger_writes_since_last_tick",
    "pane_state_changed_since_last_tick",
    "callback_received_in_last_2_ticks",
    "callback_receipt_fresh",
    "canonical_bridge_fresh"
  ],
  "auto_beads_filed": [
    "flywheel-2xdi.165",
    "flywheel-2xdi.166",
    "flywheel-2xdi.167"
  ]
}
```

Important correction: the bounded freshness probe and the full L60 doctor do
not use the same verdict vocabulary. The bounded probe isolates the explicit
freshness surfaces and reports LIMPING. The full doctor combines L60 driver
signals plus explicit freshness signals and reports DEAD. Neither validator is
green. The apply target remains live orchestration output: callback receipt
freshness, canonical bridge freshness, ledger writes, and real pane activity.

## Updated Design Decision

`flywheel-668a` should close as the design/diagnosis parent. It has now done the
durable work that its dependent apply bead needs:

1. Preserve the original architectural comparison.
2. State the stale-vs-current signal difference explicitly.
3. Route implementation to `flywheel-hg2w` rather than editing SkillOS from this
   parent bead.

`flywheel-hg2w` should no longer blindly apply the May 3 Option A wording. The
apply bead should first choose the smallest repair that makes these current
signals fire:

- `callback_receipt_fresh`: SkillOS dispatches must write a
  `callback_received_at` row in `/Users/josh/Developer/skillos/.flywheel/dispatch-log.jsonl`.
- `canonical_bridge_fresh`: SkillOS loop ticks must refresh
  `~/.local/state/flywheel-loop/last_tick_skillos.json` or intentionally update
  the classifier if that bridge is no longer the canonical signal.
- `ledger_writes_since_last_tick`: SkillOS must write a fresh load-bearing
  ledger row, not only a marker.
- `pane_state_changed_since_last_tick`: SkillOS must have real pane work or a
  classifier-backed non-pane operating mode.

If a SkillOS-local orchestrator pane remains the simplest way to own both
signals, Option A is still viable. If the bridge and callback paths can be fixed
with a narrower helper, Option B is now the lower-blast-radius path. Option C is
only a temporary bridge because it keeps SkillOS liveness dependent on Flywheel
orch availability.

## Non-Goals

- No direct writes to `/Users/josh/Developer/skillos` in this bead.
- No claim that SkillOS is healthy.
- No reinstall of the JSM payload.
- No closure of `flywheel-hg2w`.

## Close Criteria for flywheel-668a

The parent can close when all of these are true:

- This durable design-refresh file exists in repo.
- A test verifies the durable file names the old failed signals, current failed
  signals, and the dependent apply bead.
- The bounded current loop probe is cited as LIMPING, not green.
- The full gap-hunt doctor is cited as DEAD, not green.
- `flywheel-hg2w` remains open as the apply owner.
