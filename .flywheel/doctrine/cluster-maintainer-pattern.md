---
title: "Cluster-Maintainer Pattern: Batch SKILL.md Doc Completeness"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Cluster-Maintainer Pattern: Batch SKILL.md Doc Completeness

Version: `cluster-maintainer-pattern/v1`
Owner: orchestrator (cluster bead author) + workers (batch executor)
Status: canonical, shipped 2026-05-11 (N=3 promotion-confirmed)
Source bead: flywheel-r9pri (N=3 doctrine-promotion)

## TL;DR

When the gap-hunt-probe surfaces **N≥2 wired-but-cold beads in the same skill
substrate** (same `~/.claude/skills/<x>/` tree, same fix shape), package
them into **ONE cluster-maintainer bead** instead of working them
individually. The cluster bead's worker authors a single SKILL.md mutation
covering all N targets + paired patch artifact + N-subordinate-bead bulk
close.

Per kwjja Option D precedent: this is the **cheapest mechanization** that
moves substrate forward (one SKILL.md mutation vs N individual
single-script doc-fix beads; one paired patch artifact vs N artifacts; one
worker context-load vs N).

## N=3 promotion (canonical exemplars)

| # | Bead | Skill substrate | Pre→Post coverage | Sub-beads bulk-closed |
|---|---|---|---|---|
| 1 | `flywheel-03yaj` | research-triad (jsm-unmanaged) | 5/31 → 31/31 | 4 (2xdi.121/.122/.123/.124) |
| 2 | `flywheel-xhevf` | agent-ergonomics-cli-max (jsm-managed) | partial → cluster-aware | patch-only artifact (Skillos handoff) |
| 3 | `flywheel-plue9` | skill-builder (jsm-unmanaged) | 4/10 → 10/10 | 2 retrospectively closed |

N=3 = 3-strike skill-promotion threshold met. Pattern is canonical for any
subsequent multi-script cluster surfaced by gap-hunt-probe.

## The recipe (formal, 4 steps)

**Trigger:** orch (or worker auditing) discovers ≥2 wired-but-cold beads
targeting the same `~/.claude/skills/<x>/` substrate, same fix shape
(typically "SKILL.md doesn't document scripts/* operator tools").

### Step 1 — File the cluster-maintainer bead

Title format: `[<skill-name>-cluster-doc-completeness]` (research-triad and
plue9 precedents) OR `[skill-hygiene] <skill> SKILL.md should document ...
cluster (N+ flagged)` (xhevf precedent).

Body MUST include:
- **Substrate classification**: jsm-unmanaged Joshua-domain / jsm-managed
  Skillos-substrate / Jeff Premium AUDIT-ONLY (per cross-repo-consumer-vs-
  mutator-boundary doctrine)
- **Joshua-authorized cross-repo block** IF substrate is jsm-unmanaged
  (cites prior precedent: n4gt1 + myfak.1 + d6zk1.1, all PERFECT 1000)
- **Cluster scope**: which sub-beads are subordinate, which sibling
  scripts are flagged-but-not-yet-beaded
- **Cite N=3 precedent**: link 03yaj + xhevf + plue9 + r9pri (this
  doctrine)
- **Acceptance gates** including "auto-close all subordinate auto-beads
  with `resolved-upstream-via-<cluster-bead>` disposition"

### Step 2 — Dispatch to worker with cluster context warm

Dispatch packet should include:
- The cluster scope from Step 1 body
- The 4-step recipe (or cite this doctrine doc)
- Joshua-authorized cross-repo block if applicable
- Standard worker-tick contract (SKILL-ENHANCE JSM DISCIPLINE BLOCK)

### Step 3 — Worker writes paired patch artifact

For **jsm-unmanaged** substrate (e.g., research-triad, skill-builder):
- Direct mutation of `~/.claude/skills/<x>/SKILL.md`
- Paired jsm-import-ready patch artifact at
  `.flywheel/audit/<cluster-bead>/patches/` (SKILL.md.original +
  SKILL.md.proposed + SKILL.md.patch + apply-instructions.md)
- `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_
  ready_patch_artifact_written`

For **jsm-managed** substrate (e.g., agent-ergonomics-cli-max):
- NO live mutation
- Patch-only artifact at `.flywheel/audit/<cluster-bead>/patches/`
- `no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`
- `flywheel_orch_action_required=jsm_push_<cluster-bead>_patch_to_skillos`

For **Jeff Premium AUDIT-ONLY** substrate:
- AUDIT-ONLY worker tick — investigation pack at
  `.flywheel/audit/<cluster-bead>/findings.md`
- No mutation; deliverable is the audit (cite SD if discovered)

### Step 4 — Auto-close subordinate auto-beads

Per-bead probe BEFORE close (anti-pattern guard, per bead-hypothesis
META-rule): verify each sub-bead's target is now in SKILL.md and no
longer flagged by fresh gap-hunt-probe.

For each cleared sub-bead:
```bash
br close <sub-bead-id>
```

Note the closure pattern in the cluster bead's callback: `beads_updated=
<comma-list-of-closed-sub-beads>`. Each sub-bead gets `resolved-upstream-
via-<cluster-bead>` disposition in its close notes (where supported).

## Why batch vs N individual

Empirical comparison (from 03yaj's evidence pack):

| Metric | N individual sub-beads | 1 cluster bead |
|---|---|---|
| Worker context-load | N× | 1× |
| Patch artifacts | N | 1 |
| Evidence packs | N | 1 |
| Skillos handoff (if jsm-managed) | N handoffs | 1 unified handoff |
| Discovery surface | N small additions | 1 comprehensive table |

For 03yaj: 26 missing scripts in 7 capability-cluster tables landed in
one SKILL.md mutation. If filed as 26 individual sub-beads, the
per-bead overhead would have been ~26× the cluster overhead.

## Anti-pattern guard

**Don't bundle prematurely.** Per `feedback_decompose_by_natural_unit_not_
bundle`, bundling is justified ONLY when:
- All artifacts share the same upstream owner (same skill substrate)
- All artifacts share the same timeframe (same probe-tick window)
- All artifacts share the same fix shape (same recipe applies)

If any of these break (different skills, different timeframes, different
fix shapes), file individual beads.

## Sister doctrine + memory

- `feedback_decompose_by_natural_unit_not_bundle` — bundling discipline
  (this doctrine's gating rule)
- `feedback_cross_repo_consumer_vs_mutator_distinction` — substrate
  classification (jsm-managed vs jsm-unmanaged)
- `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md` —
  the canonical write-up of the cross-repo discipline this pattern relies on
- `flywheel-pmg3c` (sister N=4 promotion: forward-link-doctrine-doc-recipe
  auto-injector) — same promotion shape; sister mechanism

## Auto-detection (future enhancement, filed as follow-up)

Option B (cluster-detection in gap-hunt-probe) is a candidate enhancement:
the probe would detect N≥2 wired-but-cold in same `~/.claude/skills/<x>/`
and emit ONE cluster bead instead of N individual ones. This would
mechanize the cluster-bead-filing step (Step 1 above).

Cost-benefit (per kwjja Option D precedent): doctrine doc shipped FIRST
(this doc); auto-detection filed as a follow-up bead for future
prioritization. The doctrine doc is the cheapest mechanization that
moves substrate forward.

Filed as `flywheel-<new-id>` (see callback for ID).

## Conformance

A cluster-maintainer bead proves conformance via:
- Body cites this doctrine + at least one of the N=3 exemplars (03yaj/xhevf/plue9)
- Substrate classification explicit in bead body
- Joshua-authorized cross-repo block present if jsm-unmanaged
- Worker callback names the SKILL.md target + N subordinate beads closed
- Evidence pack has paired patch artifact (or jsm-managed patch-only)
- Subordinate beads closed per-bead-probed (not bulk-closed by ID)

## Lifecycle

This is canonical for batch SKILL.md hygiene work. The 4-step recipe is
empirically stable across N=3 distinct skills (research-triad,
agent-ergonomics-cli-max, skill-builder). When N=5 (next 2 instances
land), promote to skill: `pattern-emerged-cluster-maintainer-batch-
skill-doc-completeness`.
