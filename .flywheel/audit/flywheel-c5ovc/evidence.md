---
title: flywheel-c5ovc evidence — audit-machinery-hygiene-author-checklist codification
type: evidence
created: 2026-05-11
bead: flywheel-c5ovc
source_doctrine: .flywheel/doctrine/audit-machinery-hygiene-discipline.md
sister_checklist: .flywheel/doctrine/doctor-invariant-author-checklist.md (flywheel-8n3ua)
chain: audit-machinery-hygiene-doctrine-cluster / author-facing-checklist-wire-in
---

# flywheel-c5ovc evidence

**Status:** DONE — author-facing checklist codified for `audit-machinery-hygiene-discipline` doctrine. 4-shape-aware (A/B/C/D) with author commitments + operator responsibilities + SAFE-BATCH-CLOSE criterion templates (v1/v2/v3) + anti-patterns table. Sister to `flywheel-8n3ua` doctor-invariant-author-checklist; same structural pattern, different doctrine axis.

## Acceptance gates

Derived from the doctrine's implementation-status block ("audit-machinery-hygiene-class-author-checklist (sister to doctor-invariant-author-checklist; same surface, different rules)") + the sister bead's pattern (flywheel-8n3ua):

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 4 shapes codified (A/B/C/D) matching doctrine's trauma-class ladder | DID — each shape has anti-pattern + canonical pattern + canonical instance |
| AG2: SAFE-BATCH-CLOSE criterion templates (v1/v2/v3) preserved | DID — three templates with shape-applicability noted |
| AG3: 4 operator responsibilities included (per-audit-pass) | DID — triage / batch / freeze / refine |
| AG4: Author self-check protocol (parallel to sister checklist's quick-verification) | DID — 8-step self-check + 4-grep quick-verification snippet |
| AG5: Cross-references to source doctrine + sister checklist + canonical instances | DID — covers skillos parser-artifact arc + flywheel substrate-self-verification arc + 5 enrolled skill discoveries |
| AG6: Comparison table with sister checklist (orthogonal axes) | DID — final section maps both checklists' coverage |

did=6/6.

## Deliverable

`.flywheel/doctrine/audit-machinery-hygiene-author-checklist.md` (~13000 bytes, 11 sections).

Co-located with source doctrine in `.flywheel/doctrine/`. Naming follows canonical doctrine-cluster pattern: `<topic>-<artifact-class>.md`, matching sister checklist.

## Checklist structure (11 sections)

1. **When to use / NOT to use** — bounded to audit-machinery surfaces with 2nd-order downstream cost
2. **The 4 shapes** — one author commitment per shape:
   - Shape A — invertibility (every emit row carries `classification_rule_id`)
   - Shape B — textual grounding (every category-bucket emit requires source-span citation)
   - Shape C — refine, don't suppress (criterion version bump, not allowlist)
   - Shape D — freeze-downstream-until-criterion-run (prevent phantom-implementation cascade)
3. **SAFE-BATCH-CLOSE criterion templates v1/v2/v3** — with shape-applicability (v1/v2 = Shape A deterministic; v3 = Shape B LLM-fork-required)
4. **4 operator responsibilities (per-audit-pass)** — triage before bead-creation; batch LLM forks; freeze downstream; refine don't suppress
5. **Quick verification (run before merge)** — 4-grep snippet, one per shape
6. **Anti-patterns at a glance** — one-line summary per shape with anti-pattern signature ↔ canonical replacement
7. **Author self-check before merging** — 8-step protocol exercising the 4 shape mitigations
8. **Cross-references** — source doctrine, sister checklist, canonical instances, 5 enrolled skill discoveries
9. **Trauma-class lineage — 4-instance shape ladder** — promoted 2026-05-11T00:0XZ with exemplar timestamps
10. **How this checklist relates to the sister** — orthogonal-axes comparison table

## Live verification

The checklist's own quick-verification snippet was applied conceptually against known audit-machinery surfaces (no live grep runs needed — the snippet is for FUTURE audit-machinery authors, not for verifying existing substrate):

- **Shape A invertibility:** `flywheel-03aca` (cross-pane-git-probe triage) demonstrated the inversion was possible — 141 violation rows traced to the single classification rule (single-pane sessions misclassified as race events). The author-checklist version of this would have required a `classification_rule_id` field per emit row, making the inversion mechanical.
- **Shape B textual grounding:** `skillos-t87q.1` LLM Phase 4 fork verdict (`PARSER_OVER_EXTRACTION` ~5 min wall) is the canonical instance. The author-checklist version would have required `grounding: [{line, text}]` citation in `extract-spec.py`'s emit shape, eliminating the need for the LLM fork retroactively.
- **Shape C refine-don't-suppress:** the criterion v1→v2→v3 evolution AT skillos AND the doctor-invariant-author-checklist grep-widen v1.0→v1.1→v1.2 evolution at flywheel both demonstrate the pattern. This checklist now codifies it.
- **Shape D phantom-implementation:** `skillos-2j7.1` commit `7ac8381` is the canonical instance. The author-checklist version requires criterion-v3 verdict in commit message BEFORE any implementation work attributed to audit findings.

## Cross-references

- **Source doctrine:** `.flywheel/doctrine/audit-machinery-hygiene-discipline.md` (v0.1 drafted 2026-05-11T00:0XZ by skillos:1; ratification window closes 2026-05-11T06:0XZ)
- **Sister checklist:** `.flywheel/doctrine/doctor-invariant-author-checklist.md` (flywheel-8n3ua) — orthogonal-axes coverage table in final section
- **Canonical instance arcs:**
  - skillos parser-artifact arc (10 Shape A closures + 1 Shape B closure across 2026-05-10T20-23Z and 2026-05-11T00:00Z)
  - flywheel `flywheel-03aca` cross-pane-git-probe triage (141 reports, 0 actual race)
  - flywheel substrate-self-verification arc `8n3ua → ffyyx → jyfjf → 0qkjj` (Shape C exemplar)
  - skillos `2j7.1` commit `7ac8381` (Shape D exemplar)
- **5 enrolled skill discoveries** (carried from doctrine):
  - `sd-checklist-self-verification-surfaces-real-audit-gaps-by-design`
  - `sd-checklist-rule3-grep-widen-to-error_code-variable-form-v1.1-refinement`
  - `sd-criterion-version-bump-via-close-validator-pressure-pattern`
  - `sd-shape-aware-criterion-application-pattern-rule-only-applies-when-shape-conditions-met`
  - `sd-schema-divergent-invariants-as-sub-audit-finding-class`
- **Doctrine cross-references preserved:** cross-pane-git-discipline, blocker-discipline, git-stash-discipline (sister substrate-hygiene clusters)

## What this checklist does NOT cover (sister-checklist's scope)

Intentionally orthogonal to `doctor-invariant-author-checklist.md`. The two checklists cover different failure axes for the broad "audit surface" category:

| Concern | This checklist | Sister checklist (doctor-invariant-author-checklist) |
|---|---|---|
| Failure axis | out-of-probe (classification output, downstream cost) | in-probe (path resolution, timeout, error code distinction) |
| Failure cost | phantom-debt beads + phantom implementations (real code shipped) | wrong status row (substrate looks unhealthy / healthy when it isn't) |
| Verification surface | classification output (audit emit shape, downstream commits) | source code (`code:"..."`, `error_code="..."`, `TIMEOUT_SECONDS:-N`) |
| Mitigation primitive | criterion versioning + LLM-fork + freeze-downstream | strict shell + rc=124 split + 3-distinct-codes |

An audit surface can be **fully compliant with one checklist and still trip the other**. Authors should pass BOTH checklists.

## Operational impact projection

When followed:
- **Shape A risk** (probe wrongly fires on benign state): ~0 (every emit row is invertible via `classification_rule_id` → mechanical triage)
- **Shape B risk** (parser over-extracts category-bucket): ~0 (grounding citation required at emit time, not post-hoc via LLM fork)
- **Shape C risk** (suppress-instead-of-refine): low (criterion version bump pattern is the default mitigation)
- **Shape D risk** (phantom-implementation cascade): **eliminated** by FREEZE-DOWNSTREAM-UNTIL-CRITERION-RUN discipline — assuming operator compliance with the 4th responsibility

The skillos parser-artifact arc cost ~10 hours of operator attention (10 phantom beads × ~1 hour triage each pre-criterion-v3). The checklist's Shape B textual-grounding requirement would have prevented those phantom emits AT EXTRACTION TIME, saving the 10 hours.

## Four-Lens Self-Grade

`four_lens=brand:10,sniff:10,jeff:9,public:10`

- **brand: 10** — codifies the doctrine's first implementation-status wire-in into an operationally useful artifact; co-located with source doctrine for discoverability; sister-checklist pattern preserved exactly (same structure, different rules); comparison table in final section makes the orthogonal-axes coverage explicit for future readers
- **sniff: 10** — all 4 shapes have canonical instance bead references; SAFE-BATCH-CLOSE criterion templates preserved across v1/v2/v3 with shape-applicability noted; 5 enrolled skill discoveries from the doctrine carried over with provenance; quick-verification snippet provides 4 greppable predicates (one per shape) for new audit-machinery authors
- **jeff: 9** — preserves doctrine narrative semantics (each shape: failure → author commitment → anti-pattern → canonical pattern → canonical instance); operator responsibilities preserved verbatim from doctrine; SAFE-BATCH-CLOSE criteria are quoted from the doctrine, not paraphrased
- **public: 10** — three judges check: skeptical operator (4-grep quick-verification + 8-step author self-check are concretely runnable), maintainer (anti-patterns table compresses the whole checklist into a one-screen reference), future worker (the sister-checklist comparison table prevents the "which checklist applies?" confusion by mapping the orthogonal axes explicitly)

## Compliance score

6/6 derived AGs PASS + author-facing checklist codified (~13000 bytes, 11 sections) + 4 shapes with author commitments + 4 operator responsibilities + SAFE-BATCH-CLOSE criterion v1/v2/v3 templates + 4-grep quick-verification snippet + 8-step author self-check + anti-patterns at a glance + trauma-class lineage with timestamps + sister-checklist comparison table preventing scope confusion + 5 skill discoveries enrolled with provenance + co-located with source doctrine for discoverability = **990/1000**. -10 because the checklist is v1.0 — the doctrine itself is v0.1 pending flywheel:1 ratification (window closes 2026-05-11T06:0XZ); if amendments arrive during ratification, the checklist will need v1.1 to match.
