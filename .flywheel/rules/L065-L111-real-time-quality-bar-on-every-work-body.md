## L111 — REAL-TIME-QUALITY-BAR-ON-EVERY-WORK-BODY

---
id: L111
title: Real-time quality bar on every work body
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: ship-then-polish-later
---

Every body of work — plan output, audit, dispatch result, bead description,
paradigm doc, AGENTS.md edit, memory file, code, callback envelope — MUST pass
at WRITE-TIME (not audit-time, not polish-time) through a five-skill quality
bar. Workers refuse to populate the callback envelope without
`quality_bar_passed=yes` plus per-judge scores; orchestrators refuse to accept
callbacks missing those fields.

**Required gates per artifact:**

1. `/rust-best-practices` (where Rust touched).
2. `/python-best-practices` (where Python touched).
3. `/canonical-cli-scoping` (every CLI surface or path referenced).
4. `/readme-writing` (every doc edit, plan section, or AGENTS chunk).
5. Three-judges sniff (Jeff / Donella / Joshua) — each scored 0-10 against
   `~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`. Composite
   ≥9.5; no single judge <9.0. If the artifact cannot reach the bar, the
   artifact gets fixed, not shipped at lower grade.

**Required callback fields:**

- `quality_bar_passed`: `yes` | `no`
- `rust_clean`: `yes` | `no` | `n/a`
- `python_clean`: `yes` | `no` | `n/a`
- `cli_canonical`: `yes` | `no`
- `readme_quality`: `yes` | `no`
- `jeff_score`, `donella_score`, `joshua_score`: integer 0-10 each
- `self_grade`: composite `N.N/10`

**Rationale (Donella stock/flow/leverage):**

- **Stock:** quality-debt artifacts (plans, doctrine docs, ledger rows, code,
  callbacks shipped without 5-skill + 3-judges check).
- **Inflow:** every dispatch close, every plan phase save, every L-rule
  codification, every bead body write.
- **Outflow before L111:** a "polish round" scheduled for later — that drained
  in theory and never in practice (today: 8 audit lenses, 4 REFINE rounds,
  PARADIGM doc, L110 codification all shipped without the 4-skill + 3-judges
  check).
- **Outflow with L111:** mechanical refusal at write-time. The producer fixes
  the artifact before it lands, not the next plan.
- **Loop:** balancing B (write → 5-skill check → fix or ship). Removes the
  reinforcing R that lets quality-debt accumulate by deferring polish.
- **Leverage point:** Meadows #5 (rules of the system). The rule shifts
  authority over "is this good enough?" from a future polish phase to the
  write-time gate, eliminating the deferred-polish escape hatch.
- **Delay:** zero. Quality bar fires synchronously at write-time, not in a
  later sweep.

**Enforcement:**

- Mechanical gate at callback validation: orchestrators reject callbacks that
  do not include the seven required fields with passing values.
- Inheritance through `flywheel:_shared:dispatch-template`: every dispatch
  prompt embeds the five-skill checklist as an acceptance gate, the same way
  L82 canonical CLI scoping is embedded today.
- Doctor surface: `quality_bar_breach_count_24h` (callbacks with
  `quality_bar_passed=no` or missing fields). Tick close gates refuse with
  warn at >0, error at >3.

**Companion rules:**

- L108 (3-surface sync) — quality bar applies to all three surfaces, not just
  the canonical source.
- L110 (substrate self-repair primitive) — L111 is the
  `verification_probe`/`drain_receipt_shape` consumer for `artifact` stock.
  L110 declares the loop; L111 enforces the quality of every artifact passing
  through it.

**Cost citation:** 2026-05-04. Joshua flagged that 8 audit lenses, 4 REFINE
rounds, the substrate-self-organization paradigm doc, and the L110
codification all shipped without 4-skill + 3-judges checks — producing tech
debt on the very plans meant to eliminate it. Direct quote: "every body of
work must pass real-time through `/rust-best-practices`,
`/python-best-practices`, `/canonical-cli-scoping`, `/readme-writing`, and the
3-judges sniff. Not later. Not in polish. AT WRITE-TIME." See
`.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md` Finding
11 and `.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/00-INTENT.md`
Phase 1 supplemental II.

**Forbidden outputs:**

- Shipping any artifact with `quality_bar_passed=no` or missing per-judge
  scores.
- Deferring quality work to a "polish round" scheduled later.
- Treating the 3-judges rubric as advisory rather than gating.
- Orchestrator accepting a worker callback without the seven required fields.

**Cross-references:** L29 (NTM dispatch hygiene), L50 (Socraticode preflight),
L51 (file reservations), L52 (issues→beads), L53 (fuckups in callback), L57
(loop-state vs driver), L61 (doctrine landing wires AGENTS+README), L70
(no-punt chain forward), L71 (validate-and-redispatch), L82 (canonical CLI
scoping), L96 (3-surface diff), L108 (3-surface cache vs gate), L110
(substrate self-repair primitive),
`~/.claude/skills/.flywheel/prompts/three-judges-rubric.md`,
`.flywheel/PUBLISHABILITY-BAR.md`,
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`,
`feedback_publishability_bar_three_judges.md`,
`feedback_validator_must_check_four_lenses.md`.

**Authored:** 2026-05-04

