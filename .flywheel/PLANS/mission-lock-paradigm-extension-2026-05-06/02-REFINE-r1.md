---
title: "Refine r1 - Substrate-Quality-Gate Triple"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Refine r1 - Substrate-Quality-Gate Triple

Plan arc: `mission-lock-paradigm-extension-2026-05-06`
Task: `plan-mission-lock-paradigm-extension-phase2-refine-r1-2026-05-06`
Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r1-2026-05-06`
Phase: Phase 2 REFINE, round 1
Scope: plan-space-only
Date: 2026-05-06

This refinement absorbs Phase 1 Lane A/B/C and the third cross-orch substrate
finding into one three-gate doctrine extension:

1. Mission-lock gate: prevent a project from declaring ready-to-build while
   substrate artifacts, negative invariants, data lifecycle, trap siblings, and
   failure modes remain implicit.
2. Dispatch-author gate: prevent load-bearing work from being dispatched
   without an explicit skill suite and load-bearing classifier.
3. Close-validator gate: prevent DONE from being accepted by callback trust
   alone or without proof the required load-bearing skills were applied.

## 1. Triple-Gate Doctrine Summary

The plan arc should not treat rows 149, 151, 152, and 153 as separate repairs.
They describe the same system defect at three different checkpoints:

| Gate | Primary input | Trauma class | Required doctrine change |
|---|---|---|---|
| Mission-lock | rows 151 and 152 | `mission-lock-undersells-design-system-substrate` plus `mission-lock-must-elicit-negative-invariants` | Lock-time must emit substrate, invariant, lifecycle, skill, and failure-mode receipts before "ready to build." |
| Dispatch-author | row 153 | `load-bearing-substrate-shipped-without-skill-suite` | Dispatch packets and bead metadata must classify load-bearing work and inject the correct skills before workers start. |
| Close-validator | row 149 | `orch-trust-trap-agentmail-as-completion-signal` | Close handlers must validate evidence and skill application, not trust a callback envelope alone. |

The gates form one feedback loop:

```text
mission-lock names required substrate
-> dispatch-author maps substrate work to skill suite
-> worker applies skills and reports receipts
-> close-validator verifies evidence and skill receipts
-> gaps reopen as supplement beads instead of being silently accepted
```

Donella read:

- Meadows #6 Information Flows: missing substrate and missing skill application
  become visible in artifacts, dispatch packets, and callbacks.
- Meadows #5 Rules: "locked", "ready", "dispatched", and "DONE" receive
  stricter meanings.
- Meadows #4 Self-Organization: validators and doctors route gaps to beads,
  skillos, or redispatch supplements without waiting for Joshua.

## 2. Mission-Lock Gate Extension

Phase 1 converged on an additive extension to `/flywheel:mission-lock`, not a
replacement. The existing senior-dev-stack capture remains the base. The new
gate adds six evidence-bearing sections from Lane C and makes rows 151/152
machine-visible.

Required mission-lock additions:

1. `Section U - Substrate Scaffolding Requirement`
   - For each declared surface, require a substrate inventory before feature
     work.
   - The row 151 default artifact list is: design tokens, theme projection,
     UI primitives, composition primitives, behavior config, CI gates,
     identity layer, SEO metadata, density caps, and domain substrate.
   - Missing blocking artifacts must be generated now, converted to Phase 0
     beads, or marked not applicable with evidence.
2. `Section V - Failure-Mode Audit Per Substrate`
   - Every adopted substrate needs default lie, proof signal, refusal
     condition, repair route, and durable receipt path.
   - Generated lock text is not proof; readiness doctor evidence is proof.
3. `Section W - Data-Lifecycle Invariants`
   - Each data object needs source of truth, empty state, error state,
     forbidden fallback, freshness policy, create/update/delete/archive
     ownership, and seed/demo labeling.
   - Runtime fallback data is forbidden unless the mission explicitly marks a
     non-launch demo surface.
4. `Section X - Negative Invariants`
   - Capture per-surface "must never ship" rules.
   - Minimum invariants: no runtime fallback data, no launch-path mocks, no raw
     secrets in logs or callbacks, no unlabeled demo data, no feature work
     before required substrate is beaded or present, and no ready-to-build claim
     without readiness receipt.
5. `Section Y - Trap-Class Cross-References`
   - Link sibling lies such as runtime fallback, mocked E2E, transport ack as
     success, design-token drift, and credential-safety drift.
   - Each trap needs forbidden substitutes and a proof signal.
6. `Section Z - Skill-Arsenal-By-Surface Mapping`
   - Bind skills to surfaces before dispatch.
   - Every surface needs ADOPT/EXTEND/AVOID, `NONE_FOUND` plus skillos
     candidate, or `NOT_APPLICABLE` with reason.

The mission-lock gate should refuse `status=locked` or `ready_to_build=true`
when a blocking launch surface lacks one of the six sections, unless the gap is
converted to a bead with parentage and priority. For legacy locks, the first
release posture should be `audit_only` with explicit `ready_to_build=false`
where blocking gaps are found.

Mission-lock amendment count: 6.

## 3. Dispatch-Author Gate Extension

Row 153 proves that a lock-time substrate plan is insufficient if the dispatch
packet does not carry the right execution intelligence. Dispatch authoring needs
a load-bearing classifier, a required skill-suite block, and bead metadata that
survives planning, ready selection, and close validation.

Load-bearing classifier criteria:

1. The work creates or changes a database table read by features.
2. The work changes RLS, auth, authz, identity, session, or entitlement paths.
3. The work handles money, tokens, credentials, PII, PHI, regulated data, or
   customer trust surfaces.
4. The work creates an idempotency, retry, queue, webhook, scheduler, or
   side-effect control path.
5. The work changes a CI gate, quality gate, or deploy-blocking check.
6. The work implements MISSION-named substrate or Phase 0 foundation.
7. The work sits on a hot path or many downstream consumers depend on it.
8. The work is load-bearing documentation or an operator contract per L81.

Dispatch template amendments:

1. Add a `load_bearing` field to every generated bead and dispatch packet:
   `true`, `false`, or `unknown_requires_classifier`.
2. Add `load_bearing_reasons` as a short list of matched classifier criteria.
3. Add `required_skills` with the suite selected by surface.
4. Add `skill_application_required=true` when `load_bearing=true`.
5. Add a `worker_callback_must_include` block naming
   `load_bearing_skills_applied`.

Default required skill suites:

| Surface | Required skills |
|---|---|
| Substrate quality | `ubs`, `simplify-and-refactor-code-isomorphically`, `extreme-software-optimization`, `multi-pass-bug-hunting` |
| Database and migrations | `database-modeling`, `database-operations`, `safe-migrations`, `supabase-postgres-best-practices` |
| Webhooks and idempotency | `webhook-automation`, plus database/idempotency skills when stateful |
| Security and trust | `security-review`, `security-audit-for-saas`, `security-pen-testing` where applicable |
| Performance | `performance-review` for hot paths and fanout surfaces |
| Operator and consumer contract | `canonical-cli-scoping`, `readme-writing` for load-bearing CLI, script, schema, and module families |
| Audit and convergence | `codebase-audit`, `audit-preparation`, `jeff-convergence-audit` when a change claims broad coverage |

`gsd-planner` should classify candidate beads during graph build and expose the
field to dispatch selection. `br ready --load-bearing` is the desirable
operator shape, but Phase 4 should verify current bead tooling before naming the
exact CLI contract. Until then, JSONL bead rows can carry the metadata without
requiring a bead DB schema migration.

Dispatch amendment count: 5.

## 4. Close-Validator Gate Extension

Row 149 and L91 show that transport receipts and callback envelopes are weak
signals. Close validation must join three sources:

1. Declared dispatch contract: `load_bearing`, `required_skills`, acceptance,
   and expected evidence.
2. Returned worker callback: `load_bearing_skills_applied`, tests, file
   changes, bead routing, and callback delivery verification.
3. Independent evidence: filesystem state, test output, pane state transition,
   JSONL closure rows, or validator receipt.

Required callback envelope for load-bearing work:

```text
load_bearing=true
load_bearing_reasons=<criteria-list>
required_skills=<skill-list>
load_bearing_skills_applied=<skill:applied|not_applicable|blocked,...>
skill_evidence=<path-or-command-summary>
non_applied_skill_reason=<only if not_applicable or blocked>
```

Close-handler rules:

1. If `load_bearing=true` and `load_bearing_skills_applied` is missing, close
   fails even when tests pass.
2. If a required skill is marked `not_applicable`, the callback must state why
   the surface does not apply.
3. If a required skill found no issues, the callback must include a clean
   rationale, not an empty checklist.
4. If evidence is absent or contradicted by filesystem/test state, close fails
   and the orchestrator performs completion-by-evidence investigation.
5. If the original worker completed useful work but skipped the skill suite,
   reopen the original bead or file a supplement bead rather than redoing the
   whole task.

Reopen-and-redispatch supplement protocol:

```text
close-validator detects missing skill application
-> original bead remains closed only for already-validated work, or is reopened
   if acceptance depended on the missing skill
-> supplement bead names missing skills and exact surface
-> dispatch-author emits skill-suite-only packet
-> close-validator requires `load_bearing_skills_applied` before final DONE
```

This matches the mobile-eats 1gqt.17 mid-flight supplement shape and generalizes
it into a close-handler rule.

Close-handler amendment count: 5.

## 5. Scaffold-Validator + Readiness-Doctor Scripts

Phase 4 should implement two scripts, both read-only by default and canonical
CLI compliant per Lane B/L82.

### `mission-lock-scaffold-validator.sh`

Purpose: make the row 151 substrate artifact list mechanically visible at init
and mission-lock time.

Required canonical surface:

```text
mission-lock-scaffold-validator.sh --info --json
mission-lock-scaffold-validator.sh --examples --json
mission-lock-scaffold-validator.sh quickstart --json
mission-lock-scaffold-validator.sh help substrate --json
mission-lock-scaffold-validator.sh schema doctor --json
mission-lock-scaffold-validator.sh doctor --repo <repo> --mission <MISSION.md> --json
mission-lock-scaffold-validator.sh health --repo <repo> --json
mission-lock-scaffold-validator.sh validate substrate --repo <repo> --mission <MISSION.md> --json
mission-lock-scaffold-validator.sh audit --repo <repo> --json
mission-lock-scaffold-validator.sh why <artifact-class> --repo <repo> --json
mission-lock-scaffold-validator.sh repair --scope scaffold --repo <repo> --dry-run --json
mission-lock-scaffold-validator.sh completion bash|zsh
```

Top-level JSON fields:

```json
{
  "schema_version": "mission-lock-scaffold-validator.v1",
  "command": "doctor",
  "repo": "/abs/path",
  "mission_path": "/abs/path/.flywheel/MISSION.md",
  "status": "pass|fail|warn",
  "blocked_lock": true,
  "summary": {
    "required_count": 10,
    "present_count": 0,
    "missing_count": 0,
    "not_applicable_count": 0,
    "beaded_count": 0
  },
  "probes": {},
  "missing_artifacts": [],
  "present_artifacts": [],
  "not_applicable_artifacts": [],
  "beaded_artifacts": [],
  "next_actions": []
}
```

The ten probe names should be stable: `design_tokens`, `theme_projection`,
`ui_primitives`, `composition_primitives`, `behavior_config`, `ci_gates`,
`identity_layer`, `seo_metadata`, `density_caps`, and `domain_substrate`.

### `mission-lock-readiness-doctor.sh`

Purpose: audit new and existing mission locks against the six completeness
sections, the scaffold validator receipt, and bead routing coverage.

Required canonical surface:

```text
mission-lock-readiness-doctor.sh --info --json
mission-lock-readiness-doctor.sh --examples --json
mission-lock-readiness-doctor.sh quickstart --json
mission-lock-readiness-doctor.sh help readiness --json
mission-lock-readiness-doctor.sh schema doctor --json
mission-lock-readiness-doctor.sh doctor --repo <repo> --json
mission-lock-readiness-doctor.sh health --repo <repo> --json
mission-lock-readiness-doctor.sh validate lock --repo <repo> --json
mission-lock-readiness-doctor.sh audit --repo <repo> --json
mission-lock-readiness-doctor.sh why <section-or-gap-class> --repo <repo> --json
mission-lock-readiness-doctor.sh repair --scope amendments --repo <repo> --dry-run --json
mission-lock-readiness-doctor.sh completion bash|zsh
```

Top-level JSON fields:

```json
{
  "schema_version": "mission-lock-readiness-doctor.v1",
  "command": "doctor",
  "repo": "/abs/path",
  "mission_path": "/abs/path/.flywheel/MISSION.md",
  "status": "pass|fail|warn",
  "completeness_pct": 0,
  "ready_to_build": false,
  "current_phase": "audit_only|blocking|legacy",
  "missing_sections": [],
  "incomplete_sections": [],
  "substrate_readiness": {},
  "negative_invariants_coverage": {},
  "trap_cross_refs_coverage": {},
  "skill_surface_map_coverage": {},
  "data_lifecycle_coverage": {},
  "failure_mode_audit_coverage": {},
  "bead_routing_coverage": {},
  "suggested_amendments": [],
  "bead_routes": []
}
```

The readiness doctor is the safer backfill primitive. It should never rewrite
legacy MISSION files unless a later propagation bead explicitly authorizes an
apply mode with an idempotency key.

Scripts proposed: 2.

## 6. Cross-Gate Integration

The three gates should share one metadata vocabulary:

| Field | Produced by | Consumed by |
|---|---|---|
| `substrate_scaffolding` | mission-lock | scaffold validator, dispatch-author |
| `negative_invariants` | mission-lock | readiness doctor, dispatch-author, close-validator |
| `data_lifecycle` | mission-lock | readiness doctor, dispatch-author |
| `skill_surface_map` | mission-lock | dispatch-author |
| `load_bearing` | dispatch-author / bead graph | worker callback, close-validator |
| `load_bearing_reasons` | dispatch-author | close-validator, audit reports |
| `required_skills` | dispatch-author | worker callback, close-validator |
| `load_bearing_skills_applied` | worker callback | close-validator |
| `ready_to_build` | readiness doctor | orchestrator dispatch license |

The desired fail-closed chain:

```text
mission-lock missing required substrate
-> readiness doctor says ready_to_build=false
-> dispatch-author refuses feature work or emits Phase 0 substrate bead
-> worker applies required skills
-> close-validator accepts only evidence-backed DONE
```

The desired fail-soft legacy chain:

```text
legacy lock lacks six sections
-> readiness doctor status=warn/fail audit_only
-> suggested amendments and bead routes are emitted
-> existing work may continue only where dispatch-author proves the touched
   surface is not blocked by the missing section
```

This keeps row 151/152 strict for new locks while avoiding broad, hidden
rewrites across already-running projects.

## 7. Open Questions For Phase 3 Audit

1. Should row 154, the broad `dispatch-systematically-under-injects-skills`
   finding, be absorbed into this plan arc now or become a sibling dispatch
   author plan arc after skillos coordination?
2. What exact line separates load-bearing documentation under L81 from ordinary
   explanatory docs that do not need the full skill suite?
3. Should `load_bearing` be stored first in JSONL bead rows only, or should the
   bead DB schema migrate in the same Phase 4 wave?
4. What is the minimum acceptable proof that a skill was applied without
   turning callbacks into cargo-cult checklists?
5. Should `readme-writing` and `canonical-cli-scoping` be mandatory for all
   load-bearing beads or only for CLI/script/module-family surfaces?
6. What is the legacy repo mode for new feature dispatches when readiness
   doctor says `audit_only` but a missing section affects the touched surface?
7. Should scaffold validator `--apply` generate placeholders, or should every
   missing artifact route through explicit Phase 0 beads to preserve plan-space
   review?
8. How should mission-lock capture external research evidence without bloating
   lock artifacts beyond what workers can reliably read?
9. What truth-source pair is enough for data lifecycle readiness: live API plus
   E2E, schema plus owned fixture, or operator proof plus probe?
10. Should close-validator reopen original beads or always file supplements
    when skill-suite evidence is missing after useful implementation landed?
11. How should skillos candidate routing be represented when `NONE_FOUND`
    appears in `skill_surface_map`?
12. Which acceptance tests should be live probes rather than fixtures to avoid
    repeating the "fixture path passed, live path bypassed" failure class?

Open questions for Phase 3 audit: 12.

## 8. Sibling-Shape References

Adopted shapes:

- `mission-anchor-init`: keep mission anchor state and validation history as the
  base primitive.
- `testing-real-service-e2e-no-mocks`: pair no-mocks with no-runtime-fallback
  as the same synthetic-data trap class.
- `security-audit-for-saas` and `security-posture`: reuse invariant extraction
  and credential/secrets probe posture.
- `canonical-cli-scoping`: required for both proposed scripts and load-bearing
  operator surfaces.
- `beads-workflow`: lock-time gaps route to beads instead of prose debt.
- `agent-mail`: reservations and callback identity are coordination substrate,
  but not completion proof.
- `quality-bar-close-gate.sh`: close/readiness gate shape that reads evidence,
  emits JSON reasons, and refuses on missing critical proof.
- `watcher-isomorphic-probe.sh`: top-level status plus named probe object shape
  for the scaffold validator.
- `capacity-halt` Phase 4 success-measurement: success is measured by post-send
  state, not transport ack.
- `orch-heartbeat` Phase 4/5 plan arc: useful sibling for event-driven
  information flow, but not the same intervention.

Relevant L-rules and doctrine:

- L50: dispatch-time Socraticode survey.
- L51: file reservations before edits.
- L52: findings become beads or explicit no-bead reason.
- L56: fuckup-log to INCIDENTS to L-rule ladder.
- L71: validate and redispatch discipline.
- L81: docs can be load-bearing.
- L82: canonical CLI scoping.
- L91: four-state delivery receipt and completion-by-evidence.
- L96: doctrine lands across root/canonical/template surfaces.
- L111: real-time quality bar on every work body.

## 9. Net Delta Vs Orch-Heartbeat Plan Arc / Orthogonality

The orch-heartbeat plan arc and this mission-lock extension are orthogonal.

Orch-heartbeat answers:

```text
When state changes, how does the orchestrator regenerate prompts and keep
projects from idling?
```

Mission-lock substrate-quality gates answer:

```text
Before work is dispatched or closed, how does the system know the substrate is
complete, the right skills were applied, and DONE is evidence-backed?
```

Shared substrate:

- Both use Meadows #6 information flows.
- Both reject transport acknowledgement as sufficient proof.
- Both benefit from event/state ledgers and JSON receipts.
- Both should emit structured fields usable by doctors and morning reports.

Net delta from orch-heartbeat:

- New upstream gate at mission-lock time.
- New dispatch-author classifier for load-bearing work.
- New close-validator envelope for skill-suite evidence.
- New readiness/scaffold doctors for lock-time completeness.
- New supplement redispatch rule for missing skill application.

Do not collapse these arcs. Orch-heartbeat may later consume
`ready_to_build=false`, `load_bearing=true`, or missing-skill signals as prompt
regeneration inputs, but it is not the source of truth for substrate quality.

## Phase 3 Audit Handoff

Phase 3 should audit the exact text and field names before implementation. The
risk is over-broad process bloat: every gate must close a proven failure mode
from rows 149, 151, 152, or 153. The strictness should be highest for new locks
and load-bearing substrate, and audit-only for legacy repos until a propagation
bead chooses otherwise.

Recommended audit focus:

1. Confirm `cross_orch_findings_absorbed` remains `[151, 152, 153]` for this
   plan state, while row 149 is a sibling close-validator doctrine input and
   row 154 remains an open Phase 3 coordination question.
2. Verify the six mission-lock sections do not duplicate existing 14-section
   mission capture.
3. Verify the load-bearing classifier catches the row 153 cases without marking
   every bead as P0.
4. Verify callback fields are short enough for workers to comply but strong
   enough for close-validation.
5. Verify both proposed scripts have testable canonical CLI surfaces before any
   implementation dispatch.
