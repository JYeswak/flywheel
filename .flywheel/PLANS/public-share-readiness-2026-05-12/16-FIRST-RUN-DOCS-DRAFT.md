# First-Run Docs Draft

Created: 2026-05-12T21:33Z
Agent: TopazMeadow
Primary downstream bead: B12.0 / `flywheel-uwuxr`
Status: draft content, not `docs/getting-started/first-run.md`

## Purpose

B12.0 needs a public tutorial that a new operator can follow without knowing
Joshua, ZestStream's private fleet, or the pane history that produced Flywheel.
This draft gives the eventual `docs/getting-started/first-run.md` page a stable
shape while the actual docs path remains blocked by upstream public-release
beads.

This page is a tutorial, not reference. It should get the reader from first
checkout to one visible loop state and one credible next action.

## Source Basis

- `CHARTER.md` public promise and publishability bar.
- `09-SUBSTRATE-PREFLIGHT-INVENTORY.md` dependency tiers.
- `10-HARNESS-SUPPORT-MATRIX.md` support labels.
- `11-FIRST-RUN-JOURNEY-SPEC.md` journey promise and receipt schema.
- `14-PREFLIGHT-IMPLEMENTATION-SPEC.md` preflight command and mode resolver.
- `15-JOURNEY-SMOKE-MATRIX-SPEC.md` public copy gate.
- `documentation-website-for-software-project` skill: orient first, tutorial
  flow, mental model, concrete commands, pitfalls, and cross-links.

## Draft Page

# First Run

Flywheel helps an AI-assisted repo keep its work loop visible. The first run is
not complete when a package installs. It is complete when your repo has a local
Flywheel state, the doctor can explain whether it is safe to proceed, and you
can see the next useful action.

This guide is for a solo developer, technical lead, or SMB technical operator
trying Flywheel in one repo. Multi-pane orchestration can come later.

## What You Will Prove

By the end, you should have a receipt that shows:

1. preflight ran and chose full, reduced, blocked, or docs-only mode;
2. Flywheel initialized repo-local state without copying private ZestStream
   files;
3. doctor and tick produced stable JSON;
4. dispatch ran through a real harness or reduced-mode simulator;
5. closeout validated;
6. inspection showed the next action.

The first value is an inspectable loop state and one credible next action.

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

If you are reading this inside a release tarball, start at the extracted
directory instead.

## 2. Run Preflight

```bash
scripts/preflight.sh --json > preflight.json
cat preflight.json | jq '{mode, exit_code, summary, reduced_mode, next_action}'
```

Expected modes:

| Mode | Meaning |
|---|---|
| `full` | Required and full-mode substrate are present. |
| `reduced` | Required basics are present, but one or more full-mode tools are missing. |
| `blocked` | A required dependency is missing or misconfigured. |
| `docs-only` | You can read and inspect, but cannot run the first loop yet. |

If the mode is `blocked`, install the missing required dependencies first. If
the mode is `reduced`, continue; the reduced path is supposed to work.

## 3. Choose A Harness

Flywheel reports harness support from evidence, not optimism.

| Lane | First-run stance |
|---|---|
| Claude Code | first supported target after journey smoke proves it |
| Codex CLI | first supported target after journey smoke proves it |
| Gemini CLI | compatibility target until journey smoke proves it |
| OpenClaw | compatibility target until daemon/gateway smoke proves it |
| Reduced local mode | required fallback path |

Run the matrix before trusting public copy:

```bash
scripts/journey-smoke.sh --matrix claude,codex,gemini,openclaw,reduced --dry-run --json \
  > journey-matrix.json
cat journey-matrix.json | jq '.public_copy_gate'
```

Use a lane only when its row is `runtime_proven`, or when the row clearly names
an auth/account blocker and the docs say so.

## 4. Initialize A Target Repo

Use a scratch repo first:

```bash
mkdir -p /tmp/flywheel-first-run-target
cd /tmp/flywheel-first-run-target
git init
```

Then initialize Flywheel from the checked-out source:

```bash
/path/to/flywheel/flywheel init --repo "$PWD" --json > init.json
cat init.json | jq '{status, created_paths, private_state_scan}'
```

The init step must not copy private state. If the receipt names `.ntm` runtime
state, Agent Mail archives, CASS/JSM/Socraticode local databases, pane scrollback,
or `/Users/josh` paths, stop and treat that as a failed public release gate.

## 5. Run Doctor

```bash
flywheel doctor --repo "$PWD" --json > doctor.json
cat doctor.json | jq '{status, stable_codes, next_action}'
```

Doctor should either say the repo can tick or name stable failure codes. Do not
continue by guessing.

## 6. Run Tick

```bash
flywheel tick --repo "$PWD" --dry-run --json > tick.json
cat tick.json | jq '{status, next_action}'
```

Dry-run tick should choose the next safe action without mutating live harnesses.

## 7. Dispatch Or Simulate

Full mode may dispatch through a real harness. Reduced mode uses the simulator:

```bash
flywheel dispatch --repo "$PWD" --simulate --json > dispatch.json
cat dispatch.json | jq '{status, real_dispatch, callback_contract}'
```

Reduced mode must not claim NTM panes, Agent Mail reservations, shared inboxes,
or cross-session memory.

## 8. Validate Closeout

```bash
flywheel validate-receipt --repo "$PWD" --file .flywheel/last_closeout_receipt.json --json \
  > closeout.json
cat closeout.json | jq '{status, failure_classes}'
```

Closeout is the safety check that turns agent output into accountable work. A
failed closeout is useful evidence; do not hide it.

## 9. Inspect The Next Action

Use the available inspection surface:

```bash
br ready --json
cat .flywheel/last_closeout_receipt.json | jq '.next_action'
cat doctor.json | jq '.next_action'
```

You are done with the first run when at least one surface shows the next action
and the journey receipt explains the mode you are in.

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Treating reduced mode as failure | Reduced mode is the required fallback when full substrate is absent. |
| Claiming Gemini or OpenClaw support before smoke | Keep them compatibility targets until `runtime_proven`. |
| Copying local fleet state into a public repo | Public init must generate state from scratch. |
| Reading pane scrollback as proof | Use NTM/receipt/doctor truth surfaces, not stale raw captures. |
| Skipping closeout | Validated closeout is part of the first value, not an optional polish step. |

## Where To Go Next

- If preflight is blocked, install the missing required dependency and rerun it.
- If reduced mode worked, read the full-mode substrate guide.
- If a harness row is `fixture_blocked`, add auth or account setup and rerun the
  matrix.
- If a row is `source_gap`, treat that lane as a target, not a supported path.
- If the next action is clear, open the relevant Bead or receipt and continue
  from there.

## Non-Completion Note

This draft does not satisfy B12.0. B12.0 remains open until the real
`docs/getting-started/first-run.md` page exists, links to implemented commands,
passes markdown lint, and consumes the preflight plus journey-smoke receipts.
The active public-installability goal remains incomplete.
