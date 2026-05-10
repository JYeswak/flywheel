---
title: "Lane A.2 — Team Roster + Interactive /flywheel:init Confirmation"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A.2 — Team Roster + Interactive /flywheel:init Confirmation

Author: picoz-p0 orchestrator (Claude)
Date: 2026-05-01T13:58Z
Extends: DESIGN-session-topology.md (this same dir)
Triggered by: Joshua message — "the flywheel:init process should confirm — with me — what the pane orientation is and lock it in… every ntm session needs to know layout of their own, and layout of others… team roster log any ntm session can see in any other session"

## Problem (additional to topology gap)

The topology registry from Lane A solves "where is each pane on this session." It does NOT solve:

1. **Team identity** — when picoz orchestrator finds a critical bug in a SHARED skill that affects alpsinsurance's worker, where does picoz send the message? Today: nowhere — picoz can't see alps's roster, and there's no team-level inbox.
2. **Self-awareness** — when picoz tick fires "we have 1 idle codex worker," it doesn't know if the other 7 sessions ALSO have idle codex workers it could borrow from.
3. **Interactive confirmation** — `/flywheel:init` shipped today silently writes registry rows. Joshua never sees "I'm about to lock in: P0=cc, P1=cc, P2=codex, P3=codex — confirm?" → no human-validation gate → silent miswiring like vrtx-p0-was-zsh-pretending-to-be-orch.

## Design — Two new files + one new flow

### File 1 (extends Lane A) — `~/.local/state/flywheel/session-topology.jsonl`
*Already designed in DESIGN-session-topology.md. No change.*

### File 2 (NEW) — `~/.local/state/flywheel/team-roster.jsonl`
*The fleet-wide roster every session can read.*

Append-only, latest-wins-per-session, one row per session (lifecycle event):

```jsonl
{
  "ts": "2026-05-01T14:00:00Z",
  "event": "session_active",
  "session": "picoz",
  "repo_path": "/Users/josh/Developer/polymarket-pico-z",
  "domain": "trading",
  "client": "internal",
  "orchestrator": {"pane": 0, "kind": "claude", "model": "opus-4.6"},
  "workers": [
    {"pane": 1, "kind": "claude", "model": "opus-4.6", "role": "secondary-orch"},
    {"pane": 2, "kind": "codex", "model": "gpt-5.5-xhigh", "role": "worker"},
    {"pane": 3, "kind": "codex", "model": "gpt-5.5-xhigh", "role": "worker"}
  ],
  "agent_mail_identity": "picoz-orchestrator",
  "agent_mail_project": "/Users/josh/Developer/polymarket-pico-z",
  "current_mission": "spread-intelligence first $1 trade",
  "loop_active": true,
  "loop_tier": "active_normal",
  "available_for_borrow": true,
  "max_borrow_workers": 1
}
{"ts":"2026-05-01T14:00:00Z","event":"session_active","session":"alpsinsurance","repo_path":"/Users/josh/Developer/alpsinsurance","domain":"insurance","client":"alps","orchestrator":{"pane":0,"kind":"codex","model":"gpt-5.5-xhigh"},"workers":[{"pane":1,"kind":"claude","model":"opus-4.6","role":"orchestrator-cc"},{"pane":2,"kind":"codex","model":"gpt-5.5-xhigh","role":"worker"},{"pane":3,"kind":"claude","model":"opus-4.6","role":"worker"}],"agent_mail_identity":"alpsinsurance-orchestrator","agent_mail_project":"/Users/josh/Developer/alpsinsurance","current_mission":"...","loop_active":true,"loop_tier":"active_normal","available_for_borrow":false,"max_borrow_workers":0}
{"ts":"2026-05-01T14:00:00Z","event":"session_dormant","session":"zeststream-v2","repo_path":"/Users/josh/Developer/zeststream-v2","domain":"infrastructure","reason":"never bootstrapped — all bare shells. Run /flywheel:init to activate, or /flywheel:teardown to remove."}
```

**Rules:**
- Single global file — every session reads the SAME path. No per-session copies.
- `event` types: `session_active`, `session_dormant`, `session_paused`, `session_teardown`, `roster_update`, `worker_dead`, `worker_recovered`, `auth_rotated`
- Read pattern: `jq -s 'group_by(.session) | map(max_by(.ts)) | map(select(.event == "session_active"))' team-roster.jsonl`
- Write pattern: append-only, atomic file lock during write

### File 3 (NEW) — `~/.local/state/flywheel/team-pulse.jsonl`
*Heartbeat: each active session writes 1 row every 5min so other sessions can see "is X alive."*

```jsonl
{"ts":"2026-05-01T14:00:00Z","session":"picoz","orch_pane_alive":true,"worker_panes_alive":[1,2,3],"worker_panes_dead":[],"loop_tick_n":47,"last_dispatch_ts":"2026-05-01T13:55:00Z","fuckup_count_24h":1}
{"ts":"2026-05-01T14:00:00Z","session":"alpsinsurance","orch_pane_alive":true,"worker_panes_alive":[2,3],"worker_panes_dead":[1],"loop_tick_n":15,"last_dispatch_ts":"2026-05-01T06:30:00Z","fuckup_count_24h":3}
```

**Rule:** if a session's most recent pulse row is >15min old, that session is dead. Other sessions can see it via `jq` and act (notify Josh, take over a bead).

### Flow — `/flywheel:init` interactive confirmation

Today's `/flywheel:init` is silent. Replace with this 8-step interactive protocol:

```
$ /flywheel:init

Step 1/8 — Detecting tmux session…
  ✓ session: picoz
  ✓ pane count: 4

Step 2/8 — Probing pane states…
  pane 0: claude code 2.1.123  (this pane)
  pane 1: claude code 2.1.123
  pane 2: codex node v0.125.0  gpt-5.5-xhigh
  pane 3: codex node v0.125.0  gpt-5.5-xhigh

Step 3/8 — Inferring layout…
  Suggested: P0=orchestrator(claude), P1=secondary-orch(claude), P2=worker(codex), P3=worker(codex)
  ❓ CONFIRM (y/n/edit): _

Step 4/8 — Repo & domain…
  repo_path: /Users/josh/Developer/polymarket-pico-z
  domain: trading? (detected from CLAUDE.md keyword "trading")
  client: internal? (no client AGENTS.md found)
  ❓ CONFIRM (y/n/edit): _

Step 5/8 — Agent Mail identity…
  Detected existing identity: "picoz-orchestrator" in agent-mail registry
  Project key: /Users/josh/Developer/polymarket-pico-z
  ❓ Use this identity? (y/n/new): _

Step 6/8 — Loop tier & availability…
  Suggested: active_normal (30m tick) — based on commit velocity last 24h
  available_for_borrow: yes — you have 2 codex workers; can lend 1 if requested
  max_borrow_workers: 1
  ❓ CONFIRM (y/n/edit): _

Step 7/8 — Mission anchor…
  Current mission from CLAUDE.md: "spread-intelligence first $1 trade"
  ❓ Confirm or rewrite: _

Step 8/8 — Validation & roster broadcast…
  ✓ Topology row appended to ~/.local/state/flywheel/session-topology.jsonl
  ✓ Roster row appended to ~/.local/state/flywheel/team-roster.jsonl
  ✓ Pulse heartbeat scheduled (5min interval)
  ✓ Agent Mail identity confirmed
  ✓ Other sessions notified via roster_update event
  ✓ Doctor will now monitor this session

  Other active sessions detected:
    - flywheel (orch pane 1, claude) — LIVE, last pulse 2min ago
    - alpsinsurance (orch pane 0, codex) — LIVE, last pulse 4min ago
    - vrtx (orch pane 1, claude) — LIVE, last pulse 1min ago, 3 dead workers
    - skillos (orch pane 1, codex) — DEAD (last pulse 9h ago, P1 hung)
    - zesttube (orch pane 1, claude) — LIVE, last pulse 3min ago
    - clutterfreespaces (orch pane 0, claude) — DORMANT
    - zeststream-v2 — NOT INITIALIZED

  ✓ /flywheel:loop is now AUTHORIZED for this session.
```

**Edit step is critical:** if pane probe sees `node` on pane 1, it might be codex OR a non-codex node script. Joshua needs to confirm "yes that's codex" or override to "no that's a custom heartbeat process, ignore it." This is the **lock-in** he asked for.

### Read access — `flywheel-loop roster` subcommand (NEW)

Any session can run from anywhere:

```bash
$ flywheel-loop roster

ZestStream Fleet Roster — 2026-05-01T14:00Z (8 sessions)
═══════════════════════════════════════════════════════════════════════════
SESSION              ORCH       WORKERS              STATUS    LAST PULSE
─────────────────────────────────────────────────────────────────────────
flywheel             cc:p1      3 codex (p2,3,4)     LIVE      1min ago
picoz                cc:p0      cc:p1, 2 codex       LIVE      now
alpsinsurance        cod:p0     cc:p1, 2 mixed       LIVE      4min ago
vrtx                 cc:p1      0 alive, 3 DEAD      DEGRADED  1min ago
zesttube             cc:p1      2 cc workers         LIVE      3min ago
skillos              cod:p1     1 codex worker       DEAD ❌    9h ago (P1 hung)
clutterfreespaces    cc:p0      —                    DORMANT   —
zeststream-v2        —          —                    GHOST     never initialized

Borrow availability: 1 codex (picoz), 1 codex (zesttube)
Stuck blockers: vrtx (3 dead workers, npm rollback)
```

```bash
$ flywheel-loop roster --json | jq '.[] | select(.status=="DEAD")'
$ flywheel-loop roster --can-borrow codex
```

### Agent Mail wiring

Each session's agent-mail identity stored in roster row. Cross-session messaging becomes:

```bash
# picoz orch finds something alps needs to know
$ flywheel-loop notify --to=alpsinsurance --subject="shared skill X has bug Y" --body=...
# → resolves alpsinsurance roster row → finds agent_mail_project + identity → sends message
```

The flywheel `/flywheel:inbox` command on alpsinsurance side then surfaces it in their next tick.

### Doctor integration

New doctor sections:

```
=== team roster freshness ===
  picoz: pulse age 2min  ✓ FRESH
  alpsinsurance: pulse age 4min  ✓ FRESH
  vrtx: pulse age 1min  ✓ FRESH but workers DEAD
  skillos: pulse age 9h  ❌ DEAD (silent failure last night)
  clutterfreespaces: pulse age N/A  ⚠ DORMANT (intentional?)

=== orchestrator pane integrity ===
  flywheel:1 expected=claude actual=2.1.123  ✓ PASS
  picoz:0 expected=claude actual=2.1.123  ✓ PASS
  alpsinsurance:0 expected=codex actual=node  ✓ PASS
  vrtx:1 expected=claude actual=2.1.123  ✓ PASS
  zeststream-v2:N/A — no topology row, session GHOST  ⚠

=== fleet capacity ===
  total worker panes: 14
  alive worker panes: 11
  dead worker panes: 3 (vrtx)
  available for borrow: 2 codex (picoz, zesttube)
```

## Acceptance criteria (extends Lane A)

10. `/flywheel:init` is fully interactive with 8 confirmation steps
11. Joshua can edit any step's inferred value before locking in
12. After init, every session has a fresh `team-roster.jsonl` row visible to ALL other sessions
13. `flywheel-loop roster` from any session lists ALL 8 sessions with status
14. Pulse heartbeat fires every 5min from each active session via launchd or in-loop scheduler
15. Doctor reports DEAD sessions (pulse >15min stale) within 1 tick of detection
16. `flywheel-loop notify --to=<session>` cross-session messaging works via agent-mail
17. `/flywheel:loop` REFUSES if `team-roster.jsonl` row missing OR pulse-heartbeat not scheduled

## Estimate (delta on top of Lane A)

- team-roster.jsonl + team-pulse.jsonl format: shipped here
- `/flywheel:init` interactive rewrite: ~150 LOC bash + tests
- `flywheel-loop roster` subcommand: ~80 LOC + table renderer
- Pulse heartbeat (launchd plist OR in-loop step): ~30 LOC
- Cross-session notify wiring (agent-mail integration): ~50 LOC
- Doctor sections: ~40 LOC
- Total delta: 4-6 hours ship by one worker (or 2 in parallel)

## Why this answers Joshua's exact ask

| Joshua's ask | This design |
|---|---|
| "/flywheel:init should confirm with me what the pane orientation is" | 8-step interactive flow with y/n/edit at each step |
| "lock it in with a validation that all local flywheel processes are dialed in" | Step 8 validates topology row + pulse heartbeat scheduled + agent-mail registered before authorizing /flywheel:loop |
| "what is a team without them knowing the makeup of the team and where their workers live" | team-roster.jsonl exists for every session; flywheel-loop roster command reads it from anywhere |
| "should be part of the agent-mail setup / coordination" | agent_mail_identity + agent_mail_project stored in roster row; flywheel-loop notify uses it for cross-session messages |
| "every ntm session needs to know layout of their own, and layout of others" | Both layers — session-topology.jsonl (own) + team-roster.jsonl (all sessions) |
| "team roster log in some fashion that any ntm session can see in any other session" | Single global file ~/.local/state/flywheel/team-roster.jsonl readable by all sessions; pulse heartbeat keeps it fresh |

## Out of scope (file as separate beads)

- Cross-session worker borrowing (you can SEE the borrow availability but a dispatch protocol is a separate bead — bd-cross-session-worker-borrow)
- Roster TUI (read-only `flywheel-loop roster --watch` is a v2)
- ntm upstream sync (when ntm v5 ships its own session metadata, decide whether to deprecate roster.jsonl)
