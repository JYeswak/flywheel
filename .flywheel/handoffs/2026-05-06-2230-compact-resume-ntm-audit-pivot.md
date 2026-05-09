# Handoff — 2026-05-06T22:30Z — reason: compact-resume + ntm-audit-pivot

## PIVOT DIRECTIVE (Joshua, 2026-05-06 post-compact)

> "we've got a really important investigation happening on pane 4 - I want to ensure that we are fully utilizing the capabilities of NTM before we continue building anything new - we need full socraticode review / comparison of every surface. its probably too big of a bead for pane 4 so lets keep breaking this up and researching with proper /flywheel:plan before we keep building - this could impact our open beads."

**Translation:**
1. Pane 4's 109-surface ntm audit is the most important active work. Do NOT build new substrate until it converges.
2. The audit is too large for one bead — once pane 4 lands its first-pass deliverable, **decompose via `/flywheel:plan`** (full 5-phase arc) into bead waves.
3. Existing open beads (Wave 2a A3, B2; Wave 2b/2c/3; orch-uptime ship-runbook remainder) MAY be **superseded or reframed** by audit findings (e.g. `ntm preflight` may obsolete `dispatch-pre-send-validator.sh`; `ntm coordinator` may obsolete `cross-orch-coordination.jsonl`; `ntm rotate` already obsoleted A1).
4. The flywheel does NOT idle during audit — but new bead authoring is GATED on audit findings landing.

## Resume context for next session

- Last commit: `9b6a79c` "fix(doctrine): align 47 formatting_only drifted lines to upstream"
- Branch: master (dirty — heavy plan-arc state, expected)
- Active session: flywheel (4 panes, all THINKING per --robot-activity 22:29Z)
- Locked docs: MISSION.md (locked) | GOAL.md | STATE.md (status: locked)
- Plan arc converged: orch-uptime r3=0.00% diff streak=2; Wave 1 4-of-4 SHIPPED

## In-flight dispatches (do NOT redispatch — these are running)

| task_id | worker | pane | started | expected_by | task_file |
|---|---|---|---|---|---|
| ntm-surface-audit-109-beads-2026-05-06 | flywheel:4 codex | 4 | ~21:50Z | 23:30Z | /tmp/dispatch_ntm-surface-audit-bead-file-2026-05-06.md |
| orch-uptime-A3-auth-gate-credential-rotation-2026-05-06 | flywheel:2 codex | 2 | ~21:43Z | 22:45Z | /tmp/dispatch_orch-uptime-A3-ship-2026-05-06.md (or inline) |
| orch-uptime-B2-topology-tick-wire-2026-05-06 | flywheel:3 codex | 3 | ~21:42Z | 22:45Z | /tmp/dispatch_orch-uptime-B2-ship-2026-05-06.md (or inline) |

All three THINKING per `--robot-activity` 22:29Z. Pane 4 has 1 background terminal active (long-running socraticode K≥10 batch across surfaces).

## Open beads (repo-scoped) — POTENTIALLY AFFECTED BY AUDIT

Beads currently in flight or queued in orch-uptime-2026-05-06:
- **Wave 2a:** A3 (in flight pane 2), B2 (in flight pane 3), C3 WOE bootstrap (queued)
- **Wave 2b:** A2 detector codex_usage_limit subclass, B4 watchers register/load/fire, C2 frozen-projection-invariant-scan
- **Wave 2c:** B3 mobile-eats arity guard
- **Wave 3:** A4 recovery-ledger-credential-rotation, B5 watchers-doctor-com-scope, C4 fleet-sweep-execution
- **Wave 4:** W4 integration validation closeout

**Audit-collision candidates** (may be superseded by ntm native surfaces):
- `dispatch-pre-send-validator.sh` ↔ `ntm preflight`
- `cross-orch-coordination.jsonl` ↔ `ntm coordinator`
- recovery-ledger receipts ↔ `ntm audit`
- `ntm-fleet-health.sh` ↔ `ntm metrics`
- our hand-rolled rotation primitives ↔ `ntm rotate` (already collided on A1)
- topology-tick-refresh ↔ `ntm rebalance`?
- our Pushover/mac-alert ↔ `ntm serve` (event streaming)

Decision rule (post-audit): for each `not_using_have_workaround` row in audit deliverable, file a **supersede bead** rather than continuing to maintain the workaround. For each `using_partial`, file a **migration bead**. For `using_well`, no action.

## Pending decisions for Joshua

1. **Audit-driven bead reframing** — once pane 4 audit delivers `/tmp/ntm-surface-audit-summary-2026-05-06.md`, run `/flywheel:plan ntm-surface-utilization-migration` to decompose into wave-structured bead DAG. Joshua confirms scope before Phase 4 (decompose).
2. **Wave 2-4 freeze gate** — per Joshua's pivot, NEW bead authoring after current Wave 2a callbacks (A3, B2) is **paused** until audit lands. C3 WOE bootstrap and Wave 2b/2c/3 beads do NOT auto-dispatch.
3. **Audit decomposition strategy** — three options, Joshua picks at /flywheel:plan Phase 3:
   - (a) one /flywheel:plan per audit-status bucket (`using_partial`, `not_using_have_workaround`, `not_using_unaware`) → 3 plan-arcs
   - (b) one /flywheel:plan per leverage class (Donella #4-#9 buckets) → 5-6 plan-arcs
   - (c) one mega /flywheel:plan ntm-utilization-master with internal waves → single arc
4. **L120 doctrine-shipped status** — skillos:1 confirmed L120 first-fire validation 21:47Z (heartbeat template emits zero literal payload, path-only refs). Doctrine is now empirically validated in two repos (flywheel + skillos). No action needed; recording for memory.
5. **`/flywheel:learn --review` for 1515 unprocessed fuckup rows** — top class `post-callback-reminder-template-recovery` (1364 events). Pre-compact reminder flagged this as the most-explicit instruction. Post-audit-callback is the right time.

## Files Joshua needs to read on resume

- **`/Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-06T2144-orch-uptime-wave1-mid-shipping.md`** — prior handoff, full Wave 1 context (4-of-4 SHIPPED)
- **`/tmp/ntm-surface-audit-summary-2026-05-06.md`** — pane 4 deliverable (LANDS WITHIN ~1h)
- **`/tmp/ntm-all-commands.txt`** — 109 ntm command enumeration (already exists)
- **`/tmp/dispatch_ntm-surface-audit-bead-file-2026-05-06.md`** — full audit dispatch packet (intact)
- **`/tmp/dispatch_ntm-rotate-vs-A1-reconcile-2026-05-06.md`** — Pending Decision #1 from prior handoff (now subsumed by full audit)
- **`/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/STATE.json`** — `phase5_complete=true polish_convergence_ratified=true streak=2`
- **`.beads/issues.jsonl`** — pane 4 will append 109 P0 audit beads (idempotent on id)

## Audit deliverable shape (what to expect from pane 4)

Per `/tmp/dispatch_ntm-surface-audit-bead-file-2026-05-06.md`:

1. **109 P0 bead rows** appended to `.beads/issues.jsonl`, each classifying a single ntm surface as `using_well | using_partial | using_wrong | not_using_have_workaround | not_using_unaware` with callsites, integration proposals, leverage class.
2. **Status-distribution table** — count by status across 109.
3. **Top 16 highest-leverage `not_using_*` surfaces** with proposal summaries.
4. **Workaround-supersession candidates** — explicit list of our hand-rolled substrate that ntm native obsoletes.
5. **Critical early-exit gate** for `ntm rotate` collision with A1 (already known: A1 was reframed to wrapper, so this is informational at this point).

## Resume sequence (post-compact, in order)

1. **Probe pane 4** — `ntm --robot-activity=flywheel --panes=4` and `--robot-tail=flywheel --panes=4 --lines=30`. If still THINKING with background terminal, leave alone. If callback delivered, read `/tmp/ntm-surface-audit-summary-2026-05-06.md`.
2. **Probe pane 2 & 3** — A3 + B2 callbacks should land within ~1h. Validate four-lens (Brand/Sniff/Jeff/Public) on each before close per L70.
3. **DO NOT DISPATCH new beads** until audit lands. Workers idle is acceptable per Joshua's pivot. (This OVERRIDES the standing "flywheel never idles" rule for this specific gate — audit completion IS productive work.)
4. **When audit lands:** invoke `/flywheel:plan ntm-surface-utilization-migration` to decompose. Use audit deliverable as Phase 1 RESEARCH input (skip lane-A/B/C fanout since the audit IS the research).
5. **Run `/flywheel:learn --review`** in parallel — non-blocking on audit-plan-arc, addresses 1515 unprocessed fuckup rows (top class: post-callback-reminder-template-recovery).

## Suggested resume sequence

1. `/flywheel:status`
2. `/flywheel:tail 4` (audit progress)
3. `cat /Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-06-2230-compact-resume-ntm-audit-pivot.md` (this file)
4. `/flywheel:inbox`
5. (when audit lands) `/flywheel:plan ntm-surface-utilization-migration`
6. (parallel) `/flywheel:learn --review`

## Memory rules earned this session (pre-compact)

- `feedback_caam_activate_is_flywheel_decided_not_joshua_gated.md`
- `feedback_chevron_visible_does_not_mean_submits_work.md`
- `feedback_frozen_projection_of_mutable_state_class.md`
- `feedback_convergent_evolution_is_canonical_signal.md`
- `project_orch_uptime_plan_arc_converged_2026_05_06.md`

## Mission anchor

`continuous-orchestrator-uptime-self-sustaining-fleet` — extends to ntm-surface-full-utilization. The audit is the upstream Donella #5 (rules) leverage on the entire substrate-vs-handrolled question.
