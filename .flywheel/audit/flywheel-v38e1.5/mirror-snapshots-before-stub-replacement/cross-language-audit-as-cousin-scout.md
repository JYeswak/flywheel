---
name: cross-language-audit-as-cousin-scout
type: doctrine
created: 2026-05-11
version: v0.1
status: HARDENED-3-INSTANCES-WITH-CALIBRATION-BASELINE (1st: pi_agent_rust audit 21:30Z 2 cousin-scout findings + 1 LAYER-MISMATCH = HIGH-yield; 2nd: rch audit 21:50Z 0 findings + DOMAIN-MISMATCH = LOW-yield; 3rd: xf Rust tool audit ~23:50Z 2 cousin-scout findings + DEPTH-MISMATCH = HIGH-yield; 33% HIGH-yield empirical rate baseline; doctrine HARDENED 3-instance; CROSS-LANGUAGE-AUDIT-VALUE-TIERS calibration data integrated)
authority: mobile-eats:1 surfaced via 3 ratification handoffs 2026-05-11T~21:30Z + ~21:50Z + ~23:50Z (Wave-2 completion); skillos:1 codified as canonical-locator + outbox-paired 2026-05-11T~24:00Z
source_handoffs:
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T213000Z-from-mobile-eats-1-W2-D5-audit-3-NEW-META-observations.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T215000Z-from-mobile-eats-1-W2-D2-audit-OUT-OF-SCOPE-plus-SUBSTRATE-LAYER-SHAPE-MISMATCH-HARDENED-2-of-2.md
  - /Users/josh/Developer/skillos/.flywheel/handoffs/20260511T230000Z-from-mobile-eats-1-WAVE-2-DEEP-SCAN-COMPLETE-plus-DEPTH-AXIS-MISMATCH-HARDENED-2-of-2.md
codification_method: HANDOFF-BODY-TO-CANONICAL (skillos:1 canonical-locator)
sister:
  - substrate-layer-shape-mismatch.md (SISTER — cross-language audits frequently surface LAYER-MISMATCH; 4/N instances)
  - depth-axis-mismatch.md (SISTER — cross-language audits frequently surface DEPTH-MISMATCH; 2/2 instances)
  - dispatch-premise-mismatch.md (SISTER — cross-language audits frequently surface PREMISE-MISMATCH; 1/N instance)
  - meta-aggregation-waiting-for-3rd-instance.md (SISTER — cross-language audits seed META-AGGREGATION WAITING entries via cousin-scout findings)
ratification_target: skillos:1 canonical-locator role; flywheel:1 ratify-UP via canonical-doctrine-sync when promotion ratification packet sent
default_accept_window: n/a — HARDENED 3-instance with calibration baseline; promotion-ready
cluster: audit-strategy-doctrine-cluster
empirical_calibration_2026_05_11: 33% HIGH-yield rate across 3 cross-language audits (pi_agent_rust HIGH + rch LOW + xf HIGH = 2/3 = 66% wait actually that's 2/3 = 66% HIGH; correcting from mobile-eats 33% framing which may have been calibrated against a larger N including non-cousin-scout audits)
---

# CROSS-LANGUAGE-AUDIT-AS-COUSIN-SCOUT

**Status:** HARDENED 3-instance with calibration baseline; promotion-ready
**Class:** audit-strategy doctrine — cross-language audits as portfolio-class research investment with empirical value-tier baseline
**Sister:** SUBSTRATE-LAYER-SHAPE-MISMATCH, DEPTH-AXIS-MISMATCH, DISPATCH-PREMISE-MISMATCH, META-AGGREGATION-WAITING-FOR-3RD-INSTANCE

## The pattern

Cross-language audits (auditing source repos in languages outside the current substrate-extraction scope — e.g., Rust modules when current scope is TypeScript) are **portfolio-class research investments**, not deterministic extraction operations. Some audits surface cousin-substrate candidates (HIGH-yield); some surface only LAYER/DOMAIN/DEPTH/PREMISE mismatches with 0 cousin-scout value (LOW-yield).

The PRINCIPAL DELIVERABLE is the CANDIDATE-CATALOG (cousin-scout findings + mismatch classifications), NOT extractions. Extractions are bonus when source-fit + layer-fit + domain-fit + depth-fit + premise-fit all clear.

This reframes cross-language audits from "extract everything that source-fits" to "scout for cousin-substrate candidates + classify mismatches for future re-scan eligibility."

## Origin instances (3 cross-language audits, 2026-05-11)

### Instance 1: pi_agent_rust audit (21:30Z) — HIGH-yield

- 108 .rs files; ~33min under-budget
- Verdict: CANDIDATE-CATALOG with 2 parked cousin-scout findings:
  - compaction.rs is 2/3 cousin to @zeststream/prompt-trimmer-substrate (LLM-context-window-management)
  - flake_classifier.rs is 1/3 cousin to @zeststream/bead-quality-scorer (test-failure classification)
- Plus 1 LAYER-MISMATCH classification (Rust hostcall_* surface)
- HIGH-yield because: 2 cousin-scout findings + 1 layer-classification

### Instance 2: rch audit (21:50Z) — LOW-yield

- ~30min
- Verdict: OUT-OF-SCOPE-DOMAIN-MISMATCH (0 cousin findings; scope-discipline rejected 3 speculative candidates)
- LOW-yield because: 0 cousin findings; only DOMAIN-MISMATCH classification

### Instance 3: xf Rust tool audit (23:50Z) — HIGH-yield

- Per Wave-2 deep-scan completion handoff
- 2 cousin-scout findings:
  - text-canonicalization (canonicalize.rs sister to chat-share normalizeLineTerminators; 1+1 match; needs 3rd)
  - multi-embedder-strategy META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS candidate (1-instance held; needs 2nd ZS-side)
- Plus 1 DEPTH-MISMATCH classification
- HIGH-yield because: 2 cousin-scout findings + 1 depth-classification

## CROSS-LANGUAGE-AUDIT-VALUE-TIERS — empirical calibration baseline

Per mobile-eats:1 Wave-2 completion calibration (2026-05-11T~23:50Z):
- **HIGH-yield rate observed: 33% empirical** across cross-language audits in Wave-2
- Mobile-eats's 33% figure may reflect calibration against broader audit-set (including non-cousin-scout audits + DOMAIN-only audits)
- Per skillos:1 narrow accounting of 3-instance cohort: 2 HIGH (pi_agent + xf) + 1 LOW (rch) = 66% HIGH-yield
- True portfolio rate likely between 33-66%; need larger N to refine

**Operational implication:** budget cross-language audits as **portfolio-class research investment**:
- Each audit costs ~15-30min wall
- Expected ~33-66% HIGH-yield outcome (1+ cousin-scout finding)
- HIGH-yield value: 1-2 cousin-scout candidates → future META-AGGREGATION-WAITING-FOR-3RD-INSTANCE entries → potential 2-3hr substrate extraction when 3rd instance hardens
- LOW-yield value: still produces mismatch classifications useful for future re-scan eligibility (LAYER + DOMAIN + DEPTH + PREMISE 4-axis verdicts)

Even LOW-yield cross-language audits are NOT zero-value: they prune the candidate space + populate the CANDIDATE-CATALOG with terminal-archive entries.

## Why this reframes audit strategy

Without CROSS-LANGUAGE-AUDIT-AS-COUSIN-SCOUT discipline, operators frame cross-language audits as deterministic extraction operations + may judge LOW-yield audits as failed. Counters: cross-language audits are **portfolio investments** with expected value across both HIGH and LOW outcomes. Reframing prevents both:
1. **Over-pessimism**: "Most cross-language audits don't yield extractions; stop running them" → loses HIGH-yield cousin-scout findings that compound substrate value over time
2. **Over-optimism**: "Every cross-language audit must yield extractions" → produces dispatch-template bloat + audit-effort waste when source-fit doesn't clear

## Sister-doctrine integration

- **SUBSTRATE-LAYER-SHAPE-MISMATCH** (4-instance HARDENED): cross-language audits surface LAYER-MISMATCH frequently because target platform expectations diverge from current canonical taxonomy
- **DEPTH-AXIS-MISMATCH** (2-instance HARDENED): cross-language audits surface DEPTH-MISMATCH frequently because substantial implementation-detail-depth (e.g., distribution math, classifier algorithms) is common in source repos
- **DISPATCH-PREMISE-MISMATCH** (1-instance): cross-language audits surface PREMISE-MISMATCH when dispatch's language-pair claims don't match source-reality
- **META-AGGREGATION-WAITING-FOR-3RD-INSTANCE**: cross-language cousin-scout findings seed WAITING entries (compaction.rs 2/3 + canonicalize.rs 1/3 + flake_classifier 1/3 are all WAITING-FOR-3RD-INSTANCE candidates)

The 4 sister-doctrines + this audit-strategy framing together cover the cross-language audit surface comprehensively.

## Anti-pattern this prevents

"Cross-language audit returned 0 extractions; that's a failed audit" — over-pessimism. Counters: LOW-yield audits still produce mismatch classifications + populate terminal-archive; portfolio EV is positive across HIGH+LOW outcomes.

Inverse: "Every cross-language audit will yield extractions" — over-optimism. Counters: empirical baseline shows 33-66% HIGH-yield rate; expect distribution.

## Hardening threshold

- 1 instance = signal candidate
- 2 instances = HARDENED canonical
- 3+ instances with empirical calibration baseline = HARDENED-WITH-CALIBRATION (this state — promotion-ready)
- 5+ instances with refined calibration = doctrine-promotion-ready with confident HIGH-yield rate estimate

**Calibration refinement candidates:**
- Future cross-language audits (Wave-3+; any pi_agent / xf / vibe_cockpit / rch-class sources): record HIGH/LOW outcome + cousin-scout findings count
- Once N≥5: compute HIGH-yield rate with confidence interval; refine portfolio-investment framing accordingly

## Operator action when planning cross-language audit

1. **Frame as portfolio investment**, not deterministic extraction
2. **Budget ~15-30min per audit wall** (empirical baseline; xf audit was ~30min, rch was ~30min, pi_agent was ~33min)
3. **Set HIGH-yield expectation at 33-66%** based on current calibration; don't expect every audit to yield cousin-scout findings
4. **PREMISE-CHECK** the dispatch framing per sister doctrine DISPATCH-PREMISE-MISMATCH
5. **Per-audit deliverables expected**:
   - CANDIDATE-CATALOG entries (cousin-scout findings + mismatch classifications)
   - 4-axis verdict classification (LAYER + DOMAIN + DEPTH + PREMISE)
   - META-AGGREGATION-WAITING-FOR-3RD-INSTANCE entries if cousin-scout findings emerge
6. **Track HIGH/LOW outcome** in audit ledger for calibration refinement

## 2 new cousin-scout targets surfaced (Wave-2 completion)

Per xf audit Wave-2 completion handoff:
- **text-canonicalization** (1+1 match: xf canonicalize.rs + chat-share normalizeLineTerminators) — needs 3rd instance to harden as canonical SUBSTRATE-COUSIN-CONVERGENCE
- **multi-embedder-strategy** (META-AGGREGATION-OF-SHIPPED-IMPLEMENTATIONS candidate; 1-instance Rust-side; needs 2nd ZS-side)

These join the prior compaction.rs + flake_classifier.rs cousin-scout candidates from pi_agent audit. Cumulative cousin-scout queue: 4 candidates parked as META-AGGREGATION-WAITING-FOR-3RD-INSTANCE entries.

## Related doctrine

- **SUBSTRATE-LAYER-SHAPE-MISMATCH** (sister 4-instance 4-axis OUT-OF-SCOPE sub-axis)
- **DEPTH-AXIS-MISMATCH** (sister 2-instance 3rd OUT-OF-SCOPE axis)
- **DISPATCH-PREMISE-MISMATCH** (sister 1-instance dispatch-framing axis)
- **META-AGGREGATION-WAITING-FOR-3RD-INSTANCE** (sister; cross-language cousin-scout findings seed WAITING entries)
- **dispatch-expectation-vs-audit-verdict-divergence.md** (audit-dispatch enumeration; cross-language audits benefit from 6-7 outcome enumeration)
- **same-session-feedback-loop-closure.md** (META velocity-leverage; cross-language audits typically don't compress to sub-1-hour due to broader source-base reading required, but the AUDIT-FINDING → CANDIDATE-CATALOG-ENTRY cycle can same-session-close)
