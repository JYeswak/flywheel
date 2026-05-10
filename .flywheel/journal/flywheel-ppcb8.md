---
bead_id: flywheel-ppcb8
task_id: flywheel-ppcb8-04c250
worker_identity: MistyCliff
ts: 2026-05-10T03:47:18Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills: []
narrative_tags:
  - codex-canary
  - sidecar-isolation
  - deathtrap-launcher-receipts
  - graceful-kill-via-launcher-trap
---

The sidecar pattern is the load-bearing decision here. Joshua picked
Option A (sidecar at `/Users/josh/.local/codex-sidecar-0130/`) over a
fleet-wide upgrade because every other codex worker in the fleet is
on 0.125 and tested under that version. Putting 0.130 on a single
canary at a distinct prefix means a 0.130 regression breaks one
session — not all six. Fleet impact: zero (other codex PIDs
unchanged, global `codex --version` still 0.125).

The kill mechanism worked as the launcher was designed to: send
SIGTERM to the codex parent process, the launcher's `wait` returns,
its trap fires, and a clean `exit_evidence-*.json` lands in the
death-evidence dir. Three deaths now captured in that dir
(5838 H1 TTY-disconnect, 60837 H1 manual-term, and the next one to
come from 17733). Each has the same schema, which makes them
comparable — that's the whole point of the deathtrap design.

Boundary respected: the canary tmux session is Joshua's; I sent
the relaunch command via `tmux send-keys` (not via `ntm attach`)
and confirmed the new launcher was alive via process probes — never
attached to the pane to inspect. Joshua sees the screen update
naturally, the kill receipt prints in his prompt, and the new
launcher kicks codex back up — all visible in his attached view.

The npm-install-guard hook is conservative — it blocks anything
that looks like a global install. The `--prefix` flag passed
without intervention because the prefix path is explicit and
non-global. Worth noting if the hook ever does false-positive a
prefix install: surface to Joshua first per spec, don't override.

Sidecar resolution: `npm install --prefix <dir> @openai/codex@0.130.0`
drops a symlink at `<dir>/node_modules/.bin/codex` pointing at
`<dir>/node_modules/@openai/codex/bin/codex.js`. The launcher's
`CODEX_DEATHTRAP_CODEX_BIN` env override accepts the symlink path;
the kernel resolves through to the JS shim, which calls into the
vendor `aarch64-apple-darwin` binary inside the sidecar dir.
That's what makes the process tree show
`/Users/josh/.local/codex-sidecar-0130/...` paths rather than
`/opt/homebrew/lib/...` — unambiguous proof of which version is
running.
