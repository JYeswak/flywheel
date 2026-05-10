---
title: "Research A - Problem-Space Inventory"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Research A - Problem-Space Inventory

Plan arc: `mission-lock-paradigm-extension-2026-05-06`
Lane: A, problem-space inventory
Status: closed
Date: 2026-05-06

## Socraticode Survey

Required K: >=10. Completed K=10 against
`/Users/josh/Developer/flywheel`; index status was green with 945 indexed
chunks.

Queries run:

1. `mission-lock mission lock template senior dev stack capture MISSION lock fields`
2. `negative invariants no fallback real data no mocks e2e runtime data lifecycle mission lock`
3. `skills library load-bearing meta-rule mission-lock receipts adopted skill references skills-best-practices`
4. `design system substrate tokens theme shadcn primitives density caps frontend mission lock`
5. `mission lock data model governance fallback scaffold archive data lifecycle no fallback no mocks runtime`
6. `failure mode audit lying by default success measurement evidence verification capacity halt plan lock`
7. `mission lock audit gate locked declared ready build substrate incomplete Phase 0 catchup debt`
8. `trap class cross reference e2e no mocks runtime no fallback rotation consumer switch mission lock skill mapping`
9. `skill arsenal by surface mapping skills best practices mission lock sections frontend backend auth data observability`
10. `plan arc research lane A problem-space inventory taxonomy failure mode matrix Donella analysis STATE.json lane_a_status`

Relevant existing substrate surfaced:

- `templates/flywheel-install/MISSION.md.tmpl` already has a 14-section mission
  skeleton but does not force substrate artifact closure or negative invariant
  extraction.
- `INCIDENTS.md` has `mission-lock-drift-no-audit-trail`: lock evidence must be
  machine-readable, not implied by prose.
- `AGENTS.md` carries the load-bearing skills-library meta-rule: adopted skill
  references belong in mission-lock receipts, dispatch packets, or beads.
- `INCIDENTS.md` has the capacity-halt success-measurement sibling: completion
  must be measured by evidence, not by transport acknowledgement. Mission-lock
  needs the same principle for "ready to build."
- `templates/flywheel-install/polish-gate/README.md` models monotonic
  bootstrap -> audit_only -> blocking progression, useful for a future
  lock-time audit but out of Lane A implementation scope.

## Trauma Class Taxonomy

Unified trauma class:
`mission-lock-declares-readiness-without-lock-time-operational-completeness`

Tree:

```text
mission-lock-declares-readiness-without-lock-time-operational-completeness
├── lifecycle-not-locked-at-lock-time
│   ├── substrate-artifact-missing
│   │   ├── design-system-scaffold-missing
│   │   ├── frontend-behavior-config-missing
│   │   ├── identity-auth-scaffold-missing
│   │   ├── seo-metadata-baseline-missing
│   │   ├── ci-quality-gates-missing
│   │   └── domain-substrate-missing
│   └── data-lifecycle-not-locked
│       ├── scaffold-then-delete-not-scaffold-then-fallback
│       ├── real-or-error-not-demo-data
│       └── archive/retention/delete-policy-missing
├── invariant-not-locked-at-lock-time
│   ├── negative-invariant-missing
│   │   ├── no-fallback-data
│   │   ├── no-runtime-mocks
│   │   ├── no-raw-secrets-in-logs
│   │   └── density/UX caps as forever-rules
│   ├── trap-class-cross-reference-missing
│   │   ├── e2e-no-mocks <-> runtime-no-fallback
│   │   ├── transport-ack <-> recovery-success
│   │   └── credential-rotation <-> consumer-switch
│   └── failure-mode-audit-missing
│       ├── lying-by-default layer not named
│       ├── proof signal not named
│       └── refusal/repair path not named
└── intelligence-not-routed-at-lock-time
    ├── skill-arsenal-by-surface-mapping-missing
    │   ├── frontend surface skills not bound to UI surfaces
    │   ├── SaaS/domain skills not bound to workflows
    │   └── testing/runtime skills not bound to lifecycle gates
    └── readiness-information-flow-missing
        ├── "locked" has no substrate-complete proof
        ├── "ready to build" has no lock-time audit receipt
        └── downstream workers cannot see missing substrate until rework
```

Overlap notes:

- `tokens-gap` and `data-lifecycle-invariant` are both
  `lifecycle-not-locked-at-lock-time`: one is an artifact lifecycle, the other
  is a data lifecycle.
- `no mocks` and `no fallback data` are the same trap class at different layers:
  testing substrate and runtime substrate both lie when synthetic data is allowed
  to masquerade as truth.
- `density caps` appears twice: as a missing design-system substrate and as a
  negative invariant. The artifact is the implementation; the invariant is the
  rule that prevents future drift.
- `CI gates` are not merely tooling; they are the information flow that proves a
  rule is being enforced before "ready to build."

## Gap Inventory

Classes used:

- `substrate-artifact-missing`
- `negative-invariant-missing`
- `trap-class-cross-reference-missing`
- `skill-arsenal-by-surface-mapping-missing`
- `data-lifecycle-not-locked`
- `failure-mode-audit-missing`

### mobile-eats substrate gaps

| Item | Class | Why |
|---|---|---|
| `lib/design/tokens.ts` | `substrate-artifact-missing` | Design constants were known at lock time but not materialized. |
| `app/globals.css` `@theme` inline projection | `substrate-artifact-missing` | Tailwind/theme bridge absent, so token truth could not flow into UI. |
| 7 canonical shadcn primitives in `components/ui/` | `substrate-artifact-missing` | Reusable primitive layer absent before route work. |
| `_primitives/` composition layer | `substrate-artifact-missing` | Domain UI composition substrate missing above raw primitives. |
| `lib/design/behavior.ts` | `substrate-artifact-missing` | Behavior choices were implicit instead of locked as reusable config. |
| 4 CI gates: tokens-tailwind, density, purity, primitive-reuse | `failure-mode-audit-missing` | These gates are proof mechanisms for lying-by-default UI drift. |
| Identity layer scaffolding | `substrate-artifact-missing` | Auth/identity baseline absent before user-facing flows. |
| SEO + metadata baseline per route | `substrate-artifact-missing` | Route-level public contract absent before route construction. |
| Mission-locked density caps as Q-decision | `negative-invariant-missing` | "Do not exceed this density/spacing behavior" is a forever-rule, not a later taste pass. |
| Founder cohort substrate | `substrate-artifact-missing` | Domain cohort primitive not created before feature work. |
| Dispute substrate | `data-lifecycle-not-locked` | Claim/dispute objects imply lifecycle, state transitions, retention, and evidence rules. |

### alps fix categories

| Item | Class | Why |
|---|---|---|
| Data-lifecycle invariants | `data-lifecycle-not-locked` | Lock must decide scaffold -> archive/delete/error, never scaffold -> fallback. |
| Trap-class cross-references | `trap-class-cross-reference-missing` | Same lying-by-default class appears in test and runtime layers. |
| Skill arsenal by surface mapping | `skill-arsenal-by-surface-mapping-missing` | Relevant SaaS/e2e/data skills existed but were not bound to surfaces. |
| Negative invariants | `negative-invariant-missing` | Lock missed "we will NEVER ship X" statements such as fallback data. |
| Failure-mode audit per substrate | `failure-mode-audit-missing` | Each adopted substrate needs its default lie and proof signal named. |

No item is uncategorized.

## Failure-Mode Matrix

The rule: every adopted technology or pattern in a greenfield mission has a
lying-by-default failure mode. Lock-time readiness must name the lie, the proof
signal, and the refusal/repair path before feature work begins.

| Layer / substrate | Default lie | Lock-time proof signal | Refuse/repair at lock time |
|---|---|---|---|
| Design tokens | UI looks coherent while values are scattered literals. | Token file plus framework projection exists. | Refuse "ready" until tokens and projection are generated. |
| Theme/CSS projection | Tailwind/theme classes compile while not using canonical values. | `@theme`/CSS var mirror and token-tailwind gate. | Add projection or mark no-frontend explicitly. |
| UI primitives | Routes look done while each route invents its own controls. | Canonical primitive inventory and primitive-reuse gate. | Scaffold primitives first. |
| Composition layer | Domain UI repeats logic across pages. | `_primitives/` or equivalent domain component layer exists. | Defer route work until repeated compositions have a home. |
| Behavior config | UX decisions hide in component-local conditionals. | Behavior config file and mission-locked Q-decisions. | Extract behavior constants before feature work. |
| Density/responsiveness | Screens pass local taste but drift per route. | Density caps and responsive constraints encoded as invariants. | Add cap rule and proof gate. |
| Identity/auth scaffold | Demo flows appear user-ready without a durable identity model. | Auth model, session lifecycle, identity stubs, and protected-route proof. | Scaffold identity layer or explicitly mark anonymous-only. |
| Data model/schema | Data exists in UI but no lifecycle/ownership is locked. | Schema, state transitions, retention/archive/delete policy. | Refuse if fallback/demo data is the runtime source. |
| Runtime data fetch | Empty/fallback values make broken integrations look healthy. | Real-service e2e or explicit error UI. | Delete fallback data; return error state. |
| E2E tests | Tests pass against mocks while production path is unwired. | Real-service e2e skill mapped to critical flows. | Require real fixture/service proof for launch paths. |
| CI gates | Quality is asserted in prose, not enforced. | Named gates for tokens, density, primitive reuse, schemas, e2e. | Scaffold gates or mark project audit_only with debt bead. |
| SEO/metadata | Routes render but are not inspectable/shareable. | Per-route metadata baseline and route inventory. | Add metadata scaffold before public route work. |
| Secrets/config | Local env works while deploy/runtime cannot resolve secrets. | Secret inventory, vendor map, no-raw-secret-log invariant. | Refuse runtime work until secret ownership is named. |
| Observability | System "works" but failure is invisible. | Logging/metrics/error states named per critical path. | Add evidence path or no-observability debt bead. |
| Deployment platform | Local build passes while deployment substrate is missing. | Approved platform, tier, ToS, budget, deploy gate. | Pause only if outside mission license; otherwise scaffold. |
| Agent workflow | Mission is locked but workers cannot see missing substrate. | Lock-time audit receipt with substrate/invariant matrix. | Refuse "ready to build" until audit rows are green or beaded. |

## Criticality Matrix

| Gap class | Typical cost | Evidence | Why it compounds |
|---|---:|---|---|
| Negative invariant missing | Hours | alps reported ~6h avoidable rework. | Workers implement fallback or mock paths, then must unwind them once Joshua restates the invariant. |
| Trap-class cross-reference missing | Hours to days | e2e-no-mocks and runtime-no-fallback were treated as separate issues. | Same lie recurs at multiple layers because no one names the shared class. |
| Skill mapping missing | Hours | Joshua pointed to existing e2e and SaaS skills after work had already drifted. | Available expertise remains inert when not bound to the surface being built. |
| Single substrate artifact missing | 0.5-2 days | tokens/primitives/behavior each require retrofitting. | Routes built before substrate need cleanup. |
| Design-system substrate missing as a set | 10-15 days | mobile-eats: 5d Phase 0 catch-up + 3-5d cleanup. | Every feature route duplicates decisions that should have been centralized. |
| Lock-time audit missing across greenfield repo | Weeks | Risk generalizes to mobile-eats, alps, skillos, zesttube, agentmail, vrtx-engagement, flywheel. | Multiple projects begin from "locked" state while carrying hidden Phase 0 debt. |

## Generalization

Confirmed:

- `mobile-eats`: design-system substrate gap after 2026-05-04 mission lock.
- `alpsinsurance`: negative invariant/data-lifecycle gap after 2026-05-04 lock.

Flagged by the mobile-eats finding or sibling fleet context:

- `skillos`: skill authoring substrate needs explicit skill-surface mappings and
  backup/lifecycle invariants.
- `zesttube`: media pipeline has frontend, asset, provider, and runtime-data
  layers where fallback/demo data can lie.
- `agentmail`: identity, token, callback, and reservation substrates need
  negative invariants and lifecycle proof.
- `vrtx-engagement`: workflow/client-routing surfaces can ship with implicit
  data and stakeholder invariants unless locked.
- `flywheel`: the control-plane repo already has mission-lock drift incidents;
  it needs the same lock-time audit semantics for its own plan and template
  surfaces.

Risk signature:

```text
new or relaunched repo + frontend/user workflow + mission lock says ready
but no generated substrate inventory + no negative invariant matrix
= hidden Phase 0 debt
```

## Donella Analysis

System boundary:
Joshua's flywheel-managed project lifecycle from mission lock to first worker
feature dispatch.

Stocks:

- `locked_but_substrate_incomplete_projects`: projects whose MISSION/GOAL state
  says locked or ready, but design/data/auth/test substrate is absent.
- `negative_invariants_unstated`: forbidden runtime/test behaviors held only in
  Joshua's head or scattered skills.
- `feature_work_built_on_missing_substrate`: route/workflow code that must be
  cleaned up after substrate lands.
- `skill_knowledge_not_bound_to_surface`: relevant skills exist but do not flow
  into the lock receipt.

Inflows:

- New mission locks that capture destination but not substrate.
- Worker dispatches that treat "locked" as "build routes now."
- Skills/library knowledge not explicitly mapped by surface.
- Prose readiness without a machine-readable audit receipt.

Outflows:

- Phase 0 catch-up beads.
- Manual Joshua corrections.
- Retrofitting tokens, primitives, real-data tests, and invariants.
- Future lock-time readiness doctor/audit gate, to be designed in Lane C.

Reinforcing bad loop:

```text
mission-lock declares ready
-> workers build features
-> missing substrate discovered late
-> cleanup creates time pressure
-> teams skip deeper lock-time audit on next project
-> more projects lock incomplete
```

Balancing loop needed:

```text
mission-lock draft
-> substrate/invariant inventory
-> lock-time readiness audit
-> refuse or bead missing substrate
-> only green/audited lock can declare ready-to-build
```

Delays:

- Current delay is 2 days for mobile-eats and same-session hours for alps.
- The delay is too long relative to feature velocity; route work can multiply
  cleanup before the substrate gap is visible.

Leverage points:

- Meadows #6 Information flows: make missing substrate and negative invariants
  visible in the lock receipt before build dispatch.
- Meadows #5 Rules: change "locked" semantics so a project cannot call itself
  ready without substrate and invariant audit evidence.
- Meadows #4 Self-organization: future phases should give repos a reusable
  readiness doctor and scaffold validator so each repo can test itself.
- Meadows #2 Paradigms: shift mission-lock from "destination document" to
  "destination plus operational substrate contract."

Concrete intervention implied for later lanes:

```text
SYSTEM: mission lock to first build dispatch
STOCK: locked_but_substrate_incomplete_projects
PATTERN: ready-to-build claim hides Phase 0 debt
LOOP: missing feedback between lock artifact and worker substrate requirements
LEVERAGE_POINT: #5 Rules + #6 Information flows
INTERVENTION: lock-time substrate/invariant audit receipt
MEASURE: count of lock receipts with zero uncategorized substrate/invariant gaps
```

## Lane A Conclusion

The combined trauma class is not "frontend forgot tokens" or "ALPS forgot no
fallback." It is a mission-lock semantics failure: the current process can lock
a mission without proving the operational substrate and negative invariants that
make the mission buildable. Lane B should inventory existing skills, memories,
and related doctrine. Lane C should design the template extension,
scaffold-validator, and lock-time audit gate, but those are intentionally out of
scope for this Lane A deliverable.
