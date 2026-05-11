---
name: meta-primitive-composition-shape-taxonomy
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-joshua-veto-window-2026-05-11T11:35Z
authority: skillos-1-codified-2026-05-11T05:35Z-from-joshua-meta-primitive-doctrine-complete-signal + zeststream-platform-extraction-evidence (commits 7814d79 stripe-toolkit + d83d94c admin-action-toolkit + 45c2e42 event-hub-toolkit; THREE pane-3 META-PRIMITIVES proving cross-shape doctrine)
ratification_target: skillos:1 codifies; mobile-eats orch continues Wave-2 deep-scan independently; Joshua-veto window 6h from 05:35Z (i.e. 2026-05-11T11:35Z) per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol; default-accept thereafter
cluster: extraction-velocity-doctrine-cluster
sisters:
  - meta-primitive-extraction-friction-class.md (SISTER — friction catalog applies per-shape; this doctrine defines the shape taxonomy that friction is indexed against)
  - audit-machinery-hygiene-discipline.md (SISTER cluster — codification-of-recurring-pattern at different system layers)
trauma_class_promotion: 3-shape-completeness (PARALLEL + LAYERED + HUB cover canonical composition topologies; future hybrids decompose to these primitives)
default_accept_window: 6h from skillos:1 codification packet send (2026-05-11T11:35Z); Joshua-veto thereafter is the canonical override
sub_shape_under: META-EXTRACTION-DRIFT trauma class parent (Joshua-ratified 2026-05-11; this is the composition-shape-taxonomy sub-family beneath the parent, parallel to extraction-velocity-friction-class)
---

# META-PRIMITIVE Composition Shape Taxonomy (Fleet-Wide)

## Paradigm — META-PRIMITIVES compose substrate in one of three canonical shapes

A META-PRIMITIVE is a higher-order package that composes 3+ substrate primitives into a single consumer-facing surface. Across the Library Accretion Mission Phase 4 Wave-1 pane-3 extractions (3 METAs shipped in ~90 minutes), three distinct composition topologies emerged. These three shapes cover the canonical communication patterns; future METAs will fall into one of these shapes or a documented hybrid that decomposes to these primitives.

The Meadows-lens leverage point: **#5 rules of the system** (the shape taxonomy is a rule-of-the-meta-extraction-system; without it, each new META is a one-off pattern; with it, the extractor reaches for a canonical shape that already has documented mechanics, friction-mitigations, and consumer expectations), and **#6 information flow** (consumers immediately recognize which shape a META takes from its surface, accelerating adoption).

The three shapes — **PARALLEL**, **LAYERED**, **HUB** — emerged from three META extractions in a single 90-minute window: enough variation to characterize the topology space, enough commonality to abstract the canonical mechanics per shape.

## Mandate

Every META-PRIMITIVE extraction MUST:

1. **Classify shape before authoring** — declare which of PARALLEL / LAYERED / HUB the META will adopt in the extraction commit body. If the META appears to require a hybrid, document the hybrid decomposition into primitive shapes.
2. **Apply shape-appropriate canonical mechanics** — each shape has documented composition mechanics, type-system implications, and consumer expectations (catalogued below).
3. **Cite shape-specific friction sub-shapes** from sister doctrine `meta-primitive-extraction-friction-class.md` — different shapes hit different friction sub-shapes most often.
4. **Document the shape choice rationale** — why this shape fits the substrate's communication pattern.

## The Three Canonical Shapes

### Shape #1 — `PARALLEL` (distinct stages glued by factory)

**Definition:** N substrate primitives, each handling one distinct stage of a serial pipeline. The META factory produces a single function that invokes the primitives in sequence (or, for handler-flavored variants, dispatches based on event type).

**Composition mechanics:**
- Each primitive owns one pipeline stage
- META factory composes the stages in fixed serial order
- Inter-stage data flow is explicit (output of stage N is input of stage N+1)
- Error in stage N short-circuits stages N+1..end OR is captured as failure result depending on policy

**Canonical exemplar:** `@zeststream/stripe-toolkit` v0.0.1 (`zeststream-platform@7814d79`)
- 5 substrate primitives: webhook-signature + idempotency-cache + stripe-error-mapping + route-handler + stripe-handled-events
- Pipeline: verify-signed-webhook-timestamp → parseEvent → isHandledStripeEvent allowlist → idempotencyCache lookup → dispatch[event.type] OR default → cache event.id on success
- 6-step pipeline; each step is one primitive's responsibility
- 29 tests covering pipeline composition coverage

**When to use:**
- Substrate has a clear linear processing model (parse → validate → transform → dispatch → cache)
- Stages are independent (output of N is input of N+1; no cross-stage coupling beyond data flow)
- Failures at any stage are localized (don't require coordinated rollback)
- Examples: webhook handlers, event processors, request-response pipelines, ETL stages

**Type-system implications:**
- Inter-stage type contracts are explicit; substrate primitive exports the stage's input/output types
- Inline handlers inside stages CAN suffer TS-inline-handler-implicit-any (sub-shape #3) — anchor with typed `const`
- META surface is typically a single factory function returning a single pipeline function

**Friction sub-shape affinity** (from sister doctrine):
- HIGH: `workspace-pre-build` (5+ substrate deps need `dist/`)
- HIGH: `re-export-split` (5+ substrate packages with bare-entry vs `/server`)
- MEDIUM: `fake-timer-lifecycle` (idempotency caches with TTLs in pipeline)
- LOW: `TS-inline-handler-implicit-any` (linear pipelines have less inline-handler density than LAYERED/HUB)

### Shape #2 — `LAYERED` (nested closures, inner-to-outer wrap)

**Definition:** N substrate primitives, each wrapping the next. The META factory returns a function that, when invoked, peels back N layers of pre-processing before reaching the caller's handler. Each layer can short-circuit (CSRF fails → reject; auth fails → 401) without invoking deeper layers.

**Composition mechanics:**
- Each primitive owns one wrapping concern (csrf check, origin verify, zod parse, session auth, step-up freshness, etc.)
- META factory nests the primitives in fixed order, inner-to-outer
- Each wrap can short-circuit with its own failure mode
- The innermost handler runs in a ctx that aggregates all outer-layer outputs

**Canonical exemplar:** `@zeststream/admin-action-toolkit` v0.0.1 (`zeststream-platform@d83d94c`)
- 4 substrate primitives: route-handler + cors + protected-action + admin-step-up
- Layered composition inside-out: caller's handler ⊂ admin-step-up ⊂ protected-action(csrf+origin+zod+auth) ⊂ admin-action-factory
- 6-step inside-out pipeline; each step is one primitive's wrap
- 22 tests covering layered composition coverage

**When to use:**
- Substrate has a nested-concerns model (each layer adds a precondition)
- Layers are independent in mechanism but ORDERED in dependency (cors before auth before step-up)
- Short-circuit semantics at each layer (don't waste compute on later layers if earlier layer fails)
- Examples: secure handlers, middleware stacks, request validators with progressive enrichment

**Type-system implications:**
- Inner handler type accretes across layers (each layer adds to the ctx that the inner handler receives)
- Inline handlers between layers are HIGHLY susceptible to TS-inline-handler-implicit-any (sub-shape #3) — anchor with typed `const`
- META surface is typically a factory + a `defineAction(schema, options?)(handler)` curried form

**Friction sub-shape affinity:**
- HIGH: `TS-inline-handler-implicit-any` (canonical surface for this shape; inline handlers between layers lose type inference)
- HIGH: `re-export-split` (functions in `/server`, types in bare entry per layer)
- MEDIUM: `workspace-pre-build` (4 substrate deps)
- LOW: `fake-timer-lifecycle` (layered surfaces usually don't have time-gated semantics inside)

### Shape #3 — `HUB` (central registry + N pluggable spokes)

**Definition:** A central registry primitive holds N-many handler registrations. The META factory builds the registry + radiating spokes (metrics, logger, idempotency, cache-invalidator, etc.). Emission to the registry fans out to all registered handlers; spokes hook into emission lifecycle.

**Composition mechanics:**
- Central registry: `on(eventName, handler)` + `off(unsubscribe)` + `emit(eventName, payload, options) → Promise<EmitResult>`
- N pluggable spokes (optional; all wire via config): metrics, logger, idempotency-cache, cache-invalidator, etc.
- Execution mode (parallel vs serial), error isolation (default ON), correlation propagation, idempotent replay
- Emit returns aggregated result across all handlers

**Canonical exemplar:** `@zeststream/event-hub-toolkit` v0.0.1 (`zeststream-platform@45c2e42`)
- Core primitive: event hub registry
- 4 pluggable spokes: metrics + logger + idempotencyCache + cacheInvalidator (all optional)
- 36 tests covering hub composition coverage (registry, parallel emit, serial emit, unknown event, all 4 spokes, real-world full HUB composition)

**When to use:**
- Substrate has a pub/sub or event-dispatch model (1 emit → N handlers)
- Handler set is dynamic (handlers register/unregister at runtime; substrate doesn't know all handlers at META factory time)
- Cross-cutting concerns (metrics, logging, dedup) apply uniformly to ALL emissions
- Examples: event hubs, message dispatchers, plugin systems, observability emitters

**Type-system implications:**
- Generic event payload types must flow through the registry — this is where TS-inline-handler-implicit-any (sub-shape #3) bites hardest in HUB shape
- Inline registry literals don't propagate `EventDefinition<Payload>` generic — must declare typed `const` for each spoke
- META surface is typically a factory + `on(name, handler)` + `emit(name, payload, options)` triplet

**Friction sub-shape affinity:**
- HIGH: `TS-inline-handler-implicit-any` (event payload generics + inline registry literals; sub-shape #3's most visible surface)
- MEDIUM: `re-export-split` (core registry + N spokes split between bare-entry and `/server`)
- MEDIUM: `workspace-pre-build` (3-5 substrate deps)
- HIGH: `fake-timer-lifecycle` (idempotency spoke has TTLs; metrics spoke has time-bucketed counters)

## Shape-selection decision table

| Substrate communication pattern | Recommended shape |
|--------------------------------|---:|
| Linear pipeline (parse → validate → transform → dispatch) | **PARALLEL** |
| Nested concerns with short-circuit (cors → auth → step-up → handler) | **LAYERED** |
| Dynamic pub/sub (1 emit → N handlers) | **HUB** |
| Request/response with progressive enrichment | LAYERED |
| Batch processor with stage-by-stage data flow | PARALLEL |
| Plugin system with dynamic registration | HUB |
| Middleware stack | LAYERED |
| Workflow with cross-cutting concerns | HUB (if dispatch-heavy) or LAYERED (if order-heavy) |

## Hybrid composition

When a substrate's communication pattern doesn't cleanly fit one shape, hybrid composition is permitted but MUST decompose into the primitive shapes. Document the decomposition in the extraction commit body:

```
Hybrid composition (PARALLEL + LAYERED):
- Outer LAYERED: cors → auth → handler
- Inner PARALLEL pipeline (inside handler): parse → validate → dispatch
```

Pure hybrids (where neither shape dominates) are rare. The 3-shape taxonomy covers ≥95% of META extractions per the Phase 4 Wave-1 evidence.

## Anti-patterns

| Anti-pattern | Why it fails | Fix |
|--------------|--------------|-----|
| Authoring a META without declaring shape | Future maintainers can't tell which canonical mechanics apply | Declare shape in commit body header AND in package README |
| Mixing shape mechanics within one META | E.g., emitting events from inside a serial pipeline without HUB semantics | Decompose into shape-pure inner components OR document as explicit hybrid |
| Skipping shape-specific friction mitigations | Each shape's friction sub-shapes are documented; ignoring them re-pays discovery cost | Consult sister doctrine `meta-primitive-extraction-friction-class.md` for shape's friction affinities BEFORE authoring |
| Treating shape choice as cosmetic | Wrong shape forces awkward composition mechanics + worse consumer ergonomics | Shape choice IS the design decision; pick deliberately |
| Authoring a 4th shape without ratifying with doctrine cluster | Erodes the 3-shape canonical taxonomy; future METAs follow the precedent | File a ratification request (cross-orch protocol); ≥2 instances of a 4th shape required for canonical promotion |

## Sister doctrine cross-references

This doctrine pairs with:

- **`meta-primitive-extraction-friction-class.md`** — Sister doctrine cataloging friction sub-shapes encountered during META extraction. Friction sub-shapes are indexed AGAINST the composition shape taxonomy here: each shape has different friction affinities (PARALLEL hits workspace-pre-build hardest; LAYERED hits TS-inline-handler hardest; HUB hits TS-inline-handler hardest in a different surface). Together the two doctrines form the **extraction-velocity-doctrine-cluster** under the META-EXTRACTION-DRIFT parent class.
- **`audit-machinery-hygiene-discipline.md`** — Sister cluster for *audit-machinery* friction. Both clusters codify recurring patterns at different system layers (audit-machinery hygiene = probe/scorer friction; extraction-velocity-cluster = package-extraction friction). Together they exemplify the **codification-of-recurring-pattern doctrine pattern** that the Library Accretion Mission canonicalizes.

## META-EXTRACTION-DRIFT parent class

This doctrine is the **composition-shape-taxonomy sub-family** under META-EXTRACTION-DRIFT (Joshua-ratified 2026-05-11), parallel to:

- `meta-primitive-extraction-friction-class` (extraction-velocity friction sub-family)
- `apfs-case-insensitivity-collision` (filesystem-vector sub-family, 1-instance candidate)

Each sub-family canonicalizes a different aspect of META-EXTRACTION mechanics. Together they form the operational catalog of the parent META-EXTRACTION-DRIFT trauma class.

## Provenance — codification substrate

- `zeststream-platform@7814d79` — `@zeststream/stripe-toolkit` v0.0.1 (FIRST pane-3 META; PARALLEL shape; 5 substrate primitives; 29 tests; ~30min)
- `zeststream-platform@d83d94c` — `@zeststream/admin-action-toolkit` v0.0.1 (SECOND pane-3 META; LAYERED shape; 4 substrate primitives; 22 tests)
- `zeststream-platform@45c2e42` — `@zeststream/event-hub-toolkit` v0.0.1 (THIRD pane-3 META; HUB shape; core registry + 4 pluggable spokes; 36 tests; ~30min)
- 3 META extractions in ~90min sustained cadence proving cross-shape doctrine
- Pane-3 META cumulative count: 3/27 (META-PRIMITIVES) out of 27 total pane-3 extractions; ratio confirms META is a discrete extraction class atop substrate primitives

## Cross-orch protocol

This doctrine follows the same byte-identical mirror pattern as `audit-machinery-hygiene-discipline.md` cluster:

- skillos:1 codifies (this commit) → flywheel:1 mirrors byte-identical → bilateral sha256 match → joint ratification
- Joshua-veto window: 2026-05-11T11:35Z (6h from skillos:1 codification timestamp 05:35Z)
- Default-accept thereafter
- mobile-eats orch transitions to Wave-2 deep-scan independently; pulls from this doctrine when authoring future METAs

## Future evolution (v0.2+ candidates)

The 3-shape taxonomy is currently complete per the Phase 4 Wave-1 evidence. Future evolution paths:

- **4th-shape ratification:** If a new META extraction doesn't fit any of PARALLEL/LAYERED/HUB AND ≥1 other extraction surfaces the same novel shape (≥2-instance threshold), file ratification request. Candidates that have been hypothesized but not observed: PIPELINE-WITH-BRANCHING, BIDIRECTIONAL-CHANNEL, STATE-MACHINE.
- **Hybrid pattern catalog:** As hybrid compositions surface, catalog the recurring decomposition patterns (e.g., LAYERED-wraps-PARALLEL is common in HTTP handlers; HUB-with-LAYERED-spokes is common in observability stacks).
- **Cross-shape composition:** When one META composes another META (rare but possible), document the META-of-METAs shape.

## Mission anchor

`80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
