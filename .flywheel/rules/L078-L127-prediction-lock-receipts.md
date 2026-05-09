## L127 — PREDICTION-LOCK-RECEIPTS

---
id: L127
title: Prediction-lock receipts for high-risk hypotheses
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: post-hoc-plan-rationalization
---

High-risk `/flywheel:plan` hypotheses MUST be pre-registered before execution
starts. At the Phase 2 to Phase 3 convergence boundary, write
`STATE.json.prediction_lock` plus `STATE.json.predictions[]` rows containing
`prediction`, `ts`, `hash`, and `applies_at_phase`; the hash is SHA-256 over the
canonical JSON serialization of the prediction text. The receipt is immutable
after Phase 2: close gates fail on text/hash mismatch
(`prediction_lock_post_hoc_amendment`) or prediction rows timestamped after the
lock boundary (`prediction_lock_post_hoc_addition`).

**Evidence:** Brenner disposition Proposal 3 in
`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md`;
bead `flywheel-gau3q`; close-gate implementation in
`.flywheel/scripts/quality-bar-close-gate.sh`; regression tests
`tests/test_prediction_lock_receipt.sh` and
`tests/test_prediction_lock_post_hoc_detection.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

