## L128 PLAN-CONVERGENCE-PROVED-WITH-DATA

---
id: L128
title: Plan convergence proved with data
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: plan-convergence-by-vibes
---

A flywheel plan cannot ship if it cannot prove convergence with data. Six
mechanisms together constitute the discipline:

1. Hypothesis-slate with kill-conditions `[flywheel-ykkhv]` — every plan
   declares 2-5 candidate strategies including one third-alternative; each has a
   `kill_condition`. Phase 3 transition is refused otherwise.

   Why: kills picoz failure-mode "plans converge by consensus, never declared
   what would falsify them".

2. Prediction-lock receipts `[flywheel-gau3q]` — `STATE.json.predictions[]` is
   content-hashed at Phase 2 to Phase 3 transition; close-gate flags hash deltas
   and post-hoc additions.

   Why: kills picoz failure-mode "post-hoc rationalization without trace".

3. ADD/EDIT/KILL deltas in idea duels `[flywheel-2xsag]` —
   `dueling-idea-wizards` emits structured JSON deltas instead of prose;
   validator rejects prose-only outputs.

   Why: kills picoz failure-mode "idea duels produce prose, not mergeable
   decision objects".

4. Convergence telemetry in polish gate `[flywheel-xhfbw]` — each polish round
   emits adds/edits/kills/no-deltas counts; close-gate requires kills >= adds
   and `no_new_deltas` across 2 consecutive rounds for complex plans.

   Why: kills picoz failure-mode "we said it converged but the data shows
   otherwise".

5. EV-anchored evidence with supports/refutes/informs `[flywheel-d3q0j]` —
   compliance packs may include `evidence[]` with `EV-NNN` anchors and typed
   relations; close-gate refuses unresolved anchors and active findings with
   refuting evidence on file.

   Why: kills picoz failure-mode "audit trail without relational structure".

6. Advanced `/brenner` surfaces for evidence/anomaly/critique/assumption
   recording `[flywheel-26hsk]` — research sessions record via experiment
   encode, evidence add, anomaly create, critique create, and assumption create
   instead of prose summaries.

   Why: kills picoz failure-mode "research conclusions buried in prose, not
   queryable".

Close gate refuses ship if any of mechanisms 1 through 5 fail. Mechanism 6 is
the upstream recording discipline that feeds mechanism 5.

**Source:** Brenner research deep-dive 2026-05-07 in
`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/`.
Picoz-killer doctrine: Joshua spent 30 days building picoz because no single
rule said convergence had to be proved with data.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

