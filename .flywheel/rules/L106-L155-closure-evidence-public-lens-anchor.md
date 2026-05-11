# L155 — CLOSURE-EVIDENCE-PUBLIC-LENS-ANCHOR

---
id: L155
title: Closure evidence MUST anchor a public-lens self-grade to Three-Judges / Donella / Meadows / Jeff / four-lens / publishability / brand-voice
status: long_term
shipped: 2026-05-11
review_due: 2026-11-11
trauma_class: closure-evidence-missing-public-lens-anchor
---

Anyone authoring closure evidence in `.flywheel/audit/<bead>/` MUST include at
least ONE public-lens anchor token in the same evidence file:
`three judges`, `publishability`, `brand voice`, `donella`, `jeff`, `meadows`,
`four-lens`, `four lens`. The flywheel/skillos canonical validator
(`~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh`
lines 301-303) emits the public-lens fail `no_bar_self_grade` and BLOCKS the
close when none of the 8 tokens is present.

**Trigger condition (case-insensitive grep on the closure evidence file):**
- NONE of `{three judges, publishability, brand voice, donella, jeff, meadows, four-lens, four lens}` present

**Result**: public-lens fails with `no_bar_self_grade`; close BLOCKED.

**How to apply:**

1. Author the Four-Lens Self-Grade section with explicit Three Judges narrative
   (skeptical operator, maintainer, future worker).
2. If using a different framing, reference Donella Meadows leverage points,
   Jeff Emanuel doctrine, or the publishability bar by name.
3. Verify before close via validator dry-run:
   ```bash
   ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh \
     --evidence .flywheel/audit/<bead-id>/evidence.md --dry-run
   ```
4. If `lens_public_fail=no_bar_self_grade` appears, add an anchor + rerun.

**Producers (the load-bearing check):**

```bash
# ~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:301-303
if ! grep -qiE '(three judges|publishability|brand voice|donella|jeff|meadows|four-lens|four lens)' "$EVIDENCE_ABS"; then
  lens_fail public "no_bar_self_grade"
fi
```

**Reason:** Closure evidence that ships without grounding in the public-lens
becomes `shipped-but-stub-blind` — surface metrics pass while substrate decay
accelerates. The public-lens is a forcing function for downstream-impact
scrutiny (per Donella Meadows' 12 leverage points + Jeff Emanuel's brand-voice
discipline + Three Judges check). Origin fire: skillos:1 beug.1 closure at
2026-05-11T14:50Z BLOCKED by public-lens; unblocked after Donella/Meadows
anchor added — promoted to flywheel canonical doctrine via `flywheel-v38e1.2`
and now to L-rule via `flywheel-a38zz`.

**Evidence:** doctrine doc `.flywheel/doctrine/closure-evidence-public-lens-anchor-discipline.md`
(246 lines, full ORIENT + MOTIVATE + MENTAL-MODEL + EXEMPLIFY + WARN + conformance
sections); validator at
`~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:301-303`;
origin trace skillos-beug.1; parent bead `flywheel-v38e1.2`; promotion bead
`flywheel-a38zz`.

**Companion rules:**
- L52 (issues-to-beads-or-explicit-no-bead-receipt) — evidence completeness
- L61 (doctrine-landing-wires-into-AGENTS-and-README) — doctrine wire-in
- L80 (closed-bead-audit-mining) — the audit pass that runs the validator
- L99 (public-ready-default) — sister public-bar discipline
- L153 (capture-provenance-canonical) — sister Jeff-lens evidence integrity
- L154 (closure-evidence-contract-version-anchor) — sister anchor invariant (cohort partner)
- L155 (this rule) — the public-lens anchor invariant

**Canonical source:** `.flywheel/doctrine/closure-evidence-public-lens-anchor-discipline.md`
(schema_version: `closure-evidence-public-lens-anchor-discipline/v1`)

**Sister rules / cohort:** Part of the 4-rule v38e1 cohort promoted to flywheel
canonical from skillos:1 fuckup-log. Cohort members and L-rule promotion status:
- L154 (closure-evidence-contract-version-anchor, 12:12Z; doctrine v38e1.1, L-rule nerln) — SHIPPED
- L155 (closure-evidence-public-lens-anchor, 14:50Z; doctrine v38e1.2, L-rule a38zz) — THIS RULE
- `inbox-discipline-missed-during-deep-burndown-motion` (17:00Z; doctrine v38e1.3; L-rule pending)
- `outbox-discipline-cross-orch-ship-notification` (22:30Z; doctrine v38e1.4; L-rule pending)
