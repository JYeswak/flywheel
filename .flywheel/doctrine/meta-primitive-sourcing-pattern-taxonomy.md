---
name: meta-primitive-sourcing-pattern-taxonomy
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-joshua-veto-window-2026-05-11T14:00Z
authority: skillos:1-authored-2026-05-11T08:00Z + mobile-eats:1-ratifying-consumer (mirror-primary route per cross-orch-taxonomy-ratification protocol; established via export-shape-taxonomy v0.1 precedent at 73ad558)
ratification_target: skillos:1 codifies; mobile-eats:1 mirrors byte-identical via cross-orch-anti-divergence-v1.0.0 P3-trivial protocol upon ship; Joshua-veto window 6h from ship; default-accept thereafter
cluster: meta-primitive-taxonomy-cluster (2nd orthogonal axis — formal codification)
sisters:
  - meta-primitive-composition-shape-taxonomy.md (SISTER — 1st axis: HOW primitives compose internally; PARALLEL/LAYERED/HUB/CASCADE)
  - meta-primitive-export-shape-taxonomy.md (SISTER — 3rd axis: WHAT crosses the package boundary; CLEAN-KERNEL/GENERIC-PLUS-DEFAULTS/KITCHEN-SINK)
  - meta-primitive-extraction-friction-class.md (SISTER — friction catalog indexed per axis combination)
trauma_class_promotion: 3-axis-taxonomy-completion (this axis closes the orthogonal META-PRIMITIVE classification space; with composition-shape + export-shape, every META is fully classifiable along three independent dimensions)
default_accept_window: 6h from skillos:1 codification (2026-05-11T08:00Z); Joshua-veto thereafter is the canonical override
sub_shape_under: META-EXTRACTION-DRIFT trauma class parent (Joshua-ratified 2026-05-11; this is the sourcing-pattern-taxonomy sub-family beneath the parent, sister to composition-shape-taxonomy and export-shape-taxonomy)
---

# META-PRIMITIVE Sourcing Pattern Taxonomy (Fleet-Wide)

## Paradigm — META-PRIMITIVES draw substrate prose from one of N sources

A META-PRIMITIVE's **sourcing pattern** is *where the substrate prose came from* before it became a `@zeststream/*` package. It is orthogonal to:

- **Composition shape** (how primitives compose internally — PARALLEL/LAYERED/HUB/CASCADE)
- **Export shape** (what crosses the package boundary — CLEAN-KERNEL/GENERIC-PLUS-DEFAULTS/KITCHEN-SINK)

These three axes are independent. A LAYERED + GENERIC-PLUS-DEFAULTS META can be sourced from any of SKILL-PROSE / SOURCE-PROJECT-EXTRACTION / CLEAN-ROOM-DERIVATION / LIBRARY-MIRROR / etc. depending on where its prose originated.

The Meadows-lens leverage point: **#5 rules of the system** (the sourcing-pattern value is a rule-of-the-extraction-pipeline; without it, each META's provenance is opaque and each lineage debate is one-off; with it, future-maintainers immediately know whether to re-derive from skill prose, re-extract from source project, or mirror upstream library updates), and **#6 information flow** (explicit sourcing-pattern tags surface the operational pipeline that produced each META, accelerating both quality auditing and provenance verification).

The shapes — **SKILL-PROSE-TO-SUBSTRATE**, **SOURCE-PROJECT-EXTRACTION**, **CLEAN-ROOM-DERIVATION**, **LIBRARY-MIRROR**, **JEFF-CORPUS-PORT**, **PYTHON-TO-TS-PORT**, **AUDIT-FINDING-TO-SUBSTRATE** — emerged from cross-orch coordination between skillos:1 (taxonomy authoring) and mobile-eats:1 (Wave-1+2+3 extraction; surfaced the ≥2-threshold SKILL-PROSE-TO-SUBSTRATE instances on 2026-05-11 prompting this ratification).

## Mandate

Every META-PRIMITIVE extraction MUST:

1. **Tag sourcing pattern in package metadata** — declare which canonical sourcing-pattern value the META adopts. The tag lives in the `@zeststream/*` package.json under a `zeststream.sourcing_pattern` field OR in the substrate doctrine block.
2. **Apply pattern-appropriate canonical mechanics** — each pattern has documented prose-to-substrate translation rules, quality-gate constraints, and provenance-citation expectations.
3. **Cite source-evidence for sourcing-pattern choice** — name the canonical source (skill name + version, source-project commit SHA, library version + URL, etc.).
4. **Document sourcing-immutability** — sourcing-pattern is version-immutable. The same `@zeststream/*` package retains its sourcing-pattern across all versions. A v0.2 of `bead-quality-scorer` that re-derives from `/beads-compliance-and-completion-verification` skill prose is STILL `SKILL-PROSE-TO-SUBSTRATE`; the version-evolution is on a different axis (export-shape, often).

## The Canonical Sourcing Patterns

### Shape #1 — `SKILL-PROSE-TO-SUBSTRATE` (Anthropic skill prose → executable substrate)

**Definition:** Source prose lives in a `~/.claude/skills/<skill-name>/SKILL.md` (or sister markdown) Anthropic skill. The META extracts the skill's axioms, rubric tables, anti-pattern catalogues, polish-bar gates, and operational mechanics into executable TypeScript primitives. The skill's *prose-as-spec* becomes the substrate's *code-as-implementation*, with type-system-enforced fidelity to the rubric.

**Composition mechanics:**
- Source-of-truth: `~/.claude/skills/<skill-name>/SKILL.md` + sister files in `references/`
- Translation surface: skill axioms become invariants; rubric dimensions become typed fields; anti-pattern tables become linter classes; polish-bar gates become exit-conditions
- Provenance metadata embedded: skill name, skill version SHA at extraction, axiom IDs cited inline as TypeScript JSDoc

**Canonical exemplar (≥2-instance ratified):**
- `@zeststream/bead-quality-scorer` Face 3 (pane-3 W2-A5.3 `76fa010`): `/beads-compliance-and-completion-verification` skill prose → executable TS substrate (6-dim rubric + 6-band verdict + Axiom 4 + Polish Bar gate + false-closed flagging)
- `@zeststream/customer-support-triage-substrate` (pane-3 W3.5 `467569a`): `/user-support-triage-for-saas-and-open-source-projects` skill prose (225 HIGH score) → 5-face engine (pipelineClassifier + riskTierClassifier + antiPatternLinter + confirmationGate + phaseTracker; 23+8+20+33+6 taxonomies; 3 SAAS_* importable defaults; 9 HARDENED-FROM-SOURCE choices)

**When to use:**
- An Anthropic skill encodes operational discipline worth disseminating as code
- The skill is mature (axioms ratified, rubric stable, anti-patterns well-catalogued) and the user is paying for ongoing updates
- The skill's tactical surface (rubric tables, axiom IDs, anti-pattern classes) maps cleanly to typed primitives
- Re-derivation against a refreshed skill version is operationally feasible (weekly JSM cadence is the canonical refresh trigger)
- Examples: scoring/rubric skills (bead-quality, customer-support-triage), workflow-discipline skills (canonical-cli-scoping, beads-workflow), audit-rubric skills (beads-compliance-and-completion-verification)

**Adoption-effort profile:**
- HIGH for substrate-authoring orch (must translate skill prose into faithful typed primitives — extraction-velocity-friction)
- ZERO for consumer (consumer just imports the typed surface; no skill literacy required)
- LOW long-term maintenance (re-derivation cadence is the JSM-skill update cadence)

**Anti-patterns:**
- Don't SKILL-PROSE-TO-SUBSTRATE a skill that's still evolving rapidly (axioms unsettled, rubric drifting) — wait for skill maturity OR re-derive on each skill version bump and accept the churn
- Don't strip the skill's anti-pattern catalogue or polish-bar from the substrate — those ARE the discipline; without them the substrate is a hollow rubric

### Shape #2 — `SOURCE-PROJECT-EXTRACTION` (existing source project module → standalone package)

**Definition:** Source prose lives in a working source project (e.g., `~/Developer/zeststream-platform/src/...`, `~/Developer/mobile-eats/lib/...`). The META extracts a coherent unit of the source-project's existing code/types/utilities into a standalone `@zeststream/*` package, often with the source-project's canonical constants exported as named defaults.

**Composition mechanics:**
- Source-of-truth: working source project at a specific commit SHA
- Translation surface: identify a coherent module; lift code + types + tests; rename source-project-specific identifiers; preserve canonical defaults as importable constants
- Provenance metadata embedded: source-project name, source-project commit SHA, source-file path list

**Canonical exemplar (≥2-instance ratified):**
- `@zeststream/stripe-toolkit` (composition=PARALLEL, pane-3 W2-A2 `7814d79`): zeststream-platform Stripe webhook handler → 5-primitive PARALLEL META
- `@zeststream/lifecycle-state-machine` (composition=LAYERED, W2-A5.2 `720bf6e`): zeststream-platform lifecycle phase logic → generic state-machine builder + FC_* defaults
- Many additional Wave-1+2+3 instances catalogued in mobile-eats ship-log

**When to use:**
- A working source-project has a coherent module worth extracting
- The source-project's canonical constants are domain-significant (Stripe event allowlist, lifecycle phase taxonomy, fleet dispatcher names) — worth disseminating
- The source-project commit SHA is stable enough to anchor provenance
- Examples: webhook handlers, state machines, dispatchers, hash-chain primitives, audit-log toolkits

**Adoption-effort profile:**
- MEDIUM for substrate-authoring orch (extract + rename + de-couple from source-project context)
- LOW for source-project consumer (drop-in replacement once package published)
- LOW for second consumer (constants are importable; generic primitive accommodates their config)

**Anti-patterns:**
- Don't ship SOURCE-PROJECT-EXTRACTION as KITCHEN-SINK without scheduled refactor to CLEAN-KERNEL or GENERIC-PLUS-DEFAULTS — accumulates source-project debt
- Don't extract a source-project module that's still under active rapid iteration — provenance citation becomes meaningless if source SHA churns daily

### Shape #3 — `CLEAN-ROOM-DERIVATION` (axioms/principles → fresh implementation, no source-code copy)

**Definition:** Source prose lives in axioms, design discussions, or distilled principles (often the output of a `/planning-workflow` session or a doctrine block). The META is implemented from scratch — no code lifted from any source project, no skill prose translated line-for-line — but the design decisions trace back to the documented principles.

**Composition mechanics:**
- Source-of-truth: axiom list + design doc + (optionally) `/planning-workflow` artifact path
- Translation surface: read principles; implement primitives independently; cite principle-IDs in JSDoc
- Provenance metadata embedded: principle source path, principle version/date, optional `/planning-workflow` artifact SHA

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.*

**When to use:**
- Multiple source-projects could plausibly inform the design but none cleanly fits — extract from principles instead
- The substrate's behavior is novel (not already implemented anywhere) and the design needs first-principles authoring
- Legal/IP separation matters (substrate consumers cannot inherit source-project licensing)
- Examples: novel agentic-coordination primitives, fleet-orchestrator-protocol-implementations, cross-project-shared-doctrine-validators

**Adoption-effort profile:**
- HIGH for substrate-authoring orch (clean-room design + implementation; no existing code to lift)
- LOW for consumer (substrate is purpose-built; no source-project debt to inherit)
- MEDIUM long-term (re-derivation against updated principles requires re-reading the design doc, not diffing source)

**Anti-patterns:**
- Don't claim CLEAN-ROOM-DERIVATION when actually SOURCE-PROJECT-EXTRACTION-with-renaming — provenance lies poison future audits
- Don't skip the principle-citation step — "we made it up" is not a sourcing pattern; without traceable principles, this is just ad-hoc invention

### Shape #4 — `LIBRARY-MIRROR` (upstream npm/PyPI library → @zeststream re-publish)

**Definition:** Source prose lives in an upstream OSS library (e.g., `@hono/zod-validator`, `nanoid`, `zod`). The META is a thin wrapper or re-publish under the `@zeststream/*` namespace, often with version-pinning, additional types, or fleet-specific configuration baked in.

**Composition mechanics:**
- Source-of-truth: upstream library at specific semver version
- Translation surface: depend on upstream; expose types; configure fleet defaults
- Provenance metadata embedded: upstream library name, semver pin, upstream URL

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible candidates exist in Wave-1 libdocs-crawler outputs (`@zeststream/zod-fleet-defaults`, hypothetical) but no confirmed instance flagged yet.

**When to use:**
- Upstream library is canonical and stable; fleet needs the same library across all projects
- Fleet has additional configuration/defaults worth baking in (timeouts, retry policy, telemetry hooks)
- Provenance + supply-chain auditing benefits from a fleet-owned re-publish
- Examples: zod-fleet-defaults, hono-fleet-defaults, openai-fleet-client-wrappers

**Adoption-effort profile:**
- LOW for substrate-authoring orch (thin wrapper)
- LOW for consumer (familiar library + fleet defaults free)
- LOW long-term (track upstream semver; security-audit boundary clean)

**Anti-patterns:**
- Don't LIBRARY-MIRROR a library whose upstream churn rate exceeds the fleet's tolerance — the re-publish lag becomes operational risk
- Don't add features beyond what upstream-mirror-with-defaults justifies — at that point this is actually SOURCE-PROJECT-EXTRACTION-of-a-fork

### Shape #5 — `JEFF-CORPUS-PORT` (Jeff's tools/skills/scripts → @zeststream port)

**Definition:** Source prose lives in Jeff's upstream tooling corpus (`br`, `cm`, `ks`, `cass`, `ntm`, dicklesworthstone-stack outputs, etc.). The META ports a Jeff-authored primitive to the fleet's `@zeststream/*` namespace, often translating Bash → TypeScript or Python → TypeScript while preserving Jeff's operational intent.

**Composition mechanics:**
- Source-of-truth: Jeff's GitHub repo / shipped binary at specific version
- Translation surface: port language; preserve UX; honor canonical-cli-scoping discipline; cite Jeff's upstream version
- Provenance metadata embedded: Jeff repo URL, version/SHA, upstream-language → fleet-language translation note

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible candidates from prior fleet history exist but require explicit re-tag in the new taxonomy.

**When to use:**
- A Jeff primitive is canonical operational discipline (beads, agent-mail, etc.) and the fleet needs a typed TypeScript companion
- The fleet's TypeScript surface needs the Jeff primitive's *behavior* but in a language-native form
- Examples: typed Beads client (br-as-ts-package), typed CASS query primitive, typed dicklesworthstone-stack consumer wrappers

**Adoption-effort profile:**
- HIGH for substrate-authoring orch (port + faithful behavior + UX preservation)
- LOW for fleet consumer (idiomatic TypeScript; upstream Jeff intent preserved)
- MEDIUM long-term (track Jeff's upstream; flag breaking changes via upstream-report mechanism)

### Shape #6 — `PYTHON-TO-TS-PORT` (existing Python module → TypeScript port)

**Definition:** Source prose lives in a Python module (skillos's own server, dicklesworthstone-stack outputs, ZestStream internal Python tooling). The META ports the Python primitive to TypeScript for fleet consumption, preserving algorithm + types while idiomatizing for the TS ecosystem.

**Composition mechanics:**
- Source-of-truth: Python module at specific commit SHA
- Translation surface: translate algorithm; map Python type hints to TS types; idiomatize collections/iterators; provide a conformance harness that runs both sides against the same fixtures
- Provenance metadata embedded: Python source path, source commit SHA, conformance-harness path

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Plausible candidates exist in skillos's TS server surface vs Python server surface, but require explicit re-tag.

**When to use:**
- A Python primitive is canonical (algorithmic correctness, well-tested) and the fleet needs the same primitive in TypeScript
- Conformance-against-reference-impl discipline (per `CROSS-LANGUAGE-TWIN-DRIFT` memory) is feasible — both sides run the same test fixtures
- Examples: skillos doctor check primitives, cadence-metric calculators, audit-log parsers

**Adoption-effort profile:**
- HIGH for substrate-authoring orch (translation + conformance harness)
- LOW for consumer (idiomatic TS; provenance to Python reference)
- HIGH long-term (drift risk — port and reference can diverge; conformance harness is mandatory mitigation)

**Anti-patterns:**
- Don't PYTHON-TO-TS-PORT without a conformance harness — `CROSS-LANGUAGE-TWIN-DRIFT` (9th trauma class) is a documented failure mode

### Shape #7 — `AUDIT-FINDING-TO-SUBSTRATE` (audit/triage finding → executable substrate)

**Definition:** Source prose lives in an audit finding, triage observation, or postmortem (often surfaced by `/beads-compliance-and-completion-verification`, an `ultrareview`, a trauma-class postmortem, or a fleet doctor invariant). The META encodes the finding's discriminator into executable substrate — typically a linter rule, a doctor check, or a pre-commit guard.

**Composition mechanics:**
- Source-of-truth: audit finding artifact (markdown report, JSONL ledger row, postmortem doc)
- Translation surface: distill the finding's discriminator; implement as executable check; emit findings in the same envelope as the source audit
- Provenance metadata embedded: finding source path, finding ID, audit/triage-tool version that produced it

**Canonical exemplar:** *candidate-shape pending ≥2-instance ratification.* Skillos's own doctor checks (file-length, substrate-integrity, jeff-stack-routing-debt, cadence-receipt-velocity just shipped) plausibly qualify but require explicit re-tag.

**When to use:**
- A recurring trauma class or audit finding warrants permanent substrate enforcement
- The discriminator is well-understood (≥2 instance threshold met for the trauma class)
- The check can run in CI / doctor / pre-commit
- Examples: file-length doctor invariant (encoded from sweep findings), cadence-receipt-velocity (encoded from Meadows-#8 finding), substrate-integrity (encoded from canonical-files-manifest debt finding)

**Adoption-effort profile:**
- LOW for substrate-authoring orch (small focused check)
- ZERO for consumer (doctor / CI runs the check automatically)
- LOW long-term (check refines as finding population evolves)

## Sourcing-immutability claim

Unlike `export-shape` — which is version-mutable (a META legitimately migrates between shapes across versions) — **sourcing-pattern is version-immutable.** Once a META is tagged with a sourcing pattern, that tag is monotonic: subsequent versions REFINE within the same pattern; they do NOT migrate across patterns.

A v0.2 of `bead-quality-scorer` that re-derives against an updated `/beads-compliance-and-completion-verification` skill version is STILL `SKILL-PROSE-TO-SUBSTRATE`. A v0.2 of `stripe-toolkit` that re-extracts against an updated zeststream-platform commit is STILL `SOURCE-PROJECT-EXTRACTION`.

If a substrate fundamentally changes its source-of-truth (e.g., from `/skill-X` to `/skill-Y`), that is NOT a version bump — that is a NEW META, possibly under a NEW package name. Sourcing-immutability is the canonical signal that "this is the same lineage" vs "this is a new substrate."

## 3-axis orthogonality validation (cross-axis observation)

Mobile-eats:1 surfaced a critical cross-validation 2026-05-11: the same META can simultaneously declare values on all 3 axes orthogonally. Worked example:

`@zeststream/customer-support-triage-substrate` (pane-3 W3.5 `467569a`):

| Axis | Value |
|---|---|
| Composition shape | `LAYERED` (5-face engine with nested closures) |
| Sourcing pattern | `SKILL-PROSE-TO-SUBSTRATE` (from `/user-support-triage-for-saas-and-open-source-projects` skill) |
| Export shape | `GENERIC-PLUS-DEFAULTS` (3 SAAS_* importable defaults) |

The three values are independent — none constrains the others. This validates the orthogonality claim that motivated the EXPORT-SHAPE-TAXONOMY v0.1 separation: composition + sourcing + export are three independent dimensions, each with its own discriminator test.

## Ratification status (v0.1)

| Shape | Status | Ratified instances | Pending |
|---|---|---|---|
| `SKILL-PROSE-TO-SUBSTRATE` | **ratified** | 2 confirmed: bead-quality-scorer Face 3 (W2-A5.3 76fa010), customer-support-triage (W3.5 467569a) | none — ratifies at v0.1 |
| `SOURCE-PROJECT-EXTRACTION` | **ratified** | Multi-instance: stripe-toolkit (W2-A2 7814d79), lifecycle-state-machine (W2-A5.2 720bf6e), fleet-dispatcher (W2-A5.5 40fcf88), channel-router (W2-A5.6), and many additional Wave-1+2+3 catalogued in mobile-eats ship-log | none — ratifies at v0.1 |
| `CLEAN-ROOM-DERIVATION` | **candidate-shape** | 0 explicit (audit pending) | ≥2 instances from forward extraction |
| `LIBRARY-MIRROR` | **candidate-shape** | 0 explicit (audit pending) | ≥2 instances from libdocs-crawler outputs |
| `JEFF-CORPUS-PORT` | **candidate-shape** | 0 explicit (audit pending; plausible historical instances) | ≥2 instances from fleet historical re-tag |
| `PYTHON-TO-TS-PORT` | **candidate-shape** | 0 explicit (audit pending; plausible skillos surface) | ≥2 instances from forward extraction |
| `AUDIT-FINDING-TO-SUBSTRATE` | **candidate-shape** | 0 explicit (audit pending; plausible doctor-check instances) | ≥2 instances from forward extraction |

SKILL-PROSE-TO-SUBSTRATE and SOURCE-PROJECT-EXTRACTION are the two fully-ratified sub-shapes under this axis. The other five are codified as candidate-shapes; they ratify upon ≥2 instance confirmation per the canonical ≥2-threshold rule used in sister taxonomies (composition-shape v0.1+0.2; export-shape v0.1).

## Cross-orch ratification protocol

skillos:1 authors this doctrine (this file) under mirror-primary route per the precedent established by export-shape-taxonomy v0.1 at commit `73ad558`.

mobile-eats:1 mirrors byte-identical to `mobile-eats/.flywheel/doctrine/meta-primitive-sourcing-pattern-taxonomy.md` upon ship.

Both copies hash to the same sha256 — drift detection via `.flywheel/scripts/canonical-cli-drift-detector.sh` (skillos-side) ratifies coherence; mobile-eats-side equivalent flagged for follow-up.

mobile-eats:1 commitments (extending the export-shape-taxonomy commitments):

1. Mirror this doctrine byte-identical when shipped
2. Tag all 21+ already-shipped + future packages with explicit `sourcing_pattern` value in `@zeststream/*` metadata
3. Default tag = SOURCE-PROJECT-EXTRACTION for Wave-1+2 packages from zeststream-platform; SKILL-PROSE-TO-SUBSTRATE for the 2 confirmed instances (bead-quality-scorer Face 3, customer-support-triage)
4. Flag any CLEAN-ROOM-DERIVATION / LIBRARY-MIRROR / JEFF-CORPUS-PORT / PYTHON-TO-TS-PORT / AUDIT-FINDING-TO-SUBSTRATE instances as they surface
5. Maintain the 3-axis cross-classification record per package (composition × sourcing × export) for future cross-axis friction-class indexing

## Sister-doctrine integration

**`meta-primitive-composition-shape-taxonomy.md`** (1st axis): unchanged. Every META still declares one of PARALLEL/LAYERED/HUB/CASCADE.

**`meta-primitive-export-shape-taxonomy.md`** (3rd axis, v0.1 ratified 2026-05-11 at commit `73ad558`): unchanged. Every META declares one of CLEAN-KERNEL/GENERIC-PLUS-DEFAULTS/KITCHEN-SINK.

**`meta-primitive-extraction-friction-class.md`** (friction catalog): friction sub-shapes will be indexed against all three axes (composition × sourcing × export) once enough cross-axis friction data accumulates (≥10 cross-axis data points). v0.2 friction-class update deferred to follow-up; v0.1 of this doctrine ships without the indexing rebuild.

## Self-check

A META that does not declare its sourcing pattern in package metadata is operating outside this taxonomy. Trauma signal: future maintainers cannot determine whether to re-derive against an updated skill, re-extract against an updated source-project, or track an updated upstream library. Mitigation: substrate-integrity doctor invariant should grow a `sourcing_pattern_tag_missing` check (deferred to follow-up bead; v0.1 of this doctrine ships without the enforcement gate, per Path B "honest baseline > fast LIE").

## Provenance

- Surfaced (1st instance): pane-3 W2-A5.3 `76fa010` bead-quality-scorer Face 3 (`/beads-compliance-and-completion-verification` → executable TS)
- Surfaced (2nd instance, ratification trigger): pane-3 W3.5 `467569a` customer-support-triage-substrate (`/user-support-triage-for-saas-and-open-source-projects` → 5-face engine)
- Mobile-eats:1 routing decision: 2026-05-11T~07:50Z (mirror-primary; skillos canonical; ≥2-threshold MET signal)
- 3-axis orthogonality cross-validation: 2026-05-11T~07:50Z (customer-support-triage exhibits LAYERED × SKILL-PROSE-TO-SUBSTRATE × GENERIC-PLUS-DEFAULTS — three orthogonal axes in single substrate)
- Doctrine authored: skillos:1 2026-05-11T~08:00Z (this file)
- Mirror target: mobile-eats `/Users/josh/Developer/mobile-eats/.flywheel/doctrine/meta-primitive-sourcing-pattern-taxonomy.md`
- Schema: `cross-orch-taxonomy-ratification.v1`
