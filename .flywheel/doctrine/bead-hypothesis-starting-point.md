---
name: bead-hypothesis-starting-point
type: doctrine
created: 2026-05-11
version: v0.1
status: codified-from-N=3-convergent-worker-recognition-2026-05-11
authority: extracted from worker convergent recognition across 3 independent bead executions (o40x0, 2xdi.47, 2xdi.49) — all by MistyCliff identity within one session
cluster: meta-extraction-drift / downstream-signal-masking-upstream-gap
sisters:
  - calibrate-test-to-actual-contract-before-filing-upstream (memory: feedback_calibrate_test_to_actual_contract_before_filing_upstream.md) — sister rule in the same META-FAMILY: "downstream signal is prior, not posterior; verify the assertion before acting on it"
canonical_memory: ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_bead_hypothesis_starting_point_not_conclusion.md
parent_bead: flywheel-2xdi.54 (auto-filed memory-without-cross-link gap)
source_beads:
  - flywheel-o40x0 (MistyCliff): "race condition" hypothesis was wrong; root cause = two-hash-domain-split; root-cause fix made AG3 moot
  - flywheel-2xdi.47 (MistyCliff): "wired-but-cold dead code" hypothesis was wrong; root cause = gap-hunt-probe blind spot to for-loop indirect sourcing; 27 lib modules reclassified
  - flywheel-2xdi.49 (MistyCliff): "wired-but-cold" hypothesis was wrong; root cause = protected-session-recovery is documented compat wrapper; SKILL.md doc IS wiring
---

# Bead Hypothesis is Starting Point, Not Conclusion

## The rule

When a bead body states a hypothesis about root cause (e.g. "race condition", "concurrent modification", "off-by-one", "wired-but-cold dead code"), treat that as a **STARTING POINT for investigation, not the conclusion**.

**Probe before implementing.** The bead author's hypothesis was authored without full evidence — your job as worker is to confirm or refute it with direct probing before applying the fix.

## Why

The bead body's hypothesis is the **downstream signal**. The actual root cause is the **upstream gap**. Treating the hypothesis as a conclusion = treating signal as cause.

Real example from flywheel-o40x0 (2026-05-11): bead body hypothesized "race condition: sync-canonical-doctrine.sh re-reads source between copy and verify, another concurrent process changed the source". Worker MistyCliff probed and discovered the actual root cause was **two-hash-domain-split** — the pre-copy and post-copy hashes were computed in different domains (different stripping/canonicalization rules), not a race at all.

If the worker had implemented the proposed AG3 (status=warn instead of status=error) per the bead's hypothesis, the symptom would have been suppressed without fixing the underlying split. **Root-cause fix made AG3 moot per Donella Meadows leverage point #5** (rules of the system: fix the structure, not the symptom).

## How to apply

1. Read the bead's hypothesis section but treat as **Bayesian prior**, not posterior.
2. Probe directly: reproduce the symptom, instrument the suspected code path, confirm or refute the hypothesis with measurement.
3. If hypothesis is wrong, find the actual root cause via first-principles tracing (not via "the bead said X so I'll fix X").
4. Apply the root-cause fix. If the root-cause fix makes a stated AG (acceptance gate) moot (like "add warn-vs-error tier"), explicitly call that out in the close — **don't ship the moot AG just to check boxes**.
5. Cite this doctrine in the close: `gaps=none` is honest only if you verified the root cause matches the fix.

## Anti-pattern

Reading bead body → implementing the bead-author's proposed fix path → closing → moving on. This produces patches at the symptom layer (high Meadows leverage number) rather than the cause layer (low leverage number).

## N=3 instances 2026-05-11 (convergent independent worker recognition — FULLY LOAD-BEARING)

| Bead | Bead Hypothesis | Actual Root Cause | Outcome |
|---|---|---|---|
| flywheel-o40x0 (MistyCliff) | "race condition between copy and verify" | two-hash-domain-split (different canonicalization rules pre/post copy) | Root-cause fix made AG3 moot; status reverted to error per Meadows #5 |
| flywheel-2xdi.47 (MistyCliff) | "wired-but-cold dead code at lib/step4i-coherence.sh" | gap-hunt-probe.sh blind spot to for-loop indirect sourcing in flywheel-loop | 27 lib modules correctly reclassified as warm; corpus capture fixed at source |
| flywheel-2xdi.49 (MistyCliff) | "wired-but-cold dead code at protected-session-recovery.sh" | Script IS a documented compat wrapper — SKILL.md doc IS the wiring | Probe's 4th corpus (SKILL.md) added; documented surfaces no longer false-positive cold |

The same worker identity (MistyCliff) hit this pattern 3 times independently across one session. Pattern is canonical-class — load-bearing META-RULE per Joshua's N=3 threshold.

## Sister cluster (test-calibration family)

Same META-FAMILY: "downstream signal masking upstream gap; verify the assertion before acting on it".

| Memory | Domain | Common shape |
|---|---|---|
| `feedback_bead_hypothesis_starting_point_not_conclusion.md` (this rule) | Bug fixes | Verify root cause before implementing the bead-author's proposed fix |
| `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md` | Test failures | Calibrate test to current upstream contract before filing "upstream bug" |

Both are concrete applications of: **the downstream signal (bead body or test assertion) is the prior, not the posterior. Probe before acting.**

## Trauma class

**META-EXTRACTION-DRIFT cluster** — "downstream signal masking upstream gap" pattern. The bead body's hypothesis is the downstream signal; the actual root cause is the upstream gap. Treating the hypothesis as conclusion = treating the signal as the cause.

## Canonical memory

`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_bead_hypothesis_starting_point_not_conclusion.md` is the authoritative source for this rule. This doctrine file is the canonical cross-link anchor; the memory file is the durable storage.

When propagating to other repos / re-authoring, treat the memory file as ground truth. Update this doctrine file when the memory updates.

## Meadows leverage point

This doctrine targets Meadows leverage point **#5 (rules of the system, scope of authority)**: the system that decides "what bead body fixes are applied as-stated vs probed-first" is itself a rule-of-the-system. Fixing the worker-behavior-rule (probe before implementing) prevents symptom-layer patches that proliferate downstream.

Related Meadows leverage points referenced:
- #6 (information flow): the bead body is the information signal; probe-before-implementing is the information-validation step.
- #5 (rules of the system): this doctrine codifies the rule that workers must validate bead-body hypotheses.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
