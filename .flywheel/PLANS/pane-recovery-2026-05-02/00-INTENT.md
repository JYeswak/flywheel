---
title: "Pane-Recovery System — Intent"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Pane-Recovery System — Intent

**Plan ID:** pane-recovery-2026-05-02
**Started:** 2026-05-02T02:45Z
**Owner:** flywheel orchestrator (RubyCastle)
**Trigger:** skillos:0.1 frozen 4m+ on codex `Working` spinner with queued `›` prompt unsubmitted; `ntm health` falsely reported idle while `ntm activity` correctly reported THINKING+velocity=0.

## One-line goal

A flywheel substrate that **detects, surfaces, and recovers** wedged worker panes automatically — so the orchestrator never silently dispatches into a frozen agent.

## Why this matters

The fleet-idle DAG (z0wh + fbgi + 3m6p + ylwk) closes the loop on *idle* workers — workers sitting at empty `›` prompts who could be doing work. This pane-recovery system closes the symmetric gap: workers who APPEAR idle (per `ntm health`) but are actually wedged on a non-progressing spinner with a queued unsubmitted prompt. Without this, fleet-idle's dispatch logic will silently push new work into dead panes, which absorbs the dispatch into the queued state and the orchestrator records false progress (the L66 USE-DATA-NOT-MEAT-PUPPET trauma class).

## User workflows

### W1 — Frozen pane caught at next tick
- **Persona:** flywheel orchestrator (per-tick autoloop)
- **Trigger:** Codex worker enters `Working (Nm Ns)` spinner state, then process freezes (timer stops advancing). User has typed something into `›` but Enter never submitted, or submitted but codex hung mid-tool-call.
- **Steps:**
  1. Tick Step 3 reads `ntm activity --json` for the session
  2. Detector matches: `state ∈ {THINKING, GENERATING}` AND `velocity=0` AND `duration > 120s`
  3. Pane classified as `FROZEN_SUSPECT`
  4. Tick refuses to dispatch to that pane
  5. Tick action: emit `RECOVER_PANE` decision; either auto-runs `/flywheel:recover-pane` (if confidence high) OR surfaces in `/flywheel:status` for Joshua disposes
- **Outcome:** Frozen pane is unwedged or escalated within one tick interval (default 10m); no false dispatches into wedged workers; full pane history preserved.

### W2 — Operator manual recovery
- **Persona:** Joshua or orchestrator hitting a known-bad pane
- **Trigger:** `/flywheel:status` shows `FROZEN_SUSPECT` row; or operator notices spinner not advancing
- **Steps:**
  1. Run `/flywheel:recover-pane <session> <pane>`
  2. Command executes recovery ladder (8 steps: probe → capture → escape → C-c → re-probe → respawn → relaunch → verify)
  3. On each step, command prints outcome + halts ladder on first success
  4. On respawn, captures pane history to `/tmp/<session>_pane<N>_pre_recover_<ts>.txt` first
  5. Auto-detects agent type (cc vs cod) and uses correct relaunch command from `~/.config/ntm/config.toml`
- **Outcome:** Pane recovered with full audit trail in dispatch-log.jsonl; history file preserved for forensics.

### W3 — Recovery itself wedges (recursive trauma case)
- **Persona:** orchestrator at next tick after a recover attempt
- **Trigger:** `/flywheel:recover-pane` was run but pane is still classified `FROZEN_SUSPECT` 1 tick later (10m+)
- **Steps:**
  1. Tick detects unchanged FROZEN_SUSPECT after prior recover
  2. Logs SOFT violation `recovery_recursive_failure`
  3. Escalates: refuses any further dispatch to that session pane (not just the frozen one — full session quarantine to avoid cascade)
  4. Surfaces in /flywheel:status with `QUARANTINED` flag
  5. Files fuckup-log row with `class=recovery-recursive-failure`
  6. Joshua-disposes required: full session respawn or kill
- **Outcome:** Recursive failures don't burn dispatches in a loop; Joshua sees a clear escalation flag.

## Non-goals (explicitly out of scope)

- Reproducing why codex spinners freeze in the first place — that's an upstream codex issue, not ours
- Pre-emptive freezing detection (looking at memory pressure or process state before symptoms appear)
- Auto-retry of the lost queued prompt — once the pane is respawned, the queued text is gone; we don't try to recover it
- Fixing `ntm health` upstream — we file the issue, but our flywheel uses `ntm activity` regardless of upstream timeline
- Generic process supervisor integration (launchd/systemd-style) — we use ntm-native respawn

## Constraints

- **Read-only by default.** Detection probes never mutate state. Only the explicit recover command touches pane state.
- **Capture before mutate.** Any respawn step MUST capture 3000-line pane history to `/tmp/` first.
- **Native-only dependencies.** No new binaries; uses `ntm activity`, `ntm respawn`, `tmux send-keys`, `ntm config`. Integrates with existing flywheel substrate.
- **Substrate-registry registration.** The recover command registers as substrate before invocation per orchestrator-substrate-blindness doctrine.
- **Cross-link to upstream issue.** Local fix is overlay; upstream is the proper fix. Don't drift.
- **Cost class L0-L1.** No LLM reasoning in the detection or recovery — pure shell/tmux/ntm. Joshua-disposes only on recursive failure (W3).
- **Idempotent.** Running recover on an already-healthy pane = no-op + report.
- **Dry-run mandatory.** `/flywheel:recover-pane --dry-run` shows the ladder it would execute without touching anything.

## Success criteria (measurable)

| # | Criterion | Measurement |
|---|---|---|
| 1 | Frozen-spinner detector catches the canonical case | Synthetic test: codex pane at `Working (Nm)` + queued `› <text>` is classified FROZEN_SUSPECT within one probe |
| 2 | Detector has < 5% false positive rate | Across 24h fleet observation, `FROZEN_SUSPECT` panes that recover on their own without intervention < 5% |
| 3 | Recovery ladder succeeds on first respawn for known case | E2E test: synthetic frozen codex pane → `/flywheel:recover-pane` → pane reaches WAITING within 30s |
| 4 | Pane history preserved before any destructive step | Audit: every `respawn` invocation has matching pre_recover_<ts>.txt file with > 500 lines |
| 5 | Tick refuses to dispatch into FROZEN_SUSPECT pane | Synthetic test: tick with ready bead + frozen pane → no dispatch logged + decision=RECOVER_PANE |
| 6 | Recursive-failure quarantine triggers correctly | Synthetic test: 2 consecutive ticks with same FROZEN_SUSPECT → session marked QUARANTINED, no further dispatches |

## Anchored references

- Today's recovery proof: skillos:0.1 (gpt-5.5 YOLO mode now alive)
- Beads filed: `flywheel-terc` (detector switch) + `flywheel-7xxs` (slash command)
- Memory: `feedback_pane_state_ntm_health.md` (corrected to `ntm activity` primary)
- Upstream draft: `.planning/upstream-issues/ntm-health-vs-activity-disagreement-2026-05-02.md`
- Sister system: fleet-idle DAG (z0wh) — opposite problem (idle ≠ frozen, but both miss-classified)
- Sister memory: `feedback_two_truth_sources_before_decide.md` (cross-check before mutation)

## Phase plan

| Phase | Output | Status |
|---|---|---|
| 0 — INTENT | This doc | ✅ shipped |
| 1 — RESEARCH | 3 parallel lanes (detector, recovery ladder, integration) | ⏳ next |
| 2 — REFINE | r1 + r2 until <5% delta | pending |
| 3 — AUDIT | crosscutting + safety + idempotency | pending |
| 4 — DECOMPOSE | bead graph (extends terc + 7xxs with sub-beads) | pending |
| 5 — POLISH | 6+ rounds | pending |
