# flywheel-loop — Phase 1 Archaeology + Failure-Mode Inventory

**Bead:** flywheel-oxzyr.1 (sub-bead of flywheel-oxzyr; pending file via decomposition manifest)
**Pass:** 1 (mode=upgrade per existing doctor surface)
**Authored by:** flywheel-oxzyr-4a33a9 worker tick (MagentaPond / 2026-05-11T06:25Z)
**Skill reference:** `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md`

## Target binary

- **Path:** `~/.claude/skills/.flywheel/bin/flywheel-loop`
- **Size:** 852 lines (37,599 bytes; bash with very long lines)
- **Type:** Bourne-Again shell script, UTF-8
- **Existing doctor surface:** ~22 named scopes (massive — see "Existing doctor scopes" below)
- **Doctor mode classification:** `upgrade` (existing doctor → upgraded doctor per skill methodology)

## Existing doctor scopes (extracted from `--help`)

```
flywheel-loop doctor --repo PATH [--scope <SCOPE>] [--fix] [--storage-min-free-gb N] [--storage-min-free-pct N] [--json]
```

Named scopes (22):

1. `auto-l112-gate`
2. `dispatch-template-skill-routes`
3. `quality-bar-close-gate`
4. `stale-in-progress`
5. `jsm-sandbox-auth-marker`
6. `substrate-loop-contract`
7. `storage-headroom-watcher`
8. `peer-orch-recovery`
9. `peer-orch-monitor`
10. `codex-stuck-detector`
11. `callback-envelope-schema`
12. `tick-driver`
13. `loop-driver-writeback`
14. `tick-hook-firing`
15. `l70-ticks-punted`
16. `agents-md-fleet-propagation`
17. `beads-db-recovery`
18. `memory-rule-gate-parity`
19. `low-bead-threshold`
20. `two-blocker-ticks`
21. `wire-or-explain`
22. `session-topology-register`

## Baseline doctor envelope characteristics

A live `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` snapshot at 2026-05-11T06:25Z (raw 6MB; summary in `.flywheel/audit/flywheel-oxzyr/baseline-summary.json`):

- `status: "fail"`
- `dirty_count: 423`
- `errors_count: 3`
- `warnings_count: 16`
- `planned_writes_count: 0`
- `violations_count: 9`
- `~400+ check-keys` in the response object (massive surface area)

## 10 seed failure modes (per dispatch packet line 162)

Cross-walk MEMORY-source FMs against existing doctor scope coverage:

| # | Failure mode | MEMORY source | Existing scope coverage | Doctor-mode-upgrade gap |
|---|---|---|---|---|
| 1 | `loop-state-without-driver` | `feedback_loop_state_without_driver.md` (META-RULE 2026-05-02) | `loop-driver-writeback` partial — checks driver presence but doesn't catch `active=true` marker without dispatch trail | Detect-then-fix invariant for marker+driver coupling |
| 2 | `pulse-stale → DEAD misclassification` | dispatch-packet seed (no direct memory file) | `peer-orch-recovery` + `peer-orch-monitor` — likely emits dead/alive but classification logic not exposed for fixture | Fixture pair: stale-pulse-but-alive vs truly-dead; assert classifier |
| 3 | `stale-error preflight bypass` | dispatch-packet seed | partial (errors[] populated but no preflight gate) | Preflight gate detect-then-fix |
| 4 | `worker callback never reaches orch (Monitor not armed)` | `feedback_orch_wake_event_driven_not_time_based.md` + `feedback_dispatch_post_send_verify_for_silent_deaf.md` | `callback-envelope-schema` — schema only; no Monitor-armed probe | Add Monitor-armed-on-dispatch invariant |
| 5 | `orch wakes on time-based heartbeat with stale prompt` | `feedback_orch_wake_event_driven_not_time_based.md` (META-RULE 2026-05-08) | none direct | Add stale-prompt-detection probe |
| 6 | `legacy ~/.flywheel/loops/<project>.json schema drift` | `feedback_loop_state_without_driver.md` | partial (loop_config_present check) | Schema-drift detect-then-fix with byte-exact undo |
| 7 | `topology-resolved-pane mismatch` | `feedback_topology_lookup_before_dispatch.md` (META-RULE 2026-05-04) + `feedback_topology_jsonl_take_latest_effective_at.md` | `session-topology-register` partial | Topology mismatch detect+fix invariant |
| 8 | `watcher dispatching during input-deaf` | `feedback_post_callback_stale_chevron_input_deaf_class.md` + `feedback_dispatch_post_send_verify_for_silent_deaf.md` | partial via codex-stuck-detector | Dispatch-during-input-deaf gate detect+block |
| 9 | `frozen-projection-of-mutable-state in tick prompts` | `feedback_frozen_projection_of_mutable_state_class.md` (META-RULE 2026-05-06) | none direct | Probe scans for literal-state-in-templates; requires fixture |
| 10 | `recovery probe stale-chevron false-positive` | `feedback_post_callback_stale_chevron_input_deaf_class.md` + `feedback_chevron_visible_does_not_mean_submits_work.md` | `codex-stuck-detector` partial | Add stale-chevron-vs-active-work classifier with fixture |

## Crosswalk summary

- **5/10 FMs have partial coverage** (loop-driver, peer-orch, callback-envelope, session-topology, codex-stuck) — upgrade work is to harden detect-then-fix invariant + add fixture suite per FM.
- **5/10 FMs have no direct scope coverage** (stale-prompt time-heartbeat, schema-drift undo-byte-exact, dispatch-during-input-deaf gate, frozen-projection probe, stale-chevron classifier) — upgrade work is to add new scopes + fixtures.

## World-class-doctor-mode rubric — 10 dimensions baseline (Phase 1 best-effort)

Baseline scorecard for flywheel-loop's existing doctor (per `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md` 10-dim rubric). This is a Phase-1 best-effort estimate; Phase 6 produces the canonical scorecard with full evidence.

| Dimension | Baseline (0-1000) | Notes |
|---|---|---|
| 1. Detect coverage | 700 | 22 named scopes + 400+ check keys; broad but uneven depth |
| 2. Fix coverage (detect-then-fix invariant) | 400 | `--fix` flag exists but not all scopes implement it; mutate() chokepoint not centralized |
| 3. Idempotence | 500 | Some scopes idempotent; not enforced as invariant |
| 4. Backup + undo (`doctor undo <run-id>` byte-exact) | 100 | No `doctor undo` subcommand observed; backups not content-hashed |
| 5. Fixture suite (FM round-trip) | 200 | Some scope-specific tests exist; no per-FM fixture suite per skill rubric |
| 6. Agent-ergonomic surface (`--json`, schema, stable rc) | 800 | `--json` ubiquitous; `schema` subcommand present; rc semantics consistent |
| 7. Single mutate() chokepoint | 300 | Mutations scattered across scopes; no central `mutate()` audit trail |
| 8. Dogfooding (substrate exercises itself) | 700 | flywheel-loop is heavily dogfooded across the fleet |
| 9. Failure-mode coverage (per FM in MEMORY) | 500 | 5/10 FMs have partial scope; 5/10 uncovered |
| 10. Documentation + agent UX | 700 | `--help` substantial; `quickstart`/`why`/`schema` present; topic help exists |
| **TOTAL (estimated baseline)** | **4900 / 10000** | Phase 6 produces canonical scorecard |

**Target uplift per AG3:** baseline + 250pts → 5150 / 10000 minimum after pass-1.

## Recommended Phase 2 (next worker-tick on flywheel-oxzyr.1)

1. **Author repair specification** for the 5 uncovered FMs (stale-prompt, schema-drift undo, dispatch-during-input-deaf gate, frozen-projection probe, stale-chevron classifier).
2. **Author fixture stubs** for all 10 FMs (10 fixture pairs: corrupt → fix → assert healthy → undo → byte-identical-to-corrupted).
3. **Identify mutate() chokepoint candidate** in flywheel-loop's existing code (single function all writes flow through).
4. **Score the repair spec** against the 10-dimension rubric (target: 5150+).

## Pre-seed CASS-mine instruction

Per dispatch packet line 164: pre-seed Phase 1 with `--cass-extra-memory ~/.claude/projects/-Users-josh-Developer-flywheel/memory/`. The 10 seed FMs above are derived from MEMORY scan; full CASS-mine integration awaits Phase 2 dispatch.

## Boundary check

- ✅ flywheel-loop is an OWN binary (skill repo)
- ✅ flywheel-loop is state-mutating (writes loop config, dispatches, ledger appends)
- ✅ flywheel-loop has passed canonical baseline (existing `--info`/`--schema`/`--examples`/`doctor` per `--help`)
- ✅ NOT a jeff-stack binary

## Phase 1 → Phase 2 handoff

This document is the Phase 1 deliverable for `flywheel-oxzyr.1` pass-1. Phase 2 (repair specification) is the next worker-tick deliverable on this sub-bead. The sub-bead `flywheel-oxzyr.1` should be filed via `br create` post-decomposition; this archaeology document is the canonical reference for that sub-bead's first dispatch.
