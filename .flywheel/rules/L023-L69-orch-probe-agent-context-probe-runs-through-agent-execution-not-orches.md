## L69 — ORCH-PROBE-AGENT-CONTEXT (probe runs THROUGH agent execution, not orchestrator shell)

---
id: L69
title: ORCH-PROBE-AGENT-CONTEXT
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orchestrator-probe-discipline
---

Probe truth belongs to the runtime that will execute the work. An orchestrator
shell, pane scrollback, launchd script, or short-name `which` result is not proof
that a worker agent can resolve or run the same command from its own execution
context.

**Reason:** ORX1 H1 diagnosis at 2026-05-03T22:08Z found `which dcg` failed in
Codex tool execution even though raw pane/orchestrator probes later showed PATH
parity. The mismatch was real: Codex commands ran through non-interactive login
zsh (`/bin/zsh -lc`), where `.zprofile` had reset PATH. The earlier conclusion
overreached because the probe mixed agent execution context with orchestrator
shell context.

**How to apply:**
- For Claude Code runtime probes, use the Claude Bash tool from the target
  agent/session, because that is the agent execution context.
- For Codex runtime probes, send the probe through the Codex agent and parse its
  callback. Use `ntm send <session> --pane=<n> --no-cass-check "<probe +
  callback instruction>"`, then validate the callback content rather than only
  reading pane shell state.
- For parity probes, record both layers when relevant:
  `agent_context={ok|fail,path,version,smoke}` and
  `orchestrator_shell_context={ok|fail,path,version}`. Any disagreement is
  `context_drift`, not immediate proof that the tool is globally missing.
- Pair this rule with L65: after proving the probe ran in the right execution
  context, still verify resolved identity (`command -v`, `realpath`, semantic
  help/version/smoke), not just command name.
- If the target agent is unresponsive, classify the cell as
  `runtime_unresponsive`; do not silently substitute an orchestrator-shell probe.

**Forbidden outputs:**
- "`<tool>` is missing because `which <tool>` failed in the orchestrator shell"
  without a companion in-agent probe.
- "`<tool>` is available to Codex" based only on pane shell PATH, launchd PATH,
  or `ntm` scrollback.
- Closing a parity or substrate bead on raw shell evidence when the acceptance
  gate names an agent runtime.
- Treating an in-agent probe timeout as a successful raw-shell fallback.

**Evidence:** `/tmp/orx1-h1-vs-h3-diagnosis.md`; bead `flywheel-cnep`;
ORX1 refinement of `flywheel-orx1`; parent doctrine bead `flywheel-1z65`.

**Companion rules:** L65 (CLI identity proof after context proof), L60
(loop integrity requires the right signal source), L67 (truth source must be
live), `flywheel-1z65` (orchestrator validates callbacks), `flywheel-2p25`
(runtime parity epic), and `flywheel-q03g` (parity probe binary).


