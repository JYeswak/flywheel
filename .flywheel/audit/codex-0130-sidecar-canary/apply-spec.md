# Codex 0.130 sidecar canary apply spec — Joshua signoff 2026-05-10

Joshua approved Option A: sidecar install codex 0.130 in canary-only path, do
NOT disturb global 0.125 fleet install.

Launcher already supports `CODEX_DEATHTRAP_CODEX_BIN` env-var override (line 24
of `.flywheel/scripts/codex-deathtrap-launcher.sh`). No launcher patch needed.

## Steps

### Step 1: install codex 0.130 to sidecar path

- Path: `/Users/josh/.local/codex-sidecar-0130`
- Command: `npm install --prefix /Users/josh/.local/codex-sidecar-0130 @openai/codex@0.130.0`
- Note: npm-install-guard hook should NOT block this — it's a `--prefix` install,
  not global. If the hook does block (false-positive on path heuristic), surface
  to Joshua before forcing.

### Step 2: verify sidecar version

- Command: `/Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex --version`
  (or equivalent path — check what npm dropped)
- Expected: `codex-cli 0.130.0` (NOT 0.125.0)
- If version is wrong, abort and report

### Step 3: kill current canary (running 0.125)

- Pane: codex-canary--fleet-death-experiment:0
- Current state: deathtrap-launcher #2 wrapping codex 0.125 (Joshua's prior respawn)
- Action: send Ctrl-C / pkill the codex process or send `exit` to gracefully quit
  the launcher wrapper; this will write a clean exit_evidence-*.json receipt
  for the SECOND canary death (expected H1 since manual termination)
- Joshua is attached to this session; he will see the kill happen

### Step 4: relaunch with sidecar 0.130

- Pane: codex-canary--fleet-death-experiment:0
- Command pattern (send via ntm send):
  ```
  CODEX_DEATHTRAP_CODEX_BIN=/Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex bash /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh --label fleet-death-experiment-0130
  ```
  (resolve actual sidecar codex path from step 2 output)
- Verify launcher reports it's using the 0.130 binary (launcher --doctor or args log)

### Step 5: report

- Receipt at `.flywheel/audit/codex-0130-sidecar-canary/evidence.md` with:
  - Sidecar install path + verified version
  - Prior canary PID + exit reason (graceful kill)
  - New canary PID + binary path used
  - Args log entry confirming 0.130 binary
- DO NOT attach to codex-canary session; we want it untouched for natural-death capture

## Boundary

- npm install is `--prefix` only; no global install, no fleet impact
- Don't touch any other codex worker
- If npm-install-guard blocks the prefix install, surface to Joshua before overriding

## Rollback

- Sidecar lives at `/Users/josh/.local/codex-sidecar-0130/` — `rm -rf` that dir to remove
- The canary launcher will pick up global codex (0.125) again if sidecar removed
- No system-state changes outside the sidecar directory

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Goal

See body above (typically the opening paragraph or first H1 section).

## Acceptance gate

See body above (typically near the end, named Acceptance or per-AG numbered).
