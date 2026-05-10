---
title: "Refine r2 - Skill Injection Gate"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Refine r2 - Skill Injection Gate

Plan arc: `mission-lock-paradigm-extension-2026-05-06`
Task: `plan-mission-lock-paradigm-extension-phase2-refine-r2-2026-05-06`
Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r2-2026-05-06`
Phase: Phase 2 REFINE, round 2
Scope: plan-space-only
Date: 2026-05-06

This round absorbs Finding 4, row 154:
`dispatch-systematically-under-injects-skills`.

Round 1 already established the triple-gate shape:

1. Mission-lock gate.
2. Dispatch-author gate.
3. Close-validator gate.

Round 2 keeps that shape and widens the dispatch-author gate. The dispatch
gate is no longer only "load-bearing work needs a skill suite." It is now
"every bead gets a universal skill floor, then bead-class routing adds
domain-specific skills, and the dispatch packet self-tests that the routing
actually happened."

## 1. Diff vs r1

Added:

1. Finding 4 integration into the dispatch-author gate.
2. A two-tier skill injection model:
   - Tier 0: universal-class skills on every bead.
   - Tier 1: bead-class defaults selected from bead tags, touched files, and
     mission surfaces.
3. A required skill discovery receipt for dispatch authoring.
4. A dispatch self-test gate requiring at least three named skills, universal
   coverage, class relevance, catalog existence, and Socraticode evidence.
5. A skillos coordination touchpoint for Phase 4 before any `/flywheel:dispatch`
   amendment is written.
6. Catalog health risk: two packet-named skill tokens are not clean exact
   routes today:
   - `simplify` has no exact skill directory; closest concrete routes are
     `code-simplifier` and `simplify-and-refactor-code-isomorphically`.
   - `schema-complete-drift-guard` has no exact skill directory in the local
     skill roots.

Modified:

1. Dispatch-author gate expands from `load_bearing=true -> skills required` to
   `all_beads -> universal skill floor -> bead-class skill set`.
2. The r1 `load_bearing_skills` field becomes one member of a broader routing
   envelope:
   - `universal_skills`
   - `bead_class`
   - `bead_class_skills`
   - `load_bearing_skills`
   - `skill_discovery_receipt`
   - `dispatch_skill_self_test`
3. Phase 4 implementation order changes. The dispatch amendment now depends on
   a skillos template contract ack, not a flywheel-only hand-written template.
4. Phase 3 audit must validate skill catalog truth, not only the plan wording.

Removed:

None. R1 remains the base artifact. R2 is an additive refinement, not a
replacement or scope expansion into code-space.

Diff size read:

R2 is not converged yet. It adds a new finding class and changes the dispatch
gate semantics from conditional to every-bead. That is materially above the
5 percent convergence threshold. `convergence_streak` stays `0` for this round.

## 2. Finding 4 Integration Into Dispatch-Author Gate

Finding 4 says dispatches systematically under-inject skills. The fix is not
"remember to add skills." It needs to be a dispatch-author rule with a validator
and a data receipt.

The dispatch-author gate should run this sequence before a worker packet is
sent:

```text
bead metadata
-> classify bead class
-> query skill-search / local skill catalog
-> select universal skills
-> select bead-class skills
-> add load-bearing skills if applicable
-> run dispatch self-test
-> write skill discovery receipt into packet
-> send packet only if gate passes
```

### Tier 0 - Universal-Class Skills

Every bead dispatch names the universal set and either routes each skill or
records a machine-readable not-applicable/alias reason:

| Skill token | Current catalog check | Gate expectation |
|---|---|---|
| `canonical-cli-scoping` | Exact skill exists; skill-search route returned `blocked_no_source`. | Required when any CLI, script, command, operator contract, or dispatch surface is touched; Phase 3 must decide whether route health failure blocks dispatch. |
| `readme-writing` | Exact skill exists and skill-search route is fresh. | Required for README, docs, doctrine, plan, or user-facing explanatory surfaces. |
| `de-slopify` | Exact skill exists and skill-search route is fresh. | Required for public or durable prose. |
| `simplify` | No exact skill; aliases exist as `code-simplifier` and `simplify-and-refactor-code-isomorphically`. | Phase 4 should route to a concrete existing skill or ask skillos for an alias contract. |
| `socraticode` | Exact skill exists and route is fresh. | Always required for non-trivial dispatch; zero-query callbacks remain invalid. |

The important change is that universal skills are not advisory prose. They
become dispatch packet data.

Required packet fields:

```json
{
  "skill_routing": {
    "universal_skills": [],
    "bead_class": "",
    "bead_class_skills": [],
    "load_bearing_skills": [],
    "skill_discovery_receipt": {},
    "dispatch_skill_self_test": {}
  }
}
```

### Tier 1 - Bead-Class Defaults

The first five bead-class sets are:

| Bead class | Default skill set | Current catalog status |
|---|---|---|
| `frontend-real-data-flip` | `tanstack`, `error-handling-patterns`, `cors-configuration`, `request-validation`, `web-visual-qa` | All exact skill directories found. |
| `backend-endpoint` | `python-best-practices`, `api-design-patterns`, `authentication-authorization`, `pagination-filtering`, `rate-limiting`, `request-response-logging` | All exact skill directories found. |
| `substrate-fix` | `gh-actions`, `infisical-secrets`, `railway-api`, `vercel`, `security-audit-for-saas`, `infisical-rotation-ops` | All exact skill directories found. |
| `db-migration` | `safe-migrations`, `supabase-postgres-best-practices`, `schema-complete-drift-guard` | First two exact directories found; `schema-complete-drift-guard` missing. |
| `saas-intelligence` | Per-surface mapping from Lane B `skill-arsenal-by-surface`. | Lane B found enough substrate; Phase 4 should consume the mapping rather than recreate it. |

Class detection inputs:

1. Bead labels and title tokens.
2. Touched file prefixes.
3. Mission-lock declared surfaces.
4. Socraticode hits against prior similar work.
5. Explicit worker packet override with reason.

### Skill Discovery Receipt

Every dispatch packet should include a receipt like:

```json
{
  "source": ["skill-search", "local-skill-roots", "socraticode"],
  "catalog_stats": {
    "indexed_skills": 455,
    "filesystem_skills": 463,
    "drift_count": 8,
    "freshness_pct": 79.0,
    "route_gate_enabled": true
  },
  "queries": [],
  "selected": [],
  "aliases": [],
  "missing": [],
  "skipped_with_reason": []
}
```

The receipt exists to prevent two silent failures:

1. The dispatch names no skills because the author forgot.
2. The dispatch names skills that do not exist or are not routeable.

### Dispatch Self-Test Gate

Minimum gate:

1. `named_skill_count >= 3`.
2. `socraticode` is present and the packet requires concrete queries.
3. Universal-class set is represented.
4. Bead-class set is represented unless class is explicitly unknown.
5. Each selected skill has one of:
   - `exact_catalog_match=true`
   - `alias_to_existing_skill=<name>`
   - `missing_skill_followup=<bead-or-skillos-candidate>`
6. Any missing exact skill either fails the packet or creates a same-tick
   follow-up under skillos, depending on Phase 3 decision.

This is Meadows #5: the rule changes dispatch authority. It is also Meadows #6:
the routing evidence moves into the packet before the worker starts.

## 3. Skillos Coordination Touchpoint

R2 should not make flywheel the producer of canonical skill-routing templates.
Flywheel owns dispatch consumption. Skillos owns reusable skill template shape.

Phase 4 must coordinate with `skillos:1` before editing the dispatch surface.
The touchpoint should use
`~/.local/state/flywheel/cross-orch-coordination.jsonl` and a flywheel:1 ->
skillos:1 packet.

Ready-to-implement capsule:

```json
{
  "event": "skill_injection_template_consumer_ready",
  "consumer": "flywheel:1",
  "producer": "skillos:1",
  "plan": "mission-lock-paradigm-extension-2026-05-06",
  "need": "dispatch packet skill-routing template and schema contract",
  "inputs": [
    "bead_title",
    "bead_body",
    "labels",
    "touched_files",
    "mission_surfaces",
    "load_bearing_classifier"
  ],
  "outputs_required": [
    "universal_skills",
    "bead_class",
    "bead_class_skills",
    "aliases",
    "missing_skills",
    "skill_discovery_receipt",
    "dispatch_self_test"
  ],
  "consumer_surfaces": [
    "/flywheel:dispatch markdown packet",
    "dispatch callback contract",
    "close-validator skill receipt fields"
  ]
}
```

Required skillos ack:

1. Template path or API surface.
2. Schema version.
3. Alias policy for `simplify`.
4. Missing-skill policy for `schema-complete-drift-guard`.
5. Example invocation against at least one bead class.
6. Known limitations and freshness semantics.

Until that ack exists, Phase 4 may prepare a consumer-side integration plan but
should not write the final `/flywheel:dispatch` amendment.

## 4. Net Delta After r1 + r2

Findings absorbed:

| Row | Gap class | Gate touched |
|---|---|---|
| 151 | `mission-lock-undersells-design-system-substrate` | Mission-lock. |
| 152 | `mission-lock-must-elicit-negative-invariants` | Mission-lock. |
| 153 | `load-bearing-substrate-shipped-without-skill-suite` | Dispatch-author and close-validator. |
| 154 | `dispatch-systematically-under-injects-skills` | Dispatch-author. |

Net shape:

1. Gate count remains three.
2. Dispatch-author gate gains two layers:
   - every-bead universal skill floor
   - bead-class defaults
3. Close-validator must verify skill receipts for both universal and
   class-specific skills, not only load-bearing skills.
4. Mission-lock remains the upstream source of surfaces and negative
   invariants; it should not own the skill catalog.
5. Phase 4 implementation DAG gains a coordination dependency on skillos before
   dispatch amendment.

Counts after r2:

| Measure | r1 | r2 |
|---|---:|---:|
| Cross-orch findings absorbed | 3 | 4 |
| Mission-lock amendment groups | 6 | 6 |
| Dispatch-author amendment groups | 5 | 8 |
| Close-validator amendment groups | 5 | 6 |
| Explicit bead-class skill sets | 0 | 5 |
| Universal skill tokens | 0 | 5 |
| Skillos coordination dependencies | 0 | 1 |

This preserves orthogonality: the plan still concerns mission readiness,
dispatch quality, and evidence-based closeout. It does not drift into the
orch-heartbeat event-driven plan or into skillos template authoring.

## 5. Convergence Test For r3

R3 can claim convergence only if these checks are true:

1. No new cross-orch finding class is added.
2. The three-gate shape is unchanged.
3. The skillos coordination contract is either acked or the remaining change is
   only field-name mapping.
4. Universal skill floor remains five tokens or has documented alias decisions.
5. Bead-class defaults remain five classes or change by less than 5 percent of
   routed skill rows.
6. The dispatch self-test remains semantically unchanged.
7. Open Phase 3 audit questions shrink; they do not introduce a fourth gate.

Mechanical r3 rule:

```text
if semantic_delta_vs_r2 < 5%:
  convergence_streak = 1
else:
  convergence_streak = 0
```

Recommended exit rule:

Two consecutive refine rounds under 5 percent, or one under-5-percent round plus
a Phase 3 audit disposition of `converged_with_known_implementation_questions`,
is enough to move to Phase 4 decomposition.

Current r2 result:

`convergence_streak=0` because row 154 materially changes dispatch-author
semantics.

## 6. Sibling-Shape With Prior Plan-Arcs Today

Capacity-halt sibling:

1. Started with scattered blocker/idle symptoms.
2. Refined into a smaller number of structural gates.
3. Phase 4 decomposed only after the rules and evidence boundaries stabilized.
4. This arc follows the same "doctrine first, implementation second" pattern.

Orch-heartbeat sibling:

1. Started as a heartbeat/no-idle-projects plan.
2. Phase 4 decomposed into a 9-bead DAG.
3. Phase 5 polished toward event-driven state changes.
4. This arc is narrower: it does not decide when to regenerate prompts; it
   decides what readiness and skill evidence must be in the prompt before work
   starts and before DONE is accepted.

Skillos relationship:

1. Flywheel consumes skill-routing templates in dispatch packets.
2. Skillos owns reusable skill taxonomy/template production.
3. The coordination edge is a healthy cross-orch dependency, not a blocker on
   plan-space r2 completion.

Donella sibling read:

1. #6 Information Flows: skill evidence must move earlier.
2. #5 Rules: dispatch cannot proceed without a skill routing receipt.
3. #4 Self-Organization: missing skills route to skillos instead of being
   hand-waved in the worker packet.

## 7. Open Questions For Phase 3 Audit

1. Should `canonical-cli-scoping` route health `blocked_no_source` block a
   dispatch, warn, or force a local SKILL.md read fallback?
2. Should the universal `simplify` token be renamed to `code-simplifier`,
   `simplify-and-refactor-code-isomorphically`, or kept as an alias owned by
   skillos?
3. Should missing exact skills like `schema-complete-drift-guard` fail the
   packet immediately or create a same-tick skillos candidate and allow dispatch
   with `safe-migrations` plus `supabase-postgres-best-practices`?
4. Where does bead-class detection live: `/flywheel:dispatch`,
   `gsd-planner`, a skillos template API, or a shared helper consumed by all
   three?
5. What is the prompt-budget cap for skill injection, and when should a packet
   include skill names only versus excerpts?
6. How does close-validator prove a skill was actually applied rather than
   merely named in the dispatch?
7. Should universal skills allow `not_applicable`, or does every bead require
   every universal token with an explicit alias/skip receipt?
8. How does Phase 4 avoid skill bloat for tiny single-file or <20-line edits
   while preserving the row 154 finding?
9. Should `saas-intelligence` stay as a bead class or become a mission-lock
   surface family sourced entirely from Lane B?
10. Does the dispatch self-test create follow-up beads through flywheel, skillos,
    or the target repo when the missing skill is domain-specific?

## Evidence

Socraticode preflight:

1. `dispatch systematically under injects skills row 154 universal class skills bead class defaults skillos coordination`
2. `mission lock paradigm extension refine r1 dispatch author gate load bearing skill suite gsd planner classifier`
3. `skill injection template skillos flywheel dispatch packet skill catalog universal skills socraticode readme-writing canonical-cli-scoping`
4. `bead specific skills every dispatch dispatch self-test gate at least 3 skills named universal skills present`
5. `canonical cli scoping readme writing de slopify simplify socraticode dispatch required skills`
6. `frontend real data flip tanstack error handling cors request validation web visual qa skill default dispatch`
7. `backend endpoint python best practices api design authentication pagination rate limiting request response logging dispatch skills`
8. `substrate fix gh actions infisical secrets railway vercel security audit infisical rotation skill defaults`
9. `db migration safe migrations supabase postgres schema complete drift guard dispatch skills`
10. `saas intelligence skill arsenal by surface lane b adopt extend avoid skill mapping mission lock`

Observed index status: green, 951 indexed chunks.

Skill-search observed:

1. Catalog healthy enough to route (`qdrant_health=true`, `ollama_health=true`).
2. Route gate enabled.
3. 455 indexed skills, 463 filesystem skills, drift count 8.
4. Freshness 79 percent, below the 80 percent target but above fail threshold.
5. Most packet-named skill sets exist; exact gaps are documented above.

L112 target:

`OK_mission_lock_paradigm_phase2_r2`
