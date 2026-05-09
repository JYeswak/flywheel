## L126 — EVIDENCE-PACK-REPLACES-SELF-GRADE

---
id: L126
title: Evidence pack replaces self-grade
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: self-grade-claim-treated-as-fact
---

Closed is a claim until evidence proves it. New worker closures and new
`/flywheel:plan` close-gate transitions MUST use a beads-compliance evidence
pack instead of worker-claimed four-lens or three-judges self-grades.

**How to apply:**
- New DONE callbacks include `compliance_score=<N>/1000` and
  `compliance_pack_path=<audit-dir>/<bead-id>/`.
- The pack follows
  `~/.claude/skills/beads-compliance-and-completion-verification/references/EVIDENCE-SCHEMAS.md`
  and includes `spec.json`, `evidence.json`, `compliance.json`,
  `theater.json`, `test_depth.json`, `scorecard.md`, and `REPORT.md`.
- The starting close threshold is `compliance_score >= 700/1000`.
  `/flywheel:plan` schema v4 also requires `convergence_streak >= 2` before a
  polish plan can advance through the close gate.
- Legacy four-lens / three-judges rows remain valid history. Do not migrate
  closed beads, and do not rewrite in-flight dispatch contracts. Cutover is
  forward-only for the next `/flywheel:plan` and newly rendered dispatches.
- Plans with `schema_version < 4` may still be evaluated by their legacy
  self-grade fields; plans with `schema_version >= 4` are refused without an
  evidence pack.

**Forbidden outputs:**
- Treating `four_lens=brand:N,sniff:N,jeff:N,public:N` as a close fact for a
  new dispatch.
- Advancing a schema v4 plan to ready without a cited compliance pack and
  score.
- Re-running historical plans only to replace legacy four-lens fields.
- Adopting the beads-compliance mega-swarm tier before Solo tier is proven.

**Evidence:** Joshua directive 2026-05-07 to replace four-lens with
`beads-compliance-and-completion-verification`; skill "One Rule" and
`DESIGN-PHILOSOPHY.md`; close contract in
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; plan schema v4 in
`~/.claude/commands/flywheel/plan.md`; close gate
`.flywheel/scripts/quality-bar-close-gate.sh`; regression
`tests/quality-bar-close-gate.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L61, L80, L91, L111, L120, and
`feedback_evidence_pack_replaces_four_lens.md`.

