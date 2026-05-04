# Lane B: Ecosystem Audit — fleet-conductor

Plan: `fleet-conductor-2026-05-04`
Role: Phase 1 Lane B, ecosystem audit
Mode: READ-ONLY
Worker: `flywheel:2 codex`

## Executive Summary

The ecosystem already has many fleet-adjacent pieces: `fleet-doctor`, Jeff
status, upgrade preview, codex watchtower, info-source watchtower, daily report,
identity registry, frozen-pane detector v2, gap/leverage probes, and the
in-flight workforce-supervision mesh. The v2/v3 intent amendment raises the bar:
fleet-conductor is not merely observability. It is the autonomous founder
substrate that watches the fleet and the outside landscape, grades work against
Jeff/Meadows/research/powerhouse practice, and brings Joshua only three kinds of
high-leverage moments: `FLAG`, `INPUT`, and `QUALITY`.

The gap is not absence of tools; it is absence of a conductor that normalizes
these tools and source-watchtowers into one fleet-tier contract: session
discovery, mission anchor, liveness, work quality, intervention ledger, source
qualification, continuous landscape ingestion, drift detection, and
Joshua-facing reports.

Lane B recommendation: build fleet-conductor as a composition layer, not a
replacement. It should read session-local probes, require fleet-native metadata
on every row, route interventions through fail-closed idempotent receipts, and
store every metric in append-only fleet ledgers. Existing per-session watchers
remain inputs until workforce-supervision provides Layer 1/2 signals. Continuous
landscape ingestion is a core pillar, not a plugin.

## Skills Best-Practices Receipt

Requested command:

`/flywheel:skills-best-practices "fleet supervision multi-session conductor cross-system observability watchdog" --top=10 --include-content`

Result: shell invocation failed with `no such file or directory`; this worker
does not have slash-command execution from zsh. Fallback used the local skill
catalog search MCP with the same query and read the dispatch-named skills.

Top local skill-search matches:

| rank | skill | relevance to fleet-conductor |
|---:|---|---|
| 1 | `observability-platform` | Multi-service telemetry, SLOs, log aggregation, dashboard posture. |
| 2 | `qos-monitoring` | Signal quality and degradation monitoring pattern; domain-specific but useful for latency/jitter analogs. |
| 3 | `trouble-ticket-automation` | Triage, priority, SLA, and automated diagnostics pattern. |
| 4 | `observability-designer` | SLO/SLI, alert fatigue, golden signals, dashboard design. |
| 5 | `incident-response` | Severity, escalation, postmortem, war-room discipline. |
| 6 | `loop-enforcement` | Recurring loop compliance and no-op/stall detection. |
| 7 | `jeff-convergence-audit` | Quality gate and convergence-audit discipline. |
| 8 | `sla-monitoring` | Availability and breach reporting pattern. |
| 9 | `uptime-monitoring` | Liveness/readiness probes and alerting patterns. |
| 10 | `flywheel-doctor-author` | Doctor invariant, probe, promotion calculus, substrate registry coherence. |

Dispatch-named skill citations:
- `agent-fleet-management` says fleet capacity is constrained by accounts,
  machines/panes, and token budget, and warns not to count marker-only drivers as
  capacity ([SKILL.md](/Users/josh/.claude/skills/agent-fleet-management/SKILL.md:11),
  [SKILL.md](/Users/josh/.claude/skills/agent-fleet-management/SKILL.md:15),
  [SKILL.md](/Users/josh/.claude/skills/agent-fleet-management/SKILL.md:19)).
- `info-source-watchtower` requires first-class sources to use daily durable
  ingest and the `seen -> noted -> extracted|archived` gate
  ([SKILL.md](/Users/josh/.claude/skills/info-source-watchtower/SKILL.md:20),
  [SKILL.md](/Users/josh/.claude/skills/info-source-watchtower/SKILL.md:34)).
- `codex-watchtower` is a child watchtower for `openai/codex`, with daily ingest
  state under `~/.local/state/flywheel/codex-watchtower/` and a rule to avoid
  upgrades until gates pass ([SKILL.md](/Users/josh/.claude/skills/codex-watchtower/SKILL.md:8),
  [SKILL.md](/Users/josh/.claude/skills/codex-watchtower/SKILL.md:15),
  [SKILL.md](/Users/josh/.claude/skills/codex-watchtower/SKILL.md:23)).
- `dicklesworthstone-stack` provides the Jeff signal extraction gate and operator
  commands; every Jeff signal must transit `seen -> noted -> strike|archive|extract`
  ([SKILL.md](/Users/josh/.claude/skills/dicklesworthstone-stack/SKILL.md:1),
  [SKILL.md](/Users/josh/.claude/skills/dicklesworthstone-stack/SKILL.md:32)).
- `flywheel-end-to-end` defines the mission-to-ship pipeline and warns that the
  loop is not a timer or status file ([SKILL.md](/Users/josh/.claude/skills/flywheel-end-to-end/SKILL.md:33),
  [SKILL.md](/Users/josh/.claude/skills/flywheel-end-to-end/SKILL.md:35)).

## 1. Existing Fleet Observability Layer Audit

| artifact | current coverage | fleet-tier or session-local | gap remaining for fleet-conductor |
|---|---|---|---|
| `/flywheel:fleet-doctor` | Reads `~/.local/state/flywheel/fleet-roster.json` and runs `flywheel-onboard.sh --dry-run --doctor --json` for each repo; explicitly forbids `--stamp`, `--sync`, or `--upgrade` ([fleet-doctor.md](/Users/josh/.claude/commands/flywheel/fleet-doctor.md:20), [fleet-doctor.md](/Users/josh/.claude/commands/flywheel/fleet-doctor.md:31), [fleet-doctor.md](/Users/josh/.claude/commands/flywheel/fleet-doctor.md:39)). | Fleet-tier repo onboarding. | It checks repo onboarding, not live ntm session state, work quality, Joshua-notice debt, or cross-session intervention readiness. |
| `/flywheel:jeff-status` | Runs Jeff issue status, response polling in skip-network mode, and Jeff fixes dry-run probe; forbids repo mutation, posting comments, branch pulls, and bead closure ([jeff-status.md](/Users/josh/.claude/commands/flywheel/jeff-status.md:20), [jeff-status.md](/Users/josh/.claude/commands/flywheel/jeff-status.md:27), [jeff-status.md](/Users/josh/.claude/commands/flywheel/jeff-status.md:33)). | Fleet-tier source status for Jeff substrate. | It is Jeff-specific; conductor must fold it into a broader source qualification queue and version-drift report. |
| `/flywheel:upgrade` | Previews low-risk upgrades via flywheel onboarding and optional Jeff fixes puller dry-run; default is dry-run and `--apply` requires exact class plus idempotency key ([upgrade.md](/Users/josh/.claude/commands/flywheel/upgrade.md:19), [upgrade.md](/Users/josh/.claude/commands/flywheel/upgrade.md:23), [upgrade.md](/Users/josh/.claude/commands/flywheel/upgrade.md:40)). | Fleet-tier upgrade visibility, mutation-gated. | It is not a conductor; it should be a read-only input and one possible Joshua-approved intervention path. |
| `codex-watchtower` | Daily Codex upstream ingest, summary, and doctor surfaces; maps Codex CLI issues to local pane incidents ([SKILL.md](/Users/josh/.claude/skills/codex-watchtower/SKILL.md:19), [SKILL.md](/Users/josh/.claude/skills/codex-watchtower/SKILL.md:28)). | Fleet-tier upstream source, agent-runtime-specific. | Needs cross-session join to pane incidents and model/runtime upgrade drift. |
| `info-source-watchtower` | Parent surveillance pattern with daily durable ingest, env-match filters, state gate, and extraction destinations ([SKILL.md](/Users/josh/.claude/skills/info-source-watchtower/SKILL.md:20), [SKILL.md](/Users/josh/.claude/skills/info-source-watchtower/SKILL.md:36), [SKILL.md](/Users/josh/.claude/skills/info-source-watchtower/SKILL.md:40)). | Fleet-tier pattern. | Fleet-conductor should use it for new data-source qualification instead of inventing another source queue. |
| `flywheel-loop doctor` cross-session/identity fields | Existing doctor exposes Agent Mail identity registry drift and token orphan signals per doctrine ([AGENTS.md](/Users/josh/Developer/flywheel/AGENTS.md:1355), [README.md](/Users/josh/Developer/flywheel/README.md:658)). | Mostly repo-local doctor, with some fleet identity fields. | Needs a fleet rollup keyed by `session_name`, `repo`, `orchestrator_pane`, and freshness. |
| `daily-report.sh` | Repo-local daily narrative generator with inputs for dispatch log, fuckup log, cross-orch log, Jeff digest, incidents, and doctor JSON. Help exposes `--repo`, `--date`, `--json`, `--notify`, `--schema`, `--info`, `--examples`. | Repo-local report with fleet-capable inputs. | Needs fleet-conductor daily/weekly/milestone report that merges sessions and grades work against Three Judges and publishability. |
| `mobile-eats-receipt-bridge.sh` | Read-only bridge from mobile-eats product loop receipts to canonical flywheel tick-shaped JSON. | One project-specific bridge. | Pattern should generalize as `project_receipt_bridge/<repo>/v1`; conductor consumes all project bridges uniformly. |
| `leverage-ceiling-probe.sh` | Read-only fail-open probe for flywheel leverage ceiling; aligns with agent-fleet-management stock model. | Fleet-tier metric. | Needs conductor stock ledger: accounts, machines, tokens, queue, driver; current probe is one metric, not a control plane. |
| `gap-hunt-probe.sh` | Read-only gap discovery with append-only ledger and capped auto-bead filing. | Fleet-tier learning/probe primitive. | Needs conductor dedupe by session/repo/gap class and Joshua-notice debt integration. |
| `agent-mail-identity-audit` / `flywheel-loop identity` | Standalone script path was not found; identity registry tests and doctor fields exist. Registry rows include schema version, session, pane, token path, fleet mail project, and status in tests ([tests](/Users/josh/Developer/flywheel/tests/agent-mail-identity-registry.sh:28), [tests](/Users/josh/Developer/flywheel/tests/agent-mail-identity-registry.sh:60)). | Fleet-native identity registry. | Conductor should treat identity registry as fleet-native truth, but never carry raw tokens in reports or packets. |
| `frozen-pane-detector v2` | Supports `--session=<session>`, `--session=all`, `--doctor`, `--health`, `--schema`, auto-recovery dry-run, cooldown, leases, metrics, and recovery ledger ([script](/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh:59), [script](/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh:76), [script](/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh:349)). | Session-local detector with fleet sweep mode. | Conductor should consume detector output but centralize intervention policy to avoid multiple recovery owners. |
| watcher v4 | Per-session idle/WAITING dispatch watcher uses live capture provenance and dedupe; prior workforce Lane B recorded it as `/tmp/idle-pane-auto-dispatch*.sh`. | Session-local / transitional. | Must remain a migration input only. Fleet-conductor should not stack another auto-dispatcher on top without owner leases. |
| workforce-supervision-mesh | In-flight plan composes watcher v4, frozen-pane v2, callback validation, auto-nudge, state aggregation, classifier, and recovery dispatcher. | Per-session supervisor, future fleet input. | Hard dependency. Fleet-conductor should consume Layer 1/2 signals, not duplicate worker-state classification. |

## 2. Jeff Substrate Audit At Fleet Tier

| substrate | fleet-native? | evidence / citation | conductor implication |
|---|---|---|---|
| `ntm` | Partially. It can enumerate sessions through status/dashboard surfaces and can probe a named session, but fleet-wide activity requires iteration. Local `ntm` VS Code client models `sessions: SessionInfo[]`, total sessions, and per-session agents ([ntmClient.ts](/Users/josh/Developer/ntm/vscode/src/ntmClient.ts:10), [dashboard.ts](/Users/josh/Developer/ntm/vscode/src/dashboard.ts:174), [dashboard.ts](/Users/josh/Developer/ntm/vscode/src/dashboard.ts:189)). | Fleet-conductor should own session iteration and require every `ntm` sample to include `session_name`, `pane`, `capture_collected_at`, and `capture_provenance`. |
| `br` / Beads | Session/repo-local. Beads is per repo; Jeff corpus callback-envelope findings show many repos have generic receipt/status language but flywheel diverges for DONE/BLOCKED callback contracts ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:112)). | Conductor must map session -> repo -> bead DB, never assume a single fleet bead graph. Fleet-level findings become flywheel beads or remote repo beads with explicit `source_repo`. |
| Agent Mail | Fleet-native identity substrate exists locally. Tests seed `fleet-mail-project`, session topology rows, and identity registry schema rows ([tests](/Users/josh/Developer/flywheel/tests/agent-mail-identity-registry.sh:32), [tests](/Users/josh/Developer/flywheel/tests/agentmail-registration-broadcast.sh:40)). Doctrine forbids raw tokens in cross-orch handshakes ([AGENTS.md](/Users/josh/Developer/flywheel/AGENTS.md:1353)). | Conductor should use Agent Mail for durable cross-orch identity and async coordination, with token-safe references only. |
| `dcg` | Per-repo / per-command guard. Jeff doctrine imports dry-run/fail-closed mutation posture as a broad pattern ([01-doctrine-cluster.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:17)). | Cross-session interventions must carry `source_session`, `target_session`, `idempotency_key`, and override receipt before any mutation. |
| `cass` | Per-collection. CASS can query indexed session/corpus collections; it is not a live fleet control plane. | Conductor can use CASS for historical analysis, but live state must come from `ntm`, Agent Mail, dispatch logs, doctor JSON, and workforce-supervision samples. |
| `fleet-mail-project` | Fleet-native cross-orch coordination layer, memory-cited. LavenderGlen pattern says this is canonical cross-orch identity and every session orchestrator should register there. | Conductor should treat fleet-mail identity as mandatory onboarding tier and expose `fleet_mail_identity_missing_count`. |
| Jeff corpus watchtower | Fleet-tier dependency watch. AGENTS L63 requires daily intel over Jeff X, website, git repos, GitHub activity, and jsm/skills drift ([AGENTS.md](/Users/josh/Developer/flywheel/AGENTS.md:731), [AGENTS.md](/Users/josh/Developer/flywheel/AGENTS.md:747)). | Conductor should surface substrate drift as a fleet risk, not as a one-off Jeff digest. |

## 3. External Ecosystem Scan

| ecosystem pattern | useful primitive | translation to pane/agent-mail/beads substrate | avoid |
|---|---|---|---|
| Kubernetes operators | Reconcile loop, desired/current state, owner references, finalizers, leader election. | Fleet-conductor should reconcile desired session roster vs live `ntm`/doctor state; use owner leases for interventions; add finalizer-like closeout receipts before a session is considered integrated. | Avoid pretending panes are pods. Terminal agents have conversational state and callback contracts that Kubernetes does not model. |
| Temporal worker pools | Fleet-wide task queue, worker heartbeats, retry policy, idempotent activity IDs, durable history. | Use append-only dispatch/intervention ledgers, heartbeat freshness, retry/cooldown policy, and activity IDs keyed by `session:pane:task_id`. | Avoid adopting Temporal as infrastructure now; the local substrate is shell/JSONL/ntm/beads. |
| PM2 process supervisor | Multi-process liveness, restart policy, process list dashboard. | Use process liveness and restart policy only for agent runtime survival; expose a compact fleet dashboard and per-session status. | Avoid process-only health. A running Codex process can still be frozen, marker-only, or unproductive. |
| Vault Enterprise federation | Multi-cluster status, sealed/unsealed health, replication lag, token-safe reporting. | Report secret substrate and Agent Mail identity state by handle/path hash only; detect drift without surfacing tokens. | Avoid centralizing or printing secrets in conductor reports. |
| Datadog APM | Multi-service traces, service map, SLOs, high-cardinality control, evidence links. | Treat every session as a service with traces from dispatch -> worker -> callback -> bead close; attach evidence links and preserve cardinality by bucketing panes/sessions/trauma classes. | Avoid noisy dashboards that surface every raw event to Joshua. Conductor reports should escalate only founded steer/input/quality moments. |
| SpaceX-style flight operations | Test-rich cadence, anomaly closure, telemetry-first postflight learning, regulator/source tracking. | Every fleet intervention and report should have mission objective, telemetry receipt, anomaly class, corrective action, and next test. Source landscape should include official updates and external regulator/safety artifacts where relevant. | Avoid spectacle metrics. The useful import is telemetry and anomaly closure, not performative launch language. |
| Tesla-style fleet learning | Large-scale deployed telemetry, safety reports, shadow/evaluation loops, OTA-style feedback. | Treat every agent/session as part of an instrumented fleet. Aggregate success/failure/quality signals, compare against baseline, and promote safe improvements through dry-run/apply gates. | Avoid overclaiming autonomy. Tesla safety history also shows why guardrails, domain boundaries, and external audit matter. |

## 3a. Continuous Landscape Ingestion Source Audit

This section absorbs the v2/v3 intent amendment. Fleet-conductor must own
continuous knowledge-source ingestion as a first-class operating pillar. Jeff
and Meadows are already in scope; the missing ecosystem requirement is the
broader landscape loop.

| source family | source of truth candidates | cadence | qualify trigger | conductor use |
|---|---|---:|---|---|
| Donella Meadows systems thinking | Local `donella-meadows-systems-thinking` skill and canonical 12 leverage point reference. | Per plan / per doctrine landing. | Any plan, doctrine, or intervention rule that changes goals, rules, information flows, self-organization, or feedback loops. | Score every fleet-conductor plan/report against leverage points; report `meadows_leverage_class`. |
| Jeff Emanuel corpus | Local Jeff corpus 177 repos, L63 daily intel network, Jeff X/site/GitHub/jsm drift ([AGENTS.md](/Users/josh/Developer/flywheel/AGENTS.md:731)). | Daily diff; weekly compaction. | New repo commit/release/issue touches `ntm`, `br`, `agent-mail`, `dcg`, `cass`, `socraticode`, `jsm`, or observed flywheel pain class. | Substrate-version drift, pattern mining, issue quality, implementation primitives. |
| arXiv | arXiv recent/search feeds for agent orchestration, multi-agent systems, observability, RL for agents, alignment; example current query space includes multi-agent orchestration papers such as `arxiv.org/abs/2601.13671`. | Daily title/abstract diff; weekly deep-read queue. | Paper mentions orchestration, observability, governance, agent evaluation, multi-agent coordination, or long-horizon autonomous systems. | Source qualification capsules; Phase 1 research inputs; new evaluation/telemetry patterns. |
| Anthropic | Claude Code changelog (`https://code.claude.com/docs/en/changelog`), Claude platform release notes (`https://docs.claude.com/en/release-notes/overview`), Anthropic news/engineering/alignment posts. | Daily changelog diff; weekly synthesis. | CLI permission model, MCP, model behavior, agent autonomy, tool-use safety, API/SDK changes. | Agent runtime risk, upgrade gates, new safety patterns, codex/claude parity. |
| OpenAI | API changelog (`https://platform.openai.com/docs/changelog`), OpenAI news/research, model/system cards. | Daily changelog diff; weekly synthesis. | Model/tool/runtime behavior affects agent fleet quality, cost, safety, or evaluation. | Model-routing, tool-use contracts, eval harness updates. |
| Google DeepMind | DeepMind blog/research (`https://deepmind.google/discover/blog/`) and Google AI release posts. | Weekly. | Agentic systems, evaluation, safety, robotics/autonomy, coding-agent research. | Best-practice absorption, research comparison, new eval dimensions. |
| xAI | xAI news/model cards/risk framework (`https://x.ai/news`, `https://data.x.ai/`). | Weekly; urgent on model/risk-card release. | Grok/model/runtime release, risk framework update, tool-use or search behavior. | Model landscape drift and risk posture comparison. |
| Mistral | Mistral docs changelog (`https://docs.mistral.ai/getting-started/changelog`) and Mistral news. | Weekly; urgent on coding/agent/security change. | Agents API, coding assistant, guardrails, SDK changes, self-host/local deployment. | Alternative model/runtime options and enterprise controls. |
| Tesla | Tesla AI/Robotics (`https://www.tesla.com/AI`) and Vehicle Safety Report (`https://www.tesla.com/VehicleSafetyReport`). | Monthly; urgent on safety/autonomy report. | Telemetry, safety report, autonomy deployment, evaluation/driver-monitoring pattern. | Fleet telemetry, safety reporting, autonomy guardrails. |
| SpaceX | SpaceX updates (`https://www.spacex.com/updates/`) plus FAA/regulatory updates for mishap/flight closure. | Weekly; urgent on major flight/anomaly report. | Anomaly investigation, flight-test telemetry, launch cadence, regulatory closure. | Test cadence, anomaly closure, regulator-facing evidence discipline. |
| Stripe | Stripe engineering blog (`https://stripe.com/blog/engineering`) and changelog (`https://stripe.com/blog/changelog`). | Weekly. | Reliability, API design, developer experience, financial-grade correctness, agent integration. | Operational rigor, API/evidence contracts, developer-platform lessons. |
| Vercel | Vercel changelog (`https://vercel.com/changelog`) and engineering/blog posts. | Weekly. | Deployment, DX, AI app/runtime, frontend infra changes. | Shipping pipeline and demo readiness patterns. |
| Andreessen | a16z primary writing/podcasts and Marc Andreessen essays. | Weekly digest. | Founder-market, AI infrastructure, company-building, power-law operational insights. | Strategic framing and "why now" checks; not implementation truth. |
| Sam Altman | `https://blog.samaltman.com/` and OpenAI primary posts. | Weekly digest. | Frontier strategy, agent deployment, platform direction, governance. | Landscape orientation and source-qualification prompts. |
| Patrick/John Collison | `https://patrickcollison.com/`, Stripe primary writing/interviews. | Weekly digest. | Taste, operational excellence, ambition, systems-building, company cadence. | Report voice/taste calibration and founder-substrate benchmark. |

Ingestion contract per source:

- `source_id`, `source_url`, `source_owner`, `source_type`, `cadence`,
  `last_checked_at`, `freshness_slo`, `baseline_hash`, `latest_hash`,
  `diff_summary`, `relevance_score`, `qualify_trigger`, `destination`.
- Source signal flow: raw capture -> diff vs baseline -> relevance probe ->
  `FLAG` capsule if new source/pattern needs Joshua -> bead candidate if
  actionable -> Three Judges -> promote to skill/doctrine/report if passed.
- Every source has an archive decision path. "Interesting" is not enough.

Landscape drift classes:

- `industry_pattern_missing_locally`: external best practice appears repeatedly
  and flywheel lacks a matching primitive.
- `local_pattern_deprecated_by_landscape`: our current doctrine contradicts newer
  safety/reliability evidence.
- `source_freshness_breach`: source not checked within SLO.
- `source_signal_no_destination`: extracted signal has no skill, bead, doctrine,
  report, or no-adopt receipt.

## 4. ADOPT / EXTEND / AVOID Synthesis

| Jeff cluster or code pattern | verdict for fleet-conductor | application |
|---|---|---|
| `doctor-health-repair-triad` | ADOPT at fleet tier | Fleet-conductor needs `doctor --json`, `health`, `why`, and `repair --dry-run` siblings. Jeff code-pattern line says the triad should require `check`, `why`, and `repair --dry-run` before promotion ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:47)). |
| `idempotency-key-fail-closed` | ADOPT | Every cross-session intervention needs key+fingerprint+TTL and fail-closed conflict behavior. Jeff citations: `asupersync/src/remote.rs:1426`, `asupersync/docs/tokio_retry_idempotency_failure_contracts.json:181`, `franken_engine/.../idempotency_key.rs:212` ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:52)). |
| `callback-and-receipt-envelope` | EXTEND | Keep flywheel DONE/BLOCKED shape, but add cross-session fields: source session, target session, callback route, identity proof, evidence path, validation result. Jeff pattern says flywheel should diverge where it needs DONE/BLOCKED fields while keeping envelope tests ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:115)). |
| `append-only-audit-and-lineage` | ADOPT | `joshua_notice_debt`, source qualification, interventions, and report claims must be ledger-sourced. Jeff code-pattern cites append-only JSONL/lineage and doctor checks ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:178)). |
| `schema-versioning-and-migrations` | EXTEND | Conductor session-state and report schemas must carry `schema_version`, compatibility tests, and migration receipts. Jeff pattern says schema-versioning should extend validation-schema style with migration receipts ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:94)). |
| `frontmatter-validation` | ADOPT | Per-session `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, `.flywheel/STATE.md`, and conductor report frontmatter should validate before the session is graded. Jeff pattern recommends validators for skills, commands, plans, and doctrine artifacts ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:157)). |
| `lock-file-convention` | ADOPT | Multi-conductor and conductor-vs-workforce races require lock files with owner metadata and stale-lock diagnosis. Jeff citations include `agentic_coding_flywheel_setup/scripts/lib/state.sh:688`, `franken_node/CONCURRENCY.md:1`, and `remote_compilation_helper/rch/src/state/mod.rs:1` ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:136)). |
| `testing-fixture-conventions` | ADOPT | Cross-session fixtures should cover session missing, session live but driver stale, callback orphan, identity missing, stale report, source drift, and intervention replay. Jeff pattern requires stable fixture IDs and replay commands ([02-code-patterns.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:73)). |
| `ipc-and-transport-contracts` | ADOPT | All cross-session samples and interventions must be JSON/robot contracts, not prose or scrollback. Doctrine cluster identifies IPC/transport envelope contracts as one of eight clusters ([01-doctrine-cluster.md](/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:18)). |
| `error-handling-and-recovery` | EXTEND | Fleet-conductor should classify errors into observation, intervention, Joshua-input, and quality-review queues. It should not auto-recover without workforce-supervision truth and idempotency gates. |
| SpaceX/Tesla telemetry-rich autonomy | ADOPT | Import the pattern of continuous telemetry, anomaly closure, objective-based test cadence, safety reporting, and feedback loops across deployed units. For flywheel: sessions are the fleet, interventions are tests, reports are flight/safety reviews, and every anomaly closes into bead/skill/doctrine or explicit archive. |
| SpaceX/Tesla operations analogy | EXTEND | Apply only as operational discipline: autonomous bounded scope, telemetry-rich, source-aware, regulator/external-signal aware, and self-improving. Translate "mission control" into founder-substrate reports, not a decorative dashboard. |
| SpaceX/Tesla hero narrative | AVOID | Do not import performative language, vanity velocity, or autonomy overclaims. Fleet-conductor must stay evidence-grounded and fail-closed. |

## 5. Cross-Cutting Findings

1. Every session probe should emit JSON with `schema_version`, `capture_collected_at`,
   `capture_provenance`, `session_name`, `pane`, `repo`, `source_tool`, and
   `sample_id`.
2. Every cross-session intervention should include `source_session`,
   `source_identity`, `target_session`, `target_identity`, `target_repo`,
   `idempotency_key`, `request_fingerprint`, `override_receipt_ref`, and
   `callback_route`.
3. Every fleet metric should be append-only-ledger sourced. Dashboard projections
   are cache, not truth.
4. Fleet-conductor should depend on workforce-supervision for pane/task
   classification. It should not implement a competing frozen/idle/stale
   classifier.
5. Existing watchtower pattern should own source qualification. The conductor
   should score and route source candidates, not scrape every upstream itself.
6. Joshua-facing reports should be derived from evidence rows and should surface
   only three classes: `FLAG` source qualification, `INPUT` project steer, and
   `QUALITY` MVP/demo review.
7. Cross-session work must be identity-safe. Reports and packets carry token
   paths/hashes/identity names, never raw bearer tokens.
8. Fleet capacity must use the minimum-stock model: accounts, machines/panes,
   tokens, queue, and driver proof. Idle panes are not automatically failure.
9. Landscape ingestion rows must include a destination: archive, skill update,
   doctrine candidate, bead, report item, or `no_adopt_reason`.
10. MVP/demo readiness must self-grade Three Judges 7/7 and publishability before
    surfacing `QUALITY` asks to Joshua, unless explicitly marked `pre_bar`.
11. Add `joshua_time_saved_per_week` as a sibling metric to
    `joshua_notice_debt`, backed by avoided asks, auto-caught errors, and
    completed quality gates.

## 6. Substrate-Version-Drift Fleet Impact

Asymmetric upgrades can break conductor assumptions in ways session-local tools
will not catch:

| substrate drift | fleet impact | conductor role |
|---|---|---|
| `ntm` version differs by shell/session | `capture_provenance`, robot activity, or health JSON fields may appear in one session and vanish in another. Watcher v4 and frozen detector depend on live provenance. | Maintain `ntm_version_by_session` and fail closed for interventions when required fields are missing. |
| `br` schema/output differs by repo | Fleet bead scans can silently miss ready/in-progress work or misfile findings. | Parse with schema fixtures; emit `br_schema_drift_count`; never infer "no work" from parse failure. |
| Agent Mail registry schema/token location differs | Cross-orch identity can fail or leak if old token paths are used. | Use `flywheel-loop identity` as the only identity reader; surface `identity_registry_drift` and dead-session deferrals. |
| `dcg` guard version differs | A mutation allowed in one repo may be blocked or unsafe in another. | Interventions carry per-repo dry-run receipts and guard version; apply requires exact target repo proof. |
| CASS/socraticode index version differs | Historical search may miss patterns or mix incompatible embeddings. | Treat CASS as historical evidence only; report index freshness and indexed chunks before drawing cross-session conclusions. |
| Watchtower schemas evolve | Codex/Jeff source statuses may not join cleanly to report fields. | Require source watchtowers to emit versioned summaries and migration adapters before conductor consumes new fields. |

## Three-Judges Lens

**Jeff:** Would accept the direction if Phase 4 makes contracts executable:
doctor/health/repair, idempotency keys, append-only ledgers, lock ownership,
fixtures, and schema migration tests. Would reject a dashboard-only conductor.

**Donella:** The key stocks are sessions observed, missions mapped, drift events,
intervention success rate, Joshua-notice debt, Joshua time saved, autonomous
decisions, and accretive sources integrated. The highest leverage point is rules
and information flow: every session emits comparable truth and every Joshua ask
is classified as FLAG/INPUT/QUALITY.

**Josh:** The useful product is not "more telemetry." It is time back. Reports
must be evidence-grounded, first-person operator voice, and taste-gated; conductor
should catch fleet errors before Joshua notices them and only bring him founded
steer moments.

## v2/v3 Amendment Absorption

Lane B now treats the amendment as load-bearing:

- Self-supporting substrate: conductor reports and intervenes without requiring
  Joshua as daily driver.
- Joshua intervention modes: only `FLAG`, `INPUT`, and `QUALITY`.
- Reports: daily, weekly, and milestone, in ZestStream voice, receipt-grounded,
  and Three-Judges scored.
- MVP/demo readiness: self-grade Three Judges 7/7 plus publishability before
  surfacing, or label as `pre_bar` with rationale.
- Continuous landscape ingestion: Donella, Jeff, arXiv, Anthropic, OpenAI,
  DeepMind, xAI, Mistral, Tesla, SpaceX, Stripe, Vercel, Andreessen, Altman,
  and Collison source lanes.
- Metrics: `joshua_notice_debt`, `joshua_time_saved_per_week`,
  `source_freshness_breach_count`, `source_signal_no_destination_count`,
  `industry_pattern_missing_locally_count`, and
  `local_pattern_deprecated_by_landscape_count`.

## Fleet-Native vs Session-Local Verdict

Fleet-native now:
- `/flywheel:fleet-doctor`
- `/flywheel:jeff-status`
- `/flywheel:upgrade` dry-run view
- Agent Mail identity registry / fleet-mail project
- Jeff intel/watchtower surfaces
- Codex watchtower
- leverage ceiling probe
- gap-hunt ledger

Session-local or transitional:
- `flywheel-loop doctor --repo`
- daily report generator
- mobile-eats receipt bridge
- frozen-pane detector v2 unless run with `--session=all`
- watcher v4 scripts
- workforce-supervision mesh until Layer 1/2 signals ship
- `br`, `dcg`, `cass` surfaces

## Open Gaps For Lane C

1. Define the conductor's authoritative session roster: `ntm` discovered sessions,
   `session-topology.jsonl`, fleet roster, or a merged state with conflict rules.
2. Define the `joshua_notice_debt` ledger schema and which failures count as
   Joshua-noticed vs conductor-caught.
3. Decide whether conductor owns report generation or only supplies a fleet JSON
   input to `daily-report.sh`.
4. Define exact intervention classes allowed before workforce-supervision ships:
   likely read-only alerting and cross-session request packets only.
5. Define version-drift thresholds that are warning vs fail gates.
6. Define the landscape source registry schema and whether each source is owned
   by `info-source-watchtower` children or by a conductor-native source runner.
7. Define Three-Judges/publishability self-grade receipt shape for `QUALITY`
   asks.
8. Define how `joshua_time_saved_per_week` is estimated without inflated credit.

## Three-Q Audit

- VALIDATED: claims about existing local surfaces cite command docs, README,
  AGENTS doctrine, tests, scripts, Jeff corpus line references, or official
  source URLs for v3 landscape lanes.
- DOCUMENTED: this Lane B artifact distinguishes existing coverage, substrate
  import patterns, external analogs, and drift impacts.
- SURFACED: gaps are phrased for Lane C implementation design and Phase 4 bead
  decomposition; no source or settings files were modified.

## Ladder Check

did=6/6
didnt=none
gaps=none
ladder_passed=yes
intent_amendment_absorbed=yes

Read-only discipline: pass. Only this plan-space artifact was written.
