# Lane B - Ecosystem Audit

Plan: `orchestrator-workforce-supervision-2026-05-04`
Lane: B - Jeff/upstream ecosystem patterns
Scope: read-only ecosystem audit for workforce-supervision mesh design.

## 0. Source Ledger

Skills baseline:

| skill | decision | note |
|---|---|---|
| `agent-monitoring` | ADOPT | best match for failure detection, agent SLOs, dashboards, anomaly routing |
| `agent-orchestration` | ADOPT | best match for worker routing, multi-agent work queues, fan-out/fan-in |
| `agent-governance` | ADOPT | best match for identity, audit trail, accountable agent actions |
| `observability-platform` | EXTEND | industrial metric vocabulary, but too broad without flywheel-specific receipt semantics |
| `observability-designer` | EXTEND | SLO/error-budget ideas translate after state receipts exist |

Socraticode survey:

- Jeff corpus query: `robot mode doctor health repair JSON schema callback receipt capture provenance worker supervision`, K=10.
- Flywheel query: `idle pane auto dispatch frozen pane detector auto nudge codex watchtower workforce supervision doctor signal`, K=10.
- Key hits: `ntm/internal/robot/schema.go:1`, `ntm/docs/robot-historical-inspection.md:451`, `mcp_agent_mail_rust/docs/SPEC-doctor-forensic-bundle-schema.md:91`, `frankenterm/docs/json-schema/PROVENANCE.md:1`, `README.md:271`, `AGENTS.md:901`, `tests/codex-watchtower.sh:1`.

Required local inputs read: plan intent, Jeff doctrine clusters, Jeff code patterns, `dicklesworthstone-stack` skill, Jeff substrate inventory, and version-drift memory.

## 1. Jeff Substrate Audit

| substrate | probe / supervision surface | JSON / schema surface | robot / doctor pattern | workforce-supervision import |
|---|---|---|---|---|
| `ntm` | `activity`, `health`, `--robot-activity`, `--robot-diagnose`; activity design tracks output velocity, state, duration, and stalled output (`ntm/docs/ORCHESTRATION_FEATURES.md:90`, `:94`, `:114`, `:149`, `:162`) | robot schema map enumerates status, dashboard, events, attention, mail, cass, dcg, send, etc. (`ntm/internal/robot/schema.go:1`, `:13`) | robot taxonomy names `diagnose` as health analysis and `activity` as agent idle/busy/error state (`ntm/docs/robot-surface-taxonomy.md:156`, `:158`) | ADOPT as primary pane truth source, EXTEND with capture provenance and two-source arbitration |
| `br` / Beads | ready work, priorities, dependencies, status transitions, stale/blocking graph health (`beads_rust/AGENTS.md:205`, `:209`, `:448`, `:450`) | `serde_json`, `schemars`, schema command, stable output schema (`beads_rust/AGENTS.md:65`, `:66`, `:423`, `:429`) | `br ready --json`; `bv --robot-alerts`, `--robot-label-health`, `--robot-diff`, `--robot-graph` (`beads_rust/AGENTS.md:515`, `:521`, `:529`, `:536`, `:538`) | ADOPT as task graph and blocker stock; EXTEND dashboard with callback debt and per-pane work assignment |
| Agent Mail Python/Rust | persistent identities, inbox/outbox, acks, file reservations, health, ATC snapshot (`mcp_agent_mail_rust/README.md:77`, `:86`, `:90`, `:93`, `:95`) | MCP tools/resources and forensic bundle schema v1 (`mcp_agent_mail_rust/README.md:550`, `:552`, `:554`; `mcp_agent_mail_rust/docs/SPEC-doctor-forensic-bundle-schema.md:91`) | `am doctor check|repair|reconstruct`, `am robot health`, `am robot atc`, ack-overdue and reservation views (`mcp_agent_mail_rust/README.md:510`, `:529`, `:538`, `:637`, `:643`) | ADOPT for identity, reservations, ack debt; EXTEND workforce dashboard with identity proof age and MCP health |
| `dcg` | hook gate blocks destructive commands before execution, safe alternatives first (`destructive_command_guard/README.md:35`, `:41`, `:46`, `:48`) | hook JSON to stdout, permission decision envelope, schemas for hook/scan/stats/error (`destructive_command_guard/AGENTS.md:125`, `:483`, `:503`, `:706`) | `dcg explain`, `dcg scan`, dry-run safe variants (`destructive_command_guard/AGENTS.md:683`, `:688`; `destructive_command_guard/README.md:158`) | ADOPT fail-closed safety gate and explainability; EXTEND recovery actions with `--dry-run` before interrupt/respawn |
| `cass` / `cm` | session search, current session, workspace search, health/status/state (`coding_agent_session_search/SKILL.md:32`, `:43`, `:46`, `:217`, `:222`) | `--robot`/`--json`, `capabilities --json`, `introspect --json`, robot-docs schemas/examples/exit-codes (`coding_agent_session_search/SKILL.md:19`, `:23`, `:67`, `:70`, `:73`) | health <50ms, status, diagnostics, robot-meta, dry-run search (`coding_agent_session_search/SKILL.md:55`, `:174`, `:217`, `:229`) | ADOPT for historical callback/incident lookup; EXTEND with workforce-specific query bundles |
| `frankensqlite` | transaction observability, WAL/checkpoint/crash-recovery, page-level MVCC (`frankensqlite/README.md:158`, `:162`, `:660`, `:662`, `:839`) | typed IDs/error codes/schema epochs and compatibility gates (`frankensqlite/README.md:79`, `:126`, `:150`) | not a worker CLI, but proves storage-level observability and crash-recovery model | ADOPT append-only/durable-state posture for callback debt, not raw SQL parsing |
| `x-cli` | installed CLI supports X/Twitter auth and timeline commands; output modes are JSON, TSV, markdown, verbose (`/Users/josh/.local/bin/x-cli --help`) | Python package persists OAuth token JSON (`/Users/josh/.local/share/uv/tools/x-cli/lib/python3.14/site-packages/x_cli/auth.py.bak.20260429-100655:72`, `:80`, `:86`) | no doctor found; auth status/timeline are the usable probe surfaces | EXTEND only as upstream-signal input; AVOID making it a critical supervision dependency without version/health probe |

## 2. Existing Flywheel Supervision Layer Audit

| artifact | current behavior | cited surface | remaining gap |
|---|---|---|---|
| watcher v4 `/tmp/idle-pane-auto-dispatch.sh` | selects WAITING Codex panes only when `capture_provenance=="live"` and dispatches worker tick with per-bead dedupe | `/tmp/idle-pane-auto-dispatch.sh:19`, `:20`, `:50`, `:54` | only watches idle/WAITING; no callback debt or stuck-thinking recovery |
| watcher v4 generic | same idea across sessions, with pane filters and session-specific log | `/tmp/idle-pane-auto-dispatch-generic.sh:21`, `:31`, `:33`, `:60`, `:64` | cross-session dashboard still absent; session reachability not normalized |
| auto-nudge stale-error recovery | detects live `ERROR` panes, sends benign nudge, escalates after repeated strikes | `/tmp/auto-nudge-stale-error-recovery.sh:2`, `:15`, `:20`, `:37`, `:67`, `:73`, `:81` | single failure class; uses a hard-coded escalation path and still mentions raw capture in description text |
| frozen-pane detector v2 | canonical recovery primitive for Codex #12645/frozen spinner; tick consumes it | `INCIDENTS.md:1`, `:25`, `:29`, `.flywheel/flywheel-loop-tick:37` | detector output is input only; L60 says not enough for loop health |
| `flywheel-loop doctor` | repo-local doctor, strict gate, validation, identity, fleet, callback validation | `~/.claude/skills/.flywheel/bin/flywheel-loop:47`, `:51`, `:52`, `:54`, `:57`, `:58` | strong per-repo doctor, weak cross-session workforce rollup |
| `flywheel-readme` | full canonical CLI surface: doctor, health, repair, validate, audit, why, schemas | `~/.claude/skills/.flywheel/bin/flywheel-readme:72`, `:80`, `:82`, `:83`, `:84`, `:91` | good pattern source; not directly supervising panes |
| codex-watchtower | daily summary + doctor fixture, upstream issue pressure, frozen-pane cross-reference | `.flywheel/flywheel-loop-tick:33`, `:35`, `tests/codex-watchtower.sh:39`, `:49`, `INCIDENTS.md:541` | watches upstream Codex risk, not local worker liveness by itself |
| daily-report | generates daily report and doctor exposes daily-report age | `README.md:117`, `README.md:577`, `README.md:593` | learning rollup, not live workforce state |
| mobile-eats receipt bridge | bridges product receipt into canonical tick-shaped JSON | `README.md:289`, `.flywheel/dispatch-log.jsonl:561`, `:584`, `:589` | proves receipt mirroring pattern; needs generalization to all project loops |
| agent-mail identity audit | documented canonical identity resolution and doctor drift fields | `README.md:299`, `README.md:624`, `README.md:647`, `AGENTS.md:1355` | script path named in dispatch is absent locally; global `flywheel-loop identity --doctor` is the live surface |
| leverage-ceiling probe | Meadows leverage constraints wired as script/tick/status surface | `README.md:284`, `.flywheel/dispatch-log.jsonl:551` | useful planning signal, not workforce liveness |
| gap-hunt probe | gap discovery and ledger support; doctrine says 9th class enforces loop-integrity | `README.md:285`, `AGENTS.md:620`, `AGENTS.md:633`, `.flywheel/dispatch-log.jsonl:554` | identifies gaps after the fact; not a live recovery mesh |

## 3. ADOPT / EXTEND / AVOID Synthesis

| Jeff cluster / code pattern | verdict | workforce-supervision application |
|---|---|---|
| doctor-health-repair-triad | ADOPT | every workforce primitive needs `probe`, `doctor --json`, and `repair --dry-run/--apply`; no prose-only nudge logic |
| idempotency-key-fail-closed | ADOPT | recovery actions, callback validation, auto-open beads, and respawn attempts need idempotency keys and conflict receipts |
| callback-and-receipt-envelope | ADOPT | worker DONE/BLOCKED, delivery proof, callback validator, and evidence files should share one envelope family |
| append-only-audit-and-lineage | ADOPT | workforce state samples, callback debt, and auto-recovery attempts should be append-only JSONL with replayable lineage |
| testing-fixture-conventions | ADOPT | each failure class gets fixtures: stale-error, stuck-thinking, callback-missing, capture-unavailable, identity-mismatch |
| lock-file-convention | ADOPT | shared state writers need lock owner, TTL, stale-lock diagnosis, and no partial mutation |
| frontmatter-validation | ADOPT | dispatch packets and plan/bead docs should validate metadata before workers receive them |
| schema-versioning-and-migrations | EXTEND | capture provenance, callback receipts, and workforce state must carry schema versions and mixed-version tests |
| error-handling-and-recovery | EXTEND | Jeff taxonomy is strong; flywheel needs a narrower recovery ladder for visible panes and callback debt |
| generic callback-envelope-shape from Jeff corpus | DIVERGE | keep flywheel-specific `DONE/BLOCKED did/didnt/gaps callback_delivery_verified` fields, but validate them with reusable envelope helpers |
| `x-cli` live feed as supervision input | AVOID as critical path | use for upstream signal; do not block workforce state on OAuth/API health |

Three-judges lens:

- Jeff: the proven pattern is machine contracts first: robot output, schemas, doctor, repair, append-only evidence.
- Donella: closed loops exist where probe output feeds doctor and repair; open loops remain where flywheel logs a warning but no consumer owns recovery.
- Josh: the sellable layer is not "another pane script"; it is a canonical agentic-coding-flywheel supervision mesh with receipts, recovery, and dashboard truth.

## 4. External Ecosystem Scan

| ecosystem | useful supervision pattern | translates cleanly? | fit notes |
|---|---|---|---|
| Kubernetes operators | reconcile loop: desired state, observed state, status conditions, backoff, events | yes | use for session/pane desired-vs-observed, not for container-style replacement as first move |
| systemd | watchdog heartbeat, restart policies, unit states, journal evidence | yes | maps to pane heartbeat, callback deadlines, and restart policy; avoid blind restart loops |
| supervisord | process groups, autorestart, stdout/stderr logs, status CLI | partial | good for process supervision, weak for agent semantic states like THINKING vs stuck |
| PM2 | process list, restart count, log tail, health-ish dashboard | partial | useful for restart counters and status dashboard; not enough for callback/evidence validation |
| AWS ECS | task desired/running states, health checks, deployment events, stopped reasons | partial | desired/running/stopped reasons map well; infra scale model is too coarse for pane scrollback |
| Temporal worker pools | task queues, heartbeat timeouts, retry policy, durable workflow history | yes | best external analog for callback debt and durable recovery history; heavier than needed but conceptually right |

Translation rule: use industrial patterns for state vocabulary and recovery ladders, but keep flywheel-specific proof sources: `ntm` live pane state, callback receipts, Agent Mail identity, Beads task state, and repo doctor signals.

## 5. Cross-Cutting Findings

1. Every probe should emit JSON with `sample_collected_at`, `source`, `schema_version`, and `provenance`; `capture_provenance` should not be unique to `ntm`.
2. Workforce state needs source arbitration: `ntm activity`, `ntm health`, topology, callback logs, and doctor can disagree; disagreement is a first-class state.
3. Recovery must be a ledgered action, not a script side effect: action, idempotency key, strike count, cooldown, result, and next owner.
4. `doctor --json` should be the dashboard input, not the dashboard itself. Dashboards consume receipts; they do not create truth.
5. Callback debt is a stock, not an event. It needs current level, age buckets, owners, and reaper outcomes.
6. Identity proof belongs beside pane state. A pane can be alive but unable to reserve files, receive mail, or prove callback ownership.
7. Schema-versioning is now load-bearing because `ntm` capture provenance shipped recently and consumers are mixed-version.
8. Flywheel already has most primitives; the missing piece is composition into one state machine and one recovery policy.

## 6. Substrate-Version-Drift Risk

| dependency | version-sensitive field / behavior | current risk |
|---|---|---|
| `ntm` | PR #117 adds `capture_collected_at`, `capture_provenance`, `capture_error`; installed update noted as `v1.14.0-41` | watcher v4 and auto-nudge require these fields; stale `ntm` regresses stale-error handling |
| `br` | JSON/robot schemas and `br ready --json` shape | task graph and DID/DIDNT/GAPS mapping can misparse if schema drifts |
| Agent Mail | identity, reservations, acks, health/ATC snapshots | MCP timeout or Rust/Python migration drift can look like worker failure |
| `dcg` | hook JSON and false-positive behavior | broad matching can block canonical `ntm send` payloads if stale |
| `cass` | robot search/status schema | historical evidence lookup can silently degrade if index/schema is stale |
| `frankensqlite` | recovery, WAL/checkpoint, schema compatibility | indirect risk through cass/agent-mail storage behavior |
| `x-cli` | auth refresh and output modes | upstream-signal only; should warn, not block workforce supervision |
| flywheel scripts | hard-coded paths to `~/.local/bin/ntm`, global `flywheel-loop`, missing `.flywheel/bin/*` wrappers | path/version skew can make docs and execution disagree |

Pin-points:

- `watcher v4` and `auto-nudge` require post-#117 `capture_provenance`.
- `frozen-pane-detector` requires live byte-delta semantics per L67, not cached scrollback.
- callback validation requires `verify-callback-delivery.sh` plus `validate-callback.py` to agree on task id and callback pane.
- Agent Mail identity recovery should use `flywheel-loop identity --doctor --json`, because the standalone `agent-mail-identity-audit.sh` path was not present in this checkout.

## Closeout

DID:

1. Jeff substrate audit for `ntm`, `br`, Agent Mail, `dcg`, `cass`, `frankensqlite`, and `x-cli`.
2. Existing flywheel layer audit for watcher v4, auto-nudge, frozen-pane detector, doctor, readme, watchtower, daily report, receipt bridge, identity audit surface, leverage probe, and gap-hunt probe.
3. ADOPT/EXTEND/AVOID synthesis for Jeff doctrine clusters and code patterns.
4. External ecosystem scan across Kubernetes operators, systemd, supervisord, PM2, ECS, and Temporal.
5. Cross-cutting findings.
6. Substrate-version-drift risk table.

DIDNT:

- none

GAPS:

- none filed; this read-only research lane surfaced no out-of-scope substrate gap that is not already part of the plan problem space.

Ladder: passed.
