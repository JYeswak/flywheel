---
title: "Mission-Lock Paradigm Extension - Intent"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Mission-Lock Paradigm Extension - Intent

Plan arc: `mission-lock-paradigm-extension-2026-05-06`
Task: `plan-mission-lock-paradigm-extension-phase1-research-2026-05-06`
Phase: 1 research, Lane A problem-space inventory
Opened: 2026-05-06

## Trigger

Two peer orchestrators independently surfaced the same mission-lock failure
class within minutes. One framed it as missing substrate; the other framed it as
missing negative invariants. Both point upstream to `/flywheel:mission-lock`.

## Cross-Orch Row 151 - mobile-eats

Source: `~/.local/state/flywheel/cross-orch-coordination.jsonl`, ledger line
153, row field `151`.

Class: `mission-lock-undersells-design-system-substrate`

Verbatim finding summary:

> Mission-lock today produces ~5 docs but not substrate. mobile-eats locked
> 2026-05-04, found 10 substrate gaps (tokens, @theme, 7 shadcn primitives,
> behavior config, 4 CI gates, identity layer, SEO baseline, density caps,
> Founder cohort, dispute substrate) requiring 5d Phase 0 + 3-5d cleanup =
> 10-15d debt per project.

Payload details from source finding:

```text
mobile-eats was mission-locked 2026-05-04 but tonight's UX audit (2 days later)
surfaced 8 categories of substrate that had NEVER been built: design tokens,
canonical shadcn primitives, _primitives/ compositions, behavior config, 4 CI
gates, SEO baseline, identity layer, density caps. Phase 0 substrate work for
these = 5 days. All knowable at lock-time. Mission-lock describes destination
but doesn't produce substrate to get there.
```

Root cause from source finding:

```text
mission-lock template doesn't include design-system substrate scaffolding,
identity layer scaffolding, SEO/a11y baseline enforcement, or pre-encoded
universal Q-decisions
```

Missing substrate list from source finding:

1. `lib/design/tokens.ts`
2. `app/globals.css` `@theme` inline projection
3. 7 canonical shadcn primitives in `components/ui/`
4. `_primitives/` composition layer
5. `lib/design/behavior.ts`
6. 4 CI gates: tokens-tailwind, density, purity, primitive-reuse
7. identity layer scaffolding
8. SEO + metadata baseline per route
9. mission-locked density caps as Q-decision
10. Founder cohort substrate
11. dispute substrate, named in the acknowledgement summary

Recommendations from source finding:

1. `/flywheel:new-project`: add scaffold validator step that fails project init
   if substrate artifacts are missing.
2. `/flywheel:mission-lock`: pre-encode universal Q-decisions in the MISSION
   template so projects start from a pre-amended baseline.
3. `mission-lock-readiness-doctor.sh`: add a doctor that tests whether a lock is
   substrate-complete and can backfill mobile-eats, skillos, and flywheel.

Three-strike status:

```text
already_breached_at_filing - this is the master trauma class; prior fragmented
findings (we forgot tokens, inconsistent buttons, density got out of hand) are
symptoms
```

Joshua framing from source finding:

```text
everything we're doing here should have been caught in much greater detail in
our mission-lock process. send a message to flywheel pane 1 with a detailed
analysis on what needs to improve in our mission lock to never let any of this
ux / front end token work wait until later in the mission again
```

## Cross-Orch Row 152 - alps

Source: `~/.local/state/flywheel/cross-orch-coordination.jsonl`, ledger line
154, row field `152`.

Class: `mission-lock-must-elicit-negative-invariants`

Verbatim finding summary:

> alps mission-lock 2026-05-04 (lock-id 417660fc, 14/14 sections) MISSED class
> of invariants: data-lifecycle (no fallback EVER, scaffold-then-delete not
> scaffold-then-fallback), trap-class cross-refs
> (testing-real-service-e2e-no-mocks <-> runtime-data-fallback same trap),
> skill-arsenal-by-surface mapping, negative invariants ("we will NEVER ship X"),
> failure-mode audit per substrate. ~6h alps avoidable work this session.

Five fix categories from source finding:

1. data-lifecycle invariants
2. trap-class cross-references
3. skill-arsenal-by-surface mapping
4. negative invariants
5. failure-mode audit per substrate

Joshua quotes in order:

1. "we have an e2e skill that specifically says no mocks"
2. "we also have a bunch of saas skills that we can use"
3. "i don't want fallback data - real or nothing"
4. "fallback data is hard to find later on"
5. "most of this should have been caught in our mission lock process"

Disposition from source finding:

```text
flywheel-1-acknowledged-paradigm-class; will land alongside row_151 fix as
combined /flywheel:mission-lock template extension
```

## Shared Trauma Class

These are the same trauma class at different framings:

- mobile-eats names the substrate gap: tokens, primitives, CI gates, and design
  scaffolds that should exist at lock time.
- alps names the invariants gap: negative rules, trap-class cross-refs, data
  lifecycle constraints, and skill mappings that should be elicited at lock
  time.
- Both name `/flywheel:mission-lock` as the leverage point.
- Two independent peer orchestrators converged on the same upstream failure;
  treat this as 3-strike-equivalent urgency.

## Donella Read

Canonical Meadows numbering:

- #5 Rules: mission-lock must become a rule-bearing contract that can refuse
  "locked" when substrate or invariants are missing.
- #6 Information flows: the lock artifact must name missing substrate and
  negative invariants before workers start building features.
- #4 Self-organization: later phases should define a readiness/audit surface so
  every repo can test its own lock completeness.

Dispatch shorthand also used #5/#6 for rules and information flows. This plan
keeps the dispatch shorthand as evidence metadata but analyzes with canonical
Meadows numbering.

## Phase 1 Scope

Lane A owns problem-space inventory only:

- taxonomy
- gap inventory
- lying-by-default failure-mode matrix
- criticality matrix
- cross-project risk generalization
- concrete Donella stocks, flows, loops, and leverage points

Lane B is queued for ecosystem audit. Lane C is queued for implementation
design. This phase does not mutate skills, scripts, existing repo missions, or
project source code.
