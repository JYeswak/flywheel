---
name: dispatch-premise-mismatch
type: doctrine
created: 2026-05-11
version: v0.2
status: HARDENED-2-OF-2-PROMOTION-READY (1st: W2-T9 vibe_cockpit audit ~22:50Z dispatch framed as Python+Rust pair → source-reality Rust-CLI product binary; 2nd: ME multi-embedder-strategy cousin-scout ~23:15Z dispatch framed as xf-has-multi-embedder-pattern → source-reality xf-imports-pattern-from-frankensearch; both surface DISPATCH-FRAMING-WRONG vs SOURCE-REALITY; promotion-ready as canonical 7th audit-outcome variant)
v0_2_updated_at: 2026-05-11T23:15Z per mobile-eats:1 DOUBLE cousin-scout ratification handoff confirming 2nd-instance via ME multi-embedder dispatch-premise-mismatch
authority: mobile-eats:1 surfaced via ratification handoff 2026-05-11T~22:50Z (1st) + double cousin-scout handoff 2026-05-11T~23:15Z (2nd-instance hardening); skillos:1 codified as canonical-locator + outbox-paired 2026-05-11T~23:30Z (v0.1) + 2026-05-11T~17:55Z bumped to v0.2 HARDENED
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T225000Z-from-mobile-eats-1-ratification-W2-T9-vibe-cockpit-DISPATCH-PREMISE-MISMATCH-7th-outcome-plus-Joshua-context-bundle.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T231500Z-from-mobile-eats-1-ratification-DOUBLE-cousin-scout-text-canonicalization-LOOSE-MATCH-plus-multi-embedder-CONSUMER-REUSE-plus-DISPATCH-PREMISE-MISMATCH-HARDENED-2-of-2.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - dispatch-expectation-vs-audit-verdict-divergence.md (SISTER — DISPATCH-PREMISE-MISMATCH is the 7th candidate outcome for audit-dispatch enumeration; pre-dispatch fact-check pattern)
  - dispatch-assumes-fresh-extraction-but-package-preexists.md (SISTER — both are PRE-CHECK pattern; PREMISE-MISMATCH is the source-reality-check counterpart of PACKAGE-PREEXISTS package-state-check)
  - substrate-layer-shape-mismatch.md (SISTER — vibe_cockpit dispatch surfaced both DISPATCH-PREMISE-MISMATCH AND LAYER-MISMATCH; the two are observed concurrently in the same audit)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when 2nd-instance hardens
default_accept_window: n/a — 1-instance candidate; needs 2nd-instance
cluster: dispatch-protocol-doctrine-cluster
proposed_dispatch_template_addition: PREMISE-CHECK step in audit-dispatch packets — verify dispatch's framing claims (language pair, cousin-substrate hypothesis, repo coupling) against source-reality BEFORE running audit
---

# DISPATCH-PREMISE-MISMATCH

**Status:** HARDENED 2/2 instances; promotion-ready as canonical 7th audit-outcome variant
**Class:** dispatch-protocol failure-mode — when dispatch framing premise wrong vs source-reality
**Sister:** DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE (audit-verdict enumeration), DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS (PRE-CHECK pattern; both extend dispatch contract)

## The pattern

Audit dispatches encode a PREMISE about source-reality: language pair, cousin-substrate hypothesis, repo-coupling assumption, layer expectation. The premise informs scope + estimated effort.

When dispatch executes, sometimes the premise is wrong:
- Dispatch framed as "Python + Rust pair triage"; source is actually Rust-CLI product binary (no Python pair exists)
- Dispatch framed as "cousin to existing substrate X"; source is actually distinct from X
- Dispatch framed as "fleet-applicable primitive"; source is actually product-specific

When premise is wrong, the audit's primary verdict ALSO surfaces a META-finding: **the dispatch framing itself was wrong**, separate from whether the source is extractable.

The two findings have DIFFERENT operational implications:
1. **Substrate-fit verdict** (4-axis enumeration: EXTRACTIONS / CANDIDATE-CATALOG / OUT-OF-SCOPE-LAYER / OUT-OF-SCOPE-DOMAIN / OUT-OF-SCOPE-DEPTH per sister doctrines)
2. **DISPATCH-PREMISE-MISMATCH verdict** (the dispatch's framing was structurally wrong; future dispatches should PREMISE-CHECK)

Sister-pair: DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE handles outcome-divergence; DISPATCH-PREMISE-MISMATCH handles framing-divergence. Both improve dispatch contracts.

## 2nd-instance hardening (ME multi-embedder cousin-scout, 2026-05-11T~23:15Z)

Pane-3 dispatched to multi-embedder-strategy 2nd-instance cousin-scout (META-AGGREGATION-WAITING-FOR-3RD-INSTANCE ratification test). Dispatch was framed as **xf has multi-embedder pattern** (cousin-substrate hypothesis).

Source-reality discovered:
- xf IS NOT the source of multi-embedder pattern — xf is a CONSUMER
- The actual source is `frankensearch` (Dicklesworthstone/frankensearch.git): xf imports frankensearch-core + frankensearch-embed + frankensearch-fusion + frankensearch-index via Cargo git-deps
- `xf::ModelCategory` maps to `frankensearch_core::ModelCategory` at line 267
- 3 KNOWN CONSUMERS documented in `frankensearch-integration-for-rust-projects` skill: xf + CASS + mcp_agent_mail

Dispatch premise (xf-has-pattern) wrong vs source-reality (xf-imports-pattern-from-frankensearch). This is the 2nd-instance class match with vibe_cockpit's Python+Rust→Rust-only finding: BOTH show dispatch framing structurally wrong vs source-reality, surfacing a META-finding distinct from the substrate-fit verdict.

Operational implication: PREMISE-CHECK should include **cousin-source verification** — if dispatch claims "X has pattern P", verify P originates in X (not imported from elsewhere). This adds a sub-step to the PREMISE-CHECK protocol.

## Origin instance (W2-T9 vibe_cockpit audit, 2026-05-11)

Pane-3 audited vibe_cockpit ~12min. Dispatch was framed as **Python + Rust pair triage** (anticipated dual-language scope; expected cousin-substrate findings across both languages).

Source-reality discovered:
- vibe_cockpit is a Rust-CLI product binary, NOT a Python+Rust pair
- No Python pair exists
- Substrate would be product-specific layer not fleet-primitive layer

Two concurrent verdicts:
1. **OUT-OF-SCOPE-LAYER-MISMATCH** (substrate-fit verdict; 4th instance of SUBSTRATE-LAYER-SHAPE-MISMATCH)
2. **DISPATCH-PREMISE-MISMATCH** (dispatch framing premise wrong vs source-reality)

The dispatch-improvement implication: future audit-dispatches should include a **PREMISE-CHECK step** verifying framing claims against source-reality BEFORE running the audit. ~30s of pre-dispatch checking (look at the repo's actual file extensions + entry points) saves ~10-12min of audit work that ends in DISPATCH-PREMISE-MISMATCH verdict.

## Why this is a real dispatch-protocol failure-mode

Dispatch templates inherit from operator expectations. When operators frame dispatch based on incorrect premises (memory-of-repo-state, assumed-cousin-relationships, etc.), the audit work runs anyway and reaches verdict by RUNNING the audit even though the dispatch was structurally wrong from the start.

Operational improvement: PREMISE-CHECK before dispatch. Same META principle as DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS (PRE-CHECK package state) and DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE (pre-enumerate verdicts). All three improvements share: **enumerate-and-check before dispatch, not after**.

## Sister-axis to audit-dispatch enumeration

Per DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE's 4-outcome (now 6-outcome with DEPTH-MISMATCH addition pending hardening) enumeration: DISPATCH-PREMISE-MISMATCH may be the **7th outcome** to add. But it's a different KIND of outcome — substrate-fit verdicts describe SOURCE; PREMISE-MISMATCH describes DISPATCH. Possible canonical labeling:

| Outcome class | What it describes |
|---|---|
| Outcomes 1-6 (substrate-fit) | What the SOURCE is/isn't |
| Outcome 7 (DISPATCH-PREMISE-MISMATCH) | What the DISPATCH FRAMING got wrong |

This bifurcation (source-fit vs dispatch-framing) may itself be a META-pattern worth documenting once 2nd-instance hardens.

## Anti-pattern this prevents

"Run the audit; figure out the dispatch framing was wrong mid-audit" — wastes audit work. Counters: PREMISE-CHECK detects framing wrongness in ~30s pre-dispatch.

Inverse: "PREMISE-CHECK every dispatch exhaustively" — over-applies discipline; pre-dispatch overhead doesn't always pay back. Apply selectively when dispatch framing makes non-trivial claims (cousin-substrate, language-pair, repo-coupling).

## Hardening threshold

- 1 instance = signal candidate
- 2 instances = HARDENED canonical (this state — promotion-ready)
- 3+ instances = doctrine-promotion ready

**Hardened sub-class pattern (2/2 instances observed):**
- vibe_cockpit: language-pair-claim wrong (Python+Rust→Rust-only)
- multi-embedder: cousin-source-claim wrong (xf-has-pattern→xf-imports-from-frankensearch)
- Both have the same META-shape: dispatch framing makes a structural-relationship claim about source; source-reality refutes the claim; audit work still produces substrate-fit verdict but META-finding for dispatch-template improvement surfaces separately.

**3rd-instance promotion candidates (future):**
- Dispatches framed with repo-coupling claims that turn out structurally distinct
- Dispatches framed with layer-class claims that don't match source-reality
- Any audit where ~30s pre-dispatch PREMISE-CHECK would have prevented ~10-30min of audit work

## Operator action when authoring audit dispatch with non-trivial framing claims

1. **PREMISE-CHECK step** (~30s pre-dispatch):
   - If language-pair claimed: verify repo actually has both languages
   - If cousin-substrate claimed: verify source has structural similarity to claimed cousin
   - If repo-coupling claimed: verify the coupling is real (not assumed from memory)
2. **Document premise** in dispatch packet so callback can flag DISPATCH-PREMISE-MISMATCH if discovered
3. **Add PREMISE-MISMATCH as 7th outcome** to dispatch's enumeration (per sister doctrine improvement)
4. **If PREMISE-MISMATCH discovered mid-audit**: surface immediately; substrate-fit verdict still applies as primary; DISPATCH-PREMISE-MISMATCH is META-finding for dispatch-template improvement

## Related doctrine

- **DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE** (sister; 4-outcome enumeration → 6-outcome with DEPTH → 7-outcome with PREMISE-MISMATCH)
- **DISPATCH-ASSUMES-FRESH-EXTRACTION-BUT-PACKAGE-PREEXISTS** (sister PRE-CHECK pattern; package-state-check counterpart of PREMISE-MISMATCH source-reality-check)
- **SUBSTRATE-LAYER-SHAPE-MISMATCH** (sister; vibe_cockpit audit surfaced both verdicts concurrently)
- **DEPTH-AXIS-MISMATCH** (sister; 3-axis OUT-OF-SCOPE taxonomy)
