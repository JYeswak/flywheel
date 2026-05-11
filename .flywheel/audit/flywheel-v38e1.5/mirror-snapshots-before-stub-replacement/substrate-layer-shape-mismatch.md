---
name: substrate-layer-shape-mismatch
type: doctrine
created: 2026-05-11
version: v0.3
status: HARDENED-4-INSTANCES-PROMOTION-READY (1st: pi_agent_rust hostcall_* audit ~21:30Z LAYER-MISMATCH; 2nd: rch audit ~21:50Z DOMAIN-MISMATCH; 3rd: W2-T2 grok-voice-demos audit ~22:35Z LAYER-MISMATCH; 4th: W2-T9 vibe_cockpit audit ~22:50Z LAYER-MISMATCH; doctrine HARDENED 4-instance; promotion-ready; 3-axis OUT-OF-SCOPE taxonomy validated alongside DEPTH-MISMATCH + sister DISPATCH-PREMISE-MISMATCH which surfaced concurrent to 4th instance)
v0_3_updated_at: 2026-05-11T23:30Z per mobile-eats:1 W2-T9 vibe_cockpit handoff confirming 4th-instance + concurrent DISPATCH-PREMISE-MISMATCH 1st-instance observation (sister-axis to substrate-fit verdicts)
v0_2_updated_at: 2026-05-11T23:10Z per mobile-eats:1 W2-T2 grok-voice-demos handoff confirming 3rd-instance LAYER-MISMATCH ratification (voice.yaml already in right home; substrate would duplicate or thin-wrap; honest scope-discipline)
authority: mobile-eats:1 surfaced via 2 ratification handoffs 2026-05-11T~21:30Z (pi_agent_rust) + ~21:50Z (rch); skillos:1 codified as canonical-locator 2026-05-11T~22:45Z per Joshua-directive 2026-05-11T~14:45Z + outbox-discipline rule 22:30Z (ntm-send paired with codification)
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T213000Z-from-mobile-eats-1-W2-D5-audit-3-NEW-META-observations.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T215000Z-from-mobile-eats-1-W2-D2-audit-OUT-OF-SCOPE-plus-SUBSTRATE-LAYER-SHAPE-MISMATCH-HARDENED-2-of-2.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - substrate-layer-discovery.md (SISTER — SHAPE-MISMATCH is the OUT-OF-SCOPE sub-axis distinguishing LAYER-MISMATCH from DOMAIN-MISMATCH; complements 3-layer canonical taxonomy with re-scan-tractable verdict)
  - meta-aggregation-waiting-for-3rd-instance.md (SISTER — both refinements to META-AGGREGATION lifecycle states; SHAPE-MISMATCH about audit verdicts, WAITING-FOR-3RD about ratification states)
  - cross-language-audit-as-cousin-scout.md (SISTER — cross-language audits naturally surface SHAPE-MISMATCH when target platform diverges from current substrate-extraction language scope)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when promotion ratification packet sent
default_accept_window: n/a — HARDENED 2/2 promotion-ready; awaits cross-orch ratification packet
cluster: audit-verdict-doctrine-cluster
---

# SUBSTRATE-LAYER-SHAPE-MISMATCH

**Status:** HARDENED 2/2 instances; promotion-ready as canonical audit-verdict variant
**Class:** OUT-OF-SCOPE sub-axis refinement — distinguishes LAYER-MISMATCH from DOMAIN-MISMATCH in audit-verdict taxonomy
**Sister:** SUBSTRATE-LAYER-DISCOVERY (3-layer canonical taxonomy), META-AGGREGATION-WAITING-FOR-3RD-INSTANCE (lifecycle state refinement)

## The pattern

When auditing a candidate substrate (e.g., during cross-language or cross-platform extraction audits), OUT-OF-SCOPE verdicts partition into TWO distinct sub-axes that have DIFFERENT operational implications:

1. **SUBSTRATE-LAYER-SHAPE-MISMATCH** — candidate substrate's structural layer doesn't fit the current 3-layer canonical taxonomy (composition / runtime / primitive) OR doesn't fit the target platform's expected layer. Re-scan tractable when target platform expands (e.g., adopting Rust would unlock currently-mismatched Rust candidates).
2. **DOMAIN-MISMATCH** — candidate substrate's domain (insurance, polymarket-bot, etc.) doesn't fit the current substrate-extraction scope. Re-scan rarely productive; domain-class is structurally fixed.

**Critical operational implication:** LAYER-MISMATCH candidates deserve re-scan when target platform expands; DOMAIN-MISMATCH candidates rarely justify re-scan. Without this sub-axis distinction, both would be treated as terminal OUT-OF-SCOPE, losing the latent value of LAYER-MISMATCH candidates.

## Origin instances (2 cross-language audits, 2026-05-11)

### Instance 1: pi_agent_rust audit (handoff 21:30Z)

- pane-2 audited 108 .rs files; ~33min under-budget
- Verdict: CANDIDATE-CATALOG (0 extractions; 2 cousin-convergence findings parked: compaction.rs 2/3 LLM-context-window-management; flake_classifier.rs 1/3 test-failure classification)
- 1st instance of LAYER-MISMATCH sub-axis: Rust modules' shape didn't fit current TypeScript-canonical substrate-extraction scope, but compaction.rs is structurally 2/3 cousin to @zeststream/prompt-trimmer-substrate

### Instance 2: rch audit (handoff 21:50Z)

- pane-2 audited rch ~30min
- Verdict: OUT-OF-SCOPE-DOMAIN-MISMATCH (0 extractions; scope-discipline rejected 3 speculative candidates)
- 2nd instance: rch's domain didn't fit substrate-extraction scope; this is the DOMAIN-MISMATCH branch
- BUT mobile-eats:1 observed: LAYER-MISMATCH would be the recoverable case, DOMAIN-MISMATCH is not. So both audits surfaced the 2-axis sub-distinction.

## Why this sub-axis matters

Without SUBSTRATE-LAYER-SHAPE-MISMATCH refinement, OUT-OF-SCOPE is a binary terminal verdict. Operators have no signal about which OUT-OF-SCOPE candidates are worth re-considering. The 2-axis refinement:

- LAYER-MISMATCH → file as "latent candidate; re-scan when target-platform expands" (e.g., adding Rust extraction lane unlocks pi_agent_rust's compaction.rs)
- DOMAIN-MISMATCH → file as "terminal out-of-scope; domain-class not currently extractable"

This converts OUT-OF-SCOPE from terminal to tractable for the LAYER subset. Operationally: future audits can budget re-scan time for known LAYER-MISMATCH backlog when platform scope expands.

## Anti-pattern this prevents

"OUT-OF-SCOPE means done; move on" — when LAYER-MISMATCH is the actual class. Counters: LAYER-MISMATCH candidates are valuable; they're not extractable NOW but become extractable LATER. Without sub-axis distinction, these get lost in the OUT-OF-SCOPE bucket.

Inverse: "All OUT-OF-SCOPE deserves re-scan" — wastes time re-scanning DOMAIN-MISMATCH candidates that are structurally fixed.

## Hardening threshold

- 1 instance = signal candidate
- 2 instances = HARDENED canonical (this state — promotion-ready)
- 3+ instances = doctrine-promotion ready

## Operator action when issuing OUT-OF-SCOPE verdict

Always sub-classify into LAYER vs DOMAIN:

1. **LAYER-MISMATCH:** candidate's structural layer doesn't fit current canonical taxonomy OR target platform. File as "latent candidate; re-scan trigger: target-platform expansion to <X>". Maintain a CANDIDATE-CATALOG for these.
2. **DOMAIN-MISMATCH:** candidate's content domain doesn't fit substrate-extraction scope. File as "terminal; rationale: <domain>". No re-scan trigger.

Audit dispatch packets should require sub-classification when verdict is OUT-OF-SCOPE.

## Related doctrine

- **SUBSTRATE-LAYER-DISCOVERY** (3-layer canonical taxonomy; SHAPE-MISMATCH is the OUT-OF-SCOPE sub-axis that complements the 3-layer extraction discipline)
- **META-AGGREGATION-WAITING-FOR-3RD-INSTANCE** (sister lifecycle-state refinement; CANDIDATE-CATALOG can contain WAITING-FOR-3RD-INSTANCE entries when LAYER-MISMATCH would become tractable with 3rd cousin-convergence instance)
- **CROSS-LANGUAGE-AUDIT-AS-COUSIN-SCOUT** (sister; cross-language audits surface SHAPE-MISMATCH naturally when target platform diverges from current scope)
- **DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE** (operational improvement: dispatch packets should enumerate all 4 verdicts including OUT-OF-SCOPE-LAYER-MISMATCH sub-axis)
