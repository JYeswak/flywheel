# flywheel-nsjse Compliance Pack

Task: `flywheel-nsjse-6eceea`
Bead: `flywheel-nsjse`
Decision: BLOCKED (joshua-pane-selection + organic-death-event required)
Compliance score: 760/1000

## Finding

Phase 2 of the flywheel-delp fleet-death RCA cannot complete autonomously
inside one worker-tick:

1. **Joshua-class boundary** — the bead body explicitly says "Joshua decides
   which worker to instrument" and "no auto-spawn of orchestrator panes."
   A worker on flywheel:0.2 has no authority to respawn a peer pane on
   another session.
2. **Organic death event required** — Step 4 says "When the worker dies
   clean to bash, read the latest exit_evidence-PID-TS.json receipt." A
   worker-tick is bounded; we cannot wait minutes-to-hours for a death
   event organically to occur. The 3 known recurrences (flywheel:3,
   flywheel:4, clutterfreespaces:1) all happened in the last RCA cycle;
   the next death is fundamentally unschedulable.
3. **No prior capture exists** — `~/.local/state/flywheel/codex-death-evidence/`
   does not exist. There is no past `exit_evidence-PID-TS.json` to
   classify against the H1/H2/H3 hypothesis matrix.

The wrapper itself is shipped and healthy. `codex-deathtrap-launcher.sh
--info --json` returns the canonical hypothesis matrix. The blocker is
purely "Joshua picks which pane to instrument + waits for organic death,"
not a substrate gap.

## Substrate Probe (data-decides-not-human-meatpuppet)

Per `feedback_data_decides_not_human_meatpuppet.md`, surfacing a
data-backed pane-selection recommendation alongside the BLOCKED rather
than asking Joshua a meat-puppet question.

Pane survey (run 2026-05-09 ~13:11Z):

| Session | Pane | Agent | State | Eligibility | Recommendation rank |
|---|---|---|---|---|---|
| flywheel | 1-4 | claude/codex | active | EXCLUDED by bead boundary (orchestrator session) | — |
| alpsinsurance | 0-3 | codex/claude | live client | EXCLUDED — protected per `project_alps_quintessential_member` | — |
| skillos | 2 | codex | WAITING | **PRIMARY CANDIDATE** | 1 |
| mobile-eats | 2 | codex | UNKNOWN | secondary candidate | 2 |
| mobile-eats | 3 | codex | UNKNOWN | secondary candidate | 3 |
| clutterfreespaces | — | none | no codex live | not viable (would need fresh launch) | — |
| vrtx | — | none | no codex live | not viable | — |
| recover, test | — | — | low/no activity | not viable | — |

### Why skillos:0.2 is the recommended primary

- Single codex worker on a single-purpose loop (heartbeat every 30 minutes
  per `run-30m-loop.sh`). Respawn through the wrapper is bounded — if
  the experiment misses a death window, the next 30m tick recreates the
  conditions.
- Lower customer impact than mobile-eats (which has active session work)
  and zero customer impact vs ALPS.
- Already in active substrate touch today via flywheel-5eon's
  canonical-driver-gap port; the loop driver is fresh on the bench.
- skillos:1 (claude orch) is the dispatch surface, so the worker death
  event is observable from skillos:1's pane tail — a self-contained
  experiment.

### Why mobile-eats:0.{2,3} is secondary

- Two codex workers means a death of one doesn't halt the session.
- mobile-eats had two of the original three RCA-recurrence panes
  (flywheel-delp body cites `flywheel:3` and `flywheel:4`, but
  mobile-eats workers have similar dispatch shape).
- Slightly higher impact than skillos because mobile-eats has bounded
  customer-relevant work in pipeline.

### Why no clutterfreespaces

The original symptom DID hit `clutterfreespaces:1`, so it would be the
highest-signal target. But there are currently no codex agents on
clutterfreespaces (`ntm activity clutterfreespaces` reports "No agents
found in session"), so instrumentation would require a fresh pane spawn
— larger blast radius than respawning an existing one.

## Blocker Resolution Path

For Joshua: pick one of these three concrete next-steps:

1. **Authorize skillos:0.2 respawn through deathtrap-launcher** (recommended).
   Replay this dispatch with an additional line: `respawn_pane=skillos:0.2`.
2. **Authorize mobile-eats:0.2 or :0.3 instead** — if mobile-eats activity
   is more time-pressed and a death there would be more useful.
3. **Defer until next observed death** — if Joshua wants to wait for the
   next organic death on a non-instrumented pane and instrument the
   replacement at respawn time. Closes this bead with
   `defer_until=next_organic_death_reported`.

When the worker is wrapper-respawned and an organic death captures,
re-dispatch this bead's evidence-classification phase only — that part
is fully autonomous.

## Evidence

```text
$ ls -la ~/.local/state/flywheel/codex-death-evidence/
ls: ~/.local/state/flywheel/codex-death-evidence/: No such file or directory
                                       # no captures yet — wrapper never invoked

$ /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh --info --json
{"schema_version":"codex-deathtrap-launcher.v1","success":true,"mode":"info",
 "hypotheses_supported":["H1_voluntary_turn_complete_exit","H2_mcp_fatal_error","H3_tmux_misreport"],
 "symptom_to_evidence":[...]}        # wrapper healthy, hypothesis matrix loaded

$ ps aux | grep codex | grep -v deathtrap
[10+ codex processes — all bare invocations, none through wrapper]

$ tmux list-sessions; for s in skillos mobile-eats; do ntm activity "$s"; done
[skillos:2 codex WAITING; mobile-eats:2/3 codex UNKNOWN; ALPS excluded; clutterfreespaces no codex]
```

## Acceptance Gate Map

The bead body's six-step gate sequence:

| # | Step | Status |
|---|------|--------|
| 1 | Pick a low-impact session (NOT flywheel orch) | RECOMMENDED skillos:0.2 — pending Joshua approval |
| 2 | Spawn through deathtrap-launcher with --label fleet-death-experiment | BLOCKED: requires #1 |
| 3 | Run normal worker dispatch loops | BLOCKED: requires #2 |
| 4 | Read latest exit_evidence-PID-TS.json on death | BLOCKED: requires #2+#3 + organic death event |
| 5 | Classify per H1/H2/H3 matrix | BLOCKED: requires #4 |
| 6 | File upstream issue OR ship local mitigation | BLOCKED: requires #5 |

did=0/6 (gate 1 partially advanced via recommendation; full execution blocked
on Joshua approval + organic death event)

## L52 / L80 / L120 / L61

- DIDNT: gates 1-6 (deferred — boundary + organic-death blockers)
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: bead-itself-tracks-the-experiment-no-followup-bead-needed
- br_close_executed: not_applicable (BLOCKED keeps bead open)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 8 (boundary respected — no unilateral peer-pane respawn; data
  recommendation backs Joshua's decision rather than asking blindly)
- Sniff: 8 (probe-backed pane survey; eligibility table cites concrete
  reasons + memory cross-refs; classification matrix proven loaded)
- Jeff: 7 (no Jeff-substrate touch yet; the H2 hypothesis would feed
  upstream codex/MCP issue if a capture lands)
- Public: 9 (clean BLOCKED with three concrete next-step options for
  Joshua; evidence preserved so re-dispatch can pick up at gate 1
  decision point)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — wrapper already has full triad
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## L112 Probe (post-resolution)

When the experiment captures a death event, this probe should confirm
the evidence file exists:

```
ls -1 ~/.local/state/flywheel/codex-death-evidence/exit_evidence-*.json | head -1
```
Expected at that point: `literal:exit_evidence-<pid>-<ts>.json`. Until
Joshua authorizes a wrapper-respawn, this probe returns "No such
directory" — which is itself the proof of the BLOCKED state.
