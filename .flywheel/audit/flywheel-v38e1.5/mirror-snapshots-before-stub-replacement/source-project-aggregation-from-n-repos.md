---
name: source-project-aggregation-from-n-repos
type: doctrine
created: 2026-05-11
version: v0.2
status: HARDENED-2-OF-2-N-REPOS-GENERIC-PROMOTION-READY (1st: @zeststream/release-fallback v0.0.2 d7b2eb7 N=3 doodlestein_self_releaser+scoop-bucket+homebrew-tap; 2nd: @zeststream/source-to-prompt v0.0.1 N=2 per mobile-eats:1 WT56 ship 2026-05-11T~22:31Z handoff; both clean ships validate sub-family at N=2 + N=3, refining naming from FROM-3-REPOS-specific to FROM-N-REPOS-generic; promotion-ready)
v0_2_updated_at: 2026-05-11T23:00Z per mobile-eats:1 catch-up handoff confirming N=2 hardens N-generic framing
authority: mobile-eats:1 surfaced via ratification handoff 2026-05-11T~22:00Z (release-fallback v0.0.2 ship); skillos:1 codified as canonical-locator 2026-05-11T~22:55Z per Joshua-directive 2026-05-11T~14:45Z + outbox-discipline rule 22:30Z
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T220000Z-from-mobile-eats-1-ratification-release-fallback-v0.0.2-SOURCE-PROJECT-AGGREGATION-FROM-3-REPOS-NEW-META.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - meta-aggregation-family.md (SISTER — adds REPO-LEVEL granularity as new sub-family alongside PRACTICES + IMPLEMENTATIONS sub-families)
  - meta-primitive-sourcing-pattern-taxonomy.md (SISTER — 4-axis sourcing taxonomy; REPO-AGGREGATION may warrant a new Shape #10 if 2nd-instance hardens)
  - same-day-discovery-to-consumer-ratification.md (SISTER — N-repo aggregation typically requires multi-session unless same-day applies)
  - fast-path-via-previous-authorship.md (SISTER — N-repo aggregation has different velocity profile than single-author extraction)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when 2nd-instance hardens to N-REPOS-GENERIC
default_accept_window: n/a — 1-instance candidate; 2nd-instance test in flight (WT56 source-to-prompt 2-repo aggregation)
cluster: sourcing-pattern-doctrine-cluster
proposed_axis_position: candidate for Shape #10 in meta-primitive-sourcing-pattern-taxonomy.md when 2nd-instance hardens
---

# SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS

**Status:** 1-instance candidate; 2nd-instance test in flight (WT56)
**Class:** sourcing-pattern sub-family at REPO-LEVEL granularity (vs substrate-implementation-level granularity)
**Sister:** META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS (substrate-level), META-AGGREGATION-OF-SHIPPED-PRACTICES (operational-config-level), meta-primitive-sourcing-pattern-taxonomy (the 4-axis taxonomy this may extend)

## The pattern

META-AGGREGATION family (codified earlier 2026-05-11) currently has 2 sub-families:
- **Sub-family A — META-AGGREGATION-OF-SHIPPED-PRACTICES** (operational/config from N ratifications; e.g., security-hygiene v0.0.1)
- **Sub-family B — META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS** (substrate-package source code from N substrate impls; e.g., atomic-file-write-primitive v0.0.1)

**SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS is a NEW sub-family at REPO-LEVEL granularity:**
- Sources are N EXTERNAL/UPSTREAM REPOSITORIES (not internal substrate impls, not operational practices)
- The canonical extracts a primitive from N upstream OSS projects that solve adjacent variants of the same problem
- Aggregation absorbs the best architectural decisions across N upstream conventions

This sub-family distinguishes from sub-families A + B by:
- Source granularity: REPOSITORIES (vs operational configs vs substrate-package impls)
- Source authorship: EXTERNAL/UPSTREAM (vs internal-team operational practice vs internal-team substrate impl)
- Convergence shape: cross-OSS-project convergence on similar problem patterns

## Origin instance (release-fallback v0.0.2, 2026-05-11)

`@zeststream/release-fallback` v0.0.2 (commit `d7b2eb7` pane3/main; 79/79 tests; ~85min wall; friction=0)

Source repos aggregated:
1. **doodlestein_self_releaser** — self-release automation patterns
2. **scoop-bucket** — Windows package manager bucket conventions
3. **homebrew-tap** — macOS package manager tap conventions

Each upstream solves the WHAT-to-emit problem in a release-fallback context (different platforms; different distribution mechanisms; same underlying primitive of "emit release manifest when canonical channel fails").

The release-fallback v0.0.2 canonical absorbed best-of-3 architectural decisions:
- Distribution schema (versioned via `skillos.release-fallback.distribution.v1`)
- 5 const-set exports (SELF-AWARE-SUBSTRATE-API designed-in)
- Additive expansion alongside v0.0.1 WHEN-to-fall-back complementary doctrine (PRIMITIVE-LAYER-EXPANSION-WITHIN-EXISTING-PACKAGE sister doctrine)

Wave-2 counter 39 → 40.

## Why this is a real new sub-family (not just a META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS variant)

The 2 prior sub-families source from INTERNAL artifacts:
- Sub-family A: N internal operational practices (e.g., per-repo `.gitleaks.toml` configs)
- Sub-family B: N internal substrate-package impls (e.g., scraper-hardening checkpointStore)

Sub-family C (this one) sources from EXTERNAL repositories. The differences:
- **Coordination overhead**: external repos have no shared coordination layer. Best-of-N synthesis requires reading each repo's conventions cold.
- **Convergence signal strength**: internal SUBSTRATE-COUSIN-CONVERGENCE is "we accidentally solved this 3 times". External convergence is "the broader OSS ecosystem also converged on this primitive" — stronger structural-pressure-response evidence.
- **Velocity profile**: external sourcing has higher upfront cost (read N repos) but produces more battle-tested canonicals (each upstream has its own users).

## 2nd-instance test in flight

Mobile-eats:1 pane-3 currently on WT56 source-to-prompt 2-repo paired aggregation (~30-45min). If WT56 ships clean using same REPO-LEVEL aggregation pattern, this sub-family HARDENS at 2/2.

**Important refinement question (mobile-eats:1 flagged):** is the sub-family naming better as:
- `SOURCE-PROJECT-AGGREGATION-FROM-3-REPOS` (specific to 3-repo case)
- `SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS` (N-generic, allows 2/3/4/... repos)

If WT56 ships with N=2, that confirms N-REPOS-GENERIC framing. Current codification uses N-REPOS-GENERIC name with notation that "release-fallback v0.0.2 used N=3; WT56 will test N=2".

## Hardening threshold

- 1 instance = signal candidate (this state — release-fallback v0.0.2 d7b2eb7 with N=3)
- 2 instances same sub-family = HARDENED canonical (WT56 will test if ships clean)
- 3+ instances = doctrine-promotion-ready

If WT56 ships clean: **HARDENED 2/2**, refines naming to N-REPOS-GENERIC.

## Anti-pattern this prevents

"Source from a single upstream OSS project; copy as-is" — produces local fork without aggregation discipline; misses cross-upstream improvements. Counters: SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS specifies that N≥2 upstream sources are required for the sub-family.

Inverse: "Aggregate from N internal substrates" — that's sub-family B (META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS), not sub-family C. The distinction matters because internal vs external sources have different coordination costs + convergence-signal strengths.

## Operator action when extracting from external OSS

1. Identify N≥2 upstream OSS repositories solving adjacent variants of same primitive problem
2. Read each upstream's conventions cold (no shared coordination layer)
3. Synthesize best-of-N architectural decisions into canonical
4. Document provenance: each source repo + commit SHA + which decisions came from which
5. Ship canonical with SELF-AWARE-SUBSTRATE-API designed-in (paired const-set + derived-type)
6. Tag substrate with `sourcing_pattern: SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS` in package metadata

## Related doctrine

- **meta-aggregation-family.md** (parent doctrine; this is sub-family C complementing sub-families A + B)
- **meta-primitive-sourcing-pattern-taxonomy.md** (4-axis sourcing taxonomy; SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS may become Shape #10 when 2nd-instance hardens)
- **self-aware-substrate-api.md** (release-fallback v0.0.2 shipped with SELF-AWARE designed-in; same pattern as sub-families A + B)
- **primitive-layer-expansion-within-existing-package** (sister 1-instance candidate; release-fallback v0.0.2 also demonstrated this pattern via additive expansion alongside v0.0.1)
- **same-session-feedback-loop-closure.md** (META velocity-leverage; release-fallback v0.0.2 was ~85min ship — not same-session sub-1-hour, but is the right benchmark for N-repo aggregation cycles)
