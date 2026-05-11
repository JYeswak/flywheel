---
bead: flywheel-2xdi.125
title: memory-without-cross-link fix — respawn-canonical-recovery cluster-anchor doctrine
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.109 + flywheel-2xdi.110 (same posterior shape)
sister_owns_class: flywheel-xbsd8 (semantically-embedded-discipline)
posterior_shape: TP-with-semantic-embedding-AND-name-grep-blind-spot (3rd recurrence)
disposition: TP-via-forward-link + CLUSTER-ANCHOR (5 memories under one doctrine)
---

# Journey: flywheel-2xdi.125

## What the bead asked for

Memory `feedback_l91_auto_retry_helper_failed_4_data_points.md` not cited by
sampled commands/doctrine/incidents/plans. Standard memory-without-cross-link
fix pattern.

## Investigation (META-RULE 2026-05-11 — 19th application)

Memory documents META-RULE 2026-05-07: L91 four-state probe DETECTS reliably;
auto-retry-helper FAILED empirically 4× on j018 re-dispatch attempts; respawn
is canonical recovery. Memory body cites 4 sibling trauma memories explicitly.

**Probe result: 3rd recurrence of `TP-with-semantic-embedding-AND-name-grep-blind-spot`** (sister to 2xdi.109 + 2xdi.110).

Discipline IS load-bearing across 5 surfaces:
- `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md` (L91 detector contract)
- `.flywheel/rules/L049-L95-worker-stall-recovery-protocol.md` (recovery ladder)
- `.flywheel/rules/L053-L99-worker-recovery-slo-180s.md` (SLO 180s; cross-refs L91+L95)
- `~/.claude/skills/.flywheel/bin/flywheel` (doctor probe)
- `~/.claude/skills/.flywheel/scripts/fleet-rotate-on-caam-swap.sh` (respawn primitive)

Probe name-grep blind — same shape as 2xdi.109/.110.

## NEW sub-pattern: CLUSTER-ANCHOR

Memory body explicitly cites 4 sibling memories forming a 5-class trauma
cluster:

| # | Memory | Class |
|---|---|---|
| 1 | feedback_l91_auto_retry_helper_failed_4_data_points (this) | QUEUED_NOT_SUBMITTED auto-retry failure |
| 2 | feedback_ntm_rotate_stdin_contamination_use_respawn_path | Rotate banner pollutes target stdin |
| 3 | feedback_chevron_visible_does_not_mean_submits_work | Visual classifier ≠ work submitted |
| 4 | feedback_post_callback_stale_chevron_input_deaf_class | Post-callback input-deaf |
| 5 | feedback_enter_press_not_respawn_class | Bare-Enter sometimes works |

This is a NEW SUB-PATTERN: instead of one-doctrine-per-memory (2xdi.109/.110/.117),
this bead's doctrine doc anchors the entire 5-memory cluster under ONE umbrella
doctrine. Promotion threshold N=4 MET; doctrine doc IS the canonicalization.

Future workers handling siblings #2-5 can reference this single anchor rather
than file 4 more forward-link doctrine docs.

## What I shipped

### Primary: cluster-anchor doctrine doc

`.flywheel/doctrine/respawn-is-canonical-recovery-for-codex-tmux-stdin-states.md`:
- TL;DR canonicalizing "no programmatic recovery for codex+tmux stdin; respawn
  is canonical"
- Cites memory as Canonical memory source
- 5-memory trauma cluster table (all 5 sibling memories)
- 5-surface semantic-embedding table (3 rules + 1 script + canonical CLI)
- Behavioral-vs-name cross-linking section explicit
- 7+ sister doctrine cross-links
- Conformance contract (5-step worker stuck-input recovery)
- Below-trauma-class N=4 MET confirmation
- Harvest signal for faqj2 next-tick

### NO new calibration bead (substrate-self-improving loop)

xbsd8 already owns the semantically-embedded-discipline class. 3rd-instance
recurrence reinforces the class; doesn't warrant duplicate bead. Per user
framing on 2xdi.110, harvest delegates to faqj2 next-tick.

## Sister-pattern contrast — memory-without-cross-link class arc

| # | Bead | Memory | Pattern type | Worker |
|---|---|---|---|---|
| 1 | 2xdi.109 | silent-deaf | 1:1 forward-link | MistyCliff |
| 2 | 2xdi.110 | parallel-impl P2 | 1:1 forward-link | MagentaPond |
| 3 | 2xdi.117 | jeff-response-shape-5 | 1:1 forward-link (promotion-pending) | MagentaPond |
| 4 | **2xdi.125** (this) | l91-auto-retry-failed | **CLUSTER-ANCHOR (1 doc → 5 memories)** | MagentaPond |
| harvest | xbsd8 | (meta — semantically-embedded) | substrate-loop target | — |

The CLUSTER-ANCHOR sub-pattern is more efficient than 1:1 forward-link when
multiple memories share a common discipline class. Recommended whenever 3+
memories explicitly cite each other as siblings (as this 5-memory cluster does).

## Compliance

- AG receipt: 9/9
- META-RULE 2026-05-11: 19th application; 3rd recurrence of TP-with-semantic-embedding
- L52: 0 new beads filed; `no_bead_reason=xbsd8_owns_class_3rd_instance_reinforces_loop_validation`
- Boundary preservation: only `.flywheel/doctrine/` + audit + journal
- L107: MCP-skipped
- compliance_score: 1000/1000

## Recommendation to orch

For future memory-without-cross-link beads on sibling memories #2-5 of this
cluster:
- Reference `.flywheel/doctrine/respawn-is-canonical-recovery-for-codex-tmux-stdin-states.md`
- Append a "Trauma class siblings" row in that cluster's table if the bead's
  memory isn't yet listed (it should be — all 5 are listed)
- Close as MOOT-BY-CLUSTER-ANCHOR (analogous to MOOT-BY-CURRENT-PROBE-CLEARANCE
  in 2xdi.114)

This validates the CLUSTER-ANCHOR pattern as a 4x-efficient forward-link
shape — one doctrine doc serves multiple sibling beads instead of N:1.
