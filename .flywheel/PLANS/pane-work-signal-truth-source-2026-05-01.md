---
title: "Pane Work Signal as Codex Truth Source"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Pane Work Signal as Codex Truth Source

Bead: `flywheel-u2x`
Mode: plan-space design only
Date: 2026-05-01
Status: ready for implementation bead

## 1. Trauma Cite

Primary trauma rows:

- `~/.local/state/flywheel/fuckup-log.jsonl:115` — `meat-puppet-pane-state-misread`
  - `ntm health` reported Codex panes idle while `ntm copy flywheel:N -l 30` showed active `Working` state.
  - Direct cost: orchestrator was about to dispatch on top of working panes.
- `~/.local/state/flywheel/fuckup-log.jsonl:111` — `tmux-capture-bypasses-ntm-health`
  - This bead intentionally narrows/inverts that lesson: raw pane capture should not be ad hoc operator behavior, but Codex pane scrollback is currently the only reliable activity signal.
  - Doctrine outcome: use a named helper and receipt fields, not ad hoc raw pane reads.

Rule framing:

- `ntm health` remains required for topology/status and non-Codex panes.
- `pane-work-signal.sh` becomes canonical for Codex pane activity only.
- Direct capture is not a new general operator habit; it is encapsulated behind the flywheel helper.

## 2. Current Surfaces

Existing helper:

- `.flywheel/scripts/pane-work-signal.sh:60-88` samples pane scrollback via `ntm copy`, hashes it, and stores `agent_kind`, `ntm_activity`, `ntm_stage`, and `ntm_idle_s`.
- `.flywheel/scripts/pane-work-signal.sh:99-142` classifies via hash deltas in a trailing window.

Current `/flywheel:tick`:

- `~/.claude/commands/flywheel/tick.md:131-147` Step 3 requires `ntm health` and explicitly says it is the true idle/active status. That is now false for Codex panes.

Current `/flywheel:status`:

- `~/.claude/commands/flywheel/status.md:12-15` delegates pane state to `_shared/pane-state.sh`.
- `~/.claude/commands/flywheel/_shared/pane-state.sh:24-26` already has a display regex that includes `Working`, but it is a presentation helper, not a durable truth ledger and not tied to `ntm health` disagreement logging.

Related bead:

- `flywheel-3bk` (`dynamic-ntm-session-coverage-heartbeat`) replaces static session lists with dynamic `ntm list --json` plus config session paths, and surfaces daemon freshness in `/flywheel:status` and `/flywheel:ntm health`.
- No conflict: `flywheel-3bk` discovers and freshness-checks sessions; `flywheel-u2x` classifies per-pane Codex work state after sessions are known.

## 3. Signal Extraction Logic

Canonical source: pane scrollback foreground/status text plus hash delta.

Production access path must use the helper:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/pane-work-signal.sh "$SESSION" "$PANE" --lines 80
```

Primitive capture equivalent for the parser, not the recommended call site:

```bash
tmux capture-pane -t "${SESSION}:0.${PANE}" -p | tail -12 |
awk 'BEGIN{state="idle"} /Working \(([0-9]+m[[:space:]][0-9]+s|[0-9]+s)/ {state="working"; evidence=$0} END{print state "\t" evidence}'
```

Production-safe parser using NTM output:

```bash
tmp=$(mktemp)
ntm copy "${SESSION}:${PANE}" --last 80 --output "$tmp" >/dev/null 2>&1 || exit 1
tail -12 "$tmp" |
awk 'BEGIN{state="idle"} /Working \(([0-9]+m[[:space:]][0-9]+s|[0-9]+s)/ {state="working"; evidence=$0} END{print state "\t" evidence}'
rm -f "$tmp"
```

Regex:

```text
Working \(([0-9]+m[[:space:]][0-9]+s|[0-9]+s)
```

Why not `tail -3`:

- Tested against current Codex panes.
- `tail -3` returned `idle` for panes that still showed a visible background `Working (...)` line in the last 12 lines.
- Therefore `tail -3` is a false-negative trap. Minimum status window should be `tail -12`; helper capture should keep `--lines 80`.

Validation sample from current fleet:

```text
pane 3 ntm_health: status=error activity=idle stage=idle
pane 3 tail-12 parser: working :: Working (1m 07s ...)

pane 4 ntm_health: status=ok activity=idle stage=idle
pane 4 tail-12 parser: working :: Working (22s ...)

pane 2 ntm_health: status=ok activity=idle stage=idle
pane 2 tail-12 parser: idle
```

Helper v2 should add these fields to each JSONL sample:

```json
{
  "foreground_working_state": "working|idle|unknown",
  "foreground_working_evidence": "Working (1m 07s ...)",
  "truth_source": "pane_work_signal",
  "truth_state": "working|idle|stale|unknown",
  "truth_reason": "foreground_working_line|hash_delta|hash_quiet|no_data|ntm_non_codex"
}
```

Classification order for Codex panes:

1. If foreground regex sees `Working (...)` in last 12 lines: `truth_state=working`.
2. Else if hash changed in trailing 90s window: `truth_state=working`.
3. Else if no sample for >5m: `truth_state=stale`.
4. Else: `truth_state=idle`.

For Claude Code panes (`agent_kind=cc`), keep `ntm health` canonical unless the helper sees explicit visible work text; record helper state as advisory.

## 4. Tick Integration

Patch target: `~/.claude/commands/flywheel/tick.md:131-147`.

Replace the Step 3 semantics with this additive flow:

```markdown
### Step 3: Verify worker pane states before any dispatch

Run `ntm health <session> --json` first. This remains the topology/status source:
pane list, agent kind, process health, errors, and non-Codex activity.

Then, for every pane where `agent_type == "cod"`, run:

`/Users/josh/Developer/flywheel/.flywheel/scripts/pane-work-signal.sh "$SESSION" "$PANE" --lines 80`

Use `pane-work-signal` as the activity truth source for Codex panes. Use
`ntm health` as activity truth for `cc` and `user` panes unless a future bead
promotes those kinds too.

If `ntm health` says idle/error while `pane-work-signal` says working:
- Treat the pane as working; it is not dispatch capacity.
- Log SOFT violation `pane_work_signal_disagrees_with_ntm_health`.
- Include both signals in the tick receipt.

Dispatch capacity is:
- Codex pane: `truth_state == idle`
- Claude Code pane: `ntm activity == idle` and `status == ok`
- User pane: never auto-dispatch unless explicitly allowed by topology role
```

Receipt additions:

```json
{
  "pane_work_signal_sampled": true,
  "pane_work_signal_by_pane": {
    "3": {
      "agent_kind": "cod",
      "ntm_status": "error",
      "ntm_activity": "idle",
      "truth_state": "working",
      "truth_reason": "foreground_working_line"
    }
  },
  "pane_work_signal_disagreements": [
    {"pane": 3, "ntm_activity": "idle", "ntm_status": "error", "truth_state": "working"}
  ],
  "idle_capacity_source": "pane_work_signal_for_codex"
}
```

SOFT violation:

```text
pane_work_signal_disagrees_with_ntm_health
```

Doctor field:

```json
{
  "pane_work_signal": {
    "sampled_panes": 4,
    "codex_truth_source": "pane_work_signal",
    "disagreements": 2,
    "last_disagreement_ts": "..."
  }
}
```

## 5. Status Integration

Patch target: `~/.claude/commands/flywheel/status.md:12-15`.

Current status already calls `_shared/pane-state.sh`. Keep that as the display renderer, but feed it the truth-source state:

1. Run dynamic session selection as today.
2. Run `ntm health "$SESSION" --json` for process/status.
3. For each `agent_type=="cod"` pane, run `pane-work-signal.sh "$SESSION" "$PANE" --lines 80`.
4. Render a `source` column or suffix:
   - `working (pws)` for Codex truth from pane-work-signal
   - `idle (ntm)` for non-Codex truth from ntm health
   - `working (pws≠ntm)` when disagreement exists

Compact table shape:

```text
| # | agent | state | source | ctx | last action |
| 3 | cod   | working | pws≠ntm | ? | Working (1m 07s ...) |
```

This makes `/flywheel:status` show why a pane is unavailable for dispatch even when `ntm health` still says idle.

## 6. Disagreement Protocol

When sources diverge:

```text
if agent_kind == cod
and pane_work_signal.truth_state == working
and (ntm_activity == idle or ntm_status != ok):
  capacity=false
  soft_violation=pane_work_signal_disagrees_with_ntm_health
  followup_class=ntm_codex_false_idle
```

Do not page Joshua. Do not block the tick. The tick should:

- trust pane-work-signal for capacity,
- write the SOFT violation into the receipt,
- append enough evidence for a later ntm-health bead,
- continue dispatching only to true idle capacity.

Escalation threshold:

- `warn`: any disagreement in one tick.
- `error`: same pane disagrees for 3 consecutive ticks or >30 minutes.
- Bead filing candidate: `ntm-health-codex-false-idle-followup` if not already covered.

## 7. Coordination With flywheel-3bk

`flywheel-3bk` owns dynamic session coverage. It should answer:

- Which sessions exist?
- Which sessions are configured/tracked?
- Is the heartbeat fresh?
- Which session paths should status/tick consider?

`flywheel-u2x` owns per-pane activity truth. It should answer:

- For each discovered Codex pane, is it actually working?
- Does the helper disagree with `ntm health`?
- Is this pane dispatch capacity?

Integration point:

```bash
sessions=$(ntm list --json | jq -r '...session names...')
for session in $sessions; do
  ntm health "$session" --json
  # flywheel-u2x applies here, per pane, after flywheel-3bk coverage.
done
```

No overlap: do not put dynamic session discovery into `pane-work-signal.sh`; do not put Codex foreground parsing into `ntm-watcher-heartbeat.sh` except as a caller.

## 8. Rollback Path

Two rollback levers:

```bash
export FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1
touch /Users/josh/Developer/flywheel/.flywheel/disable-pane-work-signal
```

If either is present:

- `/flywheel:tick` falls back to current `ntm health` behavior.
- receipt records `pane_work_signal_disabled=true`.
- `/flywheel:status` omits `pws` source markers.

Rollback must not delete `~/.local/state/flywheel/pane-work-signal.jsonl`; keep it as evidence.

## 9. Implementation Breakdown

1. Update `pane-work-signal.sh` to add foreground `Working (...)` parser fields and fix `--classify` no-data behavior when a fresh sample exists but only one hash is present.
2. Update `/flywheel:tick` Step 3 text and receipt schema.
3. Update `_shared/pane-state.sh` or `/flywheel:status` to display `pws`, `ntm`, and `pws!=ntm` source markers.
4. Add a fixture for Codex false-idle:
   - input: `ntm health` says idle/error;
   - scrollback contains `Working (1m 07s ...)`;
   - expected: capacity false, truth working, SOFT violation emitted.
5. Add a dry-run acceptance check that shows at least one Codex pane classified from pane-work-signal instead of `ntm health`.

## 10. Validation Ladder

- Trauma rows cited: yes, `fuckup-log.jsonl:111` and `:115`.
- Signal extraction tested: yes, tail-12 parser matched current panes 3 and 4; tail-3 failed and is rejected.
- Tick patch concrete: yes, target `tick.md:131-147`.
- Disagreement protocol defined: yes, `pane_work_signal_disagrees_with_ntm_health` plus receipt and doctor fields.
- `flywheel-3bk` read: yes, dynamic session coverage heartbeat; no overlap.
- Rollback path specified: yes, env var and sentinel file.
- Code modifications: none.
- Socraticode: not used.

`ladder_passed=yes`
