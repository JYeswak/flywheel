---
bead: flywheel-16b53.3
title: cross-repo-write-path-discipline doctrine (P0 trauma-mitigation-C)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P0
mission_fitness: adjacent
parent: flywheel-16b53 (P0 trauma-class investigation)
cohort: 16b53.1 + 16b53.2 + 16b53.3 (3-mitigation cohort)
trauma_class: absolute-path-construction-drift-to-peer-canonical-substrate
---

# Journey: flywheel-16b53.3

## What the bead asked for

P0 trauma-mitigation-C — author the canonical doctrine documenting the
trauma class identified in flywheel-16b53. Companion to mitigation-A
(16b53.1: orch-side OWNED_WRITE_ROOTS block) and mitigation-B (16b53.2:
pre-write-path-guard.sh tool primitive). The doctrine layer makes the
discipline auditable and references the existing primitives.

## What I shipped

**3 artifacts:**

- **`.flywheel/doctrine/cross-repo-write-path-discipline.md`** (~200 lines, 10 sections):
  TL;DR / Canonical memory source / The trauma class (3 sub-sections) /
  4 discipline rules / 6 cross-references / Mitigation cohort status /
  Trauma-class observability (fuckup-log JSON schema) / What this doctrine
  is NOT / Acceptance evidence / Frontmatter

- **`.flywheel/doctrine/README.md`** (catalog update):
  `total_doctrines: 89 → 90`, `canonical_doctrines: 80 → 81`,
  `last_added: cross-repo-write-path-discipline (flywheel-16b53.3 P0 trauma-mitigation-C)`

- **`.flywheel/audit/flywheel-16b53.3/evidence.md`** + this journal

## 3-layer P0 trauma defense now complete

| Layer | Sub-bead | Artifact | Status |
|---|---|---|---|
| Orch (dispatch packet declares write-scope) | 16b53.1 | OWNED_WRITE_ROOTS block in canonical dispatch-template + worker-tick.md pre-Write check ref | ✓ shipped |
| Tool (runtime enforcement at every Write) | 16b53.2 | `pre-write-path-guard.sh` + `cli_pre_write_check()` helper + 12-AG test (incl. v38e1.5 exact trauma repro AG12) | ✓ shipped |
| Doctrine (auditable trauma-class codification) | 16b53.3 (this) | `cross-repo-write-path-discipline.md` with 4 rules + 6 cross-refs + observability schema | ✓ shipped |

## Key design decisions

### 1. Rule 4 explicitly subordinates Rule 2

The most important load-bearing decision in the doctrine: **even if a path
appears in OWNED_WRITE_ROOTS, Rule 4 (substrate-class read-only) wins for
Class 2 peer-orch substrate.** This prevents a future worker from
"authorizing" a write into skillos/mobile-eats/etc. via allowlist
manipulation. The v38e1.5 trauma is framed as a Rule 4 violation,
not just a Rule 2 violation — anchoring the discipline in substrate-class
ownership, not just path-string matching.

### 2. AGENTS.md catalog surface honestly resolved

Bead body acceptance said "AGENTS.md catalog updated with the new doctrine
entry." Inspection of AGENTS.md showed it catalogs L-rules (L29, L61, L96,
L132, etc.), not doctrines. The doctrine catalog is auto-materialized at
`.flywheel/doctrine/README.md` via `ls -1 .flywheel/doctrine/*.md`.

Routed the catalog update through the correct surface (README frontmatter
count) rather than fabricating an inappropriate AGENTS.md entry. Documented
this honestly in evidence.md AG14 + L61 receipt.

### 3. Reciprocal cross-reference discipline

6 cross-references authored in this doc; rationale provided for which
require reciprocal back-refs (none of the 6 do at this time) and the
condition under which a future bead would file the back-ref work (per
L96 3-surface-diff rule).

### 4. Trauma-class observability schema

Future occurrences of this trauma class get logged with a 9-field JSON
shape (`class=cross_repo_write_path_drift`, severity, trauma_root_bead,
doctrine_ref, dest_path, dest_toplevel, expected_toplevel, guard_invoked,
guard_outcome, recovery_path). This makes the trauma class
**permanently observable** — promotion-candidate-to-L-rule logic per L56
(8-strike threshold) can run against this schema.

## Source-incident fidelity

Doctrine cites the exact 16b53 incident numbers from the live evidence pack:
- 9 skillos canonical doctrine files + 1 README clobbered
- 905 lines deleted + 148 lines stub inserted (net -757L)
- Recovery via skillos:1 `git stash push -u -m '<exact message>'`
- Stash entry `stash@{0}`
- Full command for reproducing the diff: `git -C /Users/josh/Developer/skillos stash show --stat 'stash@{0}'`

No fabricated numbers. Per Axiom 22 (Research Before Propose): single-source
(16b53 evidence pack itself), but the source is the canonical authority for
its own incident, so triangulation is not required.

## Compliance

- AG receipt: 14/14
- L96 3-surface-diff: PASS (doctrine + catalog + evidence)
- L61 doctrine-landing-wires-into-AGENTS-and-README: routed correctly
- META-RULE 2026-05-11: 48th application
- L52: 0 new beads (cohort complete)
- L107: NONE_NEW_FILE_CREATE_PLUS_OWNED_AUDIT_DIRS
- L120: br close before callback (will execute)
- compliance_score: 1000/1000

## Mission coherence

`mission_fitness=adjacent`. Direct completion of the 16b53 P0 trauma
3-mitigation cohort. Closes the trauma class at the doctrine layer.
Combined with 16b53.1 + 16b53.2, the absolute-path-construction-drift
class is now blocked at orch declaration + tool runtime enforcement +
auditable discipline — the canonical defense-in-depth pattern.

## What's next (not in this bead's scope)

- The `cross-repo-consumer-vs-mutator-boundary.md` and
  `substrate-boundary-three-class-taxonomy.md` sister doctrines could add
  reciprocal "see also" links pointing back to this doctrine. Per L96,
  that would be a separate bead with its own 3-surface diff. Not filed.
- The trauma-class fuckup-log schema would benefit from a validator
  helper (`.flywheel/scripts/log-cross-repo-write-path-drift.sh`) that
  enforces the 9-field shape. Not in this bead's scope; could be a
  future 16b53.4 if pattern recurrence justifies it.
- L-rule promotion candidate: the cross-repo-write-path-discipline doctrine
  is a candidate for L-shard promotion per L56 ladder once N≥8
  fuckup-log occurrences accumulate. Tracked in observability section.

## Operational pattern reinforced

This is the 3rd canonical doctrine authored in the v38e1+16b53 wave
(after closure-evidence-contract-version-anchor, inbox-discipline,
outbox-discipline). The scaffold-doc-frontmatter + 10-section pattern +
3-surface-diff discipline is now thoroughly exercised and forms the
canonical "trauma-class → doctrine doc" worker-tick template.
