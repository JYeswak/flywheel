# Lane A — Per-Session Orchestrator-Pane Topology Registry

Author: picoz-pane-0 orchestrator (Claude)
Date: 2026-05-01T13:55Z
Joint deep-dive with: flywheel pane 1
Feeds: flywheel-p1 bead `fleet-liveness-in-doctrine-tick`, new bead `session-topology-registry`

## Problem (verified evidence)

Every flywheel command and every script in the substrate assumes **pane 1 is the orchestrator and panes 2+ are workers**. That assumption is wrong for half the fleet:

| Session | Actual orchestrator pane | Actual orchestrator kind |
|---|---|---|
| flywheel | 1 | claude (cc) |
| picoz | 0 | claude (cc) |
| alpsinsurance | 0 (codex) AND 1 (cc) — dual | mixed |
| vrtx | 1 | claude (cc) |
| zesttube | 0 OR 1 (unclear) | claude (cc) |
| skillos | 1 (codex) | codex |

Hardcoded `pane=1` references that break this:
- `~/.claude/commands/flywheel/dispatch.md:80` — "NEVER dispatch to pane 0 (Joshua) or pane 1 (orchestrator self)"
- `~/.claude/commands/flywheel/tick.md:241-242` — "ntm send flywheel --pane=1 'Callback: ...'"
- `~/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh` — has per-session pane mapping HARDCODED in DRIFTED_TARGETS array
- ntm itself: `ntm get-all-session-text` description says "Controller pane (pane 1)" — even our tooling vendor assumes it

When the assumption breaks (alpsinsurance's orchestrator is pane 0, not 1), worker callbacks land at the wrong pane (or in bare zsh as shell commands — exactly what happened in vrtx pane 0 last night with the 70× `M.NN complete: zsh: command not found: M.NN` lines).

## Design — Single-source-of-truth file

`~/.local/state/flywheel/session-topology.jsonl` — append-only, latest-wins-per-session, JSONL for grep+jq tooling.

Schema per row:
```json
{
  "session": "alpsinsurance",
  "orchestrator_pane": 0,
  "orchestrator_kind": "codex",
  "callback_pane": 0,
  "worker_panes": [1, 2, 3],
  "worker_kinds": {"1": "claude", "2": "codex", "3": "claude"},
  "shell_panes": [],
  "human_pane": null,
  "expected_pane_count": 4,
  "effective_at": "2026-05-01T13:55:00Z",
  "registered_by": "josh",
  "notes": "alps runs codex P0 + cc P1 dual-orchestrator pattern"
}
```

**Why JSONL not TOML:** append-only audit trail. When you change layout you append a new row; old rows stay for forensics. `jq` resolves "current" via:
```bash
jq -s 'group_by(.session) | map(max_by(.effective_at))' session-topology.jsonl
```

## Three consumer surfaces

### 1. Pre-flywheel-loop registration gate (BLOCKING)

`flywheel-loop start` (or `/flywheel:loop`) refuses to begin a loop in a session with no topology row. Concretely:

```bash
# In flywheel-loop binary OR a wrapper:
SESSION=$(tmux display-message -p '#S')
TOPO=$(jq -s --arg s "$SESSION" '
  map(select(.session == $s)) | sort_by(.effective_at) | last
' ~/.local/state/flywheel/session-topology.jsonl)

if [ "$TOPO" = "null" ] || [ -z "$TOPO" ]; then
  echo "REFUSING: session '$SESSION' has no topology registration."
  echo "Run: flywheel-loop register-session --session $SESSION --orchestrator-pane N --kind claude|codex --workers '...'"
  exit 1
fi

# Verify the declared orchestrator pane actually has the declared kind running
ORCH_PANE=$(echo "$TOPO" | jq -r '.orchestrator_pane')
ORCH_KIND=$(echo "$TOPO" | jq -r '.orchestrator_kind')
ACTUAL_CMD=$(tmux display-message -p -t "$SESSION:0.$ORCH_PANE" '#{pane_current_command}')

case "$ORCH_KIND" in
  claude) [[ "$ACTUAL_CMD" == 2.* ]] || { echo "REFUSING: session=$SESSION orch_pane=$ORCH_PANE expected claude (2.x.x), got '$ACTUAL_CMD'"; exit 1; } ;;
  codex)  [[ "$ACTUAL_CMD" == "node" ]] || { echo "REFUSING: session=$SESSION orch_pane=$ORCH_PANE expected codex (node), got '$ACTUAL_CMD'"; exit 1; } ;;
esac
```

### 2. Dispatch / callback substitution (in commands & worker-protocol-template)

Replace every literal `--pane=1` in callback strings with topology lookup:
```bash
ORCH_PANE=$(jq -s --arg s "$SESSION" 'map(select(.session == $s)) | sort_by(.effective_at) | last | .callback_pane // .orchestrator_pane' ~/.local/state/flywheel/session-topology.jsonl)
ntm send "$SESSION" --pane="$ORCH_PANE" "DONE task=$TASK_ID ..."
```

Substrate edits required (3 files):
- `~/.claude/commands/flywheel/tick.md:241-242` — replace literal `--pane=1` with topology-lookup snippet
- `~/.claude/commands/flywheel/dispatch.md:80` — change "NEVER dispatch to pane 0 (Joshua) or pane 1 (orchestrator self)" to "NEVER dispatch to the human_pane or orchestrator_pane declared in session-topology.jsonl"
- `~/.claude/commands/flywheel/_shared/dispatch-template.md` — same substitution

### 3. Doctor / autoloop ghost-orchestrator detector (per-tick check)

Add a check to the doctor binary:
```
=== orchestrator pane integrity ===
For each session in topology.jsonl:
  expected: pane $orchestrator_pane runs $orchestrator_kind
  actual:   pane_current_command of $session:0.$orchestrator_pane
  match:    PASS / FAIL (ghost-orchestrator-detected)
```

On FAIL, emit fuckup-log row with class `ghost-orchestrator-detected` and **halt that session's loop until re-registered**. This catches:
- Orchestrator pane dropped to bare zsh (vrtx p0 last night — happened 3x on Apr 27 too per existing incident logs)
- Wrong agent kind launched in orchestrator slot
- Pane index drifted (someone swapped panes)

## Bootstrap — `flywheel-loop register-session`

```
Usage: flywheel-loop register-session [--session NAME] [--orchestrator-pane N]
                                       [--kind claude|codex]
                                       [--workers "2:codex,3:codex,4:claude"]
                                       [--callback-pane N]
                                       [--human-pane N]
                                       [--notes TEXT]

Defaults if --session unset: $(tmux display-message -p '#S')
Defaults if --orchestrator-pane unset: try pane 0, then pane 1, infer kind from pane_current_command, ask if ambiguous.

Validates current state matches declaration before appending row.
Refuses if declared orchestrator pane's pane_current_command doesn't match declared kind.
```

## Initial 8-session bootstrap (proposed)

```jsonl
{"session":"flywheel","orchestrator_pane":1,"orchestrator_kind":"claude","callback_pane":1,"worker_panes":[2,3,4],"worker_kinds":{"2":"codex","3":"codex","4":"codex"},"shell_panes":[0],"human_pane":0,"expected_pane_count":5,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh"}
{"session":"picoz","orchestrator_pane":0,"orchestrator_kind":"claude","callback_pane":0,"worker_panes":[1,2,3],"worker_kinds":{"1":"claude","2":"codex","3":"codex"},"shell_panes":[],"human_pane":null,"expected_pane_count":4,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"P0=orch (Claude), P1=second cc, P2/3=codex workers"}
{"session":"alpsinsurance","orchestrator_pane":0,"orchestrator_kind":"codex","callback_pane":0,"worker_panes":[1,2,3],"worker_kinds":{"1":"claude","2":"codex","3":"claude"},"shell_panes":[],"human_pane":null,"expected_pane_count":4,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"Codex P0 orchestrator pattern"}
{"session":"vrtx","orchestrator_pane":1,"orchestrator_kind":"claude","callback_pane":1,"worker_panes":[2,3,4],"worker_kinds":{"2":"codex","3":"codex","4":"codex"},"shell_panes":[0],"human_pane":0,"expected_pane_count":5,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh"}
{"session":"zesttube","orchestrator_pane":1,"orchestrator_kind":"claude","callback_pane":1,"worker_panes":[2,3],"worker_kinds":{"2":"claude","3":"claude"},"shell_panes":[0],"human_pane":0,"expected_pane_count":4,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"P0 also cc — check if dual"}
{"session":"skillos","orchestrator_pane":1,"orchestrator_kind":"codex","callback_pane":1,"worker_panes":[2],"worker_kinds":{"2":"codex"},"shell_panes":[0],"human_pane":0,"expected_pane_count":3,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"Codex orchestrator. P1 currently HUNG — needs respawn."}
{"session":"clutterfreespaces","orchestrator_pane":0,"orchestrator_kind":"claude","callback_pane":0,"worker_panes":[],"worker_kinds":{},"shell_panes":[1,2],"human_pane":null,"expected_pane_count":3,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"Single-orchestrator session, no workers"}
{"session":"zeststream-v2","orchestrator_pane":null,"orchestrator_kind":null,"callback_pane":null,"worker_panes":[],"worker_kinds":{},"shell_panes":[0,1,2,3],"human_pane":null,"expected_pane_count":4,"effective_at":"2026-05-01T13:55:00Z","registered_by":"josh","notes":"GHOST SESSION — no agents, all bare shells. flywheel:loop must REFUSE here until bootstrapped or torn down."}
```

## Acceptance criteria

1. `~/.local/state/flywheel/session-topology.jsonl` exists with all 8 sessions registered
2. `flywheel-loop register-session --session vrtx --orchestrator-pane 1 --kind claude` works idempotently
3. `flywheel-loop start` in zeststream-v2 EXITS with "session has no topology" error
4. `flywheel-loop start` in flywheel session SUCCEEDS (topology registered)
5. Doctor adds new section `=== orchestrator pane integrity ===` reporting per-session PASS/FAIL
6. The 3 hardcoded `pane=1` references in `tick.md`, `dispatch.md`, `dispatch-template.md` are replaced with topology lookups
7. After substrate edit, dispatching from picoz pane 0 produces a callback that lands AT picoz pane 0 (not pane 1)
8. New ghost-orchestrator-detected fuckup-log class reproduces against zeststream-v2 (all-zsh session)
9. `idle-drifted-panes.sh` reads its DRIFTED_TARGETS from topology.jsonl instead of the hardcoded array

## Risks

- **TOCTTOU**: pane could change between registration check and dispatch. Mitigated by re-checking on every dispatch (cheap: 1 tmux call).
- **Codex hangs at 0% CPU look like alive `node` process** (skillos p1 right now). The `pane_current_command` check passes but the agent is dead. Need a separate liveness probe (CPU+IO+stdout-recency). FILE AS SEPARATE BEAD: `worker-deep-liveness-probe`. Out of scope for topology registry.
- **Sessions Joshua creates ad-hoc** would need explicit registration. Acceptable cost (one-line cmd) and prevents the silent ghost-orchestrator class.

## Estimate

- Registry file + format: shipped in this doc (no code)
- `flywheel-loop register-session` subcommand: ~50 LOC bash + tests
- Doctor section: ~20 LOC
- Substrate edits (3 files): ~10 lines total
- Initial 8-session bootstrap: 1 command
- Total: 1-2 hour ship by one worker

## Out of scope (file as separate beads)

- Worker deep-liveness probe (CPU+stdout-age) — distinct from topology
- ntm upstream patch to drop "Controller pane (pane 1)" assumption
- session-topology-driven autoloop targeting (which sessions get scanned)
