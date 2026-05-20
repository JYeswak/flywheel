# Codex /goal-mode Monitor Probe Primitive — Paper Spec v0.1

**Status:** Paper-only, pre-Joshua-ratification
**Owner:** flywheel:1 (dispatch-surface lane)
**Consumer of:** pane-work-signal v0.2 taxonomy (skillos:1 canonical-detector lane)
**Joint-packet input:** YES (feeds skillos joint codesign packet to Joshua)

## Purpose

Provide Layer 2/3/4 runtime enforcement of Joshua's "codex must be racking time on active /goal" rule.

## Surface

`.flywheel/scripts/codex-goal-mode-monitor-probe.sh`

## Inputs

| Flag | Type | Required | Meaning |
|---|---|---|---|
| `--pane` | int | yes | tmux pane index in flywheel session |
| `--dispatch-id` | string | yes | dispatch-log.jsonl row id to monitor |
| `--layer` | enum(2,3,4) | yes | which enforcement layer to invoke |
| `--max-entry-wait-s` | int | no, default 30 | Layer 2 grace window |
| `--persistence-poll-interval-s` | int | no, default 60 | Layer 3 polling cadence |
| `--flap-threshold` | int | no, default 3 | Layer 3 flapping trigger count |
| `--flap-window-s` | int | no, default 300 | Layer 3 flapping window |
| `--respawn-residue-s` | int | no, default 15 | suppress classification during this post-respawn window |
| `--completing-window-s` | int | no, default 5 | suppress Layer 2/3 fires during this callback→Goal-box-clear gap |
| `--json` | flag | no | emit structured output |
| `--dry-run` | flag | no | observe only, don't fire trauma |

## Layer 2 (mode-entry verification)

```
Invocation: post-dispatch (called from /flywheel:dispatch wrapper at +0s)
Wait up to --max-entry-wait-s for pane-work-signal state ∈ {goal-in-progress}
Exclude: respawn-residue window, goal-completing window
Outcome:
  goal-in-progress detected within window → OK (exit 0)
  respawn-residue persists past window → defer (exit 2, caller retries +respawn-residue-s)
  any other state at deadline → FIRE codex-goal-entry-failed trauma (exit 1)
  error-state detected → FIRE codex-goal-mode-error-on-entry (exit 1, sub-class)
```

## Layer 3 (mode-persistence monitoring)

```
Invocation: daemon-loop (called by bridge daemon or launchd, every --persistence-poll-interval-s)
For each in-flight dispatch (dispatch-ts present, callback-ts absent):
  Probe pane-work-signal current state
  Persist state-transition history per dispatch
  If state regresses to {goal-paused, idle-chat, working-non-goal} → FIRE codex-goal-abandoned
    Exception: respawn-residue or goal-completing window suppresses
  If >=--flap-threshold entry↔pause transitions within --flap-window-s → FIRE codex-goal-mode-flapping
  If goal-paused persists >120s without callback or auto-resume → FIRE codex-goal-resume-stuck
```

## Layer 4 (mode-exit alarm)

```
Invocation: on callback row write to dispatch-log.jsonl (bridge daemon hook)
Compare: dispatch's state-transition history vs expected (must have shown goal-in-progress at least once)
Outcome:
  history contains goal-in-progress → OK
  history never showed goal-in-progress, callback received → FIRE codex-goal-mode-bypassed
```

## Trauma envelope (emitted to ~/.flywheel/evidence/codex-goal-mode-trauma.jsonl)

```json
{
  "ts": "2026-05-20T00:30:00Z",
  "trauma_class": "codex-goal-mode-flapping",
  "dispatch_id": "flywheel-c7t6k",
  "pane": 2,
  "session": "flywheel",
  "layer": 3,
  "state_history": [
    {"ts": "...", "state": "goal-in-progress"},
    {"ts": "...", "state": "goal-paused"},
    {"ts": "...", "state": "goal-in-progress"},
    {"ts": "...", "state": "goal-paused"},
    {"ts": "...", "state": "goal-in-progress"}
  ],
  "transitions_count": 5,
  "window_s": 240,
  "remediation_hint": "prompt-structure-review",
  "schema_version": "codex_goal_mode_trauma.v1"
}
```

## Trauma → action mapping

| Class | Default action |
|---|---|
| `codex-goal-entry-failed` | Re-dispatch with prefix-verified packet; if 2nd entry fails → respawn pane |
| `codex-goal-abandoned` | Probe codex error-state; if error → respawn; else `/goal resume` attempt + alert orch |
| `codex-goal-mode-bypassed` | Critical — invalidate callback, halt further dispatches to that pane, alert orch+Joshua |
| `codex-goal-resume-stuck` | `/goal resume` attempt + 30s wait; if still stuck → respawn |
| `codex-goal-mode-flapping` | Halt dispatch + dump state history + prompt-structure review request |

## /flywheel:dispatch integration

```
/flywheel:dispatch wraps the existing ntm send pattern:
1. PreToolUse hook fires (czwpu Layer 1, existing)
2. ntm send fires
3. probe --layer 2 fires in background (30s wait, then either OK or trauma fire)
4. dispatch-log.jsonl row written with monitor-probe-id field
5. Layer 3 daemon picks up the dispatch on its next poll cycle
6. On callback, Layer 4 fires synchronously
```

## Bypass / override hatch

See sibling spec: `.flywheel/specs/codex-goal-mode-bypass-design.md`.

## Open questions for joint codesign

1. Should Layer 3 daemon live in bridge daemon or as separate launchd? (flywheel:1 lean = bridge daemon, single process per session)
2. State-history retention: per-dispatch (drop on callback) or per-session ledger (kept for trauma corpus)? (flywheel:1 lean = both — drop from active monitor on callback, append to trauma corpus on any fire)
3. Respawn-on-trauma policy: auto vs orch-decision? (flywheel:1 lean = `codex-goal-mode-bypassed` and `codex-goal-mode-flapping` are orch-decision; `codex-goal-entry-failed` and `codex-goal-resume-stuck` are auto-retry-then-respawn)
4. Should this monitor extend to claude/CC panes for symmetry? (flywheel:1 lean = NO — Joshua's rule is codex-specific; CC panes have a different runtime model)

— flywheel:1
