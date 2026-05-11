---
name: meta-primitive-extraction-friction-class
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-joshua-veto-window-2026-05-11T11:20Z
authority: skillos-1-codified-2026-05-11T05:20Z-from-joshua-friction-recurrence-signal + zeststream-platform-extraction-evidence (commits 31434b3 http-client + 7814d79 stripe-toolkit + d83d94c admin-action-toolkit)
ratification_target: skillos:1 codifies; mobile-eats orch continues parallel extraction; Joshua-veto window 6h from 05:20Z (i.e. 2026-05-11T11:20Z) per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol; default-accept thereafter
cluster: extraction-velocity-doctrine-cluster
sisters:
  - audit-machinery-hygiene-discipline.md (SISTER — both are codification-of-recurring-friction-patterns at different system layers)
  - apfs-case-insensitivity-collision-trauma (sub-shape candidate for sister filesystem-friction-class doctrine if pattern recurs)
trauma_class_promotion: 4-sub-shape-ladder; 3-of-4 sub-shapes confirmed at ≥2 instances across ~26 META-PRIMITIVE extractions in Library Accretion Mission Phase 4 Wave-1
default_accept_window: 6h from skillos:1 codification packet send (2026-05-11T11:20Z); Joshua-veto thereafter is the canonical override
sub_shape_under: META-EXTRACTION-DRIFT trauma class parent (Joshua-ratified 2026-05-11; this is the extraction-velocity-friction sub-family beneath the parent META-EXTRACTION-DRIFT class)
---

# META-PRIMITIVE Extraction Friction Class (Fleet-Wide)

## Paradigm — extraction at scale surfaces recurring friction surfaces, not novel ones

When extracting reusable substrate (META-PRIMITIVE packages) from production codebases at velocity — e.g. 26 extractions in a single Library Accretion Mission Wave-1 across two parallel panes — the friction surfaces encountered are NOT novel per extraction. They are a small, recurring set of canonical friction shapes that an extracting agent will hit again and again across different domains (Stripe webhooks, admin actions, HTTP clients, etc.). Each individual extraction worker discovers these frictions independently and resolves them. Without codification, every worker pays the discovery cost again.

The Meadows-lens leverage point: **#5 rules of the system** (the friction shapes are rules-of-the-extraction-system that no individual worker can see from inside their own extraction; the orchestrator-level pattern is invisible at worker scope), and **#4 self-organization** (codifying the friction class lets future extractions skip the discovery loop and reach for the canonical resolution directly).

The four sub-shapes catalogued here emerged through ~26 extractions in zeststream-platform pane-2 + pane-3 parallel work (Phase 4 Wave-1). 3 of 4 sub-shapes appear at ≥2 distinct extractions, meeting the multi-instance threshold for canonical sub-shape promotion.

## Mandate

Every META-PRIMITIVE extraction in flywheel-installed substrate MUST:

1. **Consult this doctrine BEFORE authoring** — check the sub-shape catalog for known friction shapes that apply to the target extraction (composition flavor, test layer, module shape, type strictness).
2. **Apply the canonical resolution** when a sub-shape applies — don't re-derive the fix.
3. **Surface NEW friction shapes** that don't match any catalogued sub-shape — file an amendment row to this doctrine via the canonical mirror cycle. Each new shape becomes a candidate for promotion at ≥2 instances.
4. **Cite the sub-shape ID in the extraction commit body** — `Friction surfaces (N): [SUB-SHAPE-ID] short-description-of-recurrence` — so the recurrence ladder is auditable and the doctrine self-validates via future extractions surfacing the same shape.

## Sub-shape catalog (4 shapes — promoted 2026-05-11T05:20Z)

### Sub-shape #1 — `re-export-split` (CANONICAL META FRICTION; ≥2 instances)

**Pattern:** When a META-PRIMITIVE re-exports substrate primitives for consumer convenience, types and functions live in different module entry points (bare entry vs `/server` re-export). Consumers must use separate import statements per primitive — runtime imports from `/server`, type imports from bare entry. This is non-obvious to first-time consumers.

**Exemplars:**
| META | Commit | Friction citation |
|------|--------|-------------------|
| `@zeststream/stripe-toolkit` v0.0.1 | `zeststream-platform@7814d79` | "Bare-entry vs /server re-export — types in bare entry, functions in /server. Separate import statements per primitive documented in src/server/index.ts." |
| `@zeststream/admin-action-toolkit` v0.0.1 | `zeststream-platform@d83d94c` | "Re-export split (canonical META friction; recurred from #25): functions in /server, types in bare entry — separate imports per substrate package." |

**Canonical resolution:** Document the bare-entry-vs-`/server` split explicitly in `src/server/index.ts` header comment AND in the package README. For 7+ primitives composed by a META, provide a `/server` barrel that re-exports all runtime helpers from the substrate set so consumers can do a single import.

**Severity:** WARN — extraction proceeds; consumer DX cost only.

### Sub-shape #2 — `workspace-pre-build` (≥1 instance + signal recurrence)

**Pattern:** META-PRIMITIVE workspace packages depend on substrate packages built earlier in the same workspace. First test run of a freshly-extracted META fails because the substrate packages have no `dist/`. Pre-build sequence is required: build deps → typecheck META → test META.

**Exemplars:**
| META | Commit | Friction citation |
|------|--------|-------------------|
| `@zeststream/stripe-toolkit` v0.0.1 | `zeststream-platform@7814d79` | "Workspace deps require pre-build — first run failed because the 5 substrate packages had no dist/. Resolved by building deps first. Canonical META sequence: build deps → typecheck META → test META." |
| `@zeststream/http-client` v0.0.1 | `zeststream-platform@31434b3` | Implicit (6-axis composition with substrate packages; same build-order dependency shape) |

**Canonical resolution:** META packages MUST document the build-order in package README + provide a `prebuild` npm script that builds all declared substrate dependencies first. Workspace tooling (turbo / nx / pnpm-workspaces) SHOULD enforce build-order via topological sort.

**Severity:** WARN — extraction proceeds; first-run friction only; subsequent runs cached.

### Sub-shape #3 — `TS-inline-handler-implicit-any` (≥1 instance + signal recurrence)

**Pattern:** When a META-PRIMITIVE composes LAYERED primitives (one wrapping another), inline async handler signatures inside the composition chain are subject to TypeScript implicit-`any` inference failures. The fix is to declare the inner handler as a typed `const` first, then pass it to the outer wrapper.

**Exemplars:**
| META | Commit | Friction citation |
|------|--------|-------------------|
| `@zeststream/admin-action-toolkit` v0.0.1 | `zeststream-platform@d83d94c` | "TS implicit-any in inline async (input, ctx) handler inside protectedActionWrap — fix by declaring stepUpWrappedHandler as typed ProtectedActionHandler const first. NEW pattern: LAYERED METAs need explicit type anchors for inner handlers." |

**Canonical resolution:** For LAYERED-composition METAs (vs PARALLEL-composition), declare each layer's inner handler as a typed `const` with an explicit handler-shape type from the substrate package before passing it to the outer wrapper. Inline arrow handlers `(input, ctx) => ...` inside `outerWrap(...)` will lose type inference; the explicit-const pattern preserves it.

**Severity:** INFO — extraction proceeds with the canonical resolution; one-line refactor; no semantic change.

### Sub-shape #4 — `fake-timer-lifecycle` (≥1 instance + signal recurrence)

**Pattern:** Top-level `useFakeTimers()` + bottom-level `useRealTimers()` both run at module-eval, not at test-lifecycle. Real timers "win" because they execute second. Tests for time-gated composition (idempotency caches with TTLs, retry runners with backoff, etc.) require explicit per-test lifecycle hooks to install fake timers correctly.

**Exemplars:**
| META | Commit | Friction citation |
|------|--------|-------------------|
| `@zeststream/stripe-toolkit` v0.0.1 | `zeststream-platform@7814d79` | "vitest fake-timer module-load semantics — top-level useFakeTimers + bottom-level useRealTimers both run at module-eval; real timers won. Moved to beforeAll/afterAll lifecycle hooks. Canonical META-test pattern for time-gated composition." |

**Canonical resolution:** When a META-PRIMITIVE composes time-gated substrate (idempotency TTLs, retry backoff, timestamp tolerance), test files MUST install fake timers via `beforeAll(() => vi.useFakeTimers())` and `afterAll(() => vi.useRealTimers())` lifecycle hooks — NEVER as module-top-level statements. Module-eval-order is not test-lifecycle-order.

**Severity:** WARN — extraction proceeds; tests pass after lifecycle fix; first-run flakiness only.

## Anti-patterns

| Anti-pattern | Why it fails | Fix |
|--------------|--------------|-----|
| Re-deriving the friction resolution per extraction | Wastes worker cycle on already-solved problem; each extraction re-pays discovery cost | Consult this doctrine FIRST; cite sub-shape ID in commit; apply canonical resolution |
| Authoring a META without documenting build-order | Consumers hit `workspace-pre-build` friction at install; bad first impression of the META | Document `prebuild` npm script + README build-order section per Sub-shape #2 |
| Authoring a LAYERED-composition META with inline handlers | TS implicit-any obscures the composition's type contract | Declare each inner handler as typed `const` per Sub-shape #3 |
| Top-level `useFakeTimers()` in time-gated META test files | Module-eval order vs test-lifecycle order silently breaks tests | Use `beforeAll`/`afterAll` lifecycle hooks per Sub-shape #4 |
| Top-level single import barrel for META (no `/server` split) | Forces consumers to import all runtime + types via one entry; bloats bundle | Maintain bare-entry-vs-`/server` split per Sub-shape #1 + document explicitly |
| Surfacing a NEW friction shape WITHOUT amending this doctrine | Recurrence pattern lost; next worker re-pays discovery cost | File amendment row for canonical mirror cycle (skillos:1 + flywheel:1 byte-identical pattern) |

## Sister doctrine cross-references

This doctrine pairs with:

- **`audit-machinery-hygiene-discipline.md`** — Sister cluster for *audit-machinery* friction. Both doctrines codify recurring friction patterns at different system layers: audit-machinery hygiene catalogues probe/scorer/spec-extractor friction; meta-primitive-extraction friction catalogues package-extraction friction. Together they form the **codification-of-recurring-friction cluster**: any friction class observed at ≥2 instances should be codified as a canonical sub-shape rather than re-derived per occurrence.
- **`apfs-case-insensitivity-collision`** (memory file, sister candidate) — Filesystem-friction sub-shape under the META-EXTRACTION-DRIFT parent class. Currently 1-instance; promotes when next case-insensitivity bites an extraction.

## META-EXTRACTION-DRIFT parent class

This doctrine is the **extraction-velocity-friction sub-family** under META-EXTRACTION-DRIFT (Joshua-ratified 2026-05-11). META-EXTRACTION-DRIFT spans multiple sub-shape families:

- `meta-primitive-extraction-friction-class` (THIS doctrine — extraction-velocity friction; 4 sub-shapes)
- `apfs-case-insensitivity-collision` (filesystem-vector — 1-instance candidate)
- Future: dependency-version-skew-class, test-helper-import-cycle-class, etc.

Each sub-family canonicalizes a friction surface that the parent class predicts will recur as extraction scales. The parent class is the doctrine root; sub-families are the operational catalogs.

## Provenance — codification substrate

- `zeststream-platform@31434b3` — http-client META (7th pane-2 parallel; SMALL-MEDIUM ~50min)
- `zeststream-platform@7814d79` — stripe-toolkit META (FIRST pane-3 META; 5-primitive PARALLEL composition; 3 friction surfaces)
- `zeststream-platform@d83d94c` — admin-action-toolkit META (SECOND pane-3 META; 4-primitive LAYERED composition; 2 friction surfaces)
- 7 pane-2 extractions cumulative (postgres-tenant + webhook-toolkit + supabase-auth-middleware + api-toolkit + structured-logging + backoff-retry + http-client) = ~295min total = ~42min/extraction average
- 2 pane-3 META extractions (stripe-toolkit + admin-action-toolkit)
- Library Accretion Mission Phase 4 Wave-1 cumulative extraction velocity demonstrates META-PRIMITIVE pattern maturity

## Cross-orch protocol

This doctrine follows the same byte-identical mirror pattern as `audit-machinery-hygiene-discipline.md` v0.1 through v0.1.8 cycles — proven design-speed cadence:

- skillos:1 codifies (this commit) → flywheel:1 mirrors byte-identical via worker chain (when active substrate window opens) → bilateral sha256 match → joint ratification
- Joshua-veto window: 2026-05-11T11:20Z (6h from skillos:1 codification timestamp 05:20Z) per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol
- Default-accept thereafter
- mobile-eats orch continues parallel extraction independently; pulls from this doctrine as recurring frictions are encountered

## Future evolution (v0.2+ candidates)

The sub-shape ladder is open-ended. Each new friction surface that an extraction encounters and DOES NOT match an existing sub-shape becomes a v0.2 candidate. At ≥2 instances across distinct extractions, a candidate promotes to a canonical sub-shape. Operators surfacing new shapes MUST file the amendment row on the audit-execution branch with the shape→resolution delta.

Known v0.2+ candidates (not yet promoted):

- **Dependency-version-skew** — when a META composes substrate packages with overlapping transitive dependencies, version resolution can pick incompatible majors. Candidate friction; needs ≥2 instances.
- **Test-helper-import-cycle** — when META test helpers import from substrate test helpers, vitest module resolution can cycle. Candidate friction; needs ≥2 instances.
- **README-divergence-from-EXTRAS** — META package README drifts from the EXTRAS.json source_paths declaration. Candidate friction class; needs ≥2 instances.

## Mission anchor

`80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
