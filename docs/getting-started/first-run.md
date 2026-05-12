# First Run

Flywheel helps an AI-assisted repo keep its work loop visible across agents,
sessions, receipts, and follow-up work. The first run is not complete when a
package installs. It is complete when your repo has local Flywheel state, the
doctor can explain whether it is safe to proceed, and you can see the next
useful action.

This guide is for a solo developer, technical lead, or SMB technical operator
trying Flywheel in one repo. Multi-pane orchestration can come later. The first
value is an inspectable loop state and one credible next action.

## Current Release Status

The public first-run journey is still under construction. The preflight command
exists now:

```bash
scripts/preflight.sh --json
```

The remaining end-to-end commands are still release gates until their public
surfaces exist and have journey receipts:

| Surface | Current status |
|---|---|
| `scripts/preflight.sh` | implemented with fixture-backed full, reduced, blocked, and misconfigured modes |
| `flywheel init` | implemented for reduced mode |
| `flywheel doctor` | implemented for reduced mode; full internal loop doctors still separate |
| `flywheel tick --dry-run` | implemented for reduced mode |
| `flywheel dispatch --simulate` | implemented for reduced mode |
| `flywheel validate-receipt` | implemented for reduced-mode simulator receipts |
| `flywheel inspect` | implemented for reduced-mode simulator receipts |
| `scripts/journey-smoke.sh` | planned harness evidence runner |

Do not treat this page as release proof until those rows are implemented and
linked to a passing journey receipt.

## Journey Contract

| Field | First-run contract |
|---|---|
| Persona | A developer or technical operator trying Flywheel in one repo before trusting it with a fleet. |
| First value | An inspectable loop state and one credible next action. |
| Return loop | Re-run preflight after installing substrate, then repeat doctor, tick, dispatch-or-simulate, closeout, and inspection as the repo changes. |
| Guardrail | Every support claim must come from preflight, doctor output, journey smoke, or a validated receipt. |

## What You Will Prove

By the end of the public first-run journey, you should have a receipt that
shows:

1. preflight ran and chose full, reduced, blocked, or docs-only mode;
2. Flywheel initialized repo-local state without copying private fleet files;
3. doctor and tick produced stable JSON;
4. dispatch ran through a real harness or reduced-mode simulator;
5. closeout validated;
6. inspection showed the next action.

## Mental Model

```text
preflight
  -> install or detect substrate
  -> init repo-local Flywheel state
  -> doctor
  -> tick
  -> dispatch or simulate
  -> validated closeout
  -> inspect next action
```

Full mode uses the Dicklesworthstone-derived substrate: NTM, Beads, Agent Mail,
DCG, CASS-style memory, Socraticode, and supported agent harnesses where
available. Reduced mode teaches the same loop shape without multi-agent
coordination, shared inboxes, or cross-session memory.

## 1. Clone Or Open The Repo

```bash
git clone https://github.com/JYeswak/flywheel.git
cd flywheel
```

If you are reading this inside a release tarball, start in the extracted
directory instead.

## 2. Run Preflight

```bash
scripts/preflight.sh --json > preflight.json
jq '{mode, exit_code, summary, reduced_mode, next_action}' preflight.json
```

Expected modes:

| Mode | Meaning |
|---|---|
| `full` | Required and full-mode substrate are present. |
| `reduced` | Required basics are present, but one or more full-mode tools are missing. |
| `blocked` | A required dependency is missing or misconfigured. |
| `docs-only` | You can read and inspect, but cannot run the first loop yet. |

If the mode is `blocked`, install the missing required dependencies first. If
the mode is `reduced`, continue only through reduced-mode steps. Reduced mode is
supposed to work without claiming full multi-agent coordination.

Fixture examples:

```bash
scripts/preflight.sh --fixture fixtures/preflight/existing.json --json
scripts/preflight.sh --fixture fixtures/preflight/partial.json --json
scripts/preflight.sh --fixture fixtures/preflight/fresh.json --json
scripts/preflight.sh doctor --json
```

## 3. Choose A Harness

Flywheel reports harness support from evidence, not optimism.

| Lane | First-run stance |
|---|---|
| Claude Code | first supported target after journey smoke proves it |
| Codex CLI | first supported target after journey smoke proves it |
| Gemini CLI | compatibility target until journey smoke proves it |
| OpenClaw | compatibility target until daemon or gateway smoke proves it |
| Reduced local mode | required fallback path |

The planned journey-smoke command will gate public copy:

```bash
scripts/journey-smoke.sh --matrix claude,codex,gemini,openclaw,reduced --dry-run --json
```

Until that command exists and reports a lane as `runtime_proven`, keep Gemini
and OpenClaw as compatibility targets and keep Claude/Codex support tied to
explicit journey evidence.

## 4. Initialize A Target Repo

Use a scratch repo first:

```bash
mkdir -p /tmp/flywheel-first-run-target
cd /tmp/flywheel-first-run-target
git init
```

```bash
/path/to/flywheel/flywheel init --repo "$PWD" --json > init.json
jq '{status, created_paths, private_state_scan}' init.json
```

The init step must not copy private state. If the receipt names runtime pane
state, Agent Mail archives, local memory databases, pane scrollback, or private
home-directory paths, stop and treat that as a failed public release gate.

## 5. Run Doctor

```bash
flywheel doctor --repo "$PWD" --json > doctor.json
jq '{status, stable_codes, next_action}' doctor.json
```

Doctor should either say the repo can tick or name stable failure codes. Do not
continue by guessing.

## 6. Run Tick

```bash
flywheel tick --repo "$PWD" --dry-run --json > tick.json
jq '{status, next_action}' tick.json
```

Dry-run tick should choose the next safe action without mutating live harnesses.

## 7. Dispatch Or Simulate

Full mode may dispatch through a real harness. Reduced mode uses the simulator.

```bash
flywheel dispatch --repo "$PWD" --simulate --json > dispatch.json
jq '{status, real_dispatch, callback_contract}' dispatch.json
```

Reduced mode must not claim NTM panes, Agent Mail reservations, shared inboxes,
or cross-session memory.

## 8. Validate Closeout

```bash
flywheel validate-receipt --repo "$PWD" --file .flywheel/last_closeout_receipt.json --json \
  > closeout.json
jq '{status, failure_classes}' closeout.json
```

Closeout is the safety check that turns agent output into accountable work. A
failed closeout is useful evidence; do not hide it.

## 9. Inspect The Next Action

Use the available inspection surface:

```bash
br ready --json
jq '.next_action' .flywheel/last_closeout_receipt.json
jq '.next_action' doctor.json
```

You are done with the first run when at least one surface shows the next action
and the journey receipt explains the mode you are in.

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Treating reduced mode as failure | Reduced mode is the required fallback when full substrate is absent. |
| Claiming Gemini or OpenClaw support before smoke | Keep them compatibility targets until `runtime_proven`. |
| Copying local fleet state into a public repo | Public init must generate state from scratch. |
| Reading pane scrollback as proof | Use NTM, receipt, and doctor truth surfaces, not stale raw captures. |
| Skipping closeout | Validated closeout is part of the first value, not an optional polish step. |

## Where To Go Next

- If preflight is blocked, install the missing required dependency and rerun it.
- If reduced mode worked, continue only through implemented reduced-mode
  commands.
- If a harness row is fixture-blocked, add auth or account setup and rerun the
  matrix after the journey-smoke runner exists.
- If a row is source-gap, treat that lane as a target, not a supported path.
- If the next action is clear, open the relevant Bead or receipt and continue
  from there.
