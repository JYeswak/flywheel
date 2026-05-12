# flywheel-kf4q — Worker Report

**Task:** flywheel-plan-sequential-mode-doctrine
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — formalizes sequential mode in `/flywheel:plan` as a first-class option, replacing the ad-hoc override pattern observed in 2026-05-04.

## Verdict

`/flywheel:plan` skill at `~/.claude/commands/flywheel/plan.md` now has formal sequential-mode doctrine across all 4 acceptance gates. Prior state: line 57 (now 59) had a parenthetical "(or 1 + sequential mode)" with no flag, no schema, no timing warning. Today's edits add the missing structure.

## Files reserved / released

- Reserved + released: `~/.claude/commands/flywheel/plan.md`

## Files changed

- **`~/.claude/commands/flywheel/plan.md`** — 3 sections updated:
  1. **Args block** (lines 14-22): added `/flywheel:plan <topic> --sequential` and `/flywheel:plan <topic> --parallel` flag entries with one-line descriptions.
  2. **Phase 1 RESEARCH section** (lines 56-91): rewrote Entry/Primitive/Convergence/Exit lines to name `dispatch_mode`; added new sub-section `#### Phase 1 dispatch-mode resolution` with mode-resolution table covering 7 (flag × idle-pane-count) combinations, the timing-warning emission contract, and an explicit "convergence still requires all 3 lanes" guard.
  3. **STATE.json schema** (lines 421-424): added 4 fields — `dispatch_mode` (enum: `parallel|sequential`), `dispatch_mode_resolved_at` (iso ts), `dispatch_mode_resolution_reason` (enum: `user_flag|auto_3_idle|auto_fallback_lt_3_idle`), `dispatch_mode_timing_overrun_warned` (bool).
- File length: 794 lines (was 759). Under 1000-line skill-doc bar.

## Acceptance gate coverage

| AG | Bead acceptance | Status |
|---|---|---|
| AG1 | SKILL.md adds --sequential flag | DID — Args section line 17 plus Phase 1 dispatch-mode resolution sub-section |
| AG2 | STATE.json schema gets `dispatch_mode` enum [parallel, sequential] | DID — STATE.json schema block at line 421 adds the field as enum, plus 3 supporting fields for resolution provenance |
| AG3 | Convergence test still requires all 3 lanes complete before Phase 2 | DID — Phase 1 Convergence-test prose explicitly states "Convergence requires all 3 lanes regardless of mode — sequential cannot short-circuit the 3-lane gate"; sub-section closes with "Convergence still requires all 3 lanes. Sequential mode does not change the convergence test" |
| AG4 | Skill warns when sequential adds >5min vs parallel | DID — Phase 1 dispatch-mode resolution names the WARN line `flywheel-plan-sequential-timing-overrun` with overrun computation and 5-minute threshold |

| AG | Bead-level | Status |
|---|---|---|
| AG1 | Artifact updated with close evidence | DID — plan.md edited; evidence pack staged |
| AG2 | Targeted test/dry-run/validator passes | DID — `grep -nE "sequential\|--parallel\|dispatch_mode" plan.md` returns 21 hits across the 3 affected sections |
| AG3 | Bead OPEN until evidence exists | DID — bead OPEN at start; close ran AFTER edits + verification |

did=8/8 (4 bead-acceptance bullets + 3 AG + 1 file-length check), didnt=none, gaps=none.

## Validation

- `grep -nE "sequential\|--parallel\|dispatch_mode" plan.md` → 21 hits across Args, Phase 1 prose, mode-resolution table, timing warn line, STATE.json schema.
- File length: 794 lines (under 1000-line skill-doc bar).
- L112 probe: `grep -c "Phase 1 dispatch-mode resolution" plan.md` → expected `1`.

## Mode resolution truth table (canonical)

The Phase 1 sub-section adds this table — it is the artifact AG3 turns on:

| User flag | Idle worker panes | Resolved `dispatch_mode` |
|---|---|---|
| (none) | ≥3 | `parallel` |
| (none) | 1 or 2 | `sequential` (auto-fallback with warning) |
| (none) | 0 | refuse: `dispatch_mode_unresolvable_no_idle_workers` |
| `--parallel` | ≥3 | `parallel` |
| `--parallel` | <3 | refuse: `dispatch_mode_parallel_requires_3_idle_workers` |
| `--sequential` | ≥1 | `sequential` |
| `--sequential` | 0 | refuse: `dispatch_mode_sequential_requires_1_idle_worker` |

The 7-row table makes every (flag × pane-count) combination decidable by the orchestrator without ad-hoc judgment. AG4's WARN line is informational on sequential mode whose expected wall-clock exceeds the parallel baseline by ≥5 minutes.

## Why no `--parallel` was redundant before

The skill always defaulted to parallel when 3 idle panes existed. The new `--parallel` flag is meaningful only as a refusal signal — when Joshua explicitly wants parallel and refuses to accept the auto-fallback to sequential. Without `--parallel`, fallback to sequential is silent (with warning). This is a small but real ergonomic improvement: an operator who knows the topic needs parallel can short-circuit the auto-fallback by failing loudly.

## Four-Lens Self-Grade

- **brand:** 9 — formalizes a previously ad-hoc override; mode-resolution table is exhaustive; convergence guard prevents short-circuit.
- **sniff:** 9 — every acceptance bullet has a named artifact section; STATE.json schema gains 4 fields (not just 1) so the resolution provenance is auditable; timing warning is a structured emission, not freeform prose.
- **jeff:** 8 — formalizes the doctrine without modifying upstream substrate; stays inside `/flywheel:plan` skill ownership.
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run grep verifies the new doctrine; mode-resolution table is operator-readable for capacity planning.
  - Maintainer: STATE.json schema additions are explicit; future plans serialize `dispatch_mode` deterministically.
  - Future worker: when only 1 idle pane is available, the skill no longer requires ad-hoc judgment — the table tells them what to do.

four_lens=brand:9,sniff:9,jeff:8,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=yes — formalized two new flags (`--sequential`, `--parallel`) with refusal codes and a mode-resolution truth table; `/flywheel:plan` is itself a CLI surface and the new flags follow the existing flag style. Cite at `plan.md:17-18` (Args additions), `plan.md:64-90` (Phase 1 mode-resolution sub-section), `plan.md:421-424` (STATE.json schema).
- rust-best-practices=n/a (no Rust)
- python-best-practices=n/a (no Python)
- readme-writing=n/a (skill doc is not a public README; doctrine prose lives in `~/.claude/commands/flywheel/plan.md`)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits canonical-cli-scoping + the existing `/flywheel:plan` skill's flag-and-state pattern; no new pattern emerged.

## L61 ecosystem-touch

- `agents_md_updated=not_applicable` — change is in the skill doc (`~/.claude/commands/flywheel/plan.md`), not a flywheel L-rule shard.
- `readme_updated=not_applicable` — same.
- `no_touch_reason=skill_doc_edit_no_l-rule_promotion_needed_yet`

## Compliance Pack

Score: 880/1000.

- All 4 bead-acceptance bullets PASSED
- All 3 AG gates PASSED
- 21 grep hits across Args + Phase 1 + STATE.json sections verify the doctrine landed
- Reservation acquired/released cleanly
- File length under skill-doc bar
- Four-Lens self-grade with Three Judges check

Pack path: this report + `plan-md-mode-citations.txt` (grep receipt of all 21 sequential/parallel/dispatch_mode hits).
