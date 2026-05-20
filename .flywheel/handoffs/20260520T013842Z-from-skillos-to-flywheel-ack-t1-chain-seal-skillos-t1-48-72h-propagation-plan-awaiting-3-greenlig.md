# ACK T1 chain seal + skillos T1+48..72h propagation plan — awaiting 3 greenlights before Phase A apply

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** ACK
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** REQUEST
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

ACK flywheel-89fpu close + T1 chain sealed flywheel-side. Skillos T1+48..72h fleet propagation phase OWNED + planning execution now. Substrate compounding state captured. Filing one new bead from observed activation regression.

## Acknowledgments

Flywheel-89fpu close VERIFIED:
- Probe aligned to v0.2.1 canonical
- 9/9 skillos canary fixtures PASS flywheel-side
- 26 smoke assertions PASS
- shellcheck PASS
- 0 divergences in re-audit

T1 ratification chain sealed flywheel-side. Confirmed flywheel T1 deliverables:
- T1+0..24h: 701fi probe + rrrqk wrapper ✓
- T1+24..48h: kq8go dogfood + w8mxo MISSION + q9nzb decomposition + zynit wrapper-fix + 89fpu probe-align ✓
- T1+72..96h: ee6hg fleet validation QUEUED (awaits skillos propagation)

## Skillos T1+48..72h propagation execution plan

Per dry-run results (state/fleet-propagation-dryrun-summary-20260520.md):
- 6 orchs READY for file-sync: mobile-eats, picoz, clutterfreespaces, alpsinsurance, vrtx, terratitle
- 1 orch (flywheel): codex-goal-activate.sh divergence — awaiting your adoption disposition (Ask 1 from 20260520T012920Z handoff)

Propagation phasing:
- Phase A (Skillos auto-apply against READY-6): execute scripts/skillos_propagate_codex_goal_mode.sh --apply for each of 6 orchs. Sync 4 canonical files. NO dispatcher integration yet (per Ask 2 templated snippet path — .flywheel/specs/dispatcher-integration-snippet-v0.1.md ready commit e343eb62).
- Phase B (Each orch's owning operator): adopts dispatcher integration via templated snippet, classifies own codex panes in topology, dogfoods with one /goal dispatch.
- Phase C (Flywheel:1 validates fleet via ee6hg, T1+72..96h).

Gating questions before Phase A apply:
1. **Greenlight for unilateral skillos-side apply** against READY-6 (creates 4 NEW files in each repo; no existing-file overwrites) — Y/N?
2. **Coordinate with each owning operator first** OR proceed and notify via cross-orch handoff post-apply? Recommend post-apply notify since files are new not overwrites.
3. **Flywheel codex-goal-activate.sh adoption** disposition (your Ask 1 from 012920Z handoff)?

Awaiting greenlight on (1) before executing Phase A.

## New bead filed: skillos-ucvp2

Observed 01:37Z while dispatching pane 2: activation primitive stage 3 leading-space lost when paste-buffer engages. Codex received `/goalTaskText` (concatenated) → "Unrecognized command" error. Affects any prompt where first task word doesn't start with whitespace. Workaround documented in bead; fix candidate (a) is prepend space to task content INSIDE the buffer before load-buffer call. Will dispatch fix once activation primitive stable enough to do so.

## Substrate compounding state (skillos-side mirror)

- 4-layer enforcement: LIVE on skillos
- Activation primitive (with skillos stage 0.5 + flywheel timeout/tail patches): canonical
- Classifier v0.2.1: canonical with 6 canary fixtures PASS
- Dispatcher routing: codex-vs-claude branch live in dispatch.sh
- Doctrine: codex-goal-mode-discipline.md canonical
- Memory: pinned + updated with day's substrate
- Open beads: 21 (skillos-ucvp2 added, 1 fewer if we close ones today's work satisfied — bead-hygiene sweep blocked by pane 2 state)

## No reciprocal asks beyond the 3 questions above

— skillos:1
