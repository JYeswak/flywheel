---
schema_version: 1
doc_type: architecture_plan
status: draft
authors:
  - flywheel-orchestrator-pane0 (this session, claude-opus-4.7)
review_required:
  - flywheel-pane1 (cc_1)
  - skillos-pane1 (cod_1)
  - joshua (final)
created: 2026-04-30T23:55:00Z
review_due: 2026-05-01T17:00:00Z
build_eta_phase_a: 45min
build_eta_phase_b: 60min
build_eta_phase_c: 90min
build_eta_phase_d: ongoing
---

# Flywheel Loop + Tick Contracts + Validation Architecture

> **Mission:** Convert flywheel doctrine from prose into runtime-enforced
> behavior. Every rule in `~/Developer/flywheel/AGENTS.md` becomes a tick
> check. Every violation becomes data. Every recurring violation graduates
> through L56's promotion ladder. The system observes its own gaps and
> grows those gaps into rules — no premature universalization, no design
> from intuition.

## 1. The problem this solves

Today, agentic-coding standards (Socraticode K≥10, agent-mail file
reservations, NTM dispatch discipline, skill consultation, /research-triad
on new topics, senior-dev commit format) live as **prose** in:

- `~/Developer/flywheel/AGENTS.md` (canonical L-rules)
- `~/Developer/<repo>/INCIDENTS.md` (per-repo Forever-Rules)
- `~/.claude/projects/<project>/memory/feedback_*.md` (CASS memories)

**Workers can violate any of these and the orchestrator only catches it
post-hoc during reaping** — that's slow feedback (Meadows leverage point
#6 — info flow). Most rules are Stage 1 (prose). A few have Stage 3
gates (agent-mail pre-commit guard, `git_pathspec_hook.sh`). Almost
nothing is Stage 4 invariant.

This plan ships the runtime enforcement layer that converts prose →
gate. It does it by **observing** worker behavior at fixed intervals,
**logging** violations as fuckup-log events, and **promoting** rules
through L56's ladder as evidence accumulates.

---

## 2. Three-tier cadence model

Different repos need different pulse rates. The architecture supports
**four tiers** picked per project at `/flywheel:loop start` time.

### Tier: `doctrine` (12h cadence — flywheel repo only)

```yaml
interval: 12h
ticks_per_day: 2 (09:00 + 21:00 local)
audit_depth: deep (8-step contract — see §6)
bead_creation: cross-repo synthesis only
shutdown_after_tick: true (loop pauses until next 12h fire)
purpose: doctrine custodianship; cross-repo pattern recognition
cost: ~30min wall × 2/day = 1hr human attention; ~2× orchestrator LLM cost
```

### Tier: `active_high` (5min cadence — skillos)

```yaml
interval: 5m
ticks_per_day: 288
audit_depth: minimal (rule compliance only)
bead_creation: as needed
shutdown_after_tick: false (always on)
purpose: aggressive moat-building per skillos MISSION.md Q8
cost: high tokens, high accretion velocity
```

### Tier: `active_normal` (30min cadence — alpsinsurance, picoz, vrtx)

```yaml
interval: 30m
ticks_per_day: 48
audit_depth: medium (rule compliance + progress check)
bead_creation: as needed
shutdown_after_tick: false
purpose: paying client work; production deliverables
cost: medium tokens
```

### Tier: `inactive` (no cadence — zeststream-v2, zesttube, etc.)

```yaml
interval: none
ticks_per_day: 0
autoloop_only: true (10min substrate scan from launchd autoloop)
purpose: substrate health check only; not actively driving work
cost: zero (only autoloop deterministic checks run)
```

### Tier selection rules

```bash
/flywheel:loop start                  # uses tier from .flywheel/loop-tier (default: active_normal)
/flywheel:loop start --tier doctrine  # explicit tier override
/flywheel:loop start 5m               # explicit interval, derives tier from interval
```

Tier is persisted in `~/.flywheel/loops/<project>.json`.

---

## 3. The two tick contracts

### `/flywheel:tick` (orchestrator-class, runs in pane 1 of each session)

Runs at the project's tier interval (5m / 30m / 12h). Each tick:

1. **Reads autoloop receipts** from `~/.claude/skills/.flywheel/logs/autoloop-*.jsonl` since last tick
2. **Reads fuckup-log** from `~/.local/state/flywheel/fuckup-log.jsonl` since last tick
3. **Runs N orchestrator-class checks** (table below)
4. **Runs `/flywheel:learn --review`** if 3+ unprocessed fuckup events accumulated
5. **Reaps callbacks** from worker panes
6. **Dispatches one bead** (if any ready) OR **holds idle with reason**
7. **Writes tick receipt** to `~/.local/state/flywheel-pane3/last_tick.json`

Orchestrator-class checks (full table):

| Check | Source rule | Default mode | Failure → fuckup_log class |
|---|---|---|---|
| Autoloop receipts read | spine-integration | SOFT | `orch_skipped_substrate_read` |
| Learn-review triggered when ≥3 unprocessed | L56 ladder | SOFT | `orch_skipped_learn_review` |
| Worker pane states verified before dispatch | L48 substrate-exhaustion | SOFT | `orch_dispatched_blind` |
| All dispatches via `ntm send` (not raw `tmux send-keys`) | L29 NTM-only | WARN | `orch_used_raw_tmux` |
| Substrate-registry has entry for any new launchd/cron added | L48 install-contract | WARN | `orch_unregistered_substrate` |
| Reaped callbacks contain socraticode_queries=N + skills_consulted= + files_released= | L50/L51/L54 | SOFT | `orch_accepted_incomplete_callback` |
| Tick survives compact (queue post-compact firing) | resilience | SOFT | `orch_dropped_post_compact_tick` |

Phase A ships only the **first 3 checks** in SOFT mode.

### `/flywheel:worker-tick` (worker-class, runs in panes 2/3/4)

Runs at fixed 30min cadence regardless of project tier (workers are
rules-followers, not initiative-takers; over-fast pulse on workers is
noise). Each tick:

1. **Reads tmux scrollback** of own pane (`tmux capture-pane -p -S -200`)
2. **Reads recent commits** since worker_started timestamp
3. **Reads recent tool-call log** (Claude harness or codex equivalent)
4. **Runs N worker-class checks** (table below)
5. **Writes tick receipt** to `~/.local/state/flywheel-worker-<pane>/last_tick.json`
6. **Files fuckup-log row** for each violation

Worker-class checks (full table):

| Check | Source rule | Default mode | Failure → fuckup_log class |
|---|---|---|---|
| Modified files have agent-mail reservations | L51 file reservations | WARN | `worker_unreserved_edit` |
| Socraticode K≥10 since dispatch | Axiom 9 / L50 | SOFT | `worker_low_socraticode_K` |
| Commits L52-formatted (PROBLEM/FIX/TEST/COMMIT/SKILLS/CRITERION/AUTONOMY) | L52 callback contract | SOFT | `worker_malformed_commit` |
| `PICOZ_WORKER_FILES=` (or equivalent) set on every commit | bd-rqrsr pathspec gate | WARN | `worker_no_pathspec_env` |
| ≥1 Skill tool consultation per dispatch (NONE_FOUND OK if reported) | L48/L54 | SOFT | `worker_skipped_skill_lookup` |
| `/research-triad` run if dispatch is on NEW topic (low CASS similarity) | Axiom 22 candidate | SOFT | `worker_skipped_research_triad` |
| Callbacks via `ntm send` with proper Enter suffix | L29 + Codex submit-glitch | WARN | `worker_callback_no_enter_or_raw_tmux` |
| Context bar < 85% (warn) / < 95% (halt+handoff) | context discipline | WARN @ 85, HALT @ 95 | `worker_context_ignored` |
| No pre-commit hook bypassed with `--no-verify` | git safety | HALT | `worker_bypassed_hooks` |

Phase B ships only the **first 3 checks** in SOFT mode.

---

## 4. SOFT / WARN / HALT mode auto-graduation (L56 ladder applied)

Each check has a default mode but **graduates automatically** based on
accumulated CASS evidence:

```
SOFT  : log fuckup-log, continue work     (rules with 0–2 prior events)
WARN  : log + visible warning to pane     (rules with 3–5 prior events in 7d)
HALT  : log + halt the worker/orchestrator (rules with 6+ prior events in 7d
                                            OR severity=critical)
```

Mode is computed at tick time by querying `fuckup-log.jsonl` for
`trauma_class` count in trailing 7d. This means **the same rule
auto-tightens as workers violate it more.** If a rule never violates,
it stays SOFT forever. If it violates often, it ratchets to HALT. The
system gets more strict with itself based on observed need.

This is L56 promotion ladder applied to enforcement strength, not
just doctrine layers.

---

## 5. The six-stage validation ratchet

Doctrine flows through six stages, each gated by data:

```
Stage 1: WORKER VIOLATION
         worker-tick observes rule break
         → fuckup-log row with trauma_class

Stage 2: ORCHESTRATOR DAILY REVIEW
         orch-tick runs /flywheel:learn --review
         → 3+ same trauma_class in 7d → INCIDENTS.md entry in repo

Stage 3: FLYWHEEL CROSS-REPO SYNTHESIS (12h tick)
         flywheel deep-audit notices same trauma_class in 2+ repos
         → file flywheel bead "promote to canonical L-rule"
         → workers in flywheel session implement
         → new L-rule lands in ~/Developer/flywheel/AGENTS.md

Stage 4: DISTRIBUTION
         flywheel-loop init runs across all 8 repos
         → new canonical doctrine reaches every repo's
           .flywheel/AGENTS-CANONICAL.md frozen-snapshot

Stage 5: ENFORCEMENT
         worker-tick check added with SOFT mode
         → enforces new rule on every 30min tick

Stage 6: GRADUATION
         SOFT → WARN (3+ events) → HALT (6+ events)
         → eventually doctor --strict invariant
```

**Lock-in mechanic:** A rule cannot reach HALT without:
- 3+ worker violations (Stage 1)
- 1+ orchestrator audit confirmation (Stage 2)
- Cross-repo flywheel synthesis (Stage 3 — proves not single-repo trauma)
- Distribution to all repos (Stage 4)
- N days of SOFT-mode observation (Stage 5)
- Graduation when evidence justifies (Stage 6)

You can't fake your way to HALT. Premature canonization is impossible
by construction.

---

## 6. The flywheel deep-audit contract (twice-daily, doctrine tier)

Runs at 09:00 and 21:00 in flywheel session pane 1. Bounded budget:
30–60min wall. Bounded scope: 12h delta only. Bounded outcome: queue
empty + docs updated + repo locked.

### 8-step contract

```
STEP 1 — AUTOLOOP RECEIPT REVIEW (5min)
   - Read last 12h of autoloop JSONL across all 8 repos
   - Identify repos with sustained doctor=warn or doctor=fail
   - Output: list of repos needing triage

STEP 2 — FUCKUP-LOG CROSS-REPO AGGREGATE (5min)
   - Group last 12h fuckup-log by trauma_class
   - Sort by frequency
   - Identify L56 promotion candidates:
     · Single-repo class → leave for repo orchestrator
     · Multi-repo class → flywheel bead for canonical L-rule

STEP 3 — TICK-CONTRACT VIOLATION RATE (5min)
   - Per repo: worker-tick + orch-tick violations in last 12h
   - Per check: which SOFT checks should escalate to WARN?
   - Output: graduation candidates

STEP 4 — INCIDENTS.md DELTA (5min)
   - git log --since=12h on every repo's INCIDENTS.md
   - Cross-reference: any new entry mentioning a trauma_class also
     seen in 1+ other repos = canonical promotion candidate

STEP 5 — GAP-TO-BEADS (10min)
   - For each finding: file a bead in flywheel beads.db
   - Bead types:
     · Promote trauma_class=X to AGENTS.md L-rule
     · Add doctor invariant for rule Y (3+ events evidence)
     · Update INCIDENTS.md template / tick-check coverage

STEP 6 — WORK THROUGH BEADS (until queue empty OR 30min budget hit)
   - Dispatch beads to flywheel session workers (panes 2/3/4)
   - Each bead: docs update, AGENTS.md edit, doctor patch
   - Workers run normal worker-tick checks during flywheel work
   - Reaped callbacks update bead status

STEP 7 — DOC SYNC + LOCK (5min)
   - Commit all updated AGENTS.md / INCIDENTS.md / doctor invariants
   - Run flywheel-loop init to redistribute canonical doctrine
   - /flywheel:lock if structural change shipped

STEP 8 — SHUTDOWN (1min)
   - touch ~/.flywheel/SLEEP-flywheel-until-next-tick
   - Write next tick state to STATE.md
   - Pane 1 stops /loop pulse; reactivates on next 12h schedule
```

---

## 7. Command surface — TWO verbs, not one

The pulse architecture has **two distinct ownership layers**, so it
needs two distinct verbs. Mixing them in one command (the v0.1 mistake
of this plan) hides the structural difference:

| Layer | Owner | Survives reboot? | Talks to panes? | Cadence type |
|---|---|---|---|---|
| OS-scheduled jobs (launchd plists) | `/flywheel:cron` | YES | NO (deterministic only) | wall-clock |
| Agentic pane pulses (Claude `/loop`) | `/flywheel:loop` | NO (dies with tmux) | YES (loop IS the pane) | session-relative |

These are complementary, not duplicates. **Bootstrapping a project for
true 24×7 requires BOTH.**

### `/flywheel:cron` — owns launchd plists

```
/flywheel:cron --help                    # show this menu
/flywheel:cron register <name> <interval> <command>  # build + install + register substrate
/flywheel:cron remove <name>             # bootout + delete plist + retire substrate entry
/flywheel:cron list                      # show all flywheel-managed launchd jobs
/flywheel:cron status <name>             # last fire, exit code, next fire time
/flywheel:cron logs <name> [--tail N]    # show stdout/stderr from plist
/flywheel:cron pause <name>              # disable without removing
/flywheel:cron resume <name>             # re-enable a paused job
```

**Use `/flywheel:cron` when:**
- you need a job to fire on wall-clock schedule (cron-like, e.g. `every 10min`, `daily 9am`)
- the work is deterministic shell or python (no LLM, no agent decisions)
- it must survive reboots and Mac sleep
- examples: autoloop substrate scan, jeff-issue-watch, weekly-refresh, codex-snapshot, flywheel-keepalive

**Behavior of `register`:**
1. Validate `<name>` matches `ai.zeststream.flywheel-*` convention
2. Validate `<command>` is a real executable file with shebang
3. Build plist with explicit `EnvironmentVariables.PATH` (mitigates the
   Jeff-watcher trauma class)
4. Append substrate-registry entry (`kind: launchd`)
5. `launchctl bootstrap` the plist
6. Verify first fire on `RunAtLoad=true` lands within 30s
7. Confirm: `cron registered: <name> @ <interval> next fire <ts> registry=#<N>`

### `/flywheel:loop` — owns Claude harness `/loop` activations

```
/flywheel:loop --help                    # show this menu
/flywheel:loop start [interval]          # activate agentic /loop in current pane
/flywheel:loop start --tier <tier>       # explicit tier override
/flywheel:loop stop                      # halt /loop in current pane
/flywheel:loop status                    # show all loops across sessions
/flywheel:loop revive                    # post-reboot interactive selection
/flywheel:loop tier-help                 # explain tier choices
```

**Use `/flywheel:loop` when:**
- you need an LLM-driven tick (orchestrator decisions, worker self-audit)
- the work requires agent context (reading STATE/WORK/GOAL, dispatching beads)
- the pulse only needs to run while the session is alive
- examples: `/flywheel:tick` orchestrator pulse, `/flywheel:worker-tick` rule-compliance

**Behavior of `start`:**
1. Verify `.flywheel/` directory exists; fail with guidance if not.
2. Verify `/flywheel:cron` keepalive job registered for this project; if
   not, prompt: "no keepalive cron — loop won't survive reboot. Register
   one now? (y/N)"
3. Detect tmux session topology from pane titles:
   - `*__cc_1` or `*__cod_1` → orchestrator
   - Other agent panes → workers
   - zsh panes → skip
4. If interval is `5m`: prompt *"5m is aggressive — confirm? (y/N defaults to 15m)"*
5. Append substrate-registry entry (`kind: tmux+loop`).
6. Write `~/.flywheel/loops/<project>.json` with full topology + intervals.
7. Activate `/loop <interval> /flywheel:tick` in orchestrator pane.
8. Activate `/loop 30m /flywheel:worker-tick` in each worker pane.
9. Confirm: `loop active: <project> @ orch=<interval>, workers=30m, autoloop=10m, persistence=ON`.

**Behavior of `revive`:**
1. Read `~/.flywheel/loops/*.json`
2. Filter where `auto_revive_on_reboot=true`
3. Show interactive list of candidate projects with last-tick timestamps
4. User selects which to bring online (multi-select)
5. For each selected: recreate tmux session via project's `ntm-setup`
   skill, reactivate loops per saved state.

### Bootstrap pattern — every project, two commands

```bash
# Step 1 (one-time, sets up reboot-survival keepalive):
/flywheel:cron register flywheel-keepalive-skillos 300 "ensure-loop-alive skillos"

# Step 2 (in skillos pane 1, starts the agentic pulse):
/flywheel:loop start 5m
```

After that: cron keeps the session alive forever via the keepalive
script (recreates tmux + `/flywheel:loop start` if it died). Loop
runs the agentic ticks. Substrate-registry has BOTH entries
(`kind: launchd` for cron, `kind: tmux+loop` for loop). Reboot
survives via cron's `RunAtLoad=true` + interactive `/flywheel:loop revive`.

### Tick commands (called BY loops, not directly by humans)

| Command | Class | Cadence | Owner |
|---|---|---|---|
| `/flywheel:tick` | orchestrator-class | per project tier (5m / 30m / 12h) | invoked by `/loop` in pane 1 |
| `/flywheel:worker-tick` | worker-class | always 30min | invoked by `/loop` in panes 2/3/4 |
| `/flywheel:deep-audit` | doctrine tier only | 12h | invoked by `/loop` in flywheel session pane 1 |

Each implements its respective contract (§3 orch, §3 worker, §6 deep-audit).
Reads `~/.flywheel/loops/<project>.json` to know its tier + which checks
to run.

---

## 8. Skillos integration — closing the data loop

Worker-tick events feed skillos's bandit. Each tick on each worker:

```
worker-tick observes:
  worker dispatched on bead bd-XXX
  worker called Skill(socraticode), Skill(beads-workflow), Skill(ubs)
  worker callback verdict=TRUE_BUG, mp_impact=$0/d

worker-tick writes to skillos:
  jsm outcome --skill=socraticode --bead=bd-XXX --verdict=TRUE_BUG
  jsm outcome --skill=beads-workflow --bead=bd-XXX --verdict=TRUE_BUG
  jsm outcome --skill=ubs --bead=bd-XXX --verdict=TRUE_BUG

skillos bandit updates posterior_means.
skillos `jsm suggest` improves for next dispatch.
```

This is **the actual closing of the flywheel loop**. Worker enforcement
isn't just compliance — it's the data pipeline that makes skillos's
bandit better. Every worker-tick = N events feeding the moat.

This integration ships in Phase C (after worker-tick has 24h of clean
data to validate the event format).

---

## 9. Substrate-registry contract — every loop registered at install time

Per the L48 trauma class promoted tonight (the
`substrate-registry-post-hoc-not-install-contract` event in fuckup-log):

**Every `/flywheel:loop start` MUST register the loop in
`~/.local/state/flywheel/substrate-registry.jsonl` BEFORE activating
any cadence.** This is enforced in the command itself — no post-hoc
audits needed.

Registry entry schema (matches existing 20 entries):

```json
{
  "ts": "<UTC ISO>",
  "label": "flywheel-loop-<project>",
  "kind": "tmux+launchd",
  "plist_path": "/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-loop-keepalive-<project>.plist",
  "owner": "flywheel-loop",
  "purpose": "<tier> tick cadence for <project> — orch <interval>, workers 30m",
  "expected_dispatch_class": "agentic_pulse",
  "allowed_sessions": ["<project>"],
  "allowed_targets": ["pane:<orch>", "pane:<worker1>", "pane:<worker2>"],
  "orchestrator_required": true,
  "dispatch_transport": "claude_code_loop_skill",
  "review_due": "<+30d ISO>",
  "lifecycle_state": "active",
  "registered_by": "flywheel-loop-command",
  "evidence": ["<plan-doc-path>", "<loop-state-path>"]
}
```

---

## 10. Build phases

### Phase A — `/flywheel:loop` skeleton + minimal `/flywheel:tick` (45min)

Ships:
- `~/.claude/commands/flywheel/loop.md` (the new command)
- `~/.claude/commands/flywheel/tick.md` (orchestrator tick contract)
- `~/.claude/commands/flywheel/revive.md` (post-reboot interactive)
- `flywheel-loop-keepalive` plist template
- 3 SOFT-mode orch checks: autoloop-receipts-read,
  ntm-send-discipline, learn-review-cadence

Validation: activate on skillos + alpsinsurance. Run for 4h. Verify:
- Both projects pulse at correct intervals
- Tick receipts written
- Orch checks fire (any violations land in fuckup-log)
- No new trauma classes from the architecture itself

### Phase B — `/flywheel:worker-tick` + worker pulses (60min)

Gate: Phase A clean for 24h.

Ships:
- `~/.claude/commands/flywheel/worker-tick.md`
- 3 SOFT-mode worker checks: socraticode-K-count,
  agent-mail-reservation-presence, skill-tool-call-presence
- Auto-activation of worker pulses when `/flywheel:loop start` runs

Validation: 7 days of worker-tick events accumulated across 2+ repos.
Review fuckup-log to identify which checks earn WARN promotion.

### Phase C — `/flywheel:revive` + skillos integration + reboot survival (90min)

Gate: Phase B clean for 24h.

Ships:
- `flywheel-loop-keepalive-revive` launchd job
- `/flywheel:revive` interactive flow
- `jsm outcome` event integration in worker-tick
- Pushover notification on reboot revive opportunity

Validation: actual reboot test. Verify all tagged loops revive
correctly via interactive selection. Verify skillos bandit receives
events.

### Phase D — Ongoing graduation (week+)

Per L56 ladder, rules graduate SOFT → WARN → HALT based on data.
Skillos starts surfacing "you need a new skill for X" suggestions
from rules that keep failing. Doctor invariants ship for HALT-mode
rules. New tick checks added when their trauma class hits 3+ events.

---

## 11. Rollout order

1. **skillos first** (own dogfood — skillos's MISSION says workers work,
   skillos builds the engine; this IS the engine work)
2. **alpsinsurance second** (paying client, real load, real consequences
   if rules drift)
3. **picoz third** (most CASS evidence base, highest doctrine surface)
4. **vrtx + remaining active repos** when Phase B clean for 7d
5. **inactive tier repos** never get loops; autoloop-only

---

## 12. Anti-patterns to avoid

- **Premature L-rule canonization** — every new check stays SOFT until
  L56 thresholds met. No exceptions.
- **Worker pulse < 30min** — over-fast pulse on workers creates noise;
  workers should NOT think every 5min, that's the orchestrator's job.
- **Multi-pulse per orchestrator** — one orchestrator = one pulse. If a
  project needs more, it needs more orchestrators (different sessions).
- **Post-hoc registration** — every loop registers at start, never after.
  This IS the rule we promoted tonight; eat your own dogfood.
- **Unbounded ticks** — every tick has a budget (orch ≤ 5min wall, worker
  ≤ 2min wall, deep-audit ≤ 60min wall). Halt + handoff if exceeded.
- **HALT mode without 6+ events** — graduation is data-driven, not
  intuition-driven. Resist the urge.
- **Skipping the doctrine tier on flywheel** — if flywheel itself
  doesn't run on its own contracts, the contracts are a lie.

---

## 13. Success criteria per phase

### Phase A success
- `/flywheel:loop start` works idempotently on 2+ projects
- Substrate-registry has entry per active loop (L48 honored at install)
- Orch tick fires at correct interval, writes receipts
- 4h of pulses produce 0 architecture-induced trauma classes
- `revive` correctly enumerates tagged projects

### Phase B success
- Worker-tick fires every 30min on 4+ worker panes (2 projects)
- Fuckup-log accumulates worker-class events
- 7 days of data identifies ≥1 check ready for SOFT→WARN promotion
- Auto-graduation logic correctly increases mode based on event count

### Phase C success
- Reboot test passes: all tagged projects revive via interactive flow
- Skillos bandit receives ≥10 outcome events per worker per day
- `jsm bandit stats` shows posterior_mean updates traceable to worker-tick

### Phase D ongoing success
- ≥1 rule graduates SOFT→WARN per week
- ≥1 rule graduates WARN→HALT per month
- Doctor invariants ship within 7d of HALT graduation
- Skillos surfaces "missing skill" suggestions monthly
- Cross-repo trauma classes promote to canonical L-rules quarterly

---

## 14. Open questions for review

1. **Cadence override** — should `active_high` (5m) require explicit
   confirm every time, or only at first activation per project?

2. **Tier change handling** — if a project moves from `active_normal`
   to `active_high`, does the orchestrator need a graceful re-pulse,
   or just stop+start?

3. **Worker-tick on Codex panes vs Claude Code panes** — are there
   topology differences? (Different tool-call log paths, different
   compaction semantics.)

4. **Doctrine tier bead source** — does flywheel deep-audit dispatch
   from flywheel's own beads.db, or from a special doctrine queue?
   (Recommendation: own beads.db; doctrine work IS work.)

5. **Skillos integration data format** — `jsm outcome` schema needs
   verification; current proposal assumes positional + flag args, but
   may need JSONL ingestion for batch.

6. **Sleep behavior on `inactive` tier** — are inactive-tier repos
   eligible for `revive` flow? (Recommendation: no; they're inactive
   for a reason.)

7. **Conflict resolution** — if two orchestrators (different repos)
   try to dispatch to same worker pane, who wins? (Today: pane title
   namespacing prevents this. Verify.)

8. **`/research-triad` similarity threshold** — what's the cutoff for
   "new topic" detection? Proposed: cosine similarity < 0.4 against
   nearest CASS embedding. Needs validation.

---

## 15. Review protocol

This doc is **draft**. Before Phase A build:

1. **flywheel pane 1** (cc_1) reads, runs socraticode K≥10 against
   the canonical path, files counter-proposals or ratifies.
2. **skillos pane 1** (cod_1) reads, evaluates skillos integration
   shape (Section 8), counter-proposes if `jsm outcome` integration
   is wrong-shaped.
3. **Joshua** reviews both responses, makes final architectural
   decisions on the 8 open questions.
4. Plan doc lifecycle_state moves draft → ratified.
5. Phase A build begins.

Triangulated review honors L50 (socraticode), L48 (substrate
exhaustion via three perspectives), and Axiom 22 (research before
propose).

---

## 16. References

- Tonight's session that produced this plan:
  `/Users/josh/.claude/projects/-Users-josh-Developer-polymarket-pico-z/798e3941-3698-4591-86bf-70f0006a1515.jsonl`
- Skillos MISSION.md (locked rev 6, 2026-04-30T22:50:03Z):
  `/Users/josh/Developer/skillos/.flywheel/MISSION.md`
- Canonical AGENTS.md (10 L-rules):
  `/Users/josh/Developer/flywheel/AGENTS.md`
- L56 promotion ladder (canonized this session)
- L48 substrate-exhaustion-before-escalation
- L50 socraticode-mandatory K≥10
- L51 file reservations
- L52 callback contract
- L54 skill-deep-dive
- Tonight's fuckup-log entries:
  `~/.local/state/flywheel/fuckup-log.jsonl` (entries since 22:08Z)
- Substrate registry (entry 20 = ai.zeststream.flywheel-autoloop):
  `~/.local/state/flywheel/substrate-registry.jsonl`
- Phase 0 autoloop already shipped:
  `~/.claude/skills/.flywheel/bin/flywheel-autoloop`
- Existing /flywheel commands:
  `~/.claude/commands/flywheel/`

---

## 17. Cron vs Loop — trauma-class ownership mapping

The split into two verbs cleanly separates two distinct trauma classes
that have been getting conflated:

### Trauma class A — launchd-class (owned by `/flywheel:cron`)

| Trauma | Evidence | Mitigation in `/flywheel:cron` |
|---|---|---|
| Rogue launchd job dispatching for 9 days unnoticed | `com.ntm.watcher.picoz` quarantined 2026-04-30 (CASS) | `register` MUST add substrate-registry entry before bootstrap |
| Plist runs with stripped PATH, tools silently no-op | Jeff-issue-watch missed 7 events tonight (this session) | `register` template ALWAYS sets `EnvironmentVariables.PATH` |
| Plist registered post-hoc, not at install | `ai.zeststream.flywheel-autoloop` caught tonight | `register` is the ONLY blessed install path; no manual `launchctl bootstrap` |
| Plist has no kill switch | various historical | `register` template ALWAYS includes STOP sentinel check |
| Plist consumes wall-clock without bound | various | `register` requires `--max-runtime` flag |

`/flywheel:cron register` is the install contract. Every launchd job
in the fleet MUST go through it. Manual `launchctl bootstrap` is a
deprecated path; doctor invariant flags any plist not registered.

### Trauma class B — agentic-pulse-class (owned by `/flywheel:loop`)

| Trauma | Evidence | Mitigation in `/flywheel:loop` |
|---|---|---|
| Orchestrator pane sits idle for hours | observed across multiple sessions | `start` activates `/loop` immediately; status surfaces stale ticks |
| Worker dispatched but never replies (callback ghost) | bd-3v1nu, bd-1pepa pattern | worker-tick checks callback presence + Enter suffix |
| Loop dies with tmux session, doesn't survive | sleep + reboot common | `start` requires paired cron keepalive (or warns) |
| Multiple loops on same pane | architectural confusion | `start` checks pane already has loop; refuses double-activation |
| Loop fires but finds no STATE.md/WORK.md | new project before init | `start` checks `.flywheel/` exists; fail with guidance |
| 5m on workers (overpulse) | speculative — would create noise | workers ALWAYS 30min; orch tier is the only knob |

`/flywheel:loop start` is the install contract for agentic pulses.
The harness's native `/loop` skill is the underlying primitive; this
verb wraps it with substrate registration + topology awareness +
keepalive coupling.

### Why this separation matters for skillos

Skillos's MISSION.md said the moat is **reliable, safe, tested,
accretively-learning skills**. Cron-class and loop-class infrastructure
are themselves substrates that need to be reliable, safe, tested.

Today, both have shipped via ad-hoc one-off scripts. Tomorrow, both
ship via `/flywheel:cron register` and `/flywheel:loop start`. Those
verbs become the canonical install path for ALL future schedule-based
automation.

**This is a meta-skill.** `/flywheel:cron` and `/flywheel:loop` aren't
just operational commands — they're skills that enforce the L48
substrate-registry invariant on themselves. Every cron job and every
loop registers itself. Eat your own dogfood.

---

## 18. `--help` discoverability contract — every flywheel command

Agents (and humans returning after a week) must be able to discover
flag semantics without reading source. The pattern: every
`/flywheel:*` command implements a tiered help system.

### Three help tiers

```
/flywheel:cmd --help               # short summary (under 30 lines, fits in pane)
/flywheel:cmd --help-long          # comprehensive (with examples, anti-patterns)
/flywheel:cmd --help-best-for      # decision-support: "use this when X, NOT when Y"
```

### Required structure for every command's `--help`

```markdown
NAME
   /flywheel:cron — manage launchd-scheduled deterministic jobs

SYNOPSIS
   /flywheel:cron register <name> <interval> <command>
   /flywheel:cron list
   /flywheel:cron status <name>
   ...

USE WHEN
   - you need a wall-clock schedule (every 10min, daily 9am)
   - the work is deterministic (no LLM, no agent decisions)
   - it must survive reboots

NOT FOR
   - agentic ticks (use /flywheel:loop)
   - one-shot tasks (use /flywheel:dispatch)
   - LLM-driven schedules (use /loop or /schedule)

EXAMPLES
   # register the autoloop substrate scan
   /flywheel:cron register flywheel-autoloop 600 \
       /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop

   # check status of jeff-issue-watch
   /flywheel:cron status flywheel-jeff-issue-watch

ANTI-PATTERNS
   # DON'T use /flywheel:cron for agentic work — it has no LLM context
   /flywheel:cron register my-bad-job 600 "claude --print 'do something'"
       # ✗ launchd has no Claude session; this will fail silently

   # DON'T register without explicit PATH — Jeff-watcher trauma class
   # (the wrapper handles this; never call launchctl bootstrap directly)

SEE ALSO
   /flywheel:loop          — agentic pulse activation
   /flywheel:status        — fleet-wide status
   ~/.claude/skills/.flywheel/bin/flywheel-loop  — underlying binary
```

### `--help-best-for` decision matrix

The killer feature. Returns a side-by-side decision support table:

```
Q: I need work to fire every 5min while my session is alive
A: /flywheel:loop start 5m  (NOT /flywheel:cron — cron has no agent context)

Q: I need a deterministic substrate scan every 10min, even when laptop is closed
A: /flywheel:cron register foo 600 ./bin/foo  (NOT /flywheel:loop — loop dies with session)

Q: I need workers to self-audit every 30min
A: /flywheel:loop start (workers automatically get worker-tick at 30min)

Q: I need flywheel doctrine sweep twice a day
A: /flywheel:loop start --tier doctrine  (12h cadence, deep-audit contract)

Q: I want a job to fire once at 3am tomorrow then never again
A: /schedule (Claude Code native)  (NOT /flywheel:cron — cron is for recurring)
```

### Help-as-substrate

Each command's help text gets included in:
1. The command file itself (`~/.claude/commands/flywheel/<cmd>.md`)
2. The skill index for `Skill` tool discovery
3. CASS for cross-session memory of "what did this command do?"
4. Auto-generated `~/.claude/commands/flywheel/COMMAND-MATRIX.md` updated
   on every new command (via `/flywheel:newcmd` skill)

This makes the command surface **self-documenting**. Agents
encountering `/flywheel:cron` for the first time can run `--help-best-for`
and get a decision matrix that matches their use case to the right
command.

### Discoverability invariants (doctor checks)

```
INVARIANT: every /flywheel:* command file implements --help, --help-long, --help-best-for
INVARIANT: COMMAND-MATRIX.md has an entry for every command in commands/flywheel/
INVARIANT: every command's --help mentions ≥1 SEE ALSO with a different command
```

Doctor flags any command missing these. Command authors (including
auto-generated ones via `/flywheel:newcmd`) fail the gate.

---

**END OF DRAFT v0.2.** Hand-off to flywheel pane 1 + skillos pane 1 for review.

Changelog:
- v0.1 (2026-04-30T23:55Z): initial draft, single command surface
- v0.2 (2026-04-30T23:59Z+): split `/flywheel:cron` vs `/flywheel:loop`,
  added §17 trauma-class mapping, added §18 `--help` discoverability contract
