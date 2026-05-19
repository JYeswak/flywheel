---
title: "Parallel-Impl Validators Self-Validate via P2 Receipts"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Parallel-Impl Validators Self-Validate via P2 Receipts

Version: `parallel-impl-self-validates-via-output-comparison/v1`
Owner: any orchestrator shipping a protocol-validator under
`cross-orch-anti-divergence-v1.0.0`
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.110 (memory-without-cross-link wire-in)
Sister bead: flywheel-2xdi.109 (dispatch-post-send silent-deaf class)

## TL;DR

When two implementations of the same protocol-validator (drift detector,
schema validator, lint checker) BOTH publish standardized JSON output
to a shared receipts directory, comparing their outputs surfaces
impl-level divergence within minutes — even when the inputs are clean.
The first bilateral run IS the validation, not just a smoke test. If
outputs disagree on any structured field, either there is an impl bug
OR the schema underspecifies that field. Fix once + re-run = bilateral
PASS.

## Canonical memory source

This doctrine summarizes
`feedback_drift_detector_self_validates_via_p2_receipts.md` — the
META-RULE memory documenting the
`parallel-impl-self-validates-via-output-comparison` canonical workflow.
Known exemplar: drift-detector v1 bilateral run 2026-05-10T18:27Z (3-min
discovery of `shared_surfaces` jq logic bug; 30-sec fix; zero downstream
impact). Read the memory for full timing detail and below-trauma-class
tracking context.

## The pattern

### Why it works

A shared receipts dir + a standardized output schema (e.g.,
`cross-orch-canonical-cli-drift-run/v1`) constrains the shape of each
impl's emit. Without standardized output, no comparison. With it, every
field becomes a comparison axis. Two impls running against the same
input either agree (= protocol implemented correctly in both) or
disagree (= bug somewhere, hunt-and-fix).

### Bilateral validation primitive

```bash
# Impl A (e.g., skillos's node)
node skillos/scripts/canonical-cli-drift-detector.js > /tmp/a.json
# Impl B (e.g., flywheel's bash)
.flywheel/scripts/canonical-cli-drift-detector.sh > /tmp/b.json
# Compare — any structured-field divergence is a finding
diff <(jq -S 'del(.ts, .orch_running)' /tmp/a.json) \
     <(jq -S 'del(.ts, .orch_running)' /tmp/b.json)
```

Strip impl-local fields (timestamps, orch-running identity) and compare
the canonical-output subset. A diff means a finding. No diff means
bilateral PASS.

### Disagreement triage

If outputs disagree on a structured field:

1. **Impl bug** — most common. File a P3-trivial bead, fix the offending
   impl (30 sec for the `shared_surfaces` jq logic bug; canonical
   exemplar), re-run, confirm PASS.
2. **Schema underspecification** — if BOTH impls produce defensible-but-
   different outputs, the schema needs a P3 spec edit. Tightens the
   contract for future impls.

### Output-shape contract field

Every parallel-impl ratified under
`cross-orch-anti-divergence-v1.0.0` MUST emit:

- `schema_version: "<protocol-id>/v<N>"`
- Standardized core fields (e.g., `shared_surfaces`, `drift_detected`,
  `findings_count`, `findings: []` for the drift detector)
- Impl-local annotations (e.g., `orch_running`) clearly partitioned

Output shape is the comparison surface; without it the workflow does
not work.

## Anti-pattern

Treating the first bilateral run as a "smoke test that should pass"
instead of as the actual validation. This blinds the team to silent
divergence in clean-input cases (the drift-detector caught its bug on
clean inputs — both impls returned valid-looking JSON; only the
field-by-field comparison surfaced the mismatch).

## Behavioral vs name cross-linking

This doctrine doc gives the memory a **name cross-link** so
gap-hunt-probe's memory-without-cross-link class clears. The memory's
discipline was ALREADY embedded behaviorally — `.flywheel/scripts/canonical-cli-drift-detector.sh`
header cites "P2 drift detector — bilateral parity with skillos's node
impl" + schema_version `cross-orch-canonical-cli-drift-run/v1` —
and the cross-orch protocols registry at
`~/.local/state/cross-orch-protocols/registry.jsonl` records the P2
ratification. But the probe's name-grep didn't see those as
citations of the meta-rule's CLASS name.

This is the SAME shape as flywheel-2xdi.109's silent-deaf-class
doctrine: the discipline lived in the dispatch template's
`VERIFY-CALLBACK BLOCK` for ≥6 reference instances, but the probe's
name-grep didn't see that as a citation. MistyCliff's `flywheel-xbsd8`
captures this **semantically-embedded-discipline blind spot** for
faqj2 next-tick to harvest.

See `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md`
for the immediate sister precedent.

## Sister doctrine

- `.flywheel/scripts/canonical-cli-drift-detector.sh` (runtime
  enforcement of the bilateral-validation contract; P2 protocol)
- `~/.local/state/cross-orch-protocols/registry.jsonl`
  (cross-orch-anti-divergence-v1.0.0 ratification record)
- `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md`
  (sister memory-without-cross-link wire-in; same
  semantically-embedded-discipline pattern)
- `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`
  (sister boundary doctrine)
- Memory `feedback_drift_detector_self_validates_via_p2_receipts`
  (above-cited canonical source)

## Conformance

A protocol's parallel-impl pair proves conformance via:

- Both impls emit `schema_version` matching the protocol-id contract
- A shared receipts directory hosts both impls' outputs
- A bilateral diff (post strip-impl-local-fields) runs at first ship
- Any disagreement files a P3-trivial fix bead with the divergent field
  name as the title prefix
- Cross-orch protocols registry records the protocol ratification

## Below-trauma-class tracking

Currently one confirmed exemplar (drift-detector v1 `shared_surfaces`
jq logic bug, 2026-05-10T18:27Z). 4-instance trauma class promotion
threshold not met. Track via fuckup-log if recurs:
`failure_class=parallel_impl_bilateral_divergence_<field-name>`.

Sister behavioral exemplar (skillos's detector `orch_running: null`
bug, flagged via Agent Mail letter, bilateral over 6h gate) is part of
the same class but tracked under skillos's repo.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
