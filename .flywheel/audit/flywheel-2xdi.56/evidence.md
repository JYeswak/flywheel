# Evidence Pack — flywheel-2xdi.56

**Bead:** flywheel-2xdi.56 — `[gap-wired-but-cold] .claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi (closed gap-hunt-probe substrate)

## Disposition: TRIAGED — hypothesis CONFIRMED as posterior; wire-in follow-on bead filed (`flywheel-8p6fz`)

## META-RULE applied

`feedback_bead_hypothesis_starting_point_not_conclusion.md` (META-RULE 2026-05-11): bead body's hypothesis = Bayesian prior, not posterior; probe before implementing.

Bead body's hypothesis: "wired-but-cold" — script not referenced by recent flywheel jsonl ledgers in last 30d.

Probe result: **HYPOTHESIS CONFIRMED.** Script is genuinely wired-but-cold across all LIVE invocation surfaces, not just the jsonl ledger window the gap-hunt-probe checked.

## Investigation findings

### Script identity + state
- Path: `/Users/josh/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh`
- Size: 196 lines, 7832 bytes
- mtime: 2026-05-06T21:32 (5 days stale)
- Shebang: `#!/usr/bin/env bash`
- Author parent: `flywheel-se3h.7` (closed, "[session-topology-gap] add worker deep-liveness probe")

### Function
Reads from LIVE state files (both actively written by other surfaces):
- `/Users/josh/.local/state/flywheel/session-topology.jsonl` — last mod **TODAY** 2026-05-11T02:20 (actively written; large file 1.4MB)
- `/Users/josh/.local/state/flywheel/pane-work-signal.jsonl` — last mod 2026-05-09 (2 days)

Emits per-pane `deep_liveness_state=alive|hung|unknown` based on stdout recency + pane-work-signal evidence.

Exit codes: `0` all alive, `1` ≥1 hung/unknown, `2` topology missing.

### LIVE caller probe (4 surfaces × 0 callers each)

| Surface | Probe | Result |
|---|---|---|
| Launchd plists | `ls ~/Library/LaunchAgents \| grep worker-deep-liveness` | 0 hits (closest match `com.zeststream.heartbeat-liveness.plist` invokes `heartbeat-liveness-check.py`, NOT this script) |
| Cron | `crontab -l \| grep worker-deep-liveness` | 0 hits |
| Skill SKILL.md / commands | `grep worker-deep-liveness ~/.claude/skills ~/.claude/commands` | 0 hits |
| Executable callers (sh/py/toml) | `grep -r worker-deep-liveness` excluding audit/PLANS/passes | only the script itself |

The 15 historical references found are all in `audit/`, `PLANS/`, `passes/`, or `post-fix-probe-receipt.json` — historical evidence of past invocations, not LIVE callers.

### Functional redundancy check vs `worker-auto-respawn-watchdog.sh`

`.flywheel/scripts/worker-auto-respawn-watchdog.sh` (active, run every 60s via `ai.zeststream.worker-auto-respawn-watchdog.plist`) — does it duplicate the deep-liveness probe?

`grep -nE 'deep[-_]?liveness|stdout[-_]recency|pane[-_]work[-_]signal' worker-auto-respawn-watchdog.sh` → 0 hits.

**Not functionally redundant.** Different concerns:
- **Watchdog:** respawn-decision logic (when to invoke `ntm respawn` on dead/hung panes)
- **Deep-liveness probe:** stdout-recency-based hung-pane classifier (alive|hung|unknown per pane)

The deep-liveness probe could be a complementary signal source for the watchdog's respawn decisions, but they currently don't talk.

### Sister doctrine

Per `feedback_substrate_watchtower_must_be_wired.md` (META-RULE: substrate watchtower MUST be wired, not just documented): **shipping a watchtower script without wiring it is the failure shape.** Parent bead `flywheel-se3h.7` shipped this script claiming it was the watchtower for session-topology hung-pane detection, but the wire-in step was missed.

Per `feedback_loop_state_without_driver.md` (META-RULE: state files without drivers are markers, not engines): the deep-liveness probe reads from `session-topology.jsonl` + `pane-work-signal.jsonl` but there's no driver invoking it on a schedule, so even though the inputs exist, the watchtower never fires.

## Wire-in follow-on bead filed

**`flywheel-8p6fz`** — `[wire-in] worker-deep-liveness-probe.sh shipped but never invoked — wire into orch tick or launchd`

Bead body proposes 4 wire-in options with recommendation:
- **A.** Launchd job (5-min interval, analogous to heartbeat-liveness plist)
- **B.** Orchestrator tick integration (`/flywheel:tick` Step 4n adjacent)
- **C.** **Recommended:** Watchdog integration — make `worker-auto-respawn-watchdog.sh` CALL deep-liveness-probe as pre-respawn-decision signal source (preserves single-orchestration-surface principle)
- **D.** Skill-routed invocation (register in SKILL.md)

Acceptance criteria embedded (AG1-AG4) + boundary note (this is SKILL substrate, separate repo from flywheel; wire-in follows skill-substrate conventions per `project_skillos_separated.md` memory).

## AG receipt

Implicit acceptance from gap-hunt-probe bead format:
- AG1: hypothesis test — DONE (confirmed wired-but-cold posterior via 4-surface LIVE-caller probe)
- AG2: actionable trace — DONE (wire-in bead `flywheel-8p6fz` filed with 4 options + recommendation + acceptance criteria)
- AG3: receipt — DONE (this evidence pack)

did=3/3. didnt=none. gaps=flywheel-8p6fz (the wire-in bead this triage filed).

## Boundary preservation

- Did NOT modify the script (script lives in skill substrate `~/.claude/skills/`, separate repo per `project_skillos_separated.md`)
- Did NOT wire it in (P3 triage scope; wire-in decision deferred to orch via filed follow-on bead)
- Did NOT touch parent bead `flywheel-se3h.7` (already closed; out of scope)

## L107 Reservations released

1 reservation taken (`.flywheel/audit/flywheel-2xdi.56/evidence.md`); released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): CITED + applied (probe before implementing)
- META-RULE substrate-watchtower-must-be-wired: CITED + invoked as basis for wire-in follow-on
- META-RULE loop-state-without-driver: CITED for substrate diagnosis
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 1 gap surfaced → 1 bead filed (`flywheel-8p6fz`)

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | triage-only; no CLI surface authored |
| rust-best-practices | n/a | bash investigation |
| python-best-practices | n/a | bash investigation |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 9 — clean triage with 4-surface LIVE-caller probe + functional-redundancy check
- **Sniff:** 9 — would pass skeptical review (META-RULE applied; hypothesis CONFIRMED as posterior, not assumed)
- **Jeff:** 9 — substrate honesty; surfaced the real gap (wire-in missed) rather than just acknowledging the cold metric
- **Public:** 9 — Three Judges check passes (operator can verify 4-surface probe results; maintainer has clear wire-in lineage in `flywheel-8p6fz`; future worker has 4 wire-in options + recommendation)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| META-RULE 2026-05-11 applied (probe before implement) | 200/200 | 4-surface LIVE-caller probe |
| Hypothesis test outcome documented | 200/200 | confirmed wired-but-cold posterior |
| Functional redundancy check | 150/150 | watchdog vs deep-liveness probe distinction |
| Wire-in follow-on bead filed | 200/200 | `flywheel-8p6fz` with 4 options + recommendation + AG1-AG4 |
| Sister doctrine cited | 100/100 | substrate-watchtower-must-be-wired + loop-state-without-driver |
| Boundary preservation | 100/100 | skill substrate boundary respected; no script edits this tick |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2xdi.56/evidence.md && \
  test -f ~/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh && \
  br show flywheel-8p6fz --json | jq -r '.[0].id' | grep -q '^flywheel-8p6fz$'
```
Expected: rc=0 (evidence pack exists + script still exists + wire-in follow-on bead filed). Timeout 10s.
