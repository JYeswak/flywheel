---
name: meta-primitive-export-shape-taxonomy
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-joshua-veto-window-2026-05-11T13:30Z
authority: skillos:1-authored-2026-05-11T07:30Z + mobile-eats:1-ratifying-consumer (mirror-primary route per cross-orch-taxonomy-ratification-decision.v1)
ratification_target: skillos:1 codifies; mobile-eats:1 mirrors byte-identical via cross-orch-anti-divergence-v1.0.0 P3-trivial protocol upon ship; Joshua-veto window 6h from ship; default-accept thereafter
cluster: meta-primitive-taxonomy-cluster (3rd orthogonal axis)
sisters:
  - meta-primitive-composition-shape-taxonomy.md (SISTER — 1st orthogonal axis: HOW primitives compose internally; PARALLEL/LAYERED/HUB/CASCADE)
  - meta-primitive-extraction-friction-class.md (SISTER — friction sub-shapes indexed per composition + sourcing combination)
trauma_class_promotion: 3-axis-taxonomy-completion (this axis closes the orthogonal META-PRIMITIVE classification space alongside composition-shape + sourcing-pattern)
default_accept_window: 6h from skillos:1 codification (2026-05-11T07:30Z); Joshua-veto thereafter is the canonical override
sub_shape_under: META-EXTRACTION-DRIFT trauma class parent (Joshua-ratified 2026-05-11; this is the export-shape-taxonomy sub-family beneath the parent, sister to composition-shape-taxonomy and sourcing-pattern-taxonomy)
---

# META-PRIMITIVE Export Shape Taxonomy (Fleet-Wide)

## Paradigm — META-PRIMITIVES expose substrate in one of N export shapes

A META-PRIMITIVE's **export shape** is the composition of what crosses the package boundary into consumer code. It is orthogonal to:

- **Composition shape** (how primitives compose internally — PARALLEL/LAYERED/HUB/CASCADE)
- **Sourcing pattern** (where the substrate prose came from — source-project extraction, clean-room derivation, library mirror, etc.)

These three axes are independent. A LAYERED + source-project-extraction META can export under any of CLEAN-KERNEL / KITCHEN-SINK / GENERIC-PLUS-DEFAULTS depending on what its public surface contains.

The Meadows-lens leverage point: **#5 rules of the system** (the export-shape value is a rule-of-the-consumer-contract; without it, each META negotiates its own boundary; with it, consumers immediately know whether the package will ship defaults or only a primitive), and **#6 information flow** (the explicit EXPORT-SHAPE tag in package metadata makes adoption-effort estimable from the registry, not from reading source).

The shapes — **CLEAN-KERNEL**, **GENERIC-PLUS-DEFAULTS**, **KITCHEN-SINK** — emerged from cross-orch coordination between skillos:1 (taxonomy authoring) and mobile-eats:1 (Wave-2 extraction; surfaced 2/2 instances of the middle shape on 2026-05-11 prompting this ratification).

## Mandate

Every META-PRIMITIVE extraction MUST:

1. **Tag export shape in package metadata** — declare which of CLEAN-KERNEL / GENERIC-PLUS-DEFAULTS / KITCHEN-SINK the META adopts. The tag lives in the `@zeststream/*` package.json under a `zeststream.export_shape` field OR in the substrate doctrine block.
2. **Apply shape-appropriate canonical mechanics** — each shape has documented public-surface composition, adoption-effort profile, and migration guidance.
3. **Document version-mutability** — record whether the META's export shape is intended to remain stable across versions, or evolve (e.g., CLEAN-KERNEL v0.0.1 → GENERIC-PLUS-DEFAULTS v0.1.0 once consumer-N hits a 2nd instance).
4. **Cite consumer evidence for shape choice** — why this shape fits the substrate's adoption pattern (single-consumer canonical → GENERIC-PLUS-DEFAULTS; N-consumer generic → CLEAN-KERNEL; full-port lift-and-shift → KITCHEN-SINK).

## The Canonical Shapes

### Shape #1 — `CLEAN-KERNEL` (only the generic primitive exposed)

**Definition:** The substrate exports a single generic builder, factory, or primitive function. Source-project canonical constants (FC_*, CUBCLOUD_*, ALPS_*, …) are NOT exported. Consumers bring their own constants/configuration. The minimal-surface contract.

**Composition mechanics:**
- Package public surface = the generic primitive only
- No named-default exports beyond what's needed to *use* the primitive (e.g., factory inputs, return types)
- Consumer-side configuration is mandatory (no usable defaults shipped)

**Canonical exemplar (candidate-shape pending ≥2-instance ratification):**
- `@zeststream/webhook-toolkit` (composition=PARALLEL): exports `createWebhookHandler({signingKey, dispatch})` only; no source-project event-name allowlist baked in
- `@zeststream/auth-layered-toolkit` (composition=LAYERED): exports `composeAuthMiddleware({...})`; no source-project SESSION_* defaults
- mobile-eats:1 has committed to auditing Wave-1+2 ship history (~21 packages) for confirmation; pre-confirmed mentally pending explicit instance flag

**When to use:**
- Substrate is intended for N-many consumers (≥2 expected at extraction time)
- Source-project's canonical constants are domain-specific (not reusable across projects)
- Adoption-effort is acceptable because the consumer count amortizes the configuration burden
- Examples: webhook handlers (every consumer has different event types), auth middleware (every consumer has different session schemas), feature-flag clients

**Adoption-effort profile:**
- HIGH for first consumer (must supply all configuration)
- LOW marginal cost per additional consumer (same primitive, different config)
- HIGH long-term value (substrate doesn't drag source-project-specific defaults into N projects)

**Anti-patterns:**
- Don't ship CLEAN-KERNEL when only one consumer is plausibly using it — adoption-effort is wasted (use GENERIC-PLUS-DEFAULTS instead)
- Don't ship CLEAN-KERNEL when the source-project's defaults are the lingua franca of the domain (e.g., Stripe event names) — use GENERIC-PLUS-DEFAULTS with the canonical defaults as opt-in named exports

### Shape #2 — `GENERIC-PLUS-DEFAULTS` (primitive + named-default constants)

**Definition:** The substrate exports the generic primitive PLUS named-default constants/configurations sourced from the source-project's canonical pattern. Consumers can: (a) use the generic primitive with their own constants, OR (b) adopt the source-project defaults directly. Bridges CLEAN-KERNEL (minimal surface) and KITCHEN-SINK (everything from source).

**Composition mechanics:**
- Package public surface = generic primitive + N named-default constants (typically `FC_*` / `CUBCLOUD_*` / project-prefix-style)
- Named defaults are explicit, individually importable (`import { FC_LIFECYCLE_PHASES, createStateMachine } from '@zeststream/lifecycle-state-machine'`)
- Defaults are reference implementations, not magic; consumer can substitute or extend
- Adoption-effort for source-project consumer drops to near-zero (they get their own defaults for free)

**Canonical exemplar (≥2-instance ratified; 3rd instance hardened):**
- `@zeststream/lifecycle-state-machine` (W2-A5.2 `720bf6e`): exports `createLifecycleStateMachine()` builder + `FC_LIFECYCLE_PHASES` + `FC_RESEARCH_GATE` named constants
- `@zeststream/fleet-dispatcher` (W2-A5.5 `40fcf88`): exports generic dispatch primitive + 6 `FC_`-prefixed reference defaults
- `@zeststream/channel-router` (W2-A5.6, HARDENED 3rd instance same Wave-2-A5 chunk): exports generic router + `FC_*` channel-naming defaults

**When to use:**
- Substrate has 1 obvious primary consumer (the source project) + a credible path to N-many secondary consumers
- Source-project's canonical constants are NOT just configuration — they encode operational discipline worth disseminating (e.g., FC_LIFECYCLE_PHASES is a 4-tier ratified taxonomy that other projects benefit from adopting)
- Adoption-effort asymmetry is acceptable: free for source-project consumer; ≈ CLEAN-KERNEL for others
- Examples: lifecycle state machines (source-project's phase taxonomy is canon worth disseminating), fleet dispatchers (source-project's routing convention is the reference), channel routers (source-project's naming is the standard)

**Adoption-effort profile:**
- ZERO for source-project consumer (uses defaults as-is)
- LOW for second consumer (cherry-pick the defaults that apply; substitute the rest)
- LOW long-term value (defaults are opt-in; consumers that don't need them just don't import them)

**Anti-patterns:**
- Don't ship GENERIC-PLUS-DEFAULTS when only the source-project will ever use it — that's actually KITCHEN-SINK (or just don't extract)
- Don't bury defaults inside the primitive's default args — keep them as explicit named exports so consumers can see them in the registry/types without reading source
- Don't ship defaults that contain source-project-secrets (URLs, IDs, credentials) — the named-default surface is for *patterns*, not data

### Shape #3 — `KITCHEN-SINK` (everything from source exposed)

**Definition:** The substrate exports the generic primitive PLUS the source-project's named defaults PLUS additional source-project helpers, types, ad-hoc utilities, and adjacent module exports. Effectively a "lift the source-project's whole module into a package" pattern. Maximal-surface contract.

**Composition mechanics:**
- Package public surface mirrors a source-project module verbatim (or near-verbatim)
- All source-project helpers/types/utilities are re-exported
- Consumer can adopt the full module wholesale without learning the substrate API surface

**Canonical exemplar (candidate-shape pending ≥2-instance ratification):**
- mobile-eats:1 to flag explicit instances as encountered; v0.1 ships with no ratified exemplars in this shape (codifies as candidate)
- Suspected examples in Wave-1 (require explicit instance confirmation): some early extractions that essentially `cp -r src/foo/ packages/foo/src/`

**When to use:**
- Substrate is a one-shot extraction; not intended as a long-term reusable META
- Source-project is the ONLY plausible consumer
- Lift-and-shift adoption is faster than cleaning the API surface
- Time-pressure: extraction velocity > substrate quality
- Examples: one-off ports during migration; emergency consumer demand; pre-cleanup substrate "land it then refactor"

**Adoption-effort profile:**
- ZERO for source-project consumer (drop-in replacement)
- HIGH for second consumer (they inherit source-project-specific helpers they don't need)
- HIGH long-term cost (substrate carries source-project debt forward; future cleanup creates breaking changes)

**Anti-patterns:**
- Don't ship KITCHEN-SINK as the long-term shape — flag it as a `kitchen-sink-promotion-to-clean-kernel-or-generic-plus-defaults-debt` follow-up
- Don't ship KITCHEN-SINK without a documented refactor path to CLEAN-KERNEL or GENERIC-PLUS-DEFAULTS in the package's doctrine block
- Don't leak source-project-secrets in the helpers (same constraint as GENERIC-PLUS-DEFAULTS)

## Cross-axis version-mutability claim

Unlike `composition-shape` and `sourcing-pattern` — both of which are version-immutable (a META's composition topology doesn't change v0.0.1 → v0.0.2; its sourcing-history is monotonic) — **export-shape is version-mutable.**

A single META can legitimately exhibit different export shapes across versions:

- `@zeststream/audit-hash-chain` v0.0.1 = CLEAN-KERNEL (only generic SHA-chain primitive)
- `@zeststream/audit-hash-chain` v0.1.0 = GENERIC-PLUS-DEFAULTS (added `CUBCLOUD_HASH_ALGORITHM` and `CUBCLOUD_CHAIN_INTERVAL_MS` named-default constants after cubcloud-aaas became a 2nd verified consumer)

The version-mutability is a **feature**, not a bug:

- Start CLEAN-KERNEL when consumer count is unknown
- Promote to GENERIC-PLUS-DEFAULTS when the source-project's canonical constants prove worth disseminating (≥2 consumers benefit)
- Demote from KITCHEN-SINK to CLEAN-KERNEL or GENERIC-PLUS-DEFAULTS when the substrate's debt is paid down

The version-mutability MUST be recorded in the package's CHANGELOG.md under an `export_shape_change` entry:

```markdown
## v0.1.0 — 2026-MM-DD
- **export_shape_change**: CLEAN-KERNEL → GENERIC-PLUS-DEFAULTS
- **trigger**: cubcloud-aaas verified as 2nd consumer of audit-hash-chain;
  CUBCLOUD_HASH_ALGORITHM + CUBCLOUD_CHAIN_INTERVAL_MS promoted to named-default exports
- **migration**: existing consumers unaffected (additive); new consumers
  may import the defaults
```

## Ratification status (v0.1)

| Shape | Status | Ratified instances | Pending |
|---|---|---|---|
| `CLEAN-KERNEL` | **candidate-shape** | 0 explicit (mobile-eats:1 audit in flight) | ≥2 instances from Wave-1+2 history audit |
| `GENERIC-PLUS-DEFAULTS` | **ratified** | 2 confirmed + 1 hardened: lifecycle-state-machine, fleet-dispatcher, channel-router | none — ratifies at v0.1 |
| `KITCHEN-SINK` | **candidate-shape** | 0 explicit (mobile-eats:1 to flag as encountered) | ≥2 instances from forward extraction |

GENERIC-PLUS-DEFAULTS is the first fully-ratified sub-shape under this axis. CLEAN-KERNEL and KITCHEN-SINK are codified as candidate-shapes; they ratify upon ≥2 instance confirmation per the canonical ≥2-threshold rule used in sister taxonomies (composition-shape v0.1+0.2; sourcing-pattern v0.1).

## Cross-orch ratification protocol

skillos:1 authors this doctrine (this file) under mirror-primary route.

mobile-eats:1 mirrors byte-identical to `mobile-eats/.flywheel/doctrine/meta-primitive-export-shape-taxonomy.md` upon ship.

Both copies hash to the same sha256 — drift detection via `.flywheel/scripts/canonical-cli-drift-detector.sh` ratifies coherence.

mobile-eats:1 commitments per `cross-orch-taxonomy-ratification-decision.v1` (2026-05-11):

1. Mirror this doctrine byte-identical when shipped
2. Tag all 21 already-shipped + future packages with explicit `export_shape` value in `@zeststream/*` metadata
3. Default tag = CLEAN-KERNEL unless evidence suggests otherwise
4. Tag the 3 W2-A5 confirmed packages (lifecycle-state-machine, fleet-dispatcher, channel-router) as GENERIC-PLUS-DEFAULTS
5. Flag any KITCHEN-SINK or new-axis-value instances as they surface during Wave-3+ extraction

## Sister-doctrine integration

**`meta-primitive-composition-shape-taxonomy.md`** (1st axis): unchanged. Every META still declares one of PARALLEL/LAYERED/HUB/CASCADE.

**`meta-primitive-sourcing-pattern-taxonomy.md`** (2nd axis, pre-formal): the sourcing-pattern taxonomy is currently informal pending its own ratification cycle. EXPORT-SHAPE-TAXONOMY does not block sourcing-pattern formalization; the three axes are independent.

**`meta-primitive-extraction-friction-class.md`** (friction catalog): friction sub-shapes are indexed against composition-shape and (informally) sourcing-pattern. Future v0.2 update will add export-shape indexing once enough cross-axis friction data accumulates (e.g., does GENERIC-PLUS-DEFAULTS produce different friction than CLEAN-KERNEL within the same composition shape? Open question pending ≥10 cross-axis data points).

## Self-check

A META that does not declare its export shape in package metadata is operating outside this taxonomy. Trauma signal: registry consumers cannot estimate adoption-effort without reading the source. Mitigation: substrate-integrity doctor invariant should grow an `export_shape_tag_missing` check (deferred to follow-up bead; v0.1 of this doctrine ships without the enforcement gate, per Path B "honest baseline > fast LIE").

## Provenance

- Surfaced: mobile-eats:1 2026-05-11T~06:30Z (`META-PATTERN CONFIRMED ≥2 THRESHOLD CROSSED @ pane-3 36th extraction`)
- 3-point discriminator test authored: skillos:1 2026-05-11T~06:50Z (composition-invariance + sourcing-invariance + export-shape-positive)
- Ratification routing decision: mobile-eats:1 2026-05-11T~07:15Z (mirror-primary; skillos canonical)
- Doctrine authored: skillos:1 2026-05-11T~07:30Z (this file)
- Mirror target: mobile-eats `/Users/josh/Developer/mobile-eats/.flywheel/doctrine/meta-primitive-export-shape-taxonomy.md`
- Schema: `cross-orch-taxonomy-ratification.v1`


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
