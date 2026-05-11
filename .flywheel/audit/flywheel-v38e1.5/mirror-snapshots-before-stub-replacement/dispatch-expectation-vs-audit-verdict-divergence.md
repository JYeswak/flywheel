---
name: dispatch-expectation-vs-audit-verdict-divergence
type: doctrine
created: 2026-05-11
version: v0.2
status: HARDENED-2-OF-2-VIA-OPERATIONAL-ADOPTION (1st: rch audit handoff 21:50Z surfaced pattern; 2nd: mobile-eats:1 source-to-prompt v0.0.1 23:00Z handoff confirmed 5-outcome dispatch verification VALIDATED THROUGH REAL USE; chat-share-extractor v0.0.2 + source-to-prompt v0.0.1 dispatches both used 5-outcome enumeration; in-flight WD1 + WT2 are 3rd+4th-instance candidates with PRE-CHECK + 5-outcome enumeration in flight)
v0_2_updated_at: 2026-05-11T23:00Z per mobile-eats:1 catch-up handoff confirming operational adoption validated through real use; promotion-ready
authority: mobile-eats:1 surfaced + adopted operationally; skillos:1 codified as canonical-locator
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T215000Z-from-mobile-eats-1-W2-D2-audit-OUT-OF-SCOPE-plus-SUBSTRATE-LAYER-SHAPE-MISMATCH-HARDENED-2-of-2.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator; operational improvement adopted by mobile-eats:1)
sister:
  - substrate-layer-shape-mismatch.md (SISTER — both refine OUT-OF-SCOPE audit verdict surface area; DIVERGENCE about pre-dispatch enumeration, SHAPE-MISMATCH about post-audit sub-classification)
  - canonical-cli-scoping (sister — operator-API design discipline; dispatch packets should enumerate possible outcomes by analogy to canonical-cli `--help` enumerating possible flags)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when 2nd-instance hardens
default_accept_window: n/a — 1-instance with operational adoption; needs 2nd-instance dispatch-packet using full 4-verdict enumeration to harden
cluster: dispatch-protocol-doctrine-cluster
---

# DISPATCH-EXPECTATION-VS-AUDIT-VERDICT-DIVERGENCE

**Status:** 1-instance with operational adoption; needs 2nd-instance to harden
**Class:** dispatch-protocol operational improvement — make all possible audit verdicts visible in dispatch packets, not just the expected outcome
**Sister:** SUBSTRATE-LAYER-SHAPE-MISMATCH (verdict sub-axis sister), canonical-cli-scoping (operator-API design discipline)

## The pattern

When dispatching an audit task (e.g., cross-language audit, fleet-classifier audit, substrate-extraction audit), dispatch packets traditionally name the EXPECTED outcome ("expect 3-5 extractions; OUT-OF-SCOPE acceptable if domain mismatches"). This produces a divergence pattern when the audit returns an outcome outside the named expectations:

- **Dispatcher expected**: EXTRACTIONS (with OUT-OF-SCOPE as fallback)
- **Audit returned**: CANDIDATE-CATALOG (latent-but-not-extractable now) OR OUT-OF-SCOPE-LAYER-MISMATCH (recoverable later) OR OUT-OF-SCOPE-DOMAIN-MISMATCH (terminal)

When the returned verdict was outside the dispatch's named scope, callbacks have to invent new framing inline. Operators may also under-recognize legitimate-but-unexpected verdicts as "audit failure" rather than "scope-discipline win."

**Fix:** dispatch packets should enumerate ALL 4 possible verdicts up front, so callbacks always have a canonical label:

1. **EXTRACTIONS** (primary expected outcome)
2. **CANDIDATE-CATALOG** (latent-but-valuable; tractable later)
3. **OUT-OF-SCOPE-LAYER-MISMATCH** (re-scan when target platform expands)
4. **OUT-OF-SCOPE-DOMAIN-MISMATCH** (terminal; no re-scan)

## Origin instance (W2-D2 rch audit, 2026-05-11T~21:50Z)

Mobile-eats:1 pane-2 audited rch ~30min. Dispatch packet expected EXTRACTIONS or OUT-OF-SCOPE. Audit returned OUT-OF-SCOPE-DOMAIN-MISMATCH (0 extractions; scope-discipline rejected 3 speculative candidates).

Without explicit 4-verdict enumeration in dispatch:
- Callback would frame as "audit returned 0 extractions; might be misclassified"
- Dispatcher might re-dispatch with adjusted parameters thinking the audit needed re-scoping
- Latent value of DISTINGUISHING-LAYER-VS-DOMAIN-MISMATCH would be lost

With explicit 4-verdict enumeration in dispatch (mobile-eats:1 adopted going forward 2026-05-11T~21:50Z):
- Callback unambiguously classifies OUT-OF-SCOPE-DOMAIN-MISMATCH as terminal-correct outcome
- Dispatcher recognizes scope-discipline win (3 speculative candidates correctly rejected)
- LAYER vs DOMAIN distinction is preserved for future re-scan eligibility

**Mobile-eats:1 dispatch convention going forward:** every audit dispatch packet enumerates 4 possible verdicts; callbacks classify into one + provide rationale.

## Why this matters (and why divergence happens)

Dispatch packets evolve from operator expectations. The operator expects a primary outcome (EXTRACTIONS). OUT-OF-SCOPE is included as a known-fallback. CANDIDATE-CATALOG + LAYER-vs-DOMAIN sub-axis are discoveries that emerged AFTER dispatch templates were authored. Until templates update, divergence is structural.

The operational improvement: ENUMERATE all known verdict classes in dispatch templates as they're discovered. Treat dispatch templates as a learning surface, not a static contract.

**Sister pattern: canonical-cli-scoping.** Dispatch templates are operator-facing CLI surfaces. CLI design discipline says: enumerate all known flags/outcomes in `--help`. Same principle: enumerate all known verdicts in dispatch packet contract.

## Anti-pattern this prevents

"Dispatch only mentions the expected outcome; callback figures it out" — produces divergence-recovery overhead per off-expected-outcome callback. Counters: enumerate all known verdicts upfront; callbacks have canonical labels.

Inverse: "Enumerate every possible verdict including speculative ones" — produces dispatch-template bloat that doesn't reflect actual audit reality. Only enumerate VERDICTS THAT HAVE BEEN OBSERVED at least once + the expected primary outcome.

## Hardening threshold

- 1 instance with operational adoption (this state)
- 2 instances of dispatch using full 4-verdict enumeration = HARDENED canonical
- 3+ instances = doctrine-promotion-ready

## Operator action when authoring an audit dispatch

1. List all VERDICT CLASSES that have been observed in prior similar audits
2. Include all of them in dispatch packet's "Possible callback verdicts" section
3. For each verdict: name the operator action that should follow (re-dispatch / file CANDIDATE-CATALOG entry / file LAYER-MISMATCH for re-scan / file DOMAIN-MISMATCH terminal)
4. Callback must classify into one of the enumerated verdicts + provide rationale
5. If callback proposes a NEW verdict class not in the dispatch's enumeration: surface to canonical-locator (skillos:1 per Joshua-directive 14:45Z) for doctrine consideration

## Related doctrine

- **SUBSTRATE-LAYER-SHAPE-MISMATCH** (sister verdict-refinement doctrine; SHAPE-MISMATCH is the post-audit sub-classification, DIVERGENCE is the pre-dispatch enumeration)
- **canonical-cli-scoping** (sister operator-API design discipline; same enumerate-all-known-outcomes principle)
- **CROSS-LANGUAGE-AUDIT-AS-COUSIN-SCOUT** (sister; cross-language audits frequently surface verdict-divergence; one of the natural surfaces where this discipline matters)
