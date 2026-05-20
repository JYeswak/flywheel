---
name: meta-primitive-substrate-verdict-shape-taxonomy
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-joshua-veto-window-2026-05-11T14:30Z
authority: skillos:1-authored-2026-05-11T08:30Z + mobile-eats:1-ratifying-consumer (mirror-primary route per cross-orch-taxonomy-ratification protocol; precedent at 73ad558 + 468d01d)
ratification_target: skillos:1 codifies; mobile-eats:1 mirrors byte-identical via cross-orch-anti-divergence-v1.0.0 P3-trivial protocol upon ship; Joshua-veto window 6h from ship; default-accept thereafter
cluster: meta-primitive-taxonomy-cluster (4th orthogonal axis — partial applicability)
sisters:
  - meta-primitive-composition-shape-taxonomy.md (SISTER — 1st axis, universal applicability: HOW primitives compose internally)
  - meta-primitive-sourcing-pattern-taxonomy.md (SISTER — 2nd axis, universal applicability: WHERE substrate prose came from)
  - meta-primitive-export-shape-taxonomy.md (SISTER — 3rd axis, universal applicability: WHAT crosses the package boundary)
  - meta-primitive-extraction-friction-class.md (SISTER — friction catalog indexed per axis combination)
trauma_class_promotion: 4-axis-taxonomy-extension (adds the substrate-verdict-shape sub-axis to the cluster; partial-applicability scope = evaluator-class substrates only)
default_accept_window: 6h from skillos:1 codification (2026-05-11T08:30Z); Joshua-veto thereafter is the canonical override
sub_shape_under: META-EXTRACTION-DRIFT trauma class parent (Joshua-ratified 2026-05-11; this is the substrate-verdict-shape-taxonomy sub-family beneath the parent, sister to composition-shape + sourcing-pattern + export-shape taxonomies)
applicability_scope: PARTIAL — applies only to EVALUATOR-CLASS substrates (substrates whose primary contract is take-input + emit-verdict-and/or-findings). Non-evaluator substrates declare verdict_shape=n/a.
---

# META-PRIMITIVE Substrate-Verdict-Shape Taxonomy (Fleet-Wide)

## Paradigm — EVALUATOR-CLASS META-PRIMITIVES return verdicts in one of N runtime shapes

A META-PRIMITIVE's **substrate-verdict-shape** is the runtime shape of what an evaluator-class substrate's primary function returns when invoked. It is orthogonal to:

- **Composition shape** (PARALLEL/LAYERED/HUB/CASCADE — universal)
- **Sourcing pattern** (SKILL-PROSE-TO-SUBSTRATE/SOURCE-PROJECT-EXTRACTION/... — universal)
- **Export shape** (CLEAN-KERNEL/GENERIC-PLUS-DEFAULTS/KITCHEN-SINK — universal)

The 4-axis cluster: every evaluator-class META is fully classifiable along four independent dimensions. Non-evaluator substrates declare `verdict_shape=n/a` and are classified only along the three universal axes.

The Meadows-lens leverage point: **#5 rules of the system** (the verdict-shape value is a rule-of-the-evaluation-contract; without it, consumers cannot anticipate what an evaluator returns; with it, consumers know whether to expect a boolean / a score / severity-graded findings / a tagged union), and **#6 information flow** (explicit verdict_shape tags surface the evaluation contract at the registry layer, accelerating both adoption and auditing).

The shapes emerged from cross-orch coordination between skillos:1 (taxonomy authoring) and mobile-eats:1 (Wave-3 extraction; surfaced the ≥2-threshold SEVERITY-GRADED-WITH-BLOCKING-FLOOR instances on 2026-05-11 prompting this ratification).

## Applicability gate (read first)

This taxonomy applies **only to EVALUATOR-CLASS substrates** — substrates whose primary contract is:

> take input → emit verdict and/or findings

Examples of evaluator-class substrates:
- `@zeststream/bead-quality-scorer` (input=bead, output=6-band verdict + dimension scores)
- `@zeststream/customer-support-triage-substrate` (input=support-ticket, output=P0-P3 tier + findings)
- `@zeststream/seo-saas-substrate` (input=page, output=severity-graded findings + kernel-axiom verdict)
- `@zeststream/audit-hash-chain-validator` (input=chain row, output=valid/invalid)

Non-evaluator substrates (which do NOT declare on this axis):
- `@zeststream/stripe-toolkit` (pipeline processor; webhook in → side-effect + ack out; no verdict)
- `@zeststream/lifecycle-state-machine` (state machine; transition input → new state; no verdict)
- `@zeststream/fleet-dispatcher` (router; request → target binding; no verdict)
- `@zeststream/channel-router` (router; message → channel; no verdict)

If a substrate is non-evaluator, its package metadata declares `zeststream.verdict_shape = "n/a"`. The other 3 axes still apply universally.

A substrate with multiple faces, where ONE face is an evaluator (e.g., bead-quality-scorer's Face 3 evaluator + Faces 1-2 non-evaluator), declares verdict_shape on the evaluator-face only.

## Mandate

Every EVALUATOR-CLASS META-PRIMITIVE extraction MUST:

1. **Tag verdict_shape in package metadata** — declare which canonical verdict-shape value the evaluator adopts. The tag lives in the `@zeststream/*` package.json under a `zeststream.verdict_shape` field.
2. **Apply shape-appropriate canonical mechanics** — each shape has documented runtime-contract structure, typing conventions, and consumer-side handling patterns.
3. **Cite the source axiom or rubric** — name where the verdict-shape decision came from (skill axiom ID, source-project verdict logic, principle document).
4. **Document blocking-floor semantics** if applicable — if verdict_shape=SEVERITY-GRADED-WITH-BLOCKING-FLOOR, name explicitly which findings invalidate (Axiom 4 theater-class, critical-finding-class, kernel-axiom-failure-class, etc.).

## The Canonical Verdict Shapes

### Shape #1 — `BINARY-PASS-FAIL` (evaluator emits boolean)

**Definition:** Evaluator's primary function returns a boolean (or boolean-shaped `{valid: boolean, reason?: string}`). No severity grading, no findings list, no aggregate score.

**Runtime contract:**
- TypeScript surface: `(input: T) => boolean` OR `(input: T) => { valid: boolean; reason?: string }`
- Consumer handling: simple branch on truthiness
- Provenance metadata embedded: which source axiom/rule defines the valid/invalid distinction

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible candidates: hash-chain validators, signature verifiers.

**When to use:**
- The substrate's evaluation has a single yes/no answer with no useful intermediate state
- Consumers don't need to know WHY something failed beyond a single reason string
- Examples: hash-chain row validators, signature verifiers, capability-permission checks

### Shape #2 — `NUMERIC-SCORE` (evaluator emits a score)

**Definition:** Evaluator's primary function returns a numeric score (typically 0-100 or 0-1000) representing aggregate quality. No severity bands, no findings list, just a number.

**Runtime contract:**
- TypeScript surface: `(input: T) => number` OR `(input: T) => { score: number; max?: number }`
- Consumer handling: threshold-based decisions; thresholds defined in consumer config
- Provenance metadata embedded: scoring algorithm reference

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible: quality-scorers without bands.

**When to use:**
- The substrate emits a continuous quality signal, not a discrete classification
- Consumers compare scores across cohorts or set their own thresholds
- Examples: code-quality scorers, performance benchmarkers

### Shape #3 — `SEVERITY-GRADED-FINDINGS` (evaluator emits findings with severity, no blocking)

**Definition:** Evaluator's primary function returns a list of findings each with a severity grade (info / warning / error / critical OR P0-P3 OR similar). NO blocking floor — the overall verdict is computed from finding-list cardinality + severity-distribution, but no single finding INVALIDATES the entire evaluation.

**Runtime contract:**
- TypeScript surface: `(input: T) => { findings: Finding[]; verdict: Verdict }` where `Verdict` is aggregate
- Consumer handling: iterate findings; surface to UI/CI/operator; aggregate verdict for go/no-go
- Provenance metadata embedded: severity ladder definition; aggregation rule

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible: lint-style evaluators that emit warnings without hard stops.

**When to use:**
- The substrate's evaluation produces multiple distinct findings worth surfacing
- All findings inform the verdict but none individually blocks
- Examples: lint-style evaluators, soft-quality auditors, recommendation engines

### Shape #4 — `SEVERITY-GRADED-WITH-BLOCKING-FLOOR` (severity-graded findings + blocking floor) [RATIFIED]

**Definition:** Evaluator's primary function returns findings with severity grades AND has a documented BLOCKING FLOOR: specific finding classes that INVALIDATE the entire evaluation regardless of other dimensions. Different from SEVERITY-GRADED-FINDINGS: a single blocking-class finding overrides all other dimension scores, producing an immediate fail/blocked verdict.

**Runtime contract:**
- TypeScript surface: `(input: T) => { findings: Finding[]; verdict: Verdict; blocking_findings: Finding[] }` OR `(input: T) => { ok: boolean; blocked_by?: Finding[]; findings: Finding[] }`
- Consumer handling: check blocking_findings FIRST; if non-empty, evaluation is invalid regardless of other dimensions; otherwise process findings + verdict normally
- Provenance metadata embedded: severity ladder + blocking-class definition (which severity grades AND/OR which finding classes constitute the floor)

**Canonical exemplar (≥2-instance ratified; 3rd instance hardened):**
- `@zeststream/bead-quality-scorer` Face 3 (W2-A5.3 `76fa010`): 6-band verdict + Axiom 4 theater-invalidates-dimensions blocking floor (theater finding in any dimension invalidates the corresponding PASS verdicts in adjacent dimensions)
- `@zeststream/customer-support-triage-substrate` (W3.5 `467569a`): P0-P3 risk-tier classifier + antiPatternLinter critical-finding floor (critical anti-pattern blocks the ticket from passing through normal flow)
- `@zeststream/seo-saas-substrate` (W3.4 `a4b7996`): severity-graded findings + kernel-axiom-checker blocking floor (kernel axiom failure invalidates the SEO evaluation regardless of striking-distance + page-audit dimensions)

**When to use:**
- The substrate encodes operational discipline where some failures are unrecoverable (Axiom-class violations, critical-finding-class, kernel-axiom-class)
- Consumers must be prevented from accepting "mostly OK with one critical issue" as a pass
- Examples: rubric-based audits with theater-class invalidators, risk-tiering with hard-block thresholds, compliance evaluators with non-negotiable rules

**Anti-patterns:**
- Don't ship SEVERITY-GRADED-WITH-BLOCKING-FLOOR without documenting which findings constitute the floor — opaque blocking is operationally toxic
- Don't ship a "blocking floor" that's actually just a high-severity finding without invalidation logic — that's SEVERITY-GRADED-FINDINGS with a strict aggregation rule, not a blocking floor
- Don't skip the `blocking_findings` channel in the return type — consumers need to distinguish blocking from non-blocking findings without re-parsing severity strings

### Shape #5 — `DISCRIMINATED-UNION-RESULT` (evaluator emits tagged union of result types)

**Definition:** Evaluator's primary function returns a tagged union: `Ok | InvalidA | InvalidB | NotApplicable | ...`. Each variant carries its own typed payload. No severity grading because each variant is its own discrete outcome.

**Runtime contract:**
- TypeScript surface: `(input: T) => { kind: "ok"; ... } | { kind: "invalid_a"; ... } | { kind: "invalid_b"; ... } | ...`
- Consumer handling: exhaustive switch on `kind`; each branch handles its own typed payload
- Provenance metadata embedded: variant taxonomy reference

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible: parsers, classifiers with N distinct outcomes (not severity-graded).

**When to use:**
- The substrate has multiple distinct, well-typed result categories rather than a single continuous spectrum
- Consumers need different handling per result-kind
- Examples: parsers, intent-classifiers (note: intent-classifier 3-tier itself uses CASCADE composition + this DISCRIMINATED-UNION verdict), state-transition validators

### Shape #6 — `n/a` (non-evaluator substrate)

**Definition:** The substrate is not an evaluator. Its primary contract is processing, transformation, routing, dispatching, or state-management — not verdict-emission. Declares `verdict_shape = "n/a"` in package metadata; all other axis declarations remain.

**Examples:** stripe-toolkit, lifecycle-state-machine, fleet-dispatcher, channel-router, audit-hash-chain (the BUILDER, not the validator).

## Verdict-shape immutability

verdict-shape is **version-immutable** (like composition-shape and sourcing-pattern; unlike export-shape). Once a substrate declares its verdict_shape, that declaration is monotonic across versions. A v0.2 may refine the severity ladder, expand the blocking-finding catalogue, or improve the verdict aggregation — but it does NOT migrate to a different verdict_shape.

If a substrate fundamentally changes its evaluation contract (e.g., from BINARY-PASS-FAIL to SEVERITY-GRADED-FINDINGS), that is a NEW MAJOR-VERSION CONSUMER CONTRACT break, requiring an explicit deprecation cycle of the old verdict_shape and adoption window for the new one. Major-version v1 → v2 is the canonical breaking-change vehicle.

## 4-axis classification examples

Cross-axis density makes the cluster auditable:

`@zeststream/customer-support-triage-substrate` (W3.5 `467569a`):

| Axis | Value |
|---|---|
| Composition shape | LAYERED (5-face engine with nested closures) |
| Sourcing pattern | SKILL-PROSE-TO-SUBSTRATE |
| Export shape | GENERIC-PLUS-DEFAULTS (3 SAAS_* defaults) |
| **Verdict shape** | **SEVERITY-GRADED-WITH-BLOCKING-FLOOR** (P0-P3 + critical-finding floor) |

`@zeststream/bead-quality-scorer` Face 3 (W2-A5.3 `76fa010`):

| Axis | Value |
|---|---|
| Composition shape | PARALLEL (3-face engine) |
| Sourcing pattern | SKILL-PROSE-TO-SUBSTRATE |
| Export shape | CLEAN-KERNEL |
| **Verdict shape** | **SEVERITY-GRADED-WITH-BLOCKING-FLOOR** (6-band verdict + Axiom 4 theater floor) |

`@zeststream/seo-saas-substrate` (W3.4 `a4b7996`):

| Axis | Value |
|---|---|
| Composition shape | (5-face engine; tag per mobile-eats audit) |
| Sourcing pattern | SKILL-PROSE-TO-SUBSTRATE |
| Export shape | GENERIC-PLUS-DEFAULTS (5 SAAS_SEO_* defaults) |
| **Verdict shape** | **SEVERITY-GRADED-WITH-BLOCKING-FLOOR** (severity-graded findings + kernel-axiom-checker floor) |

The 3 ratified-instance substrates each occupy different positions on composition + export axes but converge on the same verdict_shape — validating that verdict_shape is orthogonal to the other axes.

`@zeststream/stripe-toolkit` (non-evaluator, for contrast):

| Axis | Value |
|---|---|
| Composition shape | PARALLEL |
| Sourcing pattern | SOURCE-PROJECT-EXTRACTION |
| Export shape | (tag per mobile-eats audit) |
| **Verdict shape** | **n/a** (pipeline processor, not evaluator) |

## Ratification status (v0.1)

| Shape | Status | Ratified instances | Pending |
|---|---|---|---|
| `BINARY-PASS-FAIL` | **candidate-shape** | 0 explicit | ≥2 instances from audit |
| `NUMERIC-SCORE` | **candidate-shape** | 0 explicit | ≥2 instances from audit |
| `SEVERITY-GRADED-FINDINGS` | **candidate-shape** | 0 explicit (no-blocking-floor variant) | ≥2 instances from audit |
| `SEVERITY-GRADED-WITH-BLOCKING-FLOOR` | **ratified** | 3 confirmed: bead-quality-scorer F3 (W2-A5.3 76fa010), customer-support-triage (W3.5 467569a), seo-saas-substrate (W3.4 a4b7996) | none — ratifies at v0.1 |
| `DISCRIMINATED-UNION-RESULT` | **candidate-shape** | 0 explicit | ≥2 instances from audit |
| `n/a` (non-evaluator) | **structural** | Multi-instance: stripe-toolkit, lifecycle-state-machine, fleet-dispatcher, channel-router, etc. | structural value; ratifies by virtue of being the default for non-evaluator substrates |

SEVERITY-GRADED-WITH-BLOCKING-FLOOR is the first ratified evaluator-class verdict-shape value. The other 4 evaluator values are codified as candidate-shapes; they ratify upon ≥2 instance confirmation per the canonical ≥2-threshold rule. The structural `n/a` value applies to non-evaluator substrates universally.

## Cross-orch ratification protocol

skillos:1 authors this doctrine (this file) under mirror-primary route per precedent at commits `73ad558` (export-shape v0.1) + `468d01d` (sourcing-pattern v0.1).

mobile-eats:1 mirrors byte-identical to `mobile-eats/.flywheel/doctrine/meta-primitive-substrate-verdict-shape-taxonomy.md` upon ship.

mobile-eats:1 commitments (extending the prior 3-axis commitments):

1. Mirror this doctrine byte-identical when shipped
2. Tag all 21+ already-shipped + future packages with explicit `verdict_shape` value in `@zeststream/*` metadata (or `n/a` for non-evaluator substrates)
3. Tag the 3 confirmed instances (bead-quality-scorer F3, customer-support-triage, seo-saas-substrate) as `SEVERITY-GRADED-WITH-BLOCKING-FLOOR`
4. Default tag non-evaluator substrates as `verdict_shape = n/a`
5. Flag any BINARY-PASS-FAIL / NUMERIC-SCORE / SEVERITY-GRADED-FINDINGS / DISCRIMINATED-UNION-RESULT instances as they surface
6. Maintain the 4-axis cross-classification record per evaluator-class package for future cross-axis friction-class indexing

## Sister-doctrine integration

**`meta-primitive-composition-shape-taxonomy.md`** (1st axis, universal): unchanged.

**`meta-primitive-sourcing-pattern-taxonomy.md`** (2nd axis, universal): unchanged.

**`meta-primitive-export-shape-taxonomy.md`** (3rd axis, universal): unchanged. Note: export-shape (what symbols cross the boundary) is distinct from verdict-shape (what runtime contract those symbols implement). A CLEAN-KERNEL export can implement any verdict-shape; a GENERIC-PLUS-DEFAULTS export likewise. The two axes are orthogonal.

**`meta-primitive-extraction-friction-class.md`** (friction catalog): friction sub-shapes will be indexed against all four axes (composition × sourcing × export × verdict) once enough cross-axis friction data accumulates. v0.2 friction-class update deferred to follow-up.

## Self-check

A substrate that is plausibly an evaluator but does not declare verdict_shape in package metadata is operating outside this taxonomy. Trauma signal: consumers cannot anticipate the runtime contract; integration code is written speculatively and breaks when actual return shape diverges. Mitigation: substrate-integrity doctor invariant should grow a `verdict_shape_tag_missing` check that fires when a package has evaluator-class signatures (functions returning typed verdicts) but no `verdict_shape` tag. Deferred to follow-up bead; v0.1 of this doctrine ships without the enforcement gate per Path B "honest baseline > fast LIE".

## Provenance

- Surfaced (3 instances, ≥2-threshold met at 3rd): mobile-eats:1 META-PATTERN signal 2026-05-11T~08:20Z citing bead-quality-scorer F3 + customer-support-triage + seo-saas-substrate
- Taxonomy-placement question routed to skillos:1 (mirror-primary): 2026-05-11T~08:20Z
- 4-part discriminator test executed (composition-invariance + sourcing-invariance + export-shape-invariance + verdict-shape-positive): 2026-05-11T~08:25Z
- Verdict: 4th orthogonal axis with PARTIAL APPLICABILITY (evaluator-class only)
- Doctrine authored: skillos:1 2026-05-11T~08:30Z (this file)
- Mirror target: mobile-eats `/Users/josh/Developer/mobile-eats/.flywheel/doctrine/meta-primitive-substrate-verdict-shape-taxonomy.md`
- Schema: `cross-orch-taxonomy-ratification.v1`


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
