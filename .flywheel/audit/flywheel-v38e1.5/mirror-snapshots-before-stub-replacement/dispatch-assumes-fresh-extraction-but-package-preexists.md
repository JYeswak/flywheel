---
name: dispatch-assumes-fresh-extraction-but-package-preexists
type: doctrine
created: 2026-05-11
version: v0.3
status: HARDENED-3-OF-3-PROMOTION-STRENGTH (1st: release-fallback v0.0.2 22:00Z; 2nd: chat-share-extractor v0.0.2 22:30Z; 3rd: process-triage v0.0.2 4e8c178 23:15Z via PRE-CHECK adoption — PRE-CHECK step validated 3rd consecutive time; operational protocol matured; promotion-ready)
v0_3_updated_at: 2026-05-11T23:20Z per mobile-eats:1 process-triage v0.0.2 ratification handoff confirming 3rd consecutive PRE-CHECK validation; operational protocol now mature
authority: mobile-eats:1 surfaced + adopted operationally via 22:30Z + 22:31Z handoffs; skillos:1 codified as canonical-locator 2026-05-11T~23:10Z per Joshua-directive + outbox-discipline (ntm-paired)
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T220000Z-from-mobile-eats-1-ratification-release-fallback-v0.0.2-SOURCE-PROJECT-AGGREGATION-FROM-3-REPOS-NEW-META.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T223000Z-from-mobile-eats-1-ratification-chat-share-extractor-v0.0.2-ADDITIVE-plus-DISPATCH-ASSUMES-FRESH-2nd-instance.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - additive-v0.0.2-expansion-after-v0.0.1-under-extraction.md (SISTER — DISPATCH-ASSUMES is the operational PRE-CHECK; ADDITIVE-V0.0.2 is the ship-pattern outcome when PRE-CHECK surfaces package-preexists)
  - dispatch-expectation-vs-audit-verdict-divergence.md (SISTER — both improve dispatch packet contracts; ADD-PRE-CHECK is the operational mirror of ADD-5-OUTCOME-ENUMERATION; same pattern at extraction vs audit dispatch surfaces)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when promotion ratification packet sent
default_accept_window: n/a — HARDENED 2/2 with operational adoption; promotion-ready
cluster: dispatch-protocol-doctrine-cluster
---

# DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS

**Status:** HARDENED 2/2 with operational adoption; promotion-ready
**Class:** dispatch-protocol failure-mode + operational PRE-CHECK pattern
**Sister:** ADDITIVE-V0.0.2-EXPANSION-AFTER-V0.0.1-UNDER-EXTRACTION (the ship-pattern outcome), DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE (sibling dispatch-improvement)

## The pattern

Extraction dispatches default to assuming v0.0.1 slot is available for the named package. When the package ALREADY EXISTS (because a prior extraction shipped under same name, with under-extraction OR complementary scope), dispatchers discover mid-ship + must scramble to choose between:
1. Re-ship as v0.0.2 additive (sister doctrine ADDITIVE-V0.0.2-EXPANSION-AFTER-V0.0.1-UNDER-EXTRACTION)
2. Force major-version bump (rare; only if existing surface needs redesign)
3. Re-scope under different package name (substrate fragmentation; avoided)
4. Defer + file rework bead (loses session momentum)

**Fix:** dispatchers should ALWAYS PRE-CHECK package state BEFORE dispatching extraction work + enumerate 5 possible outcomes in dispatch packet:

1. **FRESH-EXTRACTION** (primary expected outcome) — package doesn't exist; ship v0.0.1
2. **ADDITIVE-V0.0.2-EXPANSION** — package exists; new extraction is complementary; ship v0.0.2 additive (per sister doctrine)
3. **CONFLICTING-REDESIGN-V1.0** — package exists; new extraction competes with existing scope; major-version bump warranted
4. **OUT-OF-SCOPE-DUPLICATE** — package exists; new extraction would duplicate existing surface; skip (file no-op decision)
5. **OUT-OF-SCOPE-WRONG-PACKAGE-NAME** — package exists under correct name but new extraction belongs elsewhere; re-scope under different package name

## Origin instances (2 same-session 2026-05-11)

### Instance 1: release-fallback v0.0.2 discovery (22:00Z handoff)

Pane-3 dispatch expected FRESH-EXTRACTION for @zeststream/release-fallback. Discovered mid-ship: v0.0.1 slot already taken (decision-policy WHEN-to-fall-back). New extraction was COMPLEMENTARY (WHAT-to-emit). Scrambled to choose between options; landed on ADDITIVE-V0.0.2-EXPANSION (outcome #2 above). Ship friction added ~5-10min for the dispatch-discovery realization.

### Instance 2: chat-share-extractor v0.0.2 discovery (22:30Z handoff)

Pane-2 dispatch expected FRESH-EXTRACTION for @zeststream/chat-share-extractor. Discovered mid-ship: v0.0.1 was UNDER-EXTRACTION. Same dispatch-assumption failure-class as instance 1. Landed on ADDITIVE-V0.0.2-EXPANSION (outcome #2). Same ~5-10min friction overhead.

**Mobile-eats:1 adoption going forward:** every extraction dispatch packet MUST include PRE-CHECK step + 5-outcome enumeration. In-flight WD1 + WT2 are first dispatches using the improved contract.

## Why this matters (and why divergence happens)

Dispatch templates evolved when fresh-extraction was the dominant case. As the Wave-2 substrate catalog grew (~40+ packages this session arc), the probability that "the package name I want is already taken" rose. Without PRE-CHECK + 5-outcome enumeration, every extraction risks mid-ship dispatch-discovery friction.

Operational improvement: PRE-CHECK adds ~30s of dispatcher overhead BEFORE dispatch; saves 5-10min mid-ship dispatch-discovery overhead AND produces canonical-labeled outcomes (vs ad-hoc framing).

## Sister-doctrine pair pattern

DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE (sister at audit-dispatch surface) and this doctrine (at extraction-dispatch surface) are the SAME OPERATIONAL PATTERN at different dispatch surfaces:

| Surface | Doctrine | Improvement | Outcomes enumerated |
|---|---|---|---|
| **Audit dispatch** | DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE | Pre-enumerate 4 verdicts | EXTRACTIONS / CANDIDATE-CATALOG / OUT-OF-SCOPE-LAYER-MISMATCH / OUT-OF-SCOPE-DOMAIN-MISMATCH |
| **Extraction dispatch** | DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS | PRE-CHECK + pre-enumerate 5 outcomes | FRESH-EXTRACTION / ADDITIVE-V0.0.2 / CONFLICTING-REDESIGN-V1.0 / OUT-OF-SCOPE-DUPLICATE / OUT-OF-SCOPE-WRONG-NAME |

Both improvements share the same META principle: **enumerate KNOWN outcomes in dispatch packets so callbacks have canonical labels**. As outcomes emerge from operational reality, dispatch templates absorb them.

## Anti-pattern this prevents

"Dispatch assumes fresh; figure out mid-ship if package exists" — produces dispatch-discovery friction. Counters: PRE-CHECK + 5-outcome enumeration anticipates all observed outcomes.

Inverse: "PRE-CHECK before every trivial dispatch" — over-applies the discipline to dispatches where fresh-extraction probability is high (e.g., dispatches for newly-named substrates). Apply PRE-CHECK selectively when the package-name-collision risk is non-trivial.

## Hardening threshold

- 1 instance = signal candidate
- 2 instances with operational adoption = HARDENED canonical (this state — promotion-ready)
- 3+ instances = doctrine-promotion-ready (in-flight WD1 + WT2 = 3rd+4th instance candidates)

## Operator action when authoring an extraction dispatch

1. **PRE-CHECK step**: `gh api repos/.../packages OR npm view @zeststream/<name>` — does the package exist? at what version? what's its current scope?
2. **Enumerate 5 outcomes** in dispatch packet (see canonical list above)
3. **For each outcome**: name the operator action that should follow
4. **Callback classifies** into one of the 5 outcomes + provides rationale
5. **If callback proposes a NEW outcome class** not in dispatch's enumeration: surface to canonical-locator (skillos:1 per Joshua-directive 14:45Z)

## Related doctrine

- **ADDITIVE-V0.0.2-EXPANSION-AFTER-V0.0.1-UNDER-EXTRACTION** (sister; ship-pattern outcome #2 when PRE-CHECK surfaces package-preexists)
- **DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE** (sister; same META principle at audit-dispatch surface)
- **canonical-cli-scoping** (sister; enumerate-all-known-outcomes principle from CLI design)
