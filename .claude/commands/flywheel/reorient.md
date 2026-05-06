---
description: Pause a drifting flywheel project, read mission-moving surfaces, diagnose with Donella Meadows leverage points, log discovered issues, and dispatch an accretive recovery gameplan.
allowed-tools: Bash, Read, Write, Edit, mcp__mcp-agent-mail__summarize_recent
---

# /flywheel:reorient

## Skills First

Source-(a) skills cited before doctrine or net-new design:

- `donella-meadows-systems-thinking`: diagnose stocks, feedback loops, delays, rules, goals, paradigms, and highest available leverage point.
- `reality-check-for-project`: compare actual state against mission and goal instead of relying on completed task count.
- `state-truth-recovery`: name canonical truth layers and verify state with secondary evidence before recovery.
- `incident-response`: treat blackout, limping, and dead-loop states as incidents with timeline, severity, mitigation, and follow-up.
- `agent-orchestration`: manage pause, failure handling, dispatch fanout, callback contracts, and circuit-breaker behavior.
- `agent-mail`: reserve files for any follow-up edits and preserve coordination state across agents.
- `beads-workflow`: convert repeated or structural gaps into durable beads with dependencies.

## Args

`$ARGUMENTS` = optional reason slug or flags:

```
/flywheel:reorient                         # infer reason from current drift
/flywheel:reorient <reason-slug>           # e.g. blackout, stuck-plan, limping-loop
/flywheel:reorient <reason-slug> --dry-run # diagnose and author plan, do not log or dispatch
/flywheel:reorient --status                # show latest reorient receipt
```

If no reason slug is supplied, derive one from the strongest current signal:
`blackout`, `l60-limping`, `callback-gap`, `mission-drift`,
`worker-stall`, `meat-puppet-gate`, or `unknown-drift`.

## Trigger Conditions

Joshua may invoke this manually when:

- "this isn't working"
- "going off kilter"
- "we're stuck"
- blackout or no visible progress exceeds 30 minutes
- `/flywheel:tick` repeatedly emits `IDLE_CLEAN` while work remains
- L60 5-signal health is below 3/5 for more than 30 minutes
- a plan phase converges but the orchestrator asks Joshua for a crisp data-driven decision
- manual form: `/flywheel:reorient <reason-slug>`

Automatic trigger proposal for `/flywheel:tick`:

```markdown
If L60 loop-integrity health is <3/5 for >30min, invoke `/flywheel:reorient l60-limping --auto-triggered` before refill or idle-clean.
```

## Doctrine

- This is a meta-orchestrator recovery command, not normal planning.
- A-D are observation and synthesis phases. Do not respawn panes, kill processes, edit source, close beads, or dispatch workers during A-D.
- E-F are the only mutating phases: issue/fuckup logging, STATE updates, dispatch-log entries, and worker dispatches.
- Never ask Joshua "should I proceed?" between phases.
- Never emit four Joshua-disposes options when the data has converged.
- Proceed on crisp data-driven choices. Surface only taste-level judgment calls.
- No meat-puppet gates: if every credible option ends in the same dispatch, dispatch now.
- Use live truth where pane state matters. Cached pane text is not a second truth source.
- Every issue surfaced becomes a bead, an existing-bead update, a fuckup-log row, or an explicit no-bead reason.

## Phase A: Pause And Snapshot (target <=2 min)

Goal: stop the orchestrator from making further assumptions while preserving all in-flight work.

1. Resolve repo and session:
   ```bash
   REPO="${REPO:-$PWD}"
   SESSION="${SESSION:-$(basename "$REPO")}"
   REASON="${ARGUMENTS%% *}"
   TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```
2. Probe session and pane state using NTM surfaces:
   ```bash
   /Users/josh/.local/bin/ntm list
   /Users/josh/.local/bin/ntm --robot-activity="$SESSION" --activity-type=codex,claude
   /Users/josh/.local/bin/ntm health "$SESSION" --json
   ```
3. Snapshot active dispatches:
   ```bash
   tail -50 "$REPO/.flywheel/dispatch-log.jsonl" 2>/dev/null || true
   ```
4. For each pane classified as active, require a live corroborating signal:
   - recent callback row in `$REPO/.flywheel/dispatch-log.jsonl`
   - scrollback-byte delta via the repo's frozen-pane detector
   - current process identity from a live process probe
5. Write the Phase A observation to `/tmp/flywheel-reorient-<reason>-<ts>-pause.json`.
   Do not append durable project state until Phase E.

## Phase B: Read Mission-Moving Surfaces (target <=5 min)

Read at least four mission-moving surfaces. Required when present:

- `$REPO/.flywheel/MISSION.md`
- `$REPO/.flywheel/GOAL.md`
- `$REPO/.flywheel/STATE.md`
- latest three tick receipts from `$REPO/.flywheel/ticks/*.json` or `~/.local/state/flywheel-loop/last_tick_<project>*.json`
- latest five fuckup-log rows from `~/.local/state/flywheel/fuckup-log.jsonl`
- latest five fuckup processed decisions from `~/.local/state/flywheel/fuckup-processed.jsonl`
- L60 5-signal health: ledger writes, pane state changes, receipt writes, callbacks, fuckup decisions
- last three dispatch-log entries per active session
- Joshua's last five messages from the current conversation context

Command shape:

```bash
PROJECT="$(basename "$REPO")"
sed -n '1,220p' "$REPO/.flywheel/MISSION.md" 2>/dev/null || true
sed -n '1,220p' "$REPO/.flywheel/GOAL.md" 2>/dev/null || true
sed -n '1,260p' "$REPO/.flywheel/STATE.md" 2>/dev/null || true
ls -t "$REPO"/.flywheel/ticks/*.json ~/.local/state/flywheel-loop/last_tick_"$PROJECT"*.json 2>/dev/null | head -3 | xargs -r jq -c '.'
tail -5 ~/.local/state/flywheel/fuckup-log.jsonl 2>/dev/null || true
tail -5 ~/.local/state/flywheel/fuckup-processed.jsonl 2>/dev/null || true
tail -100 "$REPO/.flywheel/dispatch-log.jsonl" 2>/dev/null || true
```

If fewer than four surfaces exist, continue only if the missing surfaces are
explicitly listed in the receipt with `missing_surface=<path>`.

## Phase C: Meadows Diagnosis (target <=10 min)

Use `donella-meadows-systems-thinking` with canonical 1999 leverage point
numbering. Output each finding in this exact shape:

```text
SYSTEM: <repo/session boundary>
STOCK: <accumulating stuck state>
PATTERN: <recurring behavior>
LOOP: <balancing/reinforcing/missing/delayed feedback>
CURRENT_LEVERAGE_POINT: <Meadows # + name>
AVAILABLE_HIGHER_LEVERAGE_POINT: <Meadows # + name>
EVIDENCE: <surface + line/row/path>
INTERVENTION: <small reversible action>
MEASURE: <signal proving improvement>
```

Minimum findings:

- one wrong-goal or meat-puppet-gate check, especially when converged data was
  converted into a Joshua-disposes prompt
- one information-flow check, especially where hidden state prevented action
- one rules or callback-contract check, especially where the system allowed an
  idle loop to look clean

Specifically check for:

- Meadows #3 goals trap: the orchestrator optimizes receipts or politeness while mission value stalls
- Meadows #7 positive feedback runaway: repeated planning or diagnosis without dispatch
- Meadows #6 information-flow block: existing state is not reaching the decision point
- Meadows #5 rule gap: tick, dispatch, or callback contract allows limping state to pass
- Meadows #9 delay: health signal arrives slower than the loop changes

## Phase D: Gameplan Author (target <=10 min)

Author three to five accretive next actions. Each action must include:

- `name`
- `leverage_point`
- `rationale`
- `dispatch_target` as `session:pane` or `local-orchestrator`
- `estimated_time`
- `success_metric`
- `artifact`
- `rollback_or_stop_condition`

End Phase D with exactly one decision line:

```text
DECISION: <dispatch|repair|reap-callbacks|file-beads|pause-for-taste> reason=<one-line>
```

`pause-for-taste` is valid only for paradigm-level ambiguity where the evidence
does not converge. It is invalid for crisp data-driven execution.

## Phase E: Fuckup-Log And Bead Wire-In (target <=2 min)

Skip this phase only with `--dry-run`.

1. Append a durable reorient receipt row:
   ```bash
   mkdir -p ~/.local/state/flywheel
   printf '%s\n' "$REORIENT_JSON" >> ~/.local/state/flywheel/reorient-log.jsonl
   ```
2. For each issue surfaced in Phase C:
   ```bash
   ~/.claude/skills/.flywheel/bin/flywheel-loop fuckup log \
     --class="<trauma-class>" \
     --severity="<low|medium|high|urgent>" \
     --what-happened="<evidence-backed summary>" \
     --evidence="<path-or-row>" \
     --should-become="<bead|skill|tool|incident|none>"
   ```
3. If a class has three or more recent events, recommend:
   ```text
   /flywheel:learn --promote <trauma-class>
   ```
4. For each finding, create or update a bead unless there is an explicit
   `no_bead_reason`.

## Phase F: Dispatch Recovery Gameplan (target <=3 min)

Skip this phase only with `--dry-run` or `DECISION=pause-for-taste`.

1. Reserve files for every worker that will edit repo files via Agent Mail.
2. Render dispatch packets with:
   - skills cited
   - Socraticode survey requirement
   - file reservations
   - owned write scope
   - callback contract
   - `pipeline_slug=reorient-<reason-slug>-<epoch>`
3. Send each dispatch through NTM:
   ```bash
   /Users/josh/.local/bin/ntm send <session> --pane=<pane> --file <dispatch-file> --no-cass-check
   ```
4. Append dispatch rows to `$REPO/.flywheel/dispatch-log.jsonl`.
5. Update `$REPO/.flywheel/STATE.md` with the reorientation pointer when the
   repo's state-lock policy allows it. If locked or unsafe, write the proposed
   STATE addition into the receipt instead.
6. Re-arm `/loop` or `/flywheel:tick` at the cadence justified by the gameplan.

## Success Metrics

- `reorient_pause_to_dispatch_seconds_p95<=900`
- `meat_puppet_gates_emitted_per_reorient=0`
- `mission_surfaces_read_per_reorient>=4`
- `meadows_findings_per_reorient>=3`
- `gameplan_actions_dispatched_per_reorient>=3`
- `fuckup_log_rows_written_per_reorient>=1`
- `l60_health_after_reorient>=3/5 within 2 ticks`

## Output

Print a compact status block:

```text
REORIENT: <reason-slug> status=<done|dry-run|blocked|pause-for-taste>
  Repo: <repo>
  Session: <session>
  Mission surfaces read: <N>
  L60 health: <N>/5 before, <target>/5 target
  Meadows findings: <N>
  Gameplan actions: <N>
  Fuckup rows: <N>
  Dispatches: <N>
  Receipt: <path>
  Decision: <decision line>
```

## Constraints

- READ-only against repo state and worker process state in Phases A-D.
- Mutations happen only in E-F unless `--dry-run`, in which case no durable
  writes are performed.
- No pane respawn, process kill, source edit, bead close, or dispatch before
  Phase F.
- No human escalation without a probe ledger.
- No meat-puppet gates after data convergence.
- Cite skills before Socraticode and external research in every reorientation
  receipt or dispatch packet.
- Use NTM for pane operations.
- Use live truth sources for pane-state decisions.
- Do not modify commands other than this command during reorientation.
