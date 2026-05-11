---
name: additive-v0.0.2-expansion-after-v0.0.1-under-extraction
type: doctrine
created: 2026-05-11
version: v0.3
status: HARDENED-3-OF-3-WITH-3-PRESSURE-SUB-TYPES-PROMOTION-READY (1st: release-fallback v0.0.2 AUTHOR-REDISCOVERY pressure; 2nd: chat-share-extractor v0.0.2 AUTHOR-REDISCOVERY-DURING-EXTRACTION pressure; 3rd: process-triage v0.0.2 AUDIT-DISCOVERY pressure via 4e8c178 ship; PLUS sister doctrine CONSUMER-PRESSURE-DRIVEN-VARIANT-ADDITION represents CONSUMER-PRESSURE sub-type via security-hygiene v0.0.2; cumulative 4 sub-typed instances across 3 distinct pressure mechanisms; promotion-ready)
v0_3_updated_at: 2026-05-11T23:15Z per mobile-eats:1 process-triage v0.0.2 ratification handoff 20260511T224000Z confirming 3rd-instance + DEPTH-AXIS-MISMATCH adjacent doctrine surfaced
pressure_sub_types_observed:
  - CONSUMER-PRESSURE (sister doctrine: security-hygiene v0.0.2 absorbing AMBIGUOUS-NOT-A-REPO variant after consumer surfaced gap)
  - AUTHOR-REDISCOVERY (release-fallback v0.0.2: author realized v0.0.1 covered WHEN; new extraction covers WHAT)
  - AUTHOR-REDISCOVERY-DURING-EXTRACTION (chat-share-extractor v0.0.2: dispatch discovered v0.0.1 was under-extraction mid-ship)
  - AUDIT-DISCOVERY (process-triage v0.0.2: audit surfaced the v0.0.1 under-extraction gap)
authority: mobile-eats:1 surfaced via 2 ratification handoffs 2026-05-11T~22:00Z (release-fallback v0.0.2 SOURCE-PROJECT-AGGREGATION-FROM-3-REPOS handoff) + ~22:30Z (chat-share-extractor v0.0.2 ADDITIVE handoff); skillos:1 codified as canonical-locator 2026-05-11T~23:05Z per Joshua-directive 14:45Z + outbox-discipline 22:30Z (ntm-send paired)
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T220000Z-from-mobile-eats-1-ratification-release-fallback-v0.0.2-SOURCE-PROJECT-AGGREGATION-FROM-3-REPOS-NEW-META.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T223000Z-from-mobile-eats-1-ratification-chat-share-extractor-v0.0.2-ADDITIVE-plus-DISPATCH-ASSUMES-FRESH-2nd-instance.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - dispatch-assumes-fresh-extraction-but-package-preexists.md (SISTER — both surface during dispatch-discovery; ADDITIVE-V0.0.2 is the ship-pattern; DISPATCH-ASSUMES is the operational PRE-CHECK that surfaces the under-extraction case)
  - primitive-layer-expansion-within-existing-package.md (SISTER — substrate-side coexistence; ADDITIVE-V0.0.2 is the version-level instance of the broader pattern)
  - source-project-aggregation-from-n-repos.md (SISTER — release-fallback v0.0.2 demonstrated both patterns simultaneously; same ship, different doctrines)
  - hook-chain-extend-vs-replace.md (SISTER — both are EXTEND-not-REPLACE patterns; one for substrate versions, one for operational hooks)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when promotion ratification packet sent
default_accept_window: n/a — HARDENED 2/2; awaits cross-orch ratification packet
cluster: substrate-lifecycle-doctrine-cluster
---

# ADDITIVE-V0.0.2-EXPANSION-AFTER-V0.0.1-UNDER-EXTRACTION

**Status:** HARDENED 2/2 instances
**Class:** substrate-version lifecycle pattern — when v0.0.1 slot is taken but new extraction is COMPLEMENTARY rather than competing
**Sister:** DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS (operational PRE-CHECK), PRIMITIVE-LAYER-EXPANSION-WITHIN-EXISTING-PACKAGE (substrate-side coexistence), SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS, HOOK-CHAIN-EXTEND-VS-REPLACE

## The pattern

When dispatching a new substrate extraction (`@zeststream/<name>` v0.0.1), the package may ALREADY EXIST at v0.0.1 because:
1. A prior extraction shipped under same name (v0.0.1 slot taken)
2. The new extraction is COMPLEMENTARY (not competing) — different axis of the same problem

The naive failure mode: blocked, defer, file rework. The correct response: ship as **v0.0.2 additive expansion** that complements v0.0.1's existing surface area without redesigning it.

The pattern requires:
- Both v0.0.1 + new content fall under the same problem umbrella (e.g., release-fallback: v0.0.1 WHEN-to-fall-back + v0.0.2 WHAT-to-emit)
- Both versions COEXIST (additive expansion; no breaking changes; both surfaces available to consumers)
- New content uses SELF-AWARE-SUBSTRATE-API design (const-set + derived-type) so v0.0.2 type-checks alongside v0.0.1

## Origin instances (2 same-session 2026-05-11)

### Instance 1: @zeststream/release-fallback v0.0.2 (commit d7b2eb7, 22:00Z handoff)

Pane-3 ship. Scope clarified: v0.0.1 slot already taken (decision-policy WHEN-to-fall-back); new extraction is COMPLEMENTARY (WHAT-to-emit). Shipped as v0.0.2 additive expansion under same N34 umbrella:
- v0.0.1 retained (WHEN-to-fall-back canonical)
- v0.0.2 ADDS (WHAT-to-emit canonical)
- Both available; type-checked; SELF-AWARE designed-in v0.0.2

### Instance 2: @zeststream/chat-share-extractor v0.0.2 (22:30Z handoff)

Pane-2 ship. Same pattern: dispatch assumed FRESH extraction (v0.0.1 slot expected available); discovered v0.0.1 was UNDER-EXTRACTION; shipped as v0.0.2 additive expansion that completes the under-extracted scope without redesigning v0.0.1's existing surface.

## Why this pattern matters

Without ADDITIVE-V0.0.2-EXPANSION-AFTER-V0.0.1-UNDER-EXTRACTION discipline, the naive responses to "v0.0.1 already exists" are:
1. **Block dispatch** — wastes the discovery + scope work done in dispatch authoring; substrate gap remains unfilled
2. **Force redesign as v1.0** — sweeping major-version bump for a complementary addition; consumer migration cost
3. **File new package name** — produces substrate fragmentation; consumers must know about both packages

The additive-v0.0.2 pattern is strictly better: existing v0.0.1 preserved + new content shipped + consumers can opt into either or both surfaces.

## Sister-doctrine integration

- **DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS**: operational PRE-CHECK pattern that SURFACES the under-extraction case. Without PRE-CHECK, dispatcher discovers mid-ship; with PRE-CHECK + 5-outcome enumeration (ADDITIVE-V0.0.2 as one of the outcomes), dispatcher anticipates correctly.
- **PRIMITIVE-LAYER-EXPANSION-WITHIN-EXISTING-PACKAGE**: substrate-side coexistence (single package, additive surfaces). ADDITIVE-V0.0.2 is the version-level instance of this broader pattern.
- **SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS**: release-fallback v0.0.2 demonstrated BOTH patterns simultaneously (SOURCE-AGG via 3 upstream repos + ADDITIVE-V0.0.2 via complementary expansion). Same ship, different doctrines.
- **HOOK-CHAIN-EXTEND-VS-REPLACE**: structurally analogous EXTEND-not-REPLACE pattern at operational-hook level rather than substrate-version level. Both demonstrate: respect existing legitimate content + add complementary functionality.

## Hardening threshold

- 1 instance = signal candidate
- 2 instances = HARDENED canonical (this state)
- 3+ instances = doctrine-promotion-ready

## Operator action when dispatch discovers v0.0.1 already exists

1. **PRE-CHECK** the package state (per sister doctrine DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS): does v0.0.1 already exist? What does it cover?
2. **Determine relationship**: is the new extraction COMPLEMENTARY to v0.0.1's existing scope, or COMPETING?
   - Complementary → ADDITIVE-V0.0.2 expansion
   - Competing → reconsider (v0.0.2 patch redesign? v1.0 major-version?)
3. **Verify additive ship preserves backward-compat**: existing v0.0.1 consumers should see no breaking changes
4. **Design v0.0.2 with SELF-AWARE-SUBSTRATE-API** so type-checked coexistence is natural
5. **Ship + document additive expansion in CHANGELOG** explicitly naming the v0.0.1 scope being complemented
6. **Tag substrate** with `sourcing_pattern: <whatever applies>` + note that this is an ADDITIVE-V0.0.2-EXPANSION

## Related doctrine

- **DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS** (sister operational PRE-CHECK)
- **PRIMITIVE-LAYER-EXPANSION-WITHIN-EXISTING-PACKAGE** (sister substrate-side coexistence)
- **SOURCE-PROJECT-AGGREGATION-FROM-N-REPOS** (release-fallback v0.0.2 demonstrated both)
- **HOOK-CHAIN-EXTEND-VS-REPLACE** (structurally analogous EXTEND pattern at hook level)
- **SELF-AWARE-SUBSTRATE-API** (extensibility design that enables backward-compatible v0.0.2 expansion)
