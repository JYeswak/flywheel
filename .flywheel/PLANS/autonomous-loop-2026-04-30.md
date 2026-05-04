# Autonomous Loop Plan

Question: "how do we make this loop process CORE to the entire flywheel? every project I'm working on right now is stopped - completely idle - until I jump in and ask it to do something. That is not flywheel."

Generated: 2026-04-30
Convergence: **CONVERGED (3-of-3)**
Tier: 1 (codex-pane fanout)
Models queried: codex-pane2 (claude), codex-pane3 (gpt-5.5), codex-pane4 (gpt-5.5)

## Plan A: Full Supervisor (Pane 2)

Provenance: `/tmp/flywheel-autonomous-loop-design-pane2.md` (27KB)

Proposes `flywheel-autoloop` binary with 6 subcommands (run, scan, queue, dispatch, stop, status). LaunchAgent every 10 min. 6 work-discovery probes (kill switches, doctor, beads, dispatch/callback debt, AgentMail, source freshness). 14-signal scoring formula with thresholds (<50 skip, 50-79 queue, 80-99 dispatch, >=100 priority dispatch). 4 implementation phases. Negative cache with per-outcome cooldowns. Per-repo budgets (6 ticks/day, 12 dispatches/day). Full queue schema, autonomous task prompt template, JSONL audit log.

Strength: comprehensive scoring and safety model; covers multi-repo fairness.
Weakness: too much to ship in one sitting; risks plan-space paralysis.

## Plan B: Minimal Heartbeat (Pane 4)

Provenance: `/tmp/flywheel-autonomous-loop-design-pane4.md` (18KB)

Proposes `flywheel-loop-heartbeat` bash script — thin wrapper calling existing `flywheel-check --root --json` then `flywheel-loop doctor --strict` then `flywheel-loop tick`. LaunchAgent every 30 min. Identifies 6 blockers precisely. Ships in "first hour / first day / first week" increments. Provides copy-pasteable script and plist. Key insight: "the first autonomous loop should prove that recurrence can safely produce structured tick receipts and respect STOP/override states. Once that is boring, add the tiny action executor."

Strength: ships today; uses only existing primitives; minimal blast radius.
Weakness: no scoring, no queue, no multi-repo fairness — a single-repo heartbeat.

## Plan C: Research-Backed Three-Layer Architecture (Pane 3)

Provenance: `/tmp/flywheel-autonomous-loop-design-pane3.md` (448 lines)

Proposes three-layer hybrid: (1) Event ingestion (no LLM) — record events, dirty flags, (2) Scheduler/scorer (no LLM) — deterministic priority queue, (3) Executor (sometimes LLM) — only after gates pass. Key insight: "Do not let an LLM poll 30+ repos looking for work." Adds cost classes L0-L4 (deterministic=free, synthesis=bounded, executor=gated, swarm=bead-required, live=approval-required). No-op escalation ladder: 2 warn, 3 force replan, 4 halt. 10-step "nothing to do" decision tree with whitelisted idle reasons. Hybrid event+pulse: events set dirty flags, pulse reconciles missed signals. Budget: 12 global/day, 3 per-repo/day. Circuit breakers for no-op streak, repo failure, cost cap, lock conflict, STOP.

Strength: strongest theoretical grounding; references loop-enforcement, accretive-cron-orchestration, and swarm-operator-loop precedents; prevents the known 9-hour stall pattern.
Weakness: more design than executable code; Phase 1 estimate is 4-6 hours vs pane 4's "first hour."

## Convergence Verdict: CONVERGED (3-of-3)

All three designs agree on 8 foundational decisions:

| # | Decision | Pane 2 | Pane 4 | Synthesized |
|---|----------|--------|--------|-------------|
| 1 | Persistent process | launchd | launchd | launchd |
| 2 | Core primitives | flywheel-loop doctor/tick/fleet/check | same | same |
| 3 | STOP enforcement | self-enforced in runner | same | same |
| 4 | Phase 0 scope | queue-only, no agent wakeups | receipt-only, no agent wakeups | receipt + queue, no agent wakeups |
| 5 | Dispatch transport | ntm send | ntm send | ntm send |
| 6 | Concurrency guard | flock | flock | flock |
| 7 | tick safety | bounded, writes receipts only | same | same |
| 8 | Ship strategy | incremental phases | first hour/day/week | incremental: today/day/week |

Disagreement is only on *scope of first ship* and *naming*. Resolved below.

## Synthesized Plan

### Naming

Binary: `flywheel-autoloop` (Pane 2). It will grow past "heartbeat." The plist label follows: `ai.zeststream.flywheel-autoloop`.

Provenance: Pane 2 naming, Pane 4 shipping strategy.

### Phase 0 — Ship Today (Pane 4's "First Hour" scope)

**Goal:** Prove launchd can safely and repeatedly scan repos, select one, run doctor + tick, write structured receipts, and respect STOP sentinels. Zero agent wakeups. Zero source edits. Zero model API calls.

**Files to create (in order):**

#### File 1: `~/.claude/skills/.flywheel/bin/flywheel-autoloop`

Bash script. Phase 0 implements only the `run` subcommand (future phases add `scan`, `queue`, `dispatch`, `stop`, `status`).

Behavior:
1. `flock` single-run lock at `$STATE_DIR/autoloop.lock`
2. Check STOP sentinels: `~/.flywheel/STOP-ALL`, `~/.flywheel/STOP-autoloop`
3. Run `flywheel-check --root $ROOT --json`
4. Filter repos: `status=ok|ready`, `next_owner=agent`, no `next_tick_override`
5. Select one repo (dirtiest first, then lexicographic — Pane 4's simple selector)
6. Run `flywheel-loop doctor --strict --repo "$repo" --json`
7. Run `flywheel-loop tick --repo "$repo" --json`
8. Write `$STATE_DIR/last_run.json` with ts, repo, doctor, tick
9. Append JSONL row to `$LOG_DIR/autoloop-YYYYMMDD.jsonl`
10. Exit

Environment variables (Pane 4's pattern, Pane 2's names):
- `FLYWHEEL_HOME` = `/Users/josh/.claude/skills/.flywheel`
- `FLYWHEEL_AUTOLOOP_STATE_DIR` = `/Users/josh/.local/state/flywheel-autoloop`
- `FLYWHEEL_AUTOLOOP_ROOT` = `/Users/josh/Developer`

State dir is separate from pane-3's `flywheel-pane3` state (Pane 4 blocker #6).

#### File 2: `~/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist`

LaunchAgent, `StartInterval=1800` (30 min, Pane 4's conservative start), `RunAtLoad=true`. `/bin/bash -lc` wrapper per existing house style. Logs to `~/.claude/skills/.flywheel/logs/autoloop-launchd.{out,err}`.

#### Validation commands (run after install):

```bash
chmod +x ~/.claude/skills/.flywheel/bin/flywheel-autoloop
~/.claude/skills/.flywheel/bin/flywheel-autoloop run --json
cat ~/.local/state/flywheel-autoloop/last_run.json | jq .
plutil -lint ~/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist
launchctl kickstart -k gui/$(id -u)/ai.zeststream.flywheel-autoloop
tail -50 ~/.claude/skills/.flywheel/logs/autoloop-$(date -u +%Y%m%d).jsonl
```

#### STOP test:

```bash
touch ~/.flywheel/STOP-autoloop
launchctl kickstart -k gui/$(id -u)/ai.zeststream.flywheel-autoloop
cat ~/.local/state/flywheel-autoloop/last_run.json | jq .status
# expect: "stopped"
rm ~/.flywheel/STOP-autoloop
```

### Phase 1 — First Day (add scoring + queue)

**Gate:** Phase 0 has run successfully for 24+ hours with no unexpected failures.

**Additions:**
- Add `scan` subcommand (separated from `run` for dry-run inspection)
- Add Pane 2's scoring formula (14 signals, 4 thresholds)
- Write `$STATE_DIR/queue.json` per Pane 2's schema
- Add negative cache in `$STATE_DIR/repo-state.json` (Pane 2 cooldowns)
- Add `--dry-run` flag (scan + score + queue, no tick)
- Add repo allowlist via `FLYWHEEL_AUTOLOOP_REPOS` env var (Pane 4)
- Add cooldown: same repo max once per 4 hours unless override/high score
- Drop `StartInterval` to 600 (10 min, Pane 2's target)

**Files:**
- Modify: `bin/flywheel-autoloop` (add scan, scoring, queue, dry-run)
- Create: `config/autoloop.json` (Pane 2's config schema)
- Create: `tests/test_autoloop.sh` (Pane 4's test spec: hermetic temp repos, STOP behavior, no-ready-repo, ready repo tick)

### Phase 2 — First Week (add dispatch)

**Gate:** Phase 1 queue quality is acceptable (24h of dry-run shows correct repo selection).

**Additions:**
- Add `dispatch` subcommand: pick top queue item >= 80, write task file to `/tmp/flywheel-autoloop-<id>.md`, `ntm send`, log to dispatch-log.jsonl
- Add Pane 2's autonomous task prompt template
- Add `stop` subcommand (create STOP sentinels)
- Add `status` subcommand (read last_run, queue, repo-state, launchd job state)
- Add Pane 2's budget enforcement (6 ticks/day, 12 dispatches/day per repo)
- Add closeout receipt validation requirement for dispatched agents
- Add callback reaping (Pane 2 probe #4)
- Wire `/flywheel:status` to read `last_run.json` (Pane 4)

**Constraints (Pane 2):**
- `max_autonomous_ticks_per_run=1`
- `auto_spawn=false`
- `min_score_to_wake_agent=80`

### Phase 3 — First Month (multi-repo fairness)

**Gate:** Phase 2 dispatches are producing valid closeout receipts.

**Additions:**
- Per-repo budgets (Pane 2)
- Aging score for starvation prevention
- Daily queue digest
- `flywheel-autoloop explain --repo PATH`
- `auto_spawn=true` for score >= 100 (Pane 2 Phase 2)
- Tiny action executor for whitelist: `run_baseline_validation`, `summarize_dirty_worktree` (Pane 4 "first week")
- State DB event integration (Pane 2)
- Doctor integration: report heartbeat job loaded/running and last-run age (Pane 4)

## Decision Points for Joshua

1. **Phase 0 interval:** 1800s (30 min) to start. Drop to 600s (10 min) at Phase 1. Approve?
2. **Phase 0 scope:** Receipt-only, no agent wakeups. Correct gate for Phase 1?
3. **Binary location:** `~/.claude/skills/.flywheel/bin/flywheel-autoloop`. Correct home?
4. **Name the plist:** `ai.zeststream.flywheel-autoloop`. Match existing convention?
5. **Proceed to implementation?** Phase 0 is 2 files. Ship now?

## What Ships Today

| # | File | Type | Size |
|---|------|------|------|
| 1 | `~/.claude/skills/.flywheel/bin/flywheel-autoloop` | bash script | ~80 lines |
| 2 | `~/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist` | launchd plist | ~30 lines |

Total: 2 new files, ~110 lines, zero modifications to existing code.

## What Does NOT Ship Today

- No scoring formula (Phase 1)
- No queue.json (Phase 1)
- No agent dispatch (Phase 2)
- No auto-spawn (Phase 3)
- No source edits by the loop (ever, unless explicitly whitelisted)
- No direct model API calls from launchd (ever)

## Pane 3 Additions (integrated across phases)

### Cost Classes (apply from Phase 1)

| Class | Allowed | When |
|---|---|---|
| L0 | SQL, git, doctor, bead list, jq | Every pulse, free |
| L1 | Summarize candidate, produce plan/receipt | Score threshold + budget |
| L2 | One flywheel tick or one worker dispatch | Score >= 80 + budget |
| L3 | Multiple workers, cross-repo plan | Bead/mission lane + reason |
| L4 | Deploy, publish, external side effects | Explicit Joshua approval |

### No-Op Escalation Ladder (apply from Phase 1)

| Streak | Action |
|---:|---|
| 2 | Warn: log no-value-created flag |
| 3 | Force replan: write remediation/plan artifact |
| 4 | Halt: do not re-arm; write urgent artifact |

### "Nothing To Do" Decision Tree (executor logic from Phase 2)

```
1. STOP or human-gated? -> blocked receipt + cooldown
2. next_tick_override? -> execute or explain why not
3. Worker callbacks/AM items? -> reap/validate/close
4. Doctor fail? -> repair before feature work
5. Ready/stale beads? -> dispatch one bounded lane
6. Git dirty / unvalidated commit? -> smallest validation
7. Docs/state stale? -> update repo-local STATE/WORK
8. External deltas/freshness signals? -> bounded research
9. Bead graph insufficient for mission? -> plan-space artifact
10. All probes clean -> legitimate idle receipt + evidence + cooldown
```

### The Invariant

> "A deterministic local control plane continuously observes the repo ecosystem, scores actionable work, and spends agent cognition only when the machine evidence says a tick will create value." — Pane 3

## Provenance Index

| Decision | Source |
|----------|--------|
| Binary name `flywheel-autoloop` | Pane 2 |
| Ship-today-first strategy | Pane 4 |
| Three-layer architecture (ingest/score/execute) | Pane 3 |
| Scoring formula (14 signals) | Pane 2, refined by Pane 3 |
| Cost classes L0-L4 | Pane 3 |
| No-op escalation ladder | Pane 3 |
| Decision tree for idle state | Pane 3 |
| `flock` guard | All 3 |
| STOP sentinel self-enforcement | All 3 |
| Separate state dir from pane-3 | Pane 4 blocker #6 |
| 30 min start, drop to 10 min | Pane 4 (start), Pane 2 (target) |
| `flywheel-check --root --json` as fleet scanner | Pane 4 |
| Queue schema + negative cache | Pane 2 |
| Task prompt template | Pane 2 |
| First hour/day/week pacing | Pane 4 |
| Budget enforcement (12 global/3 per-repo) | Pane 2 + Pane 3 |
| Closeout receipt validation | Pane 2 |
| Event-driven dirty flags + pulse hybrid | Pane 3 |
| `flywheel-check --heartbeat-status` | Pane 4 (renamed to `flywheel-autoloop status`) |
