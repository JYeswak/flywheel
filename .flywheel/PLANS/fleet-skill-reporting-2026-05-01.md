---
title: "Lane A.3 — Fleet-wide Skill Discovery Reporting → skillos"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A.3 — Fleet-wide Skill Discovery Reporting → skillos

Author: picoz-p0 orchestrator (Claude)
Date: 2026-05-01T14:02Z
Extends: DESIGN-team-roster-and-init-flow.md (Lane A.2)
Triggered by: Joshua message — "every worker across the fleet should know when they find a skill — log it in agentmail and ntm send to skillos worker or coordinator. We have to think of this whole ecosystem as part of our enterprise with proper reporting / logging across entire system"

## Problem (the missing reporting layer)

Today: workers discover skill needs constantly. picoz worker hits a NaN propagation bug → invents a regex pattern → fixes it → moves on. The pattern is gone. Next month another worker on alpsinsurance hits a similar bug, doesn't know picoz solved it, reinvents (badly).

The 3-strike-becomes-skill rule is **session-local**. There's no fleet-wide observatory. skillos exists as a session but nothing outside skillos knows when something is becoming skill-worthy.

This is the **enterprise reporting** layer Joshua just asked for. Workers are field reps. skillos is HQ. We need a structured pipeline of field reports flowing to HQ.

## Design — Single global skill-discovery log + skillos consumer

### File 4 (NEW) — `~/.local/state/flywheel/skill-discoveries.jsonl`
*Append-only, every worker in every session can write to it.*

```jsonl
{
  "ts": "2026-05-01T14:02:00Z",
  "discovery_id": "sd-1mxy7",
  "session": "picoz",
  "worker_pane": 2,
  "worker_kind": "codex",
  "task_context": "ntm-command-surface deep dive",
  "discovery_kind": "pattern-emerged",
  "candidate_skill_name": "fleet-liveness-watchdog",
  "evidence": {
    "occurrence_count": 1,
    "prior_occurrences": [],
    "code_pattern_hash": "sha256:...",
    "snippet": "ntm health <session> --auto-restart-stuck --threshold 30m runs as launchd plist",
    "search_terms_that_failed": ["ntm health daemon", "auto restart stuck", "fleet liveness"]
  },
  "promotion_signal": "first_sighting",
  "agent_mail_thread": "fleet-liveness-2026-05-01",
  "should_become": "skill-builder candidate",
  "blocking_current_work": false
}
{
  "ts": "2026-05-01T14:30:00Z",
  "discovery_id": "sd-2xyz4",
  "session": "alpsinsurance",
  "worker_pane": 3,
  "worker_kind": "claude",
  "task_context": "client onboarding for new dental practice",
  "discovery_kind": "pattern-recurrence",
  "candidate_skill_name": "fleet-liveness-watchdog",
  "evidence": {
    "occurrence_count": 2,
    "prior_occurrences": ["sd-1mxy7"],
    "snippet": "needed same fleet-liveness check for client environments",
    "matched_via": "skillos-coordinator-fuzzy-match-on-candidate_skill_name"
  },
  "promotion_signal": "second_sighting",
  "should_become": "skill-builder dispatch candidate (3-strike at next sighting)"
}
```

### Discovery kinds (enum)

| `discovery_kind` | When workers emit |
|---|---|
| `pattern-emerged` | Worker invented a 3+ line pattern they suspect is reusable |
| `pattern-recurrence` | Worker matched an existing discovery (skillos coordinator scores) |
| `skill-search-miss` | Worker ran `mcp__skill-search-mcp` or grepped `~/.claude/skills/` and found nothing relevant for their problem |
| `skill-found-but-incomplete` | Existing skill missing a critical case worker had to handle manually |
| `skill-broken-yaml` | Worker found a SKILL.md with corrupted frontmatter (one of the 90+ from RC1) |
| `cross-repo-shared-pattern` | Worker noticed same pattern would help N other repos |
| `anti-pattern` | Worker did something that looked right but caused regression — should be in CASS feedback |

### Auto-promotion ladder (enforced by skillos coordinator)

```
1 sighting   → log only (sd-* row, no action)
2 sightings  → notify skillos coordinator via agent-mail
3 sightings  → skillos auto-files skill-builder bead with consolidated evidence
5 sightings  → skillos auto-dispatches a worker to ship the skill
```

The 3-strike rule is the existing CASS doctrine — this just **automates the strike-counting fleet-wide** instead of requiring it to happen within one session.

### Consumer side — skillos as fleet HQ

skillos session takes on a NEW role: **fleet skill coordinator.** Its loop adds these steps:

```
Tick step N:
  1. Read ~/.local/state/flywheel/skill-discoveries.jsonl (last 24h tail)
  2. Group by candidate_skill_name (fuzzy-match if no exact)
  3. For each group:
       if count >= 3 and no skill-builder bead exists: file one
       if count >= 5 and bead is OPEN: dispatch worker
       if count >= 2: send roster notification to source sessions ("you and X others hit this")
  4. Emit fleet-skill-pulse row to team-pulse.jsonl with stats
```

skillos becomes the system's **anti-frankenagent-detection** + **3-strike automator**.

### Worker emission protocol

Every worker callback envelope gets a new optional field:

```
DONE task=<id> verdict=PASS skill_discoveries=2 sd_ids=sd-1mxy7,sd-2xyz4 ...
```

The orchestrator on dispatch side:
1. Sees `skill_discoveries=2` in callback
2. Reads the sd-* rows worker wrote
3. Attributes them to the worker's session (already in row)
4. The skillos coordinator picks them up on next tick

### Worker template addition (mandatory line)

Every worker dispatch packet now includes a "skill discovery" reminder:

```
SKILL DISCOVERY DUTY: if during your work you:
  (a) invent a pattern you think is reusable (pattern-emerged)
  (b) wished a skill existed (skill-search-miss)
  (c) found a broken SKILL.md (skill-broken-yaml)
  (d) found a skill missing a case (skill-found-but-incomplete)
THEN before callback: append a row to ~/.local/state/flywheel/skill-discoveries.jsonl
with the schema in DESIGN-fleet-skill-reporting.md. Include sd-* IDs in callback.
```

Hook enforcement: a worker that callbacks without ANY sd-* discovery in a >2hr task is suspicious. Doctor flags it on the 3rd consecutive callback with no discoveries — that worker is either (a) doing trivial work, (b) skipping the duty.

### Cross-session live notification (optional, P1)

When a sd-* row is written, fire a hook that:
1. Looks up skillos's roster row (orch_pane=1, kind=codex)
2. `ntm send skillos --pane=1 "Discovery sd-1mxy7 from picoz: candidate=fleet-liveness-watchdog (1st sighting). Read /tmp/sd-1mxy7-detail.md if you want to investigate now."`
3. skillos can choose to act immediately or wait for next coordinator tick

### Agent Mail thread per skill candidate

Every distinct `candidate_skill_name` gets an agent-mail thread:
- Title: `[skill-discovery] fleet-liveness-watchdog`
- Members: every session that has filed a discovery row for this candidate
- Auto-archive when: skill ships OR 30 days no new sightings

This gives Joshua a single inbox view of "what is the fleet learning right now."

## Doctor integration

```
=== fleet skill discovery ===
  Last 24h discoveries: 7
  Top candidates by sightings:
    fleet-liveness-watchdog: 2 (picoz, alpsinsurance) — 1 strike from auto-bead
    yaml-skill-frontmatter-bulk-fix: 4 (picoz, vrtx, zesttube, flywheel) — AUTO-BEAD FILED bd-xyz
    codex-token-rotation-via-caam: 1 (picoz) — first sighting
  Pending skillos coordinator action: 1 candidate at 3-strike threshold
```

## Acceptance criteria (extends Lane A + A.2)

18. `~/.local/state/flywheel/skill-discoveries.jsonl` exists, world-readable, append-locked
19. Worker dispatch template includes skill-discovery duty reminder
20. Workers from any session can append sd-* rows; lock is uncontended
21. skillos coordinator tick reads + groups + auto-promotes per ladder
22. 2-sighting candidates trigger agent-mail thread creation
23. 3-sighting candidates trigger skill-builder bead creation
24. 5-sighting candidates trigger worker dispatch
25. Doctor reports top candidates by strike count
26. Cross-session notification (`ntm send skillos`) fires when a fresh sd-* lands
27. Worker callbacks lacking sd-* on >2hr tasks flag a doctor warning

## Why this matches "enterprise reporting"

| Joshua's framing | This design |
|---|---|
| "every worker across the fleet should know when they find a skill" | Every dispatch packet includes skill-discovery duty; protocol enum has 7 discovery kinds |
| "log it in agentmail" | Each candidate gets an agent-mail thread; sessions discovering it auto-join |
| "ntm send to skillos worker or coordinator" | sd-* row write triggers `ntm send skillos --pane=<orch>` notification |
| "whole ecosystem as part of our enterprise" | Single global skill-discoveries.jsonl + team-roster.jsonl + team-pulse.jsonl = fleet observatory |
| "proper reporting / logging across entire system" | All append-only JSONL with structured schema; doctor surfaces aggregates; skillos acts as HQ coordinator |

## Composition with Lane A + A.2

```
~/.local/state/flywheel/
├── session-topology.jsonl        ← Lane A: per-session pane registry
├── team-roster.jsonl             ← Lane A.2: fleet-wide who-is-who
├── team-pulse.jsonl              ← Lane A.2: 5min heartbeats
└── skill-discoveries.jsonl       ← Lane A.3: every-worker pattern reports
```

Plus existing files (no change):
```
├── fuckup-log.jsonl              (existing — global trauma signals)
├── substrate-registry.jsonl      (existing — long-running processes)
└── flywheel-loop/
    └── last_tick_<session>.json  (existing — per-session tick receipts)
```

This is the four-pillar fleet observatory:
- **Topology** — where panes live per session
- **Roster** — what each session is and what it's doing
- **Pulse** — is each session alive
- **Discoveries** — what is the fleet learning

Plus the existing two:
- **Fuckups** — what is the fleet failing at
- **Substrate** — what long-running processes back the fleet

## Estimate (delta on top of Lane A + A.2)

- skill-discoveries.jsonl format: shipped here
- worker dispatch template addition (1 paragraph): trivial
- skillos coordinator tick logic (~150 LOC bash + jq): 2-3 hours
- Cross-session notify hook on sd-* write: ~30 LOC
- Agent Mail thread auto-create per candidate: depends on agent-mail API surface, ~1-2 hours
- Doctor section: ~30 LOC
- Total delta: 4-6 hours ship by skillos worker (since skillos is the consumer it should own this)

## Out of scope (file as separate beads)

- Skill regression detection ("did promoting X cause Y to fail") — separate observability layer
- Cross-fleet skill recommendation engine ("session Z would benefit from skill A you wrote") — v2
- Discovery quality scoring (some discoveries are noise) — needs supervised labeling
