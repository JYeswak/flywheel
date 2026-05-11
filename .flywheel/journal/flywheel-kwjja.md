---
bead: flywheel-kwjja
title: faqj2 finding-type-extension decision — Option D (accept FP rate)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi (faqj2 calibration class)
sister: flywheel-xbsd8 (OPEN, preserved as evidence anchor), flywheel-2xdi.117
decision: Option D — accept FP rate; document rationale + revisit triggers
---

# Journey: flywheel-kwjja

## What the bead asked for

Decide A/B/C/D for the memory-without-cross-link semantic gap:
- A: discipline-token extraction
- B: widen corpus to dispatch templates
- C: semantic cross-link metric
- D: accept FP rate (recipe at N=4 is cheap)

## Decision: D — empirical rationale

Looked at the 5 doctrine docs I shipped this session:
- 2xdi.93 cross-repo-consumer-vs-mutator-boundary
- 2xdi.109 dispatch-post-send-verification-silent-deaf
- 2xdi.116 jeff-corpus-substrate-lifecycle
- 2xdi.118 jsm-canonical-auth-contract
- 2xdi.127 api-additive-compat-both-empty-either-empty

Only ONE (2xdi.109 dispatch-post-send) was embedded in dispatch
templates and would have been resolved by Option B. The other 4
required novel doctrine writing regardless. So Option B's empirical
benefit is ~20%; the doctrine docs themselves are independently
valuable artifacts (canonical write-ups + Jeff-precedent quotes +
sister cross-refs + conformance checklists).

The probe is "working as intended" — it identifies memories that
lack canonical doctrine cross-links. The right fix is to CREATE the
cross-link, not weaken the probe.

## What I shipped

`.flywheel/scripts/gap-hunt-probe.sh` — added 40-line decision
comment block inside `probe_memory_without_cross_link()`:
- Class taxonomy documented (name-grep-only by design)
- Known FP class enumerated (semantically embedded; future-proposed)
- Decision (Option D) with 4-point rationale
- 3 when-to-revisit triggers (volume / marginal-return / cluster-specific)
- Sister findings preserved as open beads (xbsd8 + 2xdi.117)

No probe behavior change. No regression test required.

## Verification

- Probe syntax: OK
- Decision comment present: 2 mentions of "kwjja decision\|Option D"
- Memory-without-cross-link count: 20 (unchanged — decision is doc-only)

## L112 probe

    grep -c "kwjja decision\|Option D" .flywheel/scripts/gap-hunt-probe.sh

Expected: `literal:2`.

## Pattern note

Bead doesn't add a new fix shape; it CALIBRATES the probe class
taxonomy. This is the **first probe-self-aware-decision** bead
shipped in the 2xdi.* + kwjja arc — a written, codified, when-to-
revisit-stamped decision about how the probe should behave.

The N=5 doctrine docs are now sanctioned at the probe layer as the
operational answer to memory-without-cross-link. Future workers
shipping doctrine docs are operating with explicit authority.

## When the decision flips

Documented 3 concrete revisit triggers in the probe comment:
1. Volume: ≥10 memory-without-cross-link beads in single tick
2. Marginal-return: doctrine docs become repetitive without novel content
3. Cluster-specific: any surface generates ≥3 same-class FPs in one week

If any trigger fires, revisit and consider Options A/B/C surgically.
