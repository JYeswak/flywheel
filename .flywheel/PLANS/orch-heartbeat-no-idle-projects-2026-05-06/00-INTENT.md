# Orch Heartbeat No Idle Projects - Intent

Plan slug: `orch-heartbeat-no-idle-projects-2026-05-06`

Task: `/flywheel:plan orch-heartbeat-cron-no-idle-projects --through=audit`

Scope: plan-space only through Phase 3 audit. No code, script, plist, hook, or
LaunchAgent mutations in this dispatch.

Primary empirical input: `/tmp/overnight-velocity-report/SUMMARY.md`.

## Joshua Directive

Joshua's 2026-05-06 directive, as carried by the dispatch:

> this needs to be a jeff/donella-meadows-systems-thinking inspired message at
> each watcher cron loop that does not allow us to go stale - if we're reading
> logs that all agents are writing to, there should never be staleness.

## Empirical Context

The overnight velocity report covers `2026-05-05T22:00:00Z` to
`2026-05-06T10:27:28Z`.

Observed facts from `/tmp/overnight-velocity-report/SUMMARY.md`:

- `flywheel`: created=0, closed=1, updated=0.
- `skillos`: created=0, closed=0, updated=0.
- `alpsinsurance`: created=0, closed=0, updated=0.
- `mobile-eats`: created=0, closed=0, updated=0.
- Cross-orch ledger rows: 33.
- Fuckup-log rows: 330.
- Top fuckup class: 262 `post-callback-reminder-template-recovery` rows.
- Codex stuck-detector rows: 441.
- Codex stuck-detector subclass histogram in the report showed
  `unknown_stable=171`, `alive=9`, and no detected capacity-halt class.

Interpretation: the monitoring substrate was alive, but the action loop was not.
Rows accumulated, detectors fired, and cross-orch coordination happened, yet
bead velocity across the fleet stayed near zero. The missing layer is not
another detector; it is synthesis plus delivery into the orchestrator pane while
the pane is idle and work exists.

## Meadows Frame

Boundary: flywheel-controlled NTM sessions and their orchestrator panes:
`flywheel`, `skillos`, `alpsinsurance`, `mobile-eats`, and `vrtx`.

Stock: orchestrator attention attached to current next-action context. This
stock decays when panes sit idle, context compacts, or raw logs outpace synthesis.

Inflow: heartbeat prose that summarizes current ledgers and names concrete next
actions.

Outflow: dispatches, fix beads, validation receipts, and peer-orch coordination
rows that move work out of idle state.

Broken loop: scripts and ledgers emit observations, but no standard composer
turns them into a prompt delivered to the idle orchestrator. The result is
observer-only automation.

Leverage point: Donella Meadows #6 information flows, backed by #5 rules for
delivery/idempotency contracts and #4 self-organization once new source adapters
can be added without changing the composer core.

Primary Donella sources read:

- `~/.claude/skills/donella-meadows-systems-thinking/references/LEVERAGE-POINTS.md`
- `~/.claude/skills/donella-meadows-systems-thinking/references/STOCKS-AND-FLOWS.md`
- `~/.claude/skills/donella-meadows-systems-thinking/references/FEEDBACK-LOOPS.md`

## Source-A Skills Baseline

Skills-best-practices query: `orchestration heartbeat tick driver agent monitoring fleet observability no idle projects`.

Adopt:

- `agent-monitoring`: heartbeat freshness, task completion, queue age, and
  cascade indicators map directly to orchestrator SLOs.
- `loop-enforcement`: a heartbeat loop needs a non-bypassable decision protocol;
  heartbeat-only ticks are the failure mode.
- `observability-platform`: structured logs/metrics/traces and bounded
  cardinality should shape the heartbeat ledger.
- `uptime-monitoring`: liveness/readiness split maps to pane open versus pane
  ready to receive a prompt.
- `socraticode`: K>=10 survey completed before plan claims.
- `jeff-convergence-audit`: Phase 3 audit must check idempotency,
  founder-bottleneck risk, and cross-session authorization before implementation.

## Socraticode Preflight

Socraticode searches completed: 10.

Indexed chunks observed: 100.

Key local prior art surfaced:

- L101: flywheel owns continuous fleet productivity.
- L57: loop state markers are not drivers.
- L70: no-punt, same-tick chain-forward.
- L71: validate-and-redispatch discipline.
- L91: dispatch delivery is a four-state receipt.
- L115/L117: peer orchestrator recovery permit and monitor boundaries.
- `peer-orch-productivity-watch.sh`: already composes same-tick escalation
  packets for peer sessions.
- `tick-driver-manifest.json`: tick primitives need manifest registration and
  ledger proof.

## Non-Goals

- No implementation in this dispatch.
- No mutation of `.flywheel/scripts/*.sh`.
- No LaunchAgent install or edit.
- No propagation to peer repos.
- No cross-session injection design that bypasses latest topology and permit
  checks.
- No Joshua notification as the primary recovery path.

## Deliverables

- Phase 1 three-lane research: problem-space, ecosystem audit, implementation
  design.
- Phase 2 refinement: two rounds plus canonical `00-PLAN.md`.
- Phase 3 audit: idempotency, founder-bottleneck, and cross-session
  authorization lenses.
- `STATE.json` advanced through audit with `audit_disposition=auto_advance`.
- Additive incident and JSONL closure rows when shared-file reservations clear.
