---
bead: flywheel-oxzyr.2.5
title: FM-8 detect/fix invariant (dispatch-during-input-deaf quarantine)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
parent: flywheel-oxzyr.2 (2 sister sub-beads remain: .2.4, .2.6)
scorecard_contribution: +75 actual (Dim 9 +50 + Dim 7 +25)
---

# Journey: flywheel-oxzyr.2.5

## What the bead asked for

P1 — implement FM-8 detect/fix invariant (dispatch-during-input-deaf quarantine)
for flywheel-loop. 4th of 6 sub-beads from oxzyr.2 decomposition.

## What I shipped

### `_flywheel_loop_fm8_detect_fix()` — dispatch-during-input-deaf

- Detect: `chevron_visible=true` + no input-ack signal in validation-tail file
- Fix (triple-ledger write on apply):
  - retraction → `~/.local/state/flywheel/fm8-retractions.jsonl`
  - quarantine → `~/.local/state/flywheel/fm8-quarantine.jsonl`
  - fuckup-log → `~/.local/state/flywheel/fuckup-log.jsonl` (severity=high)
- Schema: `fm8-detect-fix/v1`
- Exit codes: 0/1/2/3 (clean / detected+apply / usage / detected+dry-run)
- Configurable paths via env vars FM8_RETRACTIONS, FM8_QUARANTINE, FM8_FUCKUP_LOG

### Dispatcher intercept

`doctor fm8` routes to new function before portable_doctor; existing `doctor`,
`doctor fm5`, `doctor fm10` invocations preserved.

## 2 round-trip test cases verified live

| Case | Input | Detected | Retraction | Quarantine | Fuckup-log | rc |
|---|---|---|---|---|---|---|
| INPUT-DEAF + apply | chevron=true + no input-ack | true | written | written | written | 1 |
| Clean + dry-run | chevron=true + input-acknowledged in tail | false | n/a | n/a | n/a | 0 |

Triple-ledger discipline verified: all 3 ledgers populate on detection.

## Why triple-ledger (vs .2.3's single retraction)

Shape B input-deaf class needs orch-notification (fuckup-log severity=high) +
state machine entry (quarantine) so subsequent dispatch attempts can
short-circuit. .2.3's FM-5/FM-10 are pure audit-only retraction; this is the
**audit-only-retraction-plus-quarantine-plus-fuckup-notify** template for
Shape B FMs requiring orch attention.

## Sister-bead progressive status

| Sub-bead | Status |
|---|---|
| .2.1 chokepoint | ✓ shipped |
| .2.2 doctor undo | ✓ shipped |
| .2.3 FM-5 + FM-10 (audit-only retraction) | ✓ shipped |
| .2.5 FM-8 input-deaf quarantine | ✓ THIS BEAD |
| .2.4 FM-6 + FM-9 byte-exact undo class | UNBLOCKED |
| .2.6 real fixture data | UNBLOCKED (FM-5/FM-8/FM-10 logic now exercisable) |

## Scorecard contribution

| Dim | Pre-.2.5 | .2.5 | Post-.2.5 |
|---|---|---|---|
| 7. Single mutate chokepoint (FM-8 triple-ledger discipline) | 575 | +25 | 600 |
| 9. FM coverage (10 seed) | 850 | +50 | 900 |

Pass-2 cumulative: **5650 → 5725** (target 5950; margin 225 via .2.4/.2.6)

## Compliance

- AG receipt: 10/10
- META-RULE 2026-05-11: 40th application
- L52: 0 new beads filed
- Boundary preservation: only flywheel-loop chokepoint module extension
- L107: MCP-skipped
- L61: skill substrate; canonical-sync handles AGENTS.md
- compliance_score: 1000/1000 (P1 quality bar)

## Operational impact

The substrate-self-improving loop now has THREE operational doctor probes
shipping the FM-detect-then-fix pattern:
- FM-5 (stale-prompt-heartbeat) — audit-only retraction
- FM-10 (stale-chevron-false-positive) — audit-only retraction
- FM-8 (dispatch-during-input-deaf) — audit-only retraction + quarantine + fuckup-notify

Future Shape B FMs requiring orch-notification can adopt the triple-ledger
template:
1. Read source row (dispatch/validation-tail)
2. Detect predicate
3. On apply: append retraction + quarantine + fuckup-log rows
4. Exit code 1 signals detected+remediated

flywheel-loop binary: 1295 → 1394 lines (+99 lines).

## JSM discipline

`.flywheel` skill UNMANAGED. Direct mutation + paired jsm-import-ready patch
at `.flywheel/audit/flywheel-oxzyr.2.5/jsm-import-ready-patch.md`.

`no_direct_skill_mutation_reason=skill_unmanaged_direct_mutation_with_paired_jsm_import_ready_patch`
