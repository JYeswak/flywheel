---
name: depth-axis-mismatch
type: doctrine
created: 2026-05-11
version: v0.2
status: HARDENED-2-OF-2-PROMOTION-READY (1st: W2-T8 process-triage v0.0.2 audit ~23:15Z deferred ~2400 LOC distribution math; 2nd: W2-T9 xf Rust tool audit deferred per same DEPTH threshold ~23:50Z per mobile-eats:1 Wave-2 deep-scan completion handoff; doctrine HARDENED 2/2 same-session same-source-fit-cleared-but-DEPTH-exceeded class; promotion-ready)
v0_2_updated_at: 2026-05-11T23:55Z per mobile-eats:1 WAVE-2 deep-scan COMPLETE handoff confirming 2nd-instance DEPTH-MISMATCH ratification via xf audit
authority: mobile-eats:1 surfaced via process-triage ratification handoff 2026-05-11T~23:15Z; skillos:1 codified as canonical-locator + outbox-paired per discipline 2026-05-11T~23:25Z
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T224000Z-from-mobile-eats-1-ratification-process-triage-v0.0.2-TRIPLE-3-of-3-HARDENING-plus-DEPTH-AXIS-MISMATCH.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - substrate-layer-shape-mismatch.md (SISTER — both are OUT-OF-SCOPE sub-axis refinements; together with DOMAIN-MISMATCH form 3-axis OUT-OF-SCOPE taxonomy: LAYER + DOMAIN + DEPTH)
  - dispatch-expectation-vs-audit-verdict-divergence.md (SISTER — DEPTH-AXIS-MISMATCH may warrant adding 6th outcome to audit dispatch enumeration)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when 2nd-instance hardens
default_accept_window: n/a — 1-instance candidate; needs 2nd-instance to harden
cluster: audit-verdict-doctrine-cluster
proposed_taxonomy_addition: 3-axis OUT-OF-SCOPE refinement (LAYER + DOMAIN + DEPTH); SUBSTRATE-LAYER-SHAPE-MISMATCH should reference DEPTH as adjacent sister-axis
---

# DEPTH-AXIS-MISMATCH

**Status:** 1-instance signal candidate; 2nd-instance needed
**Class:** THIRD audit-verdict sub-axis (sister to LAYER + DOMAIN) — substantial port work deliberately NOT extracted despite source-fit when implementation-detail-depth exceeds substrate-value-per-LOC
**Sister:** SUBSTRATE-LAYER-SHAPE-MISMATCH (1st axis), domain-mismatch (2nd axis; absorbed into SHAPE-MISMATCH's DOMAIN branch); DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE (may add 6th outcome)

## The pattern

When auditing a candidate substrate, OUT-OF-SCOPE verdicts previously partitioned into 2 sub-axes:
1. **LAYER-MISMATCH** — structural layer doesn't fit 3-layer canonical taxonomy
2. **DOMAIN-MISMATCH** — content domain doesn't fit extraction scope

**A THIRD axis surfaces:**
3. **DEPTH-MISMATCH** — source-fit + layer-fit + domain-fit ALL clear, BUT implementation-detail-depth exceeds substrate-value-per-LOC. Substrate would be too thick for its value-add; extraction deferred until consumer demand justifies the LOC cost.

The discriminator test: Could a clean substrate carry the canonical interface in <300 LOC? If yes → extract. If extraction would require >300 LOC of implementation-detail-port (math distribution algorithms, complex state machines, etc.) → DEPTH-MISMATCH; defer until consumer demand justifies.

The 300-LOC threshold is a heuristic; refine via 2nd+ instances.

## Origin instance (process-triage v0.0.2 audit, 2026-05-11)

W2-T8 process-triage v0.0.2 ship (commit 4e8c178). Source artifact had ~2400 LOC of distribution math (substantial implementation depth). All 3 prior axes cleared:
- LAYER: primitive (pure-function distribution math)
- DOMAIN: substrate-extraction scope (process-triage is fleet-applicable)
- SHAPE: not blocked

But the audit DEFERRED extraction. Rationale: ~2400 LOC for distribution math would produce a substrate too thick for its value-add at current consumer demand level. Substrate-value-per-LOC threshold not met. Decision: defer pending 2nd-instance consumer demand that would justify the LOC cost.

The audit verdict shape: OUT-OF-SCOPE-DEPTH-MISMATCH. Different operational implication than LAYER-MISMATCH or DOMAIN-MISMATCH:
- LAYER: re-scan when target-platform expands
- DOMAIN: terminal; no re-scan
- **DEPTH: re-scan when consumer demand reaches threshold** (could be 1-2 weeks vs LAYER's months)

## Why this third axis matters

Without DEPTH-MISMATCH discipline, substrate extraction would fall into 2 traps:
1. **Over-extraction**: substantial-LOC port work shipped despite low consumer demand; substrate becomes maintenance burden without commensurate value
2. **Under-recognition**: substantial-LOC sources get categorized as "out-of-scope" without distinguishing why; LAYER vs DOMAIN vs DEPTH conflated

DEPTH-AXIS-MISMATCH preserves a distinct verdict for "would extract if consumer demand justified" cases. This makes the deferred-extraction queue tractable: skillos:1 (or any future operator) can re-scan DEPTH-MISMATCH candidates when consumer demand rises, without re-deriving the scope analysis.

## Sister-axis integration: 3-axis OUT-OF-SCOPE taxonomy

| Axis | Cause | Re-scan trigger |
|---|---|---|
| **LAYER-MISMATCH** | Layer doesn't fit canonical taxonomy or target platform | Target platform expansion |
| **DOMAIN-MISMATCH** | Domain doesn't fit substrate-extraction scope | None (terminal) |
| **DEPTH-MISMATCH** | All fits but implementation-depth exceeds value-per-LOC threshold | Consumer demand reaches threshold |

The 3 axes have DIFFERENT re-scan trigger profiles. Operators should classify OUT-OF-SCOPE verdicts into one of the 3 (or "OUT-OF-SCOPE-MULTI-AXIS" if multiple apply) to surface the correct re-scan trigger.

## Implication for DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE

DEPTH-AXIS-MISMATCH may warrant adding a 6th outcome to audit-dispatch enumeration (currently 4 outcomes: EXTRACTIONS / CANDIDATE-CATALOG / OUT-OF-SCOPE-LAYER-MISMATCH / OUT-OF-SCOPE-DOMAIN-MISMATCH). 2nd-instance ratification of DEPTH-MISMATCH would justify the dispatch-template update.

## Anti-pattern this prevents

"Extract everything that source-fits; let consumers figure out value" — over-extraction; substrate maintenance burden without value-per-LOC justification. Counters: DEPTH-MISMATCH discipline gates substantial-LOC ports behind consumer-demand threshold.

Inverse: "Defer all substantial-LOC ports indefinitely" — misses cases where consumer demand DOES justify the LOC cost. Counters: DEPTH-MISMATCH is conditional defer; explicitly leaves re-scan trigger documented.

## Hardening threshold

- 1 instance = signal candidate (this state)
- 2 instances same sub-axis = HARDENED canonical
- 3+ instances = doctrine-promotion-ready

**2nd-instance hardening candidates:**
- Any future cross-language audit where source-fit + layer-fit + domain-fit all clear BUT implementation-depth is substantial
- Specifically: audits surfacing 500+ LOC port work where consumer demand is unclear

## Operator action when verdict is OUT-OF-SCOPE

Always classify into the 3-axis taxonomy:

1. **LAYER-MISMATCH** + document re-scan trigger (target platform expansion)
2. **DOMAIN-MISMATCH** + mark terminal
3. **DEPTH-MISMATCH** + document re-scan trigger (consumer-demand threshold) + estimate LOC cost
4. **MULTI-AXIS** if multiple apply + document each axis's re-scan trigger

Maintain a CANDIDATE-CATALOG for LAYER + DEPTH mismatches (re-scan-eligible); DOMAIN mismatches go to terminal-archive.

## Related doctrine

- **SUBSTRATE-LAYER-SHAPE-MISMATCH** (sister 1st-axis doctrine; should be updated to reference DEPTH as adjacent sister-axis when DEPTH hardens 2/2)
- **DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE** (sibling dispatch-improvement; DEPTH-MISMATCH may warrant 6th outcome enumeration when hardened)
- **CROSS-LANGUAGE-AUDIT-AS-COUSIN-SCOUT** (audit-class where DEPTH-MISMATCH is most likely to surface; substantial-LOC ports are common in cross-language audits)
