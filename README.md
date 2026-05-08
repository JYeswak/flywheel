# Flywheel

> **Mission anchor (locked):** *continuous-orchestrator-uptime-self-sustaining-fleet*

Flywheel is the source repo for Joshua Nowak's agentic coding control plane. It
does not contain product code. It holds the repo-local doctrine, templates,
scripts, audits, tests, and command contracts that keep NTM sessions, Beads,
Agent Mail, Socraticode, flywheel loops, and skill updates coordinated across
ZestStream's active repos.

I build this repo to keep the fleet moving when nobody is watching the panes:
workers dispatched, callbacks reaped, recovery paths installed, evidence
captured, and drift converted into beads before it becomes another lost day.

Treat this README as the first map. Treat `AGENTS.md` as the authority. The
architecture details live in [`ARCHITECTURE.md`](./ARCHITECTURE.md); the
operating workflow lives in [`CONTRIBUTING.md`](./CONTRIBUTING.md). The slash
surface is `/flywheel:README`.

## Quickstart

For the orchestrator:

```bash
/Users/josh/.local/bin/ntm health flywheel
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json
br ready --json
```

For a worker:

```bash
~/.cargo/bin/br show <bead-id>
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json
```

Then read the task packet, reserve owned paths, use Socraticode before edits,
ship with explicit path staging, and callback with the required L120-L128
fields. Receipts beat memory.

## Start Here

Read these in order when you land in this repo:

1. `AGENTS.md` - canonical operating doctrine and L-rules.
2. `.flywheel/MISSION.md` - what this repo owns.
3. `.flywheel/GOAL.md` - current repo-level goal and acceptance criteria.
4. `.flywheel/STATE.md` - current resume state, handoff pointers, and safe next actions.
5. `.beads/issues.jsonl` or `br ready --json` - current task graph.
6. This README - command map and worker workflow.

For live ecosystem state, read `~/.claude/skills/.flywheel/GOAL.md`,
`~/.claude/skills/.flywheel/WORK.md`, `~/.claude/skills/.flywheel/LOOP.md`,
and `~/.claude/skills/.flywheel/STATE.md`.

## New Worker Checklist

Before editing:

1. Run orientation:

   ```bash
   ~/.claude/skills/.flywheel/bin/flywheel-codex-orient
   ```

2. Survey existing substrate with Socraticode for any non-trivial change:

   ```text
   mcp__socraticode__codebase_search projectPath="/Users/josh/Developer/flywheel" query="<domain>" limit=10
   ```

3. Read the matching skill when the task names a domain, especially
   `canonical-cli-scoping`, `beads-workflow`, `agent-mail`, `dcg`, or
   `dicklesworthstone-stack`.

4. Reserve files through Agent Mail before editing:

   ```text
   project_key=/Users/josh/Developer/flywheel
   reserve only the files you will touch
   release on DONE or BLOCKED
   ```

5. Keep Beads repo-local. From this repo, `br where` must resolve to
   `/Users/josh/Developer/flywheel/.beads`.

6. Validate with the smallest relevant command before callback.

7. Callback through `ntm send`, using the callback pane from
   `~/.local/state/flywheel/session-topology.jsonl`.

## Repository Map

| Path | Role |
|---|---|
| `AGENTS.md` | Canonical operating doctrine. This is distributed to repo-local `.flywheel/AGENTS-CANONICAL.md` installs. |
| `README.md` | Worker entrypoint and command map. Keep it current when doctrine or user-facing command behavior changes. |
| `MISSION.md`, `GOAL.md`, `STATE.md` | Root compact docs for repo discovery. |
| `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, `.flywheel/STATE.md` | Locked repo-local mission, goal, and state used by loop doctor checks. |
| `.flywheel/loop.json` | Repo-local loop configuration. Active loop markers are not proof of a driver. |
| `.flywheel/AGENTS-CANONICAL.md` | Installed copy of canonical doctrine for portable loop repos. |
| `.flywheel/PUBLISHABILITY-BAR.md` | Three-judges publishability rubric for README, doctrine, doctor, tests, install, code aesthetic, and demo-ability. |
| `.flywheel/PUBLISHABILITY-AUDIT.md` | Repo-local publishability assessment consumed by the doctor signal. |
| `.flywheel/PLANS/` | Design plans, research briefs, RCA packets, and dispatch architecture notes. |
| `.flywheel/handoffs/` | End-of-session handoffs. Read the latest one when resuming orchestration. |
| `.flywheel/scripts/` | Repo-local helper/probe scripts wired into slash commands or tick steps. |
| `.flywheel/doctrine/` | Doctrine adoption packets and handoff doctrine sources. |
| `.flywheel/dispatch-log.jsonl` | Dispatch record and callback tracking surface. |
| `.flywheel/last_closeout_receipt.json` | Latest repo-local loop closeout receipt. |
| `.beads/issues.jsonl` | Repo-local Beads task graph. |
| `INCIDENTS.md` | Promoted recurring failure classes with evidence and Forever-Rules. |
| `scripts/` | Top-level maintenance scripts. Currently includes source-repo backfill support. |
| `templates/flywheel-install/` | Portable install templates for `flywheel-loop init`. |
| `tests/` | Repo-level regression tests for Beads isolation, data gates, install contracts, and loop behavior. |

There is no top-level `bin/` directory in this checkout. The active flywheel
binary surface lives in `~/.claude/skills/.flywheel/bin/`.

## Key Runtime Surfaces

| Surface | Location | Purpose |
|---|---|---|
| Flywheel binaries | `~/.claude/skills/.flywheel/bin/` | `flywheel-loop`, `flywheel-autoloop`, `flywheel`, doctors, dashboards, sync, verdict, and source-monitor tools. |
| Canonical meta-rule sync | `~/.flywheel/canonical-meta-rules/sync.sh` | Refreshes `META-RULE-CACHE.md` and checks/applies three-surface doctrine convergence. |
| Slash commands | `~/.claude/commands/flywheel/` | Operator commands such as `/flywheel:tick`, `/flywheel:dispatch`, `/flywheel:status`, and `/flywheel:init`. |
| Skills | `~/.claude/skills/` and `~/.codex/skills/` | Reusable operating patterns. Use before inventing workflow. |
| Fleet state | `~/.local/state/flywheel/` | Session topology, dispatch support files, fleet mail tokens, fuckup log, and runtime ledgers. |
| Autoloop state | `~/.local/state/flywheel-autoloop/` | Autoloop receipts, locks, payloads, and negative cache. |
| Agent Mail | MCP `mcp_agent_mail` plus fleet project state | File reservations, inboxes, callback side-channel, and cross-agent coordination. |
| Socraticode | MCP `socraticode` | Codebase semantic search and indexing before implementation. |

## Core Commands

Use absolute paths for flywheel runtime binaries unless a dispatch explicitly
names a wrapper.

| Command | Purpose |
|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel-codex-orient` | Start-of-session delta snapshot for Codex workers. |
| `~/.claude/skills/.flywheel/bin/flywheel deltas --unsurfaced` | Show fresh external/internal deltas not yet surfaced. |
| `~/.claude/skills/.flywheel/bin/flywheel doctor` | Ecosystem doctor across hooks, runtime binaries, skill OS, source registry, proposals, and incidents. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop doctor --strict --repo PATH --json` | Repo-local readiness gate. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop init --repo PATH --json` | Install portable `.flywheel/` docs. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop init --reconcile --repo PATH --json` | Preview or apply migration of older repo-local docs. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop tick --repo PATH --dry-run --json` | Emit one bounded repo-local loop decision. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop validate-receipt --repo PATH --file FILE --json` | Validate a v2 closeout receipt. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop fleet --root /Users/josh/Developer --json` | Scan flywheel-installed repos. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop fuckup log/list/triage/harvest` | Capture and promote recurring failure signals. |
| `~/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target PATH --json` | Verify AGENTS.md, `.flywheel/AGENTS-CANONICAL.md`, and template doctrine convergence. |
| `~/.claude/skills/.flywheel/bin/flywheel-loop state-mine --json` | Mine fleet `STATE.md` files for latent unresolved, stale, recurring, pattern, and orphaned opportunities. |
| `~/.claude/skills/.flywheel/bin/flywheel-readme` | Cross-pane README review CLI with draft/submit/review/reject/pass/signoff plus L61 dual-channel submit/reject transport, canonical doctor/health/repair, validate/audit/why, schemas, and observability. |
| `.flywheel/scripts/daily-report.sh --repo PATH --json` | Generate `.flywheel/reports/daily-YYYY-MM-DD.md` and feed the `daily_report_age_hours` doctor signal. |
| `.flywheel/scripts/bead-quality-mining.sh --repo PATH --json` | Back-mine recently closed beads, verify acceptance-gate artifacts, and create parented audit-gap beads for unverified gates. |
| `.flywheel/scripts/publishability-bar.sh --doctor --json` | Score the repo against the three-judges publishability bar and feed `publishability_bar_score` into `flywheel-loop doctor`. |
| `.flywheel/scripts/zeststream-public-prepublish-hook.sh public <url> --json` | Pre-publish gate for public ZestStream repos; blocks public pushes when brand voice score, banned words, or ungrounded claims fail. |
| `.flywheel/scripts/state-md-miner.sh --json` | Fleet-wide `/flywheel:learn --mine-state` backend with dry-run, apply, doctor, and 5/day/repo auto-bead cap. |
| `~/.claude/skills/.flywheel/bin/flywheel-autoloop` | Scheduled selector/driver for bounded fleet progression. |
| `ntm send/copy/grep/health/save` | Canonical pane I/O. Use `ntm`, not direct multiplexer operations. |
| `br ready/list/show/close` | Canonical Beads surface for repo-local task state. |

Do not use backup binaries such as `flywheel-loop.bak.*` except as explicit
forensics evidence.

## Slash Commands

Primary operator-facing command files live under `~/.claude/commands/flywheel/`.
Use the slash surface when operating from an orchestrator pane and the binary
surface when validating from shell.

| Slash command | Role |
|---|---|
| `/flywheel:status` | Compact fleet/session dashboard. |
| `/flywheel:daily-report` | Daily shipped/learned/Jeff/stuck/next/cross-orch narrative report. |
| `/flywheel:tail` | Read pane scrollback through NTM. |
| `/flywheel:inbox` | Agent Mail inbox and callback digest. |
| `/flywheel:beads` | Repo-scoped Beads view. |
| `/flywheel:learn` | Route failures and doctrine signals to the right substrate. |
| `/flywheel:dispatch` | Send worker work through NTM with callback expectations. |
| `/flywheel:research` | Split research across workers and synthesize findings. |
| `/flywheel:plan` | Run plan-space convergence before implementation. |
| `/flywheel:bead-new` | Create a repo-local Bead through the safe path. |
| `/flywheel:init` | Install or reconcile `.flywheel/` docs. |
| `/flywheel:onboard` | Diagnose a repo against fleet onboarding gates. |
| `/flywheel:loop` | Manage project-level loop markers and drivers. |
| `/flywheel:tick` | Run one orchestrator tick. |
| `/flywheel:ntm` | Pane operations through the canonical transport. |
| `/flywheel:synth` | Digest callbacks, reports, Beads, mail, and git activity. |
| `/flywheel:lock` | Promote draft docs to locked state. |
| `/flywheel:handoff` | End-of-session handoff. |
| `/flywheel:worker-tick` | Worker-side tick discipline when explicitly dispatched. |

## Loop Model

A loop is active only when its driver is verified. State files and receipts are
markers; they are not drivers.

The usual flow is:

1. `flywheel-autoloop` or a repo-specific launchd driver wakes on schedule.
2. The driver writes or selects a prompt and sends it through `ntm send`.
3. The orchestrator runs `/flywheel:tick` or `flywheel-loop tick`.
4. Doctor, STOP, receipt, topology, Beads, Agent Mail, and recent failure signals
   determine the next safe action.
5. Work dispatches include Socraticode survey, file reservation, output path,
   callback contract, and Bead/fuckup receipt requirements.
6. Workers report through NTM callbacks and durable output files.
7. The orchestrator reaps callbacks, updates Beads, captures outcomes, and
   refills idle panes only when the next action is safe.

Repo-local loop work must close with a v2 receipt at
`.flywheel/last_closeout_receipt.json` and validate it:

```bash
~/.claude/skills/.flywheel/bin/flywheel-loop validate-receipt \
  --repo /Users/josh/Developer/flywheel \
  --file /Users/josh/Developer/flywheel/.flywheel/last_closeout_receipt.json \
  --json
```

## Dispatch Contract

Every non-trivial worker dispatch in this repo should include:

| Field | Requirement |
|---|---|
| Bead | A repo-local Bead ID and priority. |
| Socraticode | 3 to 5 required searches, using `/Users/josh/Developer/flywheel` as canonical path. |
| File reservation | Agent Mail reservation for every file that will be edited. |
| Skills | Named skills to consult before work. |
| Skill discovery | Workers append reusable pattern findings to `~/.local/state/flywheel/skill-discoveries.jsonl` and callback with `skill_discoveries=<N> sd_ids=<list|none>`. |
| Output | A durable report path, usually `/tmp/<task>_findings.md` for research or an edited repo file for implementation. |
| Callback | `ntm send flywheel --pane="$CALLBACK_PANE" "Callback: task_id=<id> status=done ..."` |
| Receipts | `socraticode_queries=N`, reservation release, Bead update or `no_bead_reason`, and fuckup rows for blockers. |

Doctor JSON exposes `.fleet_skill_discovery` for the skill-discovery reporting
loop. It reads `~/.local/state/flywheel/skill-discoveries.jsonl`, reports
`last_24h_discoveries`, malformed-row counts, top candidates by sightings, and
pending skillos coordinator actions. It warns when a candidate reaches the
3-sighting skill-builder threshold or when 3 consecutive worker callbacks over
2 hours report `skill_discoveries=0 sd_ids=none` without an explicit legal
no-discovery reason. `doctor-signal-bead-promotion.sh` promotes those warnings
as `[auto-doctor:fleet_skill_discovery]` beads with candidate evidence.

Dispatch-log v2 migration is dry-run first:
`.flywheel/scripts/dispatch-log-backfill-v2.sh --repo "$PWD" --dry-run --json`
prints planned annotations without editing `.flywheel/dispatch-log.jsonl`.
Applied backfills require `--idempotency-key <key>` and write an audit receipt
under `.flywheel/receipts/`.

Rollback controls do not require code edits. Use
`FLYWHEEL_DISPATCH_GATE_DISABLE=callback_contract_required` for one gate,
`FLYWHEEL_DISPATCH_ENFORCE=0` for global emergency rollback,
`~/.local/state/flywheel/dispatch-gates-disabled/<gate>` for fleet-local
sentinels, or `.flywheel/no-enforce-dispatch` for a repo-local temporary
sentinel with a dated reason. Doctor remains active during rollback and reports
`dispatch_contract_violations` / `dispatch_contract`.

Use this callback pane lookup:

```bash
CALLBACK_PANE="$(jq -sr --arg s "flywheel" \
  'map(select(.session == $s)) | sort_by(.effective_at) | last | .callback_pane // .orchestrator_pane // 1' \
  ~/.local/state/flywheel/session-topology.jsonl)"
```

Topology ledger conformance is checked by:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/topology-gap-probe.sh --json
bash /Users/josh/Developer/flywheel/tests/session-topology-ledger.sh
```

The probe validates the append-only
`~/.local/state/flywheel/session-topology.jsonl` ledger, latest-wins semantics,
required row fields, and the original eight-session bootstrap fixture from the
`flywheel-31p` all-in-one implementation.

## Canonical CLI Scoping

When adding or extending any operator-facing CLI, read
`~/.claude/skills/canonical-cli-scoping/SKILL.md` before design or code.

The minimum expected surface for a real CLI is:

- `doctor`, `health`, and `repair`
- `validate`, `audit`, and `why` when state is handled
- `--info`, `--examples`, `quickstart`, `help <topic>`, and `completion <shell>`
- `--json` everywhere
- stable exit codes
- `--dry-run`, `--explain`, idempotency keys, and audit records for mutations
- schemas for machine-readable output
- `metrics`, `logs`, or `trace` for long-running systems

Before claiming a new command name, run `which <name>` and prove there is no
collision or that the existing binary is owned intentionally. For this repo,
prefer extending existing canonical surfaces (`flywheel-loop`, `flywheel`,
`flywheel-autoloop`, `/flywheel:*`) over adding new names.

AGENTS.md L82 makes this mandatory for flywheel CLIs. A CLI is not treated as
real operator substrate until doctor/health/repair, validate/audit/why,
self-documentation, JSON/schema output, canonical exit codes, and mutation
dry-run/idempotency/audit discipline are present or explicitly covered by a gap
bead.

## Load-Bearing Docs

AGENTS.md L81 makes README-grade documentation part of the contract for
load-bearing flywheel artifacts. Binaries, hooks, launchd plists, slash-command
contracts, substrate rows, doctrine, and relied-on scripts need an owned README
with frontmatter, a real `validation_command`, command/reference coverage, side
effects, error modes, and See Also links.

The authoring worker cannot be the final validator. Gate 2 review must happen
from a separate pane using `flywheel-readme` or the cross-pane protocol in
`.flywheel/plans/cross-pane-protocol-2026-05-01/04-XPANE-SYNTHESIS.md`.
Live submit/reject and Joshua-reject signoff require
`FLYWHEEL_README_ALLOW_TRANSPORT=1`; they send through `ntm`, queue a durable
Agent Mail outbox row, and append `.flywheel/dispatch-log.jsonl`, while dry-run
remains no-op.
Repeated README failures follow reject-and-revert: reject the shape, rewrite,
and file the missing validation primitive when the checklist itself is unclear.

## Templates And Install

Portable install templates live in `templates/flywheel-install/`.

| File | Purpose |
|---|---|
| `MISSION.md.tmpl` | Locked mission template. |
| `GOAL.md.tmpl` | Locked goal template. |
| `STATE.md.tmpl` | Locked state template. |
| `loop.json.tmpl` | Repo-local loop config template. |
| `ESCALATION-LADDER.md.tmpl` | Portable escalation ladder. |
| `validate-callback-before-close.sh.tmpl` | Four-lens close validator installed into `.flywheel/scripts/`. |
| `render.sh` | Bash renderer for template substitutions. |
| `schema.json` | Template and frontmatter contract. |
| `tests/test_render.sh` | Render and template-contract smoke test. |

After template edits, run:

```bash
bash /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_render.sh
shasum -a 256 /Users/josh/Developer/flywheel/templates/flywheel-install/*.tmpl
```

Update `templates/flywheel-install/README.md` hashes in the same patch when
template contents change.

## Repo-Local Scripts

`.flywheel/scripts/` contains probe and helper surfaces used by tick steps,
doctors, onboarding, and recovery.

Common current scripts:

| Script | Purpose |
|---|---|
| `flywheel-onboard.sh` | Fleet onboarding doctor/dry-run surface. |
| `topology-gap-probe.sh` | Session topology ledger schema/latest-wins/bootstrap conformance probe for the `flywheel-31p` registry. |
| `pane-work-signal.sh` | Pane work-signal probe. |
| `frozen-pane-detector.sh` | Frozen-pane detection input. |
| `frozen-pane-detector-fleet.sh` | Disabled-by-default launchd wrapper for fleet-wide frozen-pane observation with STOP/FATAL and recovery-budget gates. |
| `recovery-slo-probe.sh` | L99 recovery SLO probe exposing 24h p50/p95 latency, breach count, and green/yellow/red status. |
| `architecture-health-rollup.sh` | L98 architecture-health rollup that writes 24h/7d/30d/90d fleet-perf JSON with trend, cohort, counterfactual, and anti-agent-shaming checks. |
| `fleet-conformance-probe.sh` | L103 fleet conformance observatory: one bounded score per session plus red-session `CONFORMANCE-DRIFT` packet planning. |
| `fleet-process-gap-detector.sh` | L105 process-gap detector: recurring fuckup classes, sticky doctor errors, doctrine drift, stale promotions, audit gaps, identity drift, and watcher holes into top-3 fix-bead routes. |
| `shared-surface-reservation-check.sh` | L107 append-only cross-pane reservation checker for shared surfaces before `git add`; doctor counts `coordination_collision_count_24h`. |
| `no-silent-darkness-probe.sh` | L60 five-signal health check. |
| `leverage-ceiling-probe.sh` | Meadows leverage constraint probe. |
| `gap-hunt-probe.sh` | Gap discovery and ledger support. |
| `value-gap-probe.sh` | Step 4o paradigm-tier scan for missing high-leverage measurements; files at most one bead per tick. |
| `vc-observability-probe.sh` | Vibe Cockpit observability probe. |
| `mission-lock-age-probe.sh` | Mission-lock age probe. |
| `agent-mail-fd-doctor.sh` | Agent Mail file-descriptor pressure doctor. |
| `agent-mail-restart.sh` | Dry-run-first Agent Mail LaunchAgent restart helper with bootout/bootstrap/kickstart recovery. |
| `mobile-eats-receipt-bridge.sh` | Product receipt to canonical tick-shaped JSON bridge. |
| `validate-callback.py` | Builds B01 validation receipts from worker callback claims before integration; enforces L61 ecosystem-touch callback fields for doctrine-shaped dispatches. |
| `validation-fix-bead.py` | Plans or applies repo-local fix beads for failed validation receipts. |
| `closed-bead-artifact-scan.py` | Detects closed beads whose shipped artifact evidence fails mechanical probes and can reopen them explicitly. |
| `bead-ag-format.py` | Validates canonical `AG<N>:` single-line acceptance gates and flags nested/non-testable bead gates. |
| `br-create-validated.sh` | Validated `br create` wrapper that blocks noncanonical AG format before bead creation. |
| `verify-callback-delivery.sh` | Worker-side callback sender that verifies ntm delivery before clean exit. |
| `validate-callback-before-close.sh` | Four-lens close validator that blocks bead close on evidence or bar failures and can create/reuse a rework bead with `--apply`. |
| `sync-four-lens-validator.sh` | Fleet sync/audit helper that installs the close validator from the flywheel-install template into active flywheel repos. |
| `~/.claude/skills/.flywheel/bin/flywheel-conductor --mvp-gate` | Fleet-conductor MVP/demo readiness gate; surfaces artifacts only on four-lens pass or explicit `pre-bar`, otherwise files/reuses rework and records Joshua-time-saved. |
| `sync-canonical-doctrine.sh` | Canonical doctrine sync helper. |
| `peer-orch-blocker-watch.sh` | L75 cross-orch blocker watcher for stale flywheel-class blockers awaiting `flywheel:1` acknowledgement. |
| `three-q-surface-audit.py` | Audits the surface registry for validated, documented, and surfaced evidence. |
| `jeff-issue-rubric.py` | Scores Jeff issue drafts against the 7-axis pre-posting quality gate. |
| `jeff-binary-version-watchtower.sh` | Hourly tick probe for installed-vs-latest Jeff substrate binaries; auto-files version-drift beads. |
| `headless-browser-probe.sh` | Detects orphaned `agent-browser-chrome` processes without touching the primary Chrome profile. |
| `headless-browser-reap.sh` | Dry-run-first reaper for stale or over-count agent browser processes. |
| `flywheel-loop identity` | Resolves durable Agent Mail identity by session:pane and reports identity registry drift in doctor JSON. |
| `agentmail-registration-broadcast.sh` | Token-safe broadcaster for live Agent Mail `needs_registration` rows; doctor exposes `agentmail_pending_registration_broadcasts_count`. |
| `fleet-comms-health-probe.sh` | L104 fleet comms observatory: scores token freshness, cross-orch packet age, unread escalations, pending productivity escalations, identity liveness, and multi-frame liveness classifier agreement. |

Run script-specific `--help`, `--info`, `--schema`, and `--examples` where
available before wiring a script into a loop, doctor, or slash command.

Architecture-health rollups are generated with:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/architecture-health-rollup.sh \
  --period all \
  --write \
  --json

jq '.fleet_metrics,.candidate_l_rules,.candidate_probe_additions' \
  /Users/josh/.flywheel/fleet-perf/7d.json

bash /Users/josh/Developer/flywheel/tests/architecture-health-rollup.sh
```

Rollups measure system architecture health, not individual agent performance.
They expose `architecture_health_metric_unpaired_count` and
`agent_shaming_report_detected`; any threshold crossing routes to doctrine,
skills, or probes.

Codex upstream surveillance is a first-class tick input. The daily ingest lives
at `~/.local/bin/codex-watchtower-daily.sh`, the skill substrate lives at
`~/.claude/skills/codex-cli-tracker/`, and `.flywheel/flywheel-loop-tick` Step
4t records `codex_watchtower` in dispatch logs and receipts.

## Validation

Useful checks from this repo:

```bash
~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --strict \
  --repo /Users/josh/Developer/flywheel \
  --json

bash /Users/josh/Developer/flywheel/tests/phase2-audit.sh

bash /Users/josh/Developer/flywheel/tests/flywheel-loop-core.sh

bash /Users/josh/Developer/flywheel/tests/test_install_contract_step10.sh

bash /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_render.sh

bash /Users/josh/Developer/flywheel/tests/validate-callback.sh

bash /Users/josh/Developer/flywheel/tests/validation-fix-bead.sh

bash /Users/josh/Developer/flywheel/tests/closed-bead-artifact-scan.sh

bash /Users/josh/Developer/flywheel/tests/verify-callback-delivery.sh

bash /Users/josh/Developer/flywheel/tests/validate-callback-before-close.sh

bash /Users/josh/Developer/flywheel/tests/fleet-conductor-mvp-gate.sh

bash /Users/josh/Developer/flywheel/tests/sync-four-lens-validator.sh

bash /Users/josh/Developer/flywheel/tests/value-gap-probe.sh

bash /Users/josh/Developer/flywheel/tests/validation-e2e.sh

bash /Users/josh/Developer/flywheel/tests/three-q-surface-audit.sh
```

Callback validation uses:

```bash
~/.claude/skills/.flywheel/bin/flywheel-loop validate-callback \
  --repo /Users/josh/Developer/flywheel \
  --dispatch-id <task-id> \
  --callback-ref <callback-json-or-raw-line> \
  --json
```

The command is read-only unless `--write-receipt` is passed. Written receipts
go under `.flywheel/validation-receipts/` and must validate against
`.flywheel/validation-schema/v1/schema.json` before an INTEGRATE step treats a
worker `DONE` as usable proof.

Failed callback validation can be routed to a fix bead with:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/validation-fix-bead.py \
  --repo /Users/josh/Developer/flywheel \
  --receipt <failed-validation-receipt-json> \
  --parent <source-bead-id> \
  --dry-run \
  --json
```

The helper is dry-run by default and emits the exact `br create --dry-run` or
`br update` payload it would use. Mutating mode requires both `--apply` and
`--idempotency-key`, writes an audit row under
`.flywheel/validation-fix-beads/audit.jsonl`, and verifies `br where` points to
the repo-local `.beads` directory before touching bead state.

Closed beads with shipped artifact claims can be scanned with:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/closed-bead-artifact-scan.py \
  --repo /Users/josh/Developer/flywheel \
  --dry-run \
  --json
```

The scanner extracts typed close-reason refs such as `artifact=`, `schema_path=`,
`executable=`, and `smoke_cmd=`. Missing files, invalid JSON schemas,
non-executable scripts, and failing smoke commands become `reopen_candidate`.
Ambiguous prose-only close reasons stay `unknown` and are not reopened
automatically. Apply mode requires `--apply --idempotency-key`, records a
validation receipt under `.flywheel/validation-reopen/receipts/`, appends an
audit row, and uses repo-local `br reopen` plus a comment.

Worker callback delivery verification uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/verify-callback-delivery.sh \
  --session flywheel \
  --pane 1 \
  --task-id <task-id> \
  --message "DONE <task-id> evidence=<path> callback_delivery_verified=pending" \
  --json
```

The helper sends with `ntm --no-cass-check`, verifies the callback is visible
via `ntm logs` or `ntm copy`, retries idempotently, and writes
`/tmp/<task-id>-callback-failed.md` instead of exiting cleanly after repeated
delivery failures.

Agent-context parity validation uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/agent-context-parity-probe.py \
  --repo /Users/josh/Developer/flywheel \
  --runtime codex \
  --session flywheel \
  --pane <worker-pane> \
  --command <tool> \
  --json

bash /Users/josh/Developer/flywheel/tests/agent-context-parity-probe.sh
```

For Codex, the probe sends through `ntm send` and validates the callback; for
Claude, fixture/live proof must come from the agent Bash context. Raw shell
success plus agent failure is `context_drift`, not a pass.

The validate-and-redispatch discipline is the repo-wide rule for treating
callbacks, close reasons, and changed surfaces as claims until mechanically
validated. Use skill
`/Users/josh/.claude/skills/orchestrator-validation-discipline/SKILL.md` when
you are validating work before summary or integration. Canonical doctrine lives
in AGENTS.md L71, memory lives at
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_validate_redispatch_foundational_discipline.md`,
and the core command surfaces are `validate-callback.py`,
`validation-fix-bead.py`, `closed-bead-artifact-scan.py`, and
`verify-callback-delivery.sh`.

The final validate-and-redispatch smoke harness is:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/validation-e2e-smoke.sh \
  --receipt-dir /tmp/flywheel-validation-e2e \
  --json
```

It emits a `validation-e2e/v1` final receipt tying together the dispatch
validation block, callback validator, fix-bead dry-run, doctor signal,
VALIDATE tick phase, learn routing, L70 chain fixture, runtime parity fixture,
staged rollout modes, and changed-surface ledger.

Validation receipts route into the learn pipeline with:

```bash
~/.claude/skills/.flywheel/bin/flywheel-loop validation-learn \
  --repo /Users/josh/Developer/flywheel \
  --review \
  --json

~/.claude/skills/.flywheel/bin/flywheel-loop validation-learn \
  --repo /Users/josh/Developer/flywheel \
  --receipt <validation-receipt-json> \
  --apply \
  --json
```

The command records exactly-once routing in
`.flywheel/validation-learn-ledger.jsonl`. Failed or unknown receipts enter the
L56 fuckup-log promotion ladder once per dedupe key, positive receipts stay out
of the fuckup log, and `skill_extend` routes become skill candidates.

STATE.md opportunity mining uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/state-md-miner.sh --json
/Users/josh/Developer/flywheel/.flywheel/scripts/state-md-miner.sh --apply --json
```

It scans fleet `.flywheel/STATE.md` and root `STATE.md` files for unresolved,
stale, recurring, pattern, and orphaned work. Each discovery gets a durable
decision: new bead, existing bead reference, or explicit `no_bead_reason`.
Doctor and daily-report surfaces expose `state_md_unmined_count`,
`state_md_last_run_age_hours`, and class counts.

Orchestrator Joshua-input capture parity uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/orch-capture-parity-probe.py \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.orchs_with_capture_gap_count, .orch_capture_parity.rows'

bash /Users/josh/Developer/flywheel/tests/orch-capture-parity-probe.sh
```

The probe compares canonical session topology with
`~/.local/state/flywheel/josh-requests.jsonl`. A Claude hook row, a canonical
Codex capture row, or Codex agent-context callback evidence can satisfy
capture; raw pane scrollback alone is always a gap. B13 only defines the
rule/signal contract. `flywheel-xap2` owns the concrete Codex capture mechanism
track.

Three-Q surface registry auditing uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/three-q-surface-audit.py \
  --repo /Users/josh/Developer/flywheel \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/three-q-surface-audit.py \
  --repo /Users/josh/Developer/flywheel \
  --strict \
  --write-receipt \
  --json

bash /Users/josh/Developer/flywheel/tests/three-q-surface-audit.sh
```

The registry lives at
`.flywheel/three-q-surface-registry/v1/registry.json`. Each row answers the
umbrella audit questions: validated, documented, and surfaced. Runtime-dependent
rows model Claude and Codex separately, so a Claude-only pass cannot satisfy a
Codex-required surface. Doctor JSON exposes `three_q_unaudited_count`,
`surfaces_unwired_count`, and `.three_q_surface_audit.top_failing_surfaces`.

Storage discipline is a doctor-backed gate for growth-heavy work:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.storage'

bash /Users/josh/Developer/flywheel/tests/storage-probe.sh

bash /Users/josh/Developer/flywheel/tests/storage-override.sh
```

Doctor JSON exposes `.storage` with disk, Developer, local-state, stale backup,
Qdrant, and `/tmp` dispatch-artifact metrics. The doctor fails when
`disk_free_pct < 10` or `stale_baks_count > 5`; `<5%` free triggers the
`~/.local/bin/notify --priority 1 "STORAGE LOW"` path. Daily Jeff ingest runs
the storage preflight before diff pulls or mirror clones and aborts below 10%.
Policy and dry-run pruning live in `.flywheel/STORAGE.md`.

Joshua-disposed storage overrides use
`.flywheel/validation-schema/v1/storage-override.schema.json` and receipts under
`~/.local/state/flywheel/storage-overrides/`. `flywheel-loop doctor` honors
`--storage-min-free-pct`, `FLYWHEEL_STORAGE_MIN_FREE_PCT`, and active
`storage-override/v1` receipts, then exposes `storage_override_active_count`
and `storage_override_expiring_in_min`. When storage recovers above the base
threshold, doctor appends a `STORAGE-CLEARED` event and reverts to the base gate.

Jeff corpus ingestion is maintained as an accretive storage surface:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/regenerate-dicklesworthstone-sources.sh \
  --apply \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-intel-scheduled-runner.sh \
  --mode doctor \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-corpus-freeze-baseline.sh \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-corpus-diff-watcher.sh \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-corpus-delta-reindex.sh \
  --dry-run \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-corpus-compact.sh \
  --dry-run \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.jeff_corpus_storage_health, .jeff_corpus_v1_total_mb'

bash /Users/josh/Developer/flywheel/tests/jeff-corpus-accretive.sh
bash /Users/josh/Developer/flywheel/tests/regenerate-dicklesworthstone-sources.sh
bash /Users/josh/Developer/flywheel/tests/jeff-intel-schedule.sh
bash /Users/josh/Developer/flywheel/tests/jeff-intel-network.sh
```

The baseline manifest lives at `.flywheel/jeff-corpus/v1/manifest.json`.
Daily 03:00Z diff watching writes `.flywheel/jeff-corpus/pending-reindex.jsonl`;
delta indexing writes append-only v2 rows; Sunday 04:00Z compaction rolls v1+v2
into v3. Doctor JSON exposes `jeff_corpus_v1_total_mb` and
`jeff_corpus_storage_health` (`GREEN|YELLOW|RED`), and RED blocks new ingestion
until compaction runs.
`regenerate-dicklesworthstone-sources.sh` is the documented pre-ingest runner
for `~/.claude/skills/dicklesworthstone-stack/data/sources.txt`: run it before
daily Jeff ingest so live GitHub repo feeds use exact-case names, real default
branches, and archived-repo exclusion while preserving doctrine/X sections.
The canonical operator surface is `.flywheel/scripts/jeff-intel-network.sh`
and `/flywheel:jeff-intel`; `daily-jeff-ingest.sh` and
`jeff-intel-scheduled-runner.sh` are implementation helpers behind that surface.
Active launchd labels are `ai.zeststream.flywheel-daily-jeff-ingest` for the
daily GitHub/git, website/RSS, X, JSM, and mirror ingest, and
`ai.zeststream.flywheel-jeff-x-poll` for the hourly @doodlestein X poll. Both
write receipts under `~/.local/state/jeff-intel/`; daily ingest also writes
`~/.local/state/flywheel/daily-jeff-ingest.jsonl`.

Daily reporting is a doctor-backed learning surface:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/daily-report.sh \
  --repo /Users/josh/Developer/flywheel \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.daily_report_age_hours, .daily_report.latest_report'

bash /Users/josh/Developer/flywheel/tests/daily-report.sh
```

The report lands at `.flywheel/reports/daily-YYYY-MM-DD.md`. Doctor fails when
the latest report is older than 36 hours, and `/flywheel:status` references the
latest report path.

Headless browser leak detection is a doctor-backed gate for Chrome singleton
lock incidents:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/headless-browser-probe.sh \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/headless-browser-reap.sh \
  --dry-run \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.agent_browser_leak'

bash /Users/josh/Developer/flywheel/tests/headless-browser-probe.sh
```

Doctor JSON exposes `.agent_browser_leak` and
`headless_agent_browser_count`. It fails when more than five
`agent-browser-chrome` processes exist or the oldest is older than 60 minutes.
The reaper only targets `agent-browser-chrome-*` user-data-dir processes,
defaults to dry-run, and records applied receipts at
`~/.local/state/flywheel/headless-browser-reaps.jsonl`.

Agent Mail identity resolution is canonical and durable:

```bash
~/.claude/skills/.flywheel/bin/flywheel-loop identity \
  --session flywheel \
  --pane 1 \
  --json

~/.claude/skills/.flywheel/bin/flywheel-loop identity \
  --migrate-existing \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh \
  --session flywheel \
  --apply \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.identity_registry'

bash /Users/josh/Developer/flywheel/tests/agent-mail-identity-registry.sh
bash /Users/josh/Developer/flywheel/tests/locked-worker-identities.sh
```

Registry rows live in
`~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json`; token files
live in `~/.local/state/flywheel/agent-mail/tokens/` with mode 600. The durable
identity key is `(session, pane, fleet_mail_project_key)`; `identity_name` is
only the current mailbox pointer. Rotation rows preserve
`predecessor_identity_chain[]` and one of the canonical rotation reasons:
`agent-mail-name-policy`, `resolver-mcp-generated-identity`,
`compaction-continuity`, `missing-token-recovery`, `path-canonicalization`, or
`strict-mode-preallocation`.

The doctor field reports `identity_registry_drift`, `identity_token_orphan`,
`orphan_tokens_unswept_count`, `identity_rotation_count_24h`,
`identity_chain_max_length`, `worker_identity_registered_count`, and
`agentmail_orphan_session_rows_count`. Worker dispatches and callbacks should
include `identity_name=<registry-identity-name>` and, when available,
`identity_primary_key=session:pane:project`. Cross-orch handshakes should
include `identity_resolved=<identity_name>` and must not carry raw Agent Mail
tokens.

Identity history for churn diagnosis:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/identity-history.sh \
  --session flywheel \
  --pane 2 \
  --json

/Users/josh/Developer/flywheel/.flywheel/scripts/identity-history.sh doctor --json
```

Registration broadcast uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/agentmail-registration-broadcast.sh \
  --doctor \
  --json

bash /Users/josh/Developer/flywheel/tests/agentmail-registration-broadcast.sh
```

The broadcaster sends only coordination packets to live orchestrator panes,
dedupes each session:pane for 60 minutes, and honors active deferral receipts
for dead sessions.

Fleet comms health uses:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-comms-health-probe.sh \
  --fleet \
  --json

bash /Users/josh/Developer/flywheel/tests/fleet-comms-health-probe.sh
```

`--apply` sends `COMMS_HEALTH_PING` packets to silent sessions and logs
`false_positive_classifier` mismatches. It only notifies Joshua for token
expiry beyond the recovery window.

Shared-surface commits use an append-only pane reservation ledger:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh \
  --reserve AGENTS.md --pane=3 --task-id=<task> --json
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh \
  --check AGENTS.md --pane=3 --json
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh \
  --release AGENTS.md --pane=3 --task-id=<task> --json

~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.coordination_collision_count_24h, .shared_surface_reservation'

bash /Users/josh/Developer/flywheel/tests/shared-surface-reservation-check.sh
```

The ledger lives at `~/.local/state/flywheel/file-reservations.jsonl`.
Collisions log `coordination-collision-detected` to the fuckup log and block
staging until the holder releases or coordinates.

Jeff issue drafts must pass the 7-axis rubric before posting:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-issue-rubric.py \
  --draft /tmp/jeff-issue-runtime-handoff-singleton.md \
  --write-receipt \
  --json

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.jeff_drafts_unrubricd_count, .jeff_issue_rubric.rows'

bash /Users/josh/Developer/flywheel/tests/jeff-issue-rubric.sh
```

The rubric requires high marks on bug reality, duplicate search, source trace,
signal-not-prescription, tone match, Jeff thank-test hostile check, and no
derail. A 7/7 high draft is `auto_post`; 6/7 is `revise`; 5/7 or lower is
`withdraw`. Doctor JSON exposes `jeff_drafts_unrubricd_count` for `/tmp`
Jeff issue drafts without a current hash-matched receipt.

Mentor-corpus doctrine, skill, and plan imports must cite source evidence:

```bash
.flywheel/scripts/jeff-pattern-citation-probe.sh --json
.flywheel/scripts/jeff-pattern-citation-probe.sh --doctor --json \
  | jq '.jeff_pattern_uncited_count, .rows'

bash tests/jeff-pattern-citation-probe.sh
```

The required shape is
`Source: Jeff <repo>:<file>:<line> + ZestStream adaptation`. The validator
fails on vague "inspired by Jeff" claims and exposes
`jeff_pattern_uncited_count` as the lightweight doctor-equivalent signal.

Idle worker panes are classified by the repo-local probe, not by watcher-local
logic:

```bash
.flywheel/scripts/idle-state-probe.sh --json
~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '.idle_state_summary, .idle_state_class'

bash tests/idle-state-probe.sh
```

`/tmp/idle-pane-auto-dispatch.sh` is the daemon wrapper. It consumes
`idle_state_class == "dispatching"` rows, then performs the existing `br update`
and `ntm send` mutation. The wrapper is the path to run from launchd or cron;
classification thresholds and peer-orchestrator defaults live in the
`idle-state-config/v1` schema.

Stale `failed_text` or `api_error` in pane scrollback can temporarily poison
`ntm` activity classification even when a fresh Codex chevron prompt is present.
Until upstream `ntm` resolves that classifier edge case, use the dry-run-first
recovery layer:

```bash
.flywheel/scripts/stale-error-auto-ping.sh --json
.flywheel/scripts/stale-error-auto-ping.sh --apply --json --session flywheel --panes 2,3,4

bash tests/stale-error-auto-ping.sh
```

Cross-session auto-dispatch requires a live callback receiver. Fleet-wide or
infrastructure-deployment work may be selected by flywheel, but work must not be
sent directly to another session's worker pane unless that session's
orchestrator/callback pane is reachable and actively processing loop callbacks.
If liveness is not proven, file or update a local orphan/gap receipt and route
the work to the peer orchestrator instead.

Pane-state reads use the canonical NTM surface. Use `ntm health <session>` for
state truth, `ntm copy <session>:<pane> -l <N>` for scrollback, `ntm grep
<session> <pattern>` for content search, and `ntm save <session>:<pane> <path>`
for persistence. Dispatch rows record `pane_state_source`; valid values are
`ntm_health`, `ntm_copy`, `raw_capture`, or `none`, and dispatch context treats
`raw_capture` as a gate violation.

Codex dispatch capacity has an additional defense-in-depth truth source:
Pane Work Signal. The rollout proof lives in `tests/test_pws_integration_proof.sh`
and writes `/tmp/flywheel-5ktd-final-receipt.md`. PWS owns per-pane Codex truth
after a session is known; `flywheel-3bk` owns dynamic session coverage and
session-level freshness.

For README-only edits, a practical smoke check is:

```bash
rg -n "flywheel-loop|flywheel-autoloop|/flywheel:|ntm|br " /Users/josh/Developer/flywheel/README.md
```

## Operating Boundaries

- `AGENTS.md` wins over this README on doctrine.
- Use Socraticode before non-trivial edits.
- Use canonical real paths, not symlink aliases.
- Use Agent Mail file reservations before editing shared files.
- Use NTM for pane I/O and callbacks: `ntm health`, `ntm copy`, `ntm grep`,
  and `ntm save` are the pane-state verbs.
- Keep Beads repo-local; do not reintroduce global Beads fallback or silent
  `.beads` walk-up behavior.
- Do not use cached loop markers as proof of liveness; verify the driver.
- Do not rotate secrets or tokens unless Joshua explicitly asks.
- Do not edit JSM-managed skills directly; use the owning sync/push workflow.
- Keep detailed session history in `.flywheel/STATE.md`, `.flywheel/handoffs/`,
  `.flywheel/PLANS/`, `INCIDENTS.md`, Beads, and memory files.

## Maintenance Rule

Update this README when a change affects how a new worker should understand or
operate the repo:

- new or renamed CLI surface
- new slash command
- new loop-driver behavior
- new validation gate
- new canonical L-rule that changes worker behavior
- new directory or runtime surface that becomes load-bearing

Do not turn the README into a session log. Current status belongs in
`.flywheel/STATE.md`, handoffs, Beads, and receipts.
