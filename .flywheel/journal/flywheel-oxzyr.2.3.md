---
bead: flywheel-oxzyr.2.3
title: FM-5 + FM-10 detect/fix invariants (audit-only retraction class)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
parent: flywheel-oxzyr.2 (3 sister sub-beads remain)
scorecard_contribution: +150 actual (Dim 1 +25 + Dim 2 +50 + Dim 9 +75)
---

# Journey: flywheel-oxzyr.2.3

## What the bead asked for

P1 — implement FM-5 + FM-10 detect/fix invariants (audit-only retraction class)
for flywheel-loop. 3rd of 6 sub-beads from oxzyr.2 decomposition.

## What I shipped

### `_flywheel_loop_fm5_detect_fix()` — stale-prompt-heartbeat
- Detect: cur tick_prompt_sha256 == prior + wake_class=="heartbeat"
- Fix: audit-only retraction to ~/.local/state/flywheel/fm5-retractions.jsonl
- Schema: fm5-detect-fix/v1 | Exit codes: 0/1/2/3

### `_flywheel_loop_fm10_detect_fix()` — stale-chevron-false-positive
- Detect: chevron_visible + submits-work signal in validation-tail
- Fix: audit-only retraction to ~/.local/state/flywheel/fm10-retractions.jsonl
- Schema: fm10-detect-fix/v1 | Exit codes: 0/1/2/3

### Dispatcher intercepts
- `doctor fm5` and `doctor fm10` route to new functions before portable_doctor
- Other doctor invocations route normally

## 4 round-trip test cases verified live

| FM | Case | Detected | Retraction Written | rc |
|---|---|---|---|---|
| FM-5 | STALE+apply | true | true | 1 |
| FM-5 | Clean | false | n/a | 0 |
| FM-10 | FP+apply | true | true | 1 |
| FM-10 | Clean | false | n/a | 0 |

Both positive AND negative cases verified. Retraction ledgers populated
correctly. canonical-CLI-scoping yes (--help/--json/--dry-run/--apply + exit codes).

## Sister-bead progressive status

| Sub-bead | Status |
|---|---|
| .2.1 chokepoint | ✓ shipped |
| .2.2 doctor undo | ✓ shipped |
| .2.3 FM-5 + FM-10 | ✓ THIS BEAD |
| .2.4 FM-6 + FM-9 byte-exact | UNBLOCKED (sister-shape to .2.3) |
| .2.5 FM-8 input-deaf quarantine | UNBLOCKED |
| .2.6 real fixture data | progressively unblocked |

## Scorecard contribution

| Dim | Pre-.2.3 | .2.3 | Post-.2.3 |
|---|---|---|---|
| 1. Detect coverage | 725 | +25 | 750 |
| 2. Fix coverage | 450 | +50 | 500 |
| 9. FM coverage | 775 | +75 | 850 |

Pass-2 cumulative: **5500 → 5650** (target 5950; margin 300 via .2.4/.2.5/.2.6)

## Compliance

- AG receipt: 10/10
- META-RULE 2026-05-11: 39th application
- L52: 0 new beads filed
- Boundary preservation: only flywheel-loop chokepoint module extension
- L107: MCP-skipped
- L61: skill substrate; canonical-sync handles AGENTS.md
- compliance_score: 1000/1000 (P1 quality bar)

## Operational impact

FM-5 + FM-10 are the audit-only retraction template. Future audit-trail-class
FMs can adopt this shape:
1. Read source row (dispatch/recovery candidate)
2. Detect predicate
3. Append retraction row to dedicated ledger
4. Exit code signals detected (1=retracted, 3=dry-run-detected, 0=clean)

The substrate-self-improving loop now has TWO operational doctor probes that
ship the FM-detect-then-fix-as-audit-only-annotation pattern.

flywheel-loop binary: 1147 → 1295 lines (+148 lines).
