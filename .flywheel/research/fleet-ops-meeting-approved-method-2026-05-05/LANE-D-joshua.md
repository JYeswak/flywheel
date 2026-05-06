# LANE D — Joshua's Flywheel Substrate Inventory (Fleet Ops Meeting Research)

Lane: D (Joshua's own substrate)
Author: research lane D
Generated: 2026-05-05
Output anchor: `/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md`
Sister lanes (parallel): A (Donella), B (Jeff Emanuel), C (Anthropic / Claude Code)
Mission of survey: enumerate every existing piece of substrate that already touches daily-ops / fleet-coordination / status-rollup / check-in / observability so the eventual `/flywheel:plan` does NOT reinvent existing pieces.

---

## 1. Method

### Path verification (`test -d`)

```
EXISTS: /Users/josh/Developer/flywheel
EXISTS: /Users/josh/Developer/skillos
EXISTS: /Users/josh/Developer/mobile-eats
EXISTS: /Users/josh/Developer/alpsinsurance
EXISTS: /Users/josh/Developer/vrtx
```

All five repos are local. No skip notes.

### Socraticode queries executed

Flywheel repo (10 queries, K≥10 each, projectPath `/Users/josh/Developer/flywheel`):

| # | Query | Hits | Top file |
|---|-------|------|----------|
| 1 | "daily ops meeting fleet check-in protocol" | 10 | `AGENTS.md L104` (FLEET-COMMS-MEASURED-NOT-ASSUMED) |
| 2 | "cross-orchestrator status rollup aggregator" | 10 | `tests/cross-repo-trauma-aggregator.sh` |
| 3 | "fleet observatory architecture-health rollup" | 10 | `AGENTS.md L98` + `architecture-health-rollup.sh` |
| 4 | "bead velocity composite score per-orch metric" | 10 | `tests/fleet-observatory-aggregate.sh` (composite) |
| 5 | "handoff EOD end of day session schema" | 10 | `tests/phase2-audit.sh` (runtime_handoff schema) |
| 6 | "peer orchestrator cross-fleet escalation broadcast" | 10 | `AGENTS.md L75/L115` |
| 7 | "L70 punt counter mission anchor drift" | 10 | `tests/l70-ticks-punted-counter.sh` |
| 8 | "tick driver loop schedule periodic" | 10 | `AGENTS.md L116` (`flywheel-tick-driver`) |
| 9 | "daily-report aggregator beads closed shipped per repo" | 10 | `AGENTS.md L77` + `daily-report.sh` |
| 10 | "team pulse roster fleet roster identity" | 10 | `tests/state-md-miner.sh` (fleet-roster.json) |

Sister repos (5 queries, K≥5 each):

| Repo | Query | Hits |
|------|-------|------|
| skillos | "handoff EOD reboot recovery schema sections" | 5 |
| skillos | "skill pack lifecycle ladder candidate gated promoted" | 5 |
| mobile-eats | "publishability bar canary owner Nango" | 5 |
| alpsinsurance | "mike daily report client deliverable status" | 5 |
| vrtx | "vrtx mission client deliverable orchestrator" | 5 |

### Counters (final)

```
socraticode_queries=15
indexed_chunks_observed≈140 (10 query × 10 hits flywheel + 5 query × 5 hits sister)
grep_sweeps=6 (AGENTS-CANONICAL L-rules, AGENTS.md L-rules, INCIDENTS sections,
               handoff section-headers intersection, ledger row counts,
               launchctl plist load-state)
```

### Grep / find sweeps

- `grep -nE '^## L[0-9]+ —' /Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` → 66 L-rule headings
- Same on `/Users/josh/Developer/flywheel/AGENTS.md` → 66 L-rule headings
- Same on `/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md` → 65 L-rule headings (template intentionally trails the live AGENTS by 1)
- `find` on `~/Library/LaunchAgents` → 39 com.flywheel.* / ai.zeststream.* plists; 7 currently loaded with PID per `launchctl list`
- `~/.local/state/flywheel/*.jsonl` → 61 JSONL ledgers
- `find /Users/josh/Developer/flywheel -maxdepth 3 -name INCIDENTS.md` → 1 root file (681 lines, 23 entries)

---

## 2. Existing fleet-coordination skills + slash-commands inventory

### Slash commands (under `~/.claude/commands/flywheel/`)

| Command | File | Trigger | Inputs | Outputs | Daily-ops overlap | Gap |
|---|---|---|---|---|---|---|
| `/flywheel:status` | `status.md:1-223` | "what's happening?" | doctor JSON, robot-activity, dispatch-log, fuckup-log | one-screen ≤500-token dashboard with 13 named compact lines (Identities, Leverage, Gaps, Watchers, Fleet productivity, Fleet conformance, Fleet comms, Fleet process, Recovery SLO, Architecture Health, Hidden gates, Beads, Learning signals) | **HIGH overlap** — already aggregates 10+ measurement spines into one tactical view. Read-only. Per-session, NOT cross-session today (it picks one session via `cwd` heuristic at `status.md:12-15`). | No structured cross-orch rollup; no comparison or trend; no daily-cadence write surface. |
| `/flywheel:fleet-observatory` | `fleet-observatory.md:1-50` | strategic step-back | reads `fleet-observatory-aggregate.sh` 60s-cached doctor JSON | `fleet_overall_health_score` (0-100), `status`, 8 spine objects, `worst_spine`, `worst_session`, `top_process_gaps`, `recommended_action`. Threshold ≥85 green / 60-84 yellow / <60 red per L106 (`AGENTS.md:2829`). | **HIGHEST overlap** — already the "single number" strategic command-center view. Has `--watch=30s` live mode. | One number for one moment in time. No daily/weekly history surface; no Joshua narrative. |
| `/flywheel:fleet-doctor` | `fleet-doctor.md` (file present) | repo-level deep doctor | calls `flywheel-loop doctor --repo …` | doctor JSON | Tactical, single-repo. | Not a fleet rollup. |
| `/flywheel:fleet-conductor` | `fleet-conductor.md:1-13` | MVP-gate before surfacing artifact | `--mvp-gate <session>:<artifact>` consumes 4-lens validator | conductor decision | Used at artifact-surface time, not daily ops. | Not a meeting protocol. |
| `/flywheel:daily-report` | `daily-report.md:1-79` | scheduled (launchd) + on-demand | repo cwd, today's date | `<repo>/.flywheel/reports/daily-YYYY-MM-DD.md` with 6 fixed sections: 1.Shipped 2.Learned 3.Jeff 4.Stuck 5.Next 6.Cross-orch state | **HIGH overlap** — repo-local daily narrative. L77 (`AGENTS.md:1455`) makes this the canonical synthesis surface. Doctor fails when latest > 36h. | Per-repo, NOT fleet-rollup. No cross-repo aggregation; no peer-review section. |
| `/flywheel:tick` | `tick.md` | each tick (self-paced or launchd) | full pipeline | tick-driver ledger row | Operational glue, runs every cadence (5min via `com.flywheel.tick.plist`). | Tick is HIGH frequency — not a daily-ops cadence. |
| `/flywheel:synth` | `synth.md:1-69` | end-of-window digest | inbox, dispatch-log, research-log, bead diff, git log | `<repo>/.flywheel/digests/<iso-date>-<HHMM>.md` with **Decisions Joshua needs to make** (mandatory section), What changed, Still open, Worth knowing, Suggested next | **HIGH overlap** — already the "what to surface to Joshua" digest. Auto-runs as part of `/flywheel:handoff`. | Per-repo and ad-hoc; no daily fleet cadence. |
| `/flywheel:handoff` | `handoff.md:1-223` | session pause | `/flywheel:synth` first, then per-section capture | `<repo>/.flywheel/handoffs/<iso-date>-<HHMM>-<reason>.md` + STATE.md pointer + agent-mail broadcast + CASS PreCompact cache (`handoff.md:99-189`) | **MAX overlap** — handoff schema is the closest thing to canonical ops-meeting schema. v0.4 PRIME RULE: orchestrator-only, workers don't halt (`handoff.md:8-16`). | Per-repo and event-driven (session pause), not a daily synchronized fleet event. |
| `/flywheel:inbox` | `inbox.md` | unread messages | agent-mail | rendered inbox | Tactical. | Not ops-meeting. |
| `/flywheel:tail` | `tail.md` | catch up on a worker | pane scrollback | summary | Tactical. | Not ops-meeting. |
| `/flywheel:learn` | `learn.md` | promotion review | fuckup-log, doctor candidates | promoted classes | Reviews learning state. Quarterly+ flavor. | Not daily. |
| `/flywheel:research` | `research.md` | spawn research dispatch | topic | research callback file | Operational. | N/A. |
| `/flywheel:weeklyreflection` | `weeklyreflection.md` | weekly cadence | full week of artifacts | reflection doc | **Cadence overlap** — already a weekly surface. L98 mandates `learning_loop_closed=yes|no` field. | Not daily; not cross-orch synchronized. |
| `/flywheel:plan` | `plan.md` | new plan | mission anchor | plan + bead graph | Plan space, not ops. | N/A. |
| `/flywheel:respawn` | `respawn.md` | dead pane | topology | respawned pane | Tactical recovery. | N/A. |
| `/flywheel:recovery` | `recovery.md` | resume after compact | last handoff + STATE | restored context | Recovery, not meeting. | N/A. |

### Skills (under `~/.claude/skills/`) touching daily-ops/fleet-coord

| Skill | Daily-ops overlap | Gap |
|---|---|---|
| `flywheel-end-to-end` | Canonical 7-phase mission→shipped pipeline; multi-pane author-redteam-audit-rework cycle. Project memory: `project_flywheel_e2e_skill_2026_05_02.md` confirms 2,228 lines / 8 files. | Pipeline doctrine, not meeting cadence. |
| `agent-fleet-management` | Listed at `~/.claude/skills/agent-fleet-management/`. | Not yet inspected; per inventory present. |
| `agent-monitoring` | Listed. Telemetry framing for live agent dashboards. | Not bound to flywheel canonical surfaces. |
| `agent-evaluation` | Listed. Per-agent scoring framing — **dangerous** vs L98 architecture-health frame (`AGENTS.md:2407`). | Risks Goodhart drift if used naively. |
| `agent-orchestration` | Listed. Orchestrator playbook. | Generic; flywheel doctrine is more specific. |
| `multi-agent-swarm-workflow` | Listed. Swarm pattern. | Generic. |
| `swarm-operator-loop` | Listed. The operator pane loop primitive. | Tactical not meeting. |
| `flywheel-recovery` | Listed. Reboot/compact recovery pattern. | Recovery, not ops cadence. |
| `accretive-cron-orchestration` | Listed. Locked rule per memory: cron substrate accretes via canonical paths. | Cadence-adjacent; could host the meeting plist. |
| `living-documentation` | Listed. Substrate that updates with every artifact. | L96 (3-surface diff) lives here in spirit. |
| `donella-meadows-systems-thinking` | Listed. Lane A's anchor. | N/A for D. |
| `flywheel` | Top-level skill. | Pointer/hub. |

**Net read on §2:** ops-meeting concerns are *mostly* solved tactically (`/flywheel:status`, `/flywheel:fleet-observatory`) and event-driven (`/flywheel:handoff`, `/flywheel:synth`). What is missing is a **daily synchronized fleet cadence + cross-orch peer-review surface + bidirectional Joshua check-in artifact**.

---

## 3. Existing scripts inventory

### `~/.local/bin/flywheel-*` (8 binaries)

| Path | One-line purpose | Daily-ops touch | Schema/output |
|---|---|---|---|
| `flywheel-fleet-shutdown` | Reboot prep + recovery manifest | YES (event-driven, not cadence) | `fleet-shutdown-recovery.v1` JSON manifests under `.flywheel/reboot-recovery/<iso>/` |
| `flywheel-loop` | Canonical doctor / tick / validate-callback / fuckup-list CLI | YES (every command rolls up via doctor JSON) | `flywheel-loop doctor --json` is the universal data plane |
| `flywheel-readme` | README assert/render | NO | text |
| `flywheel-resume` | Post-compact resume helper | NO (recovery) | text |
| `flywheel-tick-driver` | Launchd tick driver | YES (every 300s per `com.flywheel.tick.plist`) | `~/.local/state/flywheel/tick-driver.jsonl` rows (`tick-driver-manifest.v1`) |
| `flywheel-toolset-parity` | Toolset parity probe | INDIRECT | parity JSON |
| `flywheel-watchers` | Watcher inventory probe | YES (fleet-watcher-coverage-probe sibling) | watcher coverage JSON |

### `/Users/josh/Developer/flywheel/.flywheel/scripts/` (selected high-relevance, full list 100+)

| Script | Purpose | Ops-meeting touch | Output |
|---|---|---|---|
| `architecture-health-rollup.sh` | L98 24h/7d/30d/90d rollup | **YES — daily/weekly cadence native** | `~/.flywheel/fleet-perf/{24h,7d,30d,90d}.json` |
| `fleet-observatory-aggregate.sh` | 8-spine composite | **YES — strategic ops view** | `fleet_overall_health_score` (0-100) JSON |
| `fleet-conformance-probe.sh` | L103 per-session conformance | YES | green/yellow/red per session |
| `fleet-comms-health-probe.sh` | L104 comms (token freshness, packet age, unread escalations) | YES | `fleet_comms_health` JSON, `--apply` sends `COMMS_HEALTH_PING` |
| `fleet-process-gap-detector.sh` | L105 process-class auto-route | YES | `fleet_process_gap_detector/v1` |
| `peer-orch-productivity-watch.sh` | L101 idle-with-work | YES | `peer_orch_productivity_total_count`, `peer_orch_idle_with_work_available_count`, `peer_orch_substrate_blocked_count` |
| `peer-orch-blocker-watch.sh` | L75 blocker-coordination probe | YES | rows from `cross-orch-coordination.jsonl` aged > 300s |
| `peer-orch-respawn-permit.sh` | L115 recovery permit gate | EVENT (not cadence) | permit/refuse decision JSON |
| `peer-orch-freeze-monitor.sh` | L117 freeze-monitor driver | EVENT | mttr_p95, false_recovery_count |
| `recovery-slo-probe.sh` | L99 180s recovery SLO | YES | p50/p95 latency, breach count |
| `daily-report.sh` / `daily-report.py` | L77 narrative report | **YES** | `<repo>/.flywheel/reports/daily-<date>.md` (6 sections) |
| `daily-report-enabled-repos.sh` | iterates daily-report-config.json `{enabled:true}` repos | **YES** | aggregated daily-report run |
| `cross-repo-trauma-aggregator.sh` | trauma-class roll-up across repos | YES | top trauma classes / repo counts |
| `fleet-canonical-rule-freshness-probe.sh` | L102/L108 META-RULE freshness | YES | `lag_seconds` per session |
| `fleet-l-rule-lag-probe.sh` | L-rule cross-repo lag | YES | `fleet_repo_l_rule_lag_count` |
| `agents-md-fleet-propagator.sh` | propagate AGENTS.md changes | YES (tick) | `~/.local/state/flywheel/agents-md-fleet-propagation.jsonl` (79 rows) |
| `tick-driver-manifest.json` | what runs on tick | structural | manifest |
| `tick-hook-firing-verifier.sh` | pbt55 invisible-break detector | YES | per-primitive `last_fired_ts` |
| `l70-ticks-punted-counter.sh` | gqoz L70 ORCH-NO-PUNT counter | **YES — direct meeting metric** | `l70_ticks_punted_24h` |
| `mission-lock-age-probe.sh` | mission-lock drift | YES | mission-lock age / drift status |
| `mission-anchor-dispatch-license.sh` | dispatch license per mission | structural | license JSON |
| `leverage-ceiling-probe.sh` | leverage binding+score | YES | `~/.local/state/flywheel/leverage-ceiling.jsonl` |
| `gap-hunt-probe.sh` | structural gap finder | YES | `~/.local/state/flywheel/gap-hunt.jsonl` (871KB, heavy) |
| `value-gap-probe.sh` | leverage gap | YES | `value-gap-probe.jsonl` |
| `mobile-eats-receipt-bridge.sh` | mobile-eats publishability dashboard line | YES (per-repo specialization) | dashboard line |
| `skillos-relay-tail.sh` / `skillos-routed-tail.sh` | skillos lifecycle tail | YES (per-repo specialization) | relay rows |
| `state-md-miner.sh` | mine STATE.md across roster | YES | `state-md-miner/v1` findings |
| `roster-register.sh` | fleet-roster.json maintenance | structural | roster |
| `fleet-watcher-coverage-probe.sh` | which sessions have idle watchers | YES | `fleet_watcher_coverage_count`/`_total` |
| `frozen-pane-detector{,-fleet}.sh` | v2 detector | EVENT | hash-diff freeze detection |
| `stale-error-auto-ping.sh` | L87 recovery ping | EVENT | `headless-browser-reaps.jsonl` sibling |
| `stale-in-progress-reaper.sh` | reaping aged in-progress beads | YES | reap count |
| `validate-callback-before-close.sh` / `validate-callback.py` | L71 4-lens close-validator | YES | validation receipts under `.flywheel/validation-receipts/<task>.json` |
| `closed-bead-artifact-scan.py` | L80 closed-bead audit-mining | YES | audit-gap beads |
| `bead-quality-mining.sh` | bead-quality miner | YES | mining JSONL |
| `josh-request-tick-promote.sh` + `josh-requests-jsonl-init.sh` | Joshua-request-capture inflow surface | **HIGH — bidirectional Joshua channel** | `~/.local/state/flywheel/josh-requests.jsonl` |
| `quality-bar-close-gate.sh` | L111 3-judges close gate | YES | gate decision |
| `callback-envelope-schema-validator.sh` | L111 7-field envelope check | YES | validation receipt |
| `auto-l112-gate.sh` | L112 callback-time gate | YES | `auto-l112-gate-ledger.jsonl` |
| `publishability-bar.sh` | L88/L89 readiness probe (currently missing per alps reboot handoff line 49 — noted) | YES | `publishability_bar_score` object |
| `worker-slot-ledger.sh` / `worker-stall-alert-probe.sh` / `worker-lifecycle-transaction.sh` | worker capacity instrumentation | YES | worker-slot rows |
| `idle-pane-auto-dispatch.sh` + `idle-state-probe.sh` | L85 idle-state-class | YES | idle dispatch ledger |

### Launchd plists (`~/Library/LaunchAgents/com.flywheel.* + ai.zeststream.*`)

39 plists exist. `launchctl list | grep -E "flywheel|zeststream"` shows 39 entries with status. Currently LOADED with PID (live):

| Plist | PID | Schedule (per filename / convention) | Produces |
|---|---|---|---|
| `com.flywheel.tick.plist` | 4167 | `StartInterval 300` (5min) per L116 (`AGENTS.md:3271`) | `tick-driver.jsonl` rows; runs full tick-driver-manifest.json primitives |
| `ai.zeststream.mcp-agent-mail-local.plist` | 43934 | persistent | Agent Mail HTTP service |
| `ai.zeststream.skillos-flywheel-loop.plist` | 44523 | tick-driven | skillos session loop driver |
| `ai.zeststream.alps-flywheel-loop.plist` | (loaded, no PID = recently fired) | per-session | alps loop driver |
| `ai.zeststream.mobile-eats-flywheel-loop.plist` | (loaded) | per-session | mobile-eats loop driver |
| `ai.zeststream.frozen-pane-detector-fleet.plist` | (present, may be disabled-by-default per `frozen-pane-detector-fleet.sh` STOP/FATAL gate) | fleet-wide |
| `ai.zeststream.canonical-meta-rules-sync-watchdog.plist` | (loaded) | watchdog | `canonical-meta-rules-watchdog.jsonl` (57KB) |
| `ai.zeststream.codex-watchtower-daily.plist` | (loaded) | daily | `codex-watchtower-daily.sh` summary |
| `ai.zeststream.skillos-idle-pane-watch.plist` / `mobile-eats-idle-pane-watch.plist` / `vrtx-idle-pane-watch.plist` / `alps-idle-pane-watch.plist` | (loaded) | per-session | `idle-pane-auto-dispatch-<session>.log` |
| `ai.zeststream.ntm-fleet-health.plist` | (loaded) | periodic | `ntm-fleet-health.jsonl` |
| `ai.zeststream.flywheel-daily-report.plist` (referenced in `daily-report.md:67-69`, `tests/daily-report.sh:71`) | (referenced) | once daily | runs `daily-report-enabled-repos.sh` |

**Notable absence:** there is NO `ai.zeststream.fleet-ops-meeting.plist`. There is no `ai.zeststream.fleet-observatory-aggregate.plist` running on a daily cadence (`fleet-observatory-aggregate.sh` is invoked on-demand by `/flywheel:fleet-observatory` only).

---

## 4. Existing ledgers + state files

`~/.local/state/flywheel/` JSONL ledgers (61 total). Required-list inspection:

| Ledger | Schema (jq sample) | Tracks | Rows | Last write |
|---|---|---|---|---|
| `dispatch-log.jsonl` | per-repo only at `<repo>/.flywheel/dispatch-log.jsonl`; **NOT** in `~/.local/state/flywheel/` | every dispatch + callback + event row, schema includes `ts, session, pane, task_id, task_summary, event=callback_received, callback_status, skills_consulted` (test fixture `tests/architecture-health-rollup.sh:30-36`) | per-repo (~tens to hundreds) | per-repo |
| `cross-orch-coordination.jsonl` | rows include `ts, session, pane, blocker_type ∈ {flywheel_class, peer_class, external, unknown}, blocker_class, requested_owner, proposed_action, flywheel_orch_action_required` (`AGENTS.md L75:1361` schema) | cross-orch escalation packets | **88** | 2026-05-04T23:38Z |
| `tick-driver.jsonl` | `tick-driver-manifest.v1` rows: `primitive_count, ok_count, timeout_count, error_count, status` (`tests/flywheel-tick-driver.sh:115-117`) | every 5min tick fire | **10** | 2026-05-05T00:11Z |
| `codex-stuck-detector.jsonl` | `codex-stuck-detector.fixture.v1` per-pane: `session, pane, t0, t1, send_ack, after_retry, subclass_hint ∈ {buffer_stuck, input_deaf, post_completion}` (`tests/codex-template-stuck-detector.sh:24-45`) | per-pane stuck classification | **121** | 2026-05-05T00:11Z |
| `peer-orch-recovery.jsonl` | rows from L115 recovery permit gate, write occurs after `--apply` | peer-orch recoveries | **1** | 2026-05-04T23:21Z |
| `l70-ticks-punted.jsonl` | `l70-ticks-punted/v1`: `tick_id, punted, reason ∈ {no_ready_p0_p1_work, no_idle_worker_capacity, dispatched, …}` (`tests/l70-ticks-punted-counter.sh:60-95`) | every tick where orch should have dispatched but punted | **15** | 2026-05-05T00:09Z |
| `storage-headroom-watcher.jsonl` | recurring storage probe row | storage prune events | **16** | 2026-05-05T00:09Z |
| `agents-md-fleet-propagation.jsonl` | propagator row per fleet-AGENTS sync | fleet-wide AGENTS.md propagation | **79** | 2026-05-05T00:10Z |
| `fuckup-log.jsonl` | `ts, session, pane, trauma_class, severity ∈ {low, medium, high}, what_happened, evidence` (canonical) | every trauma-class observation | **798** | 2026-05-05T00:10Z |
| `session-topology.jsonl` | rows: `session, orchestrator_pane, worker_panes[], worker_kinds, project_key, effective_at, callback_pane?` (per `README.md:206-211`) | append-only, latest-by-effective_at | **22** | 2026-05-04T12:12Z |

Other directly relevant ledgers under `~/.local/state/flywheel/`:

| Ledger | What it tracks | Bytes |
|---|---|---|
| `auto-l112-gate-ledger.jsonl` | L112 callback gate | ~19 KB |
| `bak-quarantine-ledger.jsonl` | quarantined `.bak.*` files | ~10 KB |
| `canonical-meta-rules-watchdog.jsonl` | meta-rule watchdog firings | ~57 KB |
| `cass-v2-sustained-validation.jsonl` | cass-v2 validation runs | ~10 KB |
| `daily-jeff-ingest.jsonl` | daily Jeff repo ingest | ~3 KB |
| `doctrine-sync-ledger.jsonl` | doctrine-sync events (apply or sync) | ~219 KB (heavy) |
| `file-reservations.jsonl` | shared-surface file-reservation locks | ~15 KB |
| `flywheel-refresh-source.apply-ledger.jsonl` | source-refresh applications | ~3.6 KB |
| `gap-hunt.jsonl` | every structural-gap probe finding | ~871 KB (very heavy) |
| `gap-hunt-false-positives.jsonl` | filtered classes | ~3 KB |
| `halt-disease-watchdog.jsonl` | halt-disease | ~21 KB |
| `headless-browser-reaps.jsonl` | L73 leak doctor | ~414 B |
| `identity-tokens.jsonl` | identity-tuple registry | ~13 KB |
| `jeff-binary-version-watchtower.jsonl` | 7-binary Jeff substrate version drift | small |
| `jeff-issues.jsonl` + `.audit.jsonl` | Jeff-issue submissions | small |
| `jeff-substrate-upgrades.jsonl` | substrate upgrades log | small |
| `josh-requests.jsonl` + `josh-requests-audit.jsonl` | Joshua-request capture | small (canonical Joshua→fleet inflow) |
| `launchctl-guard-ledger.jsonl` | plist guard events | small |
| `leverage-ceiling.jsonl` | leverage ceiling probe rows | small |
| `mission-anchor-license-ledger.jsonl` | mission-anchor dispatch license | small |
| `ntm-fleet-health.jsonl` | NTM fleet-health probe | small |
| `orphan-disposition-ledger.jsonl` | orphan handling | small |
| `pane-work-signal.jsonl` | per-pane work-signal probe | small |
| `parked-scripts-disposition-ledger.jsonl` | quarantined scripts | small |
| `peer-orch-freeze-monitor.jsonl` | L117 freeze monitor | small |
| `plist-allowlist.jsonl` + `plist-registry.jsonl` | launchd governance | small |
| `recovery-drill.jsonl` | kill-recover drills | small |
| `resume-log.jsonl` | resume events | small |
| `skill-discoveries.jsonl` | skill discovery events | small |
| `skillos-pending-candidates.jsonl` + `skillos-relay-{ledger,soft-violations,agents-hash}.jsonl` + `skillos-routed.jsonl` | skillos lifecycle ladder rows | small |
| `storage-history.jsonl` + `storage-prune-ledger.jsonl` | storage history | small |
| `substrate-loop-contract.jsonl` | L110 self-repair-loop contracts | small |
| `substrate-registry.jsonl` | registered substrate primitives | small |
| `substrate-tuning.jsonl` | substrate tuning events | small |
| `team-pulse.jsonl` + `team-roster.jsonl` | **fleet team pulse** (canonical roster + pulse rows) | small — direct ops-meeting attendance/identity ledger |
| `tick-hook-firing-audit.jsonl` | tick-hook audit (pbt55 sibling) | small |
| `trauma-class-trend.jsonl` | trauma-class trend rollup | small |
| `value-gap-probe.jsonl` | leverage value-gap rows | small |
| `watcher-control-ledger.jsonl` + `watcher-tuning-ledger.jsonl` | watcher governance | small |

`~/.flywheel/` (separate dir) state:

| Path | Contents |
|---|---|
| `~/.flywheel/loops/<session>.json` | per-session loop config (flywheel.json, skillos.json, mobile-eats.json, alpsinsurance.json, vrtx.json) |
| `~/.flywheel/fleet-perf/{24h,7d,30d,90d}.json` | architecture-health rollup outputs (L98) |
| `~/.flywheel/canonical-meta-rules/INDEX.md` + `sync.sh` | canonical META-RULE bundle synced into per-repo `<repo>/.flywheel/META-RULE-CACHE.md` per L102 |
| `~/.flywheel/global-trauma-log.jsonl` | global trauma log (1.2 KB) |
| `~/.flywheel/mem/` | CASS PreCompact cache + handoff-cache writes per `handoff.md:120-187` |
| `~/.flywheel/recovery/` | recovery-drill artifacts |

**Net read on §4:** the substrate ALREADY has the ledger primitives a daily-ops meeting needs. What is missing is the **synthesizer that consumes them on a daily synchronized cadence and emits a single canonical artifact**.

---

## 5. Existing AGENTS / doctrine surfaces

### `/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` (3,380 lines, 66 L-rule headings)

Confirmed by `grep -nE '^## L[0-9]+ —'`. Numbering is non-contiguous (jumps L29, L35, then runs L48 → L117 with gaps at L74, L109, L112-L114).

Per L-rule (D = daily-ops/fleet-coord touch; M = mission-anchor; S = strategic; ✓ = direct ops-meeting relevance):

| L# | Title | Touch |
|---|---|---|
| L29 | NTM-only doctrine | D ✓ (transport boundary for any meeting comms) |
| L35 | Tier 3 paired-tool bead | — |
| L48 | Substrate-exhaustion before escalation | D (decide-locally rule) |
| L50 | Socraticode mandatory in every dispatch | — (dispatch hygiene) |
| L51 | Dispatch file reservations mandatory | — |
| L52 | Issues-to-beads or explicit no-bead receipt | D ✓ (every meeting finding routes here) |
| L53 | Fuckups reported in callback | D |
| L54 | Skill deep-dive on blockers | — |
| L55 | Skillos escalation for missing skills | — |
| L56 | Fuckup-log → INCIDENTS → canonical L-rule promotion ladder | D ✓ (learning loop closer) |
| L57 | Loop-state marker not driver | D ✓ (driver-truth check) |
| L58 | Secret material never in pane text | D ✓ (any rolled-up artifact must respect) |
| L59 | Reconcile-script postcheck step | — |
| L60 | Loop integrity 5-signal contract | D ✓ (canonical doctor signals) |
| L61 | Doctrine landing wires into AGENTS and README | D ✓ (any new ops-meeting doctrine) |
| L62 | STATE.md is latent opportunity substrate | D ✓ (state-md-miner already reads roster) |
| L63 | Jeff-intel network is canonical substrate dependency | — |
| L64 | Jeff is mentor not just dependency | — |
| L65 | CLI-identity beats command name | — |
| L66 | Outbound Jeff issues use phased command gate | — |
| L67 | Truth-source must be live not cached | D ✓ (capture provenance for any rollup) |
| L68 | No-silent-darkness goal contract | D ✓ (mission-anchor must be visible in meeting) |
| L69 | Orch probe agent context | — |
| L70 | ORCH-NO-PUNT (next actionable runs same tick) | **D ✓ ✓** — direct ops-meeting metric (`l70-ticks-punted-counter.sh` + `l70-ticks-punted.jsonl`) |
| L71 | Validate-and-redispatch discipline | D ✓ (every claim is unvalidated until a receipt) |
| L72 | Storage discipline system-wide | D |
| L73 | Headless-browser orphan-leak doctor | — |
| L75 | Orch-blocker coordination (5min rule + ledger) | **D ✓ ✓** — cross-orch ops-meeting escalation contract |
| L76 | AgentMail identity canonical | D ✓ (identity layer for cross-orch) |
| L77 | Daily-report learning rollup | **D ✓ ✓** — closest existing daily cadence rule |
| L78 | Jeff-corpus accretive ingestion | — |
| L79 | Storage-override receipts mechanical | — |
| L80 | Closed-bead audit mining | D ✓ |
| L81 | Docs are load-bearing cross-pane validated | D ✓ |
| L82 | Canonical CLI scoping mandatory | D ✓ |
| L83 | File-length discipline fleet-wide | — |
| L84 | Locked worker identities canonical | D ✓ |
| L85 | Idle-state class canonical | D ✓ |
| L86 | Cross-session callback receiver must be live | D ✓ |
| L87 | Stale-error text auto-ping recovery | D |
| L88 | Publishability bar canonical (3-judges) | D ✓ |
| L89 | ZestStream voice public-repo canonical | D ✓ (voice gate for any public-facing meeting artifact) |
| L90 | Pane-action plan requires live capture | D ✓ |
| L91 | Dispatch delivery is a 4-state receipt | D ✓ |
| L92 | Audit-findings route by data | D ✓ |
| L93 | Jeff-issue requires workaround-research first | — |
| L94 | Shared-sqlite writes must serialize | — |
| L95 | Worker-stall recovery protocol | D |
| L96 | Doctrine lands as 3-surface diff or does not land | **D ✓ ✓** — propagation contract |
| L97 | Orch dispatches only to known workers | D ✓ |
| L98 | **Architecture-health measured not individuals** | **D ✓ ✓ ✓** — paradigm anchor for the meeting |
| L99 | Worker-recovery SLO 180s | D ✓ |
| L100 | Identity primary key is session-pane-project | D ✓ |
| L101 | **Flywheel owns continuous fleet productivity** | **D ✓ ✓ ✓** — direct meeting agenda item |
| L102 | META-RULE cache must refresh on tick | D ✓ |
| L103 | **Fleet conformance score is the gate** | **D ✓ ✓ ✓** — primary fleet health gate |
| L104 | **Fleet comms measured not assumed** | **D ✓ ✓ ✓** — comms-line liveness measurement |
| L105 | **Process gaps are measured and auto-routed** | **D ✓ ✓** |
| L106 | **Fleet health is a single number aggregated from 8 spines** | **D ✓ ✓ ✓** — canonical "one number" for the meeting |
| L107 | Shared-surface writes must reserve across panes | — |
| L108 | META-RULE cache is cache not convergence gate | — |
| L110 | Substrate primitives declare self-repair loop | D ✓ |
| L111 | Real-time quality bar on every work body (3-judges + 4-skill) | D ✓ |
| L115 | Peer-orch recovery permit gate | D ✓ |
| L116 | Tick is process not document | D ✓ |
| L117 | Peer-orch freeze monitor is a driver | D ✓ |

### `/Users/josh/Developer/flywheel/AGENTS.md` (3,331 lines, 66 L-rule headings)

Same numbering. Confirmed via grep. Verified line counts:
- `wc -l AGENTS-CANONICAL.md` = 3380
- `wc -l AGENTS.md` = 3331
- `wc -l templates/flywheel-install/AGENTS.md` = 3206 (65 L-rule headings — trails by L116/L117)

The AGENTS-CANONICAL ↔ AGENTS root differ by 49 lines (header / branding / cross-ref nuances); they share the same L-rule corpus per spot-check. Per L96, doctrine landing requires a 3-surface diff (root AGENTS, install template AGENTS, README) — the install template currently lacks L116 and L117.

### `~/.claude/CLAUDE.md` axioms (per global instructions §6)

| # | Axiom | Petal |
|---|---|---|
| 1 | Flywheel is Sacred | ALL |
| 2 | Planning-First, Beads-Centric | 1-6 |
| 3 | Avoid Overprompting | 9 |
| 4 | Cognitive Offloading | ALL |
| 5 | Taste is Human | 5,8 |
| 6 | Safety Defense-in-Depth | 5,8 |
| 7 | Recursive Self-Improvement | 9 |
| 8 | Accretive Leverage | 9 |
| 9 | Socraticode-First | 1,5,6,8 |
| 10 | Reliability-Invariant | 5,8,9 |
| 11 | Live API Truth | 3,5,6,9 |
| 12 | Phantom-Substrate Liveness | 5,8,9 |
| 22 | Research Before Propose (candidate, ratification deferred) | ALL |

(Listed corpus is 12 in active text + 1 candidate; the prompt frames "22" as a forward limit. Source: `~/.claude/CLAUDE.md` §6 table.)

### `/Users/josh/Developer/flywheel/INCIDENTS.md` (681 lines, 23 entries)

Section headers (each = a promoted trauma class):

1. corpus-dispatches-must-include-consumability-gate (2026-05-04, high)
2. Codex CLI 0.125.0 kitty-keyboard+tmux Enter drop #12645 (5+ strikes)
3. br dep add OpenRead after JSONL rebuild
4. autoloop-skip-instead-of-fix
5. agent-fighting-gate
6. repeat-gate-deny-dispatch_transport
7. orchestrator-idle-with-actionable-work
8. repeat-gate-deny-readiness
9. credential-substrate-truth-drift
10. orchestrator-observability-contract-bypass
11. test-data-in-fuckup-log
12. positive-event-misrouted-to-fuckup-log
13. skill-substrate-validation-drift
14. meat-puppet-orchestrator-decision-on-partial-state
15. bypass-canonical-substrate-cluster
16. cli-spec-without-canonical-cli-scoping-gate
17. jeff-watcher-false-positive-on-gh-auth-fail
18. orchestrator-substrate-blindness
19. documented-bug-not-actioned-self-recursion
20. mission-lock-drift-no-audit-trail
21. (additional 2026-05-03 surveillance pattern)
22. robot-mode-classification-disagreement
23. (Lacking surveillance pattern caused 6hr blackout 2026-05-03)

Several entries (especially 7, 14, 19) are direct ops-meeting failure-modes the protocol must prevent.

---

## 6. Existing handoffs sample → canonical schema basis

All four reference paths verified with `test -e` (output: `exists 1`, `exists 2`, `exists 3`, `exists 4`).

Section-header intersection matrix:

| Section | flywheel | skillos | mobile-eats | alps |
|---|---|---|---|---|
| `## Files Joshua needs to read on resume` | ✅ | — | — | ✅ |
| `## Resume context for next session` | ✅ | — | — | — |
| `## Resume Steps` / `## Resume sequence after reboot` | — | — | ✅ | ✅ |
| `## Immediate Resume` / `## Fresh Next Action` | — | ✅ | — | — |
| `## Pending decisions for Joshua` (or "at reboot") | ✅ | — | — | ✅ |
| `## In-flight dispatches (do NOT redispatch — running)` / `at reboot` | ✅ | — | — | ✅ |
| `## Last Known State` / `## State at reboot time` | — | ✅ | — | ✅ |
| `## Closed today (the haul)` | ✅ | — | — | — |
| `## Doctrine codified today` / `tonight (5 memories)` | ✅ | — | — | ✅ |
| `## Cross-orch resolution log` / `## Cross-orch updates sent` | ✅ | — | — | ✅ |
| `## Substrate gates LIVE at handoff` / `## Substrate concerns at reboot` | ✅ | — | — | ✅ |
| `## Memory rules added today` | ✅ | — | — | — |
| `## New canonical surfaces wired today` | ✅ | — | — | — |
| `## Hard rules carried forward` | ✅ | — | — | — |
| `## Open in_progress (besides today's in-flight)` | ✅ | — | — | — |
| `## Halt-class status at reboot` | — | — | — | ✅ |
| `## Doctrine: post-reboot pane state recovery` | — | — | — | ✅ |
| `## Suggested resume sequence` | ✅ | — | — | — |
| `## Worker Callback Received` | — | — | ✅ | — |
| `## Saved Artifacts` | — | — | ✅ | — |
| `## Known Worker State` | — | — | ✅ | — |
| `## Health Context` | — | — | ✅ | — |
| `## Mission Alignment` | — | — | ✅ | — |
| `## Current Bead` | — | — | ✅ | — |
| `## Promotion candidates ready (/flywheel:learn --review)` | — | — | — | ✅ |
| `## What comes after typecheck=0 (next session priorities)` | — | — | — | ✅ |
| `## Tonight's totals (pre-reboot)` | — | — | — | ✅ |
| `## Verification Already Seen Before Reboot` | — | ✅ | — | — |
| `## Pane Health At Save` | — | ✅ | — | — |
| `## Dirty Worktree To Preserve` | — | ✅ | — | — |

**Observed common semantic dimensions across all 4** (even when section headers diverge, the *meaning* recurs):

1. Resume context (last commit, branch, session, panes) — universal
2. In-flight dispatches with task_id + worker + pane + bead + callback ETA — universal in 3/4 (skillos packs into prose)
3. Pending decisions for Joshua — 3/4
4. Substrate concerns / gates at handoff time — 3/4
5. Cross-orch state — 2/4 (flywheel + alps)
6. Closed-today / shipped-today summary — 2/4 (flywheel + alps)
7. Doctrine / memory rules added — 2/4 (flywheel + alps)
8. Files Joshua should read on resume — 2/4

The canonical handoff is **per-repo, event-driven, orchestrator-only**, written under `<repo>/.flywheel/handoffs/<iso-date>-<HHMM>-<reason>.md` (see `handoff.md:45`). The doctrine prime rule at `handoff.md:8-16` (workers DO NOT halt; STATUS-PROBE FORBIDDEN) is foundational for the meeting design.

---

## 7. Memory rules registry

From `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md` (per global memory injection in this session). Classification scheme: **OPS-MEETING-RELEVANT** / **GENERAL** / **REFERENCE**.

### Direct ops-meeting-relevant rules (load-bearing)

| Rule file | Class | Headline |
|---|---|---|
| `feedback_orchestrator_must_dispatch.md` | OPS-MEETING-RELEVANT | "When data unambiguously points at an action … the orchestrator MUST dispatch. Asking Joshua's permission for every move IS the meat-puppet failure mode." Specific to plan-space too: "When research lanes converge and 'Joshua-disposes' candidates have data-recommended defaults, the orchestrator DECLARES the decisions and proceeds; it does NOT pause for blanket approval." |
| `feedback_data_decides_not_human_meatpuppet.md` | OPS-MEETING-RELEVANT | "I keep answering this and I'll keep doing so — i've built this system to be smarter than me — I need the data to guide the decisions not the human meat puppet." Operational creed: "Probe. Apply methodology. Decide. Execute. Report. Loop." Only legitimate Joshua-disposes pauses are: (a) `/flywheel:plan` Phase 3→4 transition, (b) destructive/irreversible operation, (c) security/secret/PHI-class disclosure. |
| `feedback_orch_paralysis_recurring.md` | OPS-MEETING-RELEVANT | "You have the data. You have donella-meadows-systems-thinking. You have the CLAUDE.md, AGENTS.md, INCIDENTS.md, fuckup-log, doctor JSON, and ~284 skills indexed. … Stop asking, decide." Reversibility test: if action is reversible AND data argues clearly, do it; if irreversible OR ambiguous, surface with default + tie-breaker (not a menu). |
| `feedback_orch_punt_is_l70_failure_dispatch_dont_ask.md` | OPS-MEETING-RELEVANT | META-RULE 2026-05-05: "When workers idle + ready beads exist + Donella+data answers the pick, asking 'want me to dispatch X?' IS the bug. That is L70 ORCH-NO-PUNT failure." Counter wired via `flywheel-gqoz` → `l70-ticks-punted.jsonl` (15 rows as of 2026-05-05). |
| `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md` | OPS-MEETING-RELEVANT | Three states a fleet session can be in: (1) Productive, (2) Idle-with-work-available — flywheel:1 OWNS, (3) True Josh-blocker — IMMEDIATELY notify. **Always-available work hierarchy (9 sources)**: doctor errors, fuckup_triage candidates, closed_bead_audit_pending, canonical_drift / fleet_repo_l_rule_lag, recent commits without README/AGENTS update, INCIDENTS unprocessed, skill citation graph gaps, gap-hunt findings, mission-anchor doctrine drift. Joshua-notify ONLY for substrate-corrupt + security/PHI + paradigm + destructive — NEVER "session is quiet." |
| `feedback_orchestrator_validates_callbacks.md` | OPS-MEETING-RELEVANT | META-RULE: "When a worker returns DONE, orchestrator must probe acceptance-gate artifacts and auto-open fix-beads for any unfulfilled gates BEFORE summarizing to Joshua." Treat `DONE` callback as proposal, not proof. The dispatch packet's "Acceptance gates" section IS the validation checklist; run it. Auto-open fix-beads is not optional and not Joshua-decision. |
| `feedback_two_blocker_ticks_escalate_to_flywheel_plan.md` | OPS-MEETING-RELEVANT | "Every sister orch tracks a per-blocker tick counter. If the same blocker survives **2 consecutive ticks** without resolution, the sister orch is REQUIRED to (1) send blocker capsule to flywheel-orch via fleet-mail (2) stop attempting local fixes (3) wait for flywheel-orch's `/flywheel:plan` response." Why 2 ticks: 1=noise, 2=signal, 3+=damage. Canonical capsule format included. |
| `feedback_canonical_meta_rules_propagation_doctrine_2026_05_03.md` | (CHECK) — file path probed; existing memory dir contains `canonical-cli-at-dispatch`, `canonical-ntm-spawn-shape`, `codex-relaunch-command-canonical`, but **not the literal name asked**. Per probe `ls memory/ \| grep -i canonical` returned 4 files, none with that exact slug. **Treat as referenced-but-absent.** | The L102/L108 doctrine is captured in AGENTS L102 (`AGENTS.md:2625`) regardless. |
| `project_self_sustaining_company_paradigm_2026_05_04.md` | OPS-MEETING-RELEVANT (anchor) | "The flywheel is a company outgrowing its founder. Joshua = founder providing direction + paradigm + taste. … Long-arc target: a SpaceX/Tesla command-center equivalent — total visibility into who is doing what, with what effectiveness/quality/productivity, measured continuously, with the organization regularly learning and improving its architecture rather than its employees." Performance vectors table: **Reliability, Faithfulness, Leverage, Reuse, Coordination, Drift authoring** — all derivable from existing substrate, instrumented at orch, attached to `agent_id × project × timestamp` tuple. Architecture-health > individual evaluation. |

### General (not ops-meeting-specific but relevant)

`feedback_orchestrator_scope_boundary.md`, `feedback_orchestrator_must_finish_p0_before_filing_more.md`, `feedback_workers_read_not_mint_identity.md`, `feedback_validator_must_check_four_lenses.md`, `feedback_publishability_bar_three_judges.md`, `feedback_pane_state_ntm_health.md`, `feedback_validate_redispatch_foundational_discipline.md`, `feedback_low_bead_threshold_work_hunt.md`, `feedback_three_audit_questions_per_surface.md`, `feedback_two_truth_sources_before_decide.md`, `feedback_no_idle_clean_doctrine.md`, `feedback_orch_drifts_to_rubber_stamp_closures.md`, `feedback_audit_findings_are_data_decided_not_joshua_gated.md`, `feedback_canonical_meta_rules_watchdog`, `feedback_xpane_recovery_recommendations_must_verify_canonical_flags_and_protections.md`, `feedback_canonical_ntm_spawn_shape.md`, `feedback_canonical_cli_at_dispatch.md`, `feedback_codex_relaunch_command_canonical.md`.

### Reference

`reference_jeff_substrate_inventory.md`, `reference_alps_real_path.md`, `reference_lavenderglen_fleet_mail.md`, `reference_dicklesworthstone_stack_ntm.md`, `reference_watcherctl_zeststream_infra.md`, `reference_agent_mail_service.md`, `reference_cass_vs_cassv2.md`, `reference_upstream_issues.md`.

**Net read on §7:** the rules in this section *operationally constrain* the protocol design. The protocol MUST:

1. Run synchronously, mechanically, without Joshua-decision gates (per `feedback_data_decides`, `feedback_orch_punt`, `feedback_orchestrator_must_dispatch`).
2. Emit one Joshua-readable artifact per cadence with hard blockers explicit (per `flywheel_owns_continuous_productivity`).
3. Validate every claim before forwarding (per `feedback_orchestrator_validates_callbacks`).
4. Auto-escalate a blocker that survives 2 consecutive cadence ticks to a `/flywheel:plan` accretive fix (per `feedback_two_blocker_ticks`).
5. Score architecture-health system-level, never individual-level (per `project_self_sustaining_company_paradigm`).

---

## 8. Per-orch repo specialization

### skillos (`/Users/josh/Developer/skillos`)

**Domain:** skill moat / skill-pack lifecycle / JSM-managed skill catalog / skillos relay (the inflow-to-skill-creation surface).

**Key ops-meeting questions:**
- Skill-pack lifecycle ladder state per pack: `candidate → gated → promoted` (verified via `state/packs/registry.json`: 2 packs — `skills-os-router-pack` lifecycle=`gated` v1.1.0 / 3 members; `vendor-wranglers-pack` lifecycle=`candidate` v0.1.0 / 4 members).
- Skill-graduation gates met per pack: `confidentiality_gate_explicit, human_review, validation_exit_0` (and `vendor_mutation_review` for vendor packs) per registry JSON `promotion_requires`.
- JSM queue drain status (queued mutations, currently blocked at `skillos-1kc` per skillos handoff line 28).
- `skillos-routed.jsonl` row volume (skillos relay productivity).

**Existing substrate:**
- `state/packs/registry.json` — canonical pack registry (`skillos.skillpack.registry.v1`).
- `scripts/skillos_pack.py` — `list, doctor, validate, install --dry-run, why`.
- `tests/test_skillos_pack.py` (7 tests, passing per skillos handoff line 53).
- `~/.local/state/flywheel/skillos-{relay-ledger,relay-soft-violations,relay-agents-hash,routed,pending-candidates}.jsonl`.
- `.flywheel/scripts/skillos-relay-tail.sh`, `skillos-routed-tail.sh`, `skillos-candidate-append.sh`.
- Memory: `project_skillos_goal_rotation_v2_2026_05_03.md` (2026-05-03 GOAL rotation: bootstrap-observability → measured-skill-shipping; first repair = FoggyBear routed-decision notification gap).

### mobile-eats (`/Users/josh/Developer/mobile-eats`)

**Domain:** public ZestStream offering / Nango-integration substrate / publishability bar (consumer-facing).

**Key ops-meeting questions:**
- Publishability bar score (`publishability_bar_score` doctor field per L88) for the public surface; 3-judge composite ≥ 9.5 / brand_voice ≥ 95.
- Banned-words / ungrounded-claims count (per L89).
- Nango canary / owner-social bridge readiness (per `next-app/lib/mobile-eats/nango-webhook.ts:87-170`: `OwnerSocialCanaryPayload`, `OwnerSocialCanaryReceipt`, schema `mobile-eats-owner-social-canary/v1`).
- Owner-approval gate state: `owner_review_gate` vs `owner_portal`.
- Truth boundary integrity: `livePostingEnabled=false`, `livePostingAttempted=false`, `providerPublishClaimed=false`, `providerDeliveryClaimed=false`, `rawBearerValuesIncluded=false`.

**Existing substrate:**
- `.flywheel/scripts/mobile-eats-receipt-bridge.sh` (publishability dashboard line for `/flywheel:status`).
- `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh`.
- `nango-webhook.ts` + `nango-webhook.test.ts` (canary contract).
- Mobile-eats handoff (`20260505T053247Z`) shows worker WARN callback schema with `four_lens=brand:7,sniff:7,jeff:7,public:6`.
- Memory: `project_mobile_eats_session_2026_05_02_lessons.md` (8 meta-lessons; mobile-eats as proof case).

### alpsinsurance (`/Users/josh/Developer/alpsinsurance`)

**Domain:** client (CubCloud co-engagement: Mike+Kurt+Kelly+Laura+Robin) / data-engineering / Q2-2026 sprint / mid-July cutover.

**Key ops-meeting questions:**
- Mike-daily-report state (LOCKED format per `reports/mike-daily/README.md:1-63`: 4-section, outcomes-only, no bead IDs / no doctor verdicts / no infisical / no internal jargon). Cadence locked at mission-lock `417660fc` (2026-05-04). 16:00 MT send time.
- Mypy-violation burndown (1513 → 8, 99.5% cleared per alps reboot handoff line 13).
- PR throughput (78 PRs merged on tonight's wave per handoff line 11).
- Phase-3a/3b/3c ladder progress + R1-R7 rigor metrics per `.flywheel/GOAL.md`.
- Worktree count (75+ pollution per handoff line 48, prune needed).
- Beads-db corruption status (~100 unused pages, freelist leaf count too big — handoff line 46).
- Storage: 42.79GB free (below 50GB threshold) — handoff line 47.
- Phase-4 shadow-mode kickoff timing (per Mission Section 15 + R1 cadence) — multi-component architectural work via `/flywheel:plan`.

**Existing substrate:**
- `.flywheel/MISSION.md` mission-lock `417660fc`.
- `.flywheel/GOAL.md` Phase ladder + R1-R7.
- `.flywheel/STATE.md`.
- `.flywheel/lock-log.jsonl`.
- `reports/mike-daily/README.md` cadence convention; `_drafts/`, `_review/` folder pattern.
- `planning/ENGAGEMENT-PLAN.md`, `IMPLEMENTATION-ROADMAP-Q2-2026.md`, `TOP-PRIORITIES.md`, `STAKEHOLDERS.md`.
- `knowledge/planning/pivot-july-cutover.md`.
- `.flywheel/dispatch-log.jsonl` (80+ entries per session).
- Memory: `project_alps_quintessential_member_2026_05_01.md`.

### vrtx (`/Users/josh/Developer/vrtx`)

**Domain:** client (VRTX Gym Missoula) / 90-day fixed-price ($10K) / Phase 1 lead system / brand voice + content production.

**Key ops-meeting questions:**
- Phase 1 leads-touched-under-4hr-via-Teams metric (north_star per `manifest.yml:6-15`).
- Mailchimp sunset week-11 progress.
- ZooTown lead engine + ClubReady booking integration state.
- Phase 1 subgoals (per `manifest.yml:33-41`): `zootown_lead_engine, unified_lead_tracking, ai_drafted_followup, jack_4hr_fallback, thirtysix_hour_followup, cold_lead_reengagement, clubready_booking, manager_inbox_ai_scrubbing`.
- Brand naming canon state: `primary_in_flux="Strength Training for Everyone"` (Q43 BBQ candidate) vs deprecated `LIVE BETTER` (Walmart conflict, Q9).
- Voice canonical: `~/.claude/skills/zeststream-brand-voice/brands/vrtx/voice.yaml` + `brands/vrtx/voice.yaml`.
- Wednesday 14:00 MT on-site briefing artifacts (per `audits/2026-04-29-codex-vrtx-wednesday-operator-briefing.md`).

**Existing substrate:**
- `manifest.yml` mission + phase config.
- `MISSION.md`, `GOAL.md`.
- `docs/SIGNED-SCOPE-EMAIL-2026-04-22.md` (canonical scope source).
- `docs/peel-report-joshua-decisions.md` (Joshua-locked Q&A).
- `audits/_msgs/p1-to-p2-*.md`, `p2-to-p1-*.md` (cross-pane message lane).
- `brands/vrtx/voice.yaml` (mirror).
- `brands/vrtx/_raw/{cluster-analysis,canva-audit,mailchimp-audit,wordpress-deep-audit,sharepoint-audit,clubready-audit}.md`.
- `.mission-pulse.md`, `.loop-state.md`, `audits/_mission.md` (per `p2-to-p1-026-lock-mission-update.md`).

### Future repos (zesttube, zeststream.ai, nango, AaaS, langgraph, agent-harness)

Pattern observed: each has its own `.flywheel/MISSION.md`, scripts/, memory dir, and per-session ntm topology. Onboarding is canonical via `flywheel-onboard.sh` + `/flywheel:onboard` per L102 META-RULE inheritance. Per-repo `daily-report-config.json` `{enabled:true}` opts a repo into the doctor-signal daily cadence per `daily-report.md:60-62`.

---

## 9. Substrate gaps register

Legend: **EXISTS** = already shipped and wired; **PARTIAL** = primitive present but cadence/glue missing; **MISSING** = no canonical surface today.

| Concern | Verdict | Evidence |
|---|---|---|
| daily orch self-audit (push) | **EXISTS** | `/flywheel:daily-report` per-repo, L77 (`AGENTS.md:1455`); doctor signal `daily_report_age_hours` |
| daily fleet roll-up (pull / cross-orch) | **PARTIAL** | `architecture-health-rollup.sh` writes 24h/7d/30d/90d to `~/.flywheel/fleet-perf/`; `fleet-observatory-aggregate.sh` produces composite. **Missing:** synchronized daily cadence + Joshua-narrative output. No `ai.zeststream.fleet-observatory-aggregate-daily.plist`. |
| weekly cross-orch peer review | **PARTIAL** | `/flywheel:weeklyreflection` exists per skill catalog. **Missing:** cross-orch peer-review structure (each orch reviews another's week, not just self-reflection). |
| bidirectional Joshua-to-fleet check-in (event-driven) | **EXISTS** (canonical inflow) | `~/.local/state/flywheel/josh-requests.jsonl` + `josh-request-tick-promote.sh` + `josh-requests-jsonl-init.sh`; Surface in `/flywheel:status` step 4a (`status.md:40-45`). Field schema: `id, captured_at, state, priority, linked_bead_ids, stale_after, excerpt`. Stale-after default 24h. |
| bead velocity metric per orch | **PARTIAL** | `closed_today_count` is rolled up by `daily-report.sh` (`tests/daily-report.sh:73-87` shows `.closed_today_count`). **Missing:** per-orch trend chart over 7d/30d. Architecture-health rollup attaches via `agent_id × project × timestamp` per memory; no historical fleet-wide chart. |
| composite-score trend per orch | **PARTIAL** | `fleet_observatory_health_score` per snapshot exists; `architecture-health-rollup.sh` writes 7d/30d/90d windows. **Missing:** per-orch trend line embedded in any meeting artifact. |
| worker-capacity / freeze-rate trend | **PARTIAL** | `worker-slot-ledger.sh`, `frozen-pane-detector(-fleet).sh`, `codex-stuck-detector.jsonl` (121 rows), `recovery-slo-probe.sh` p50/p95. **Missing:** trend rollup that compares week-over-week per session. |
| L70-punt counter trend | **EXISTS** | `l70-ticks-punted-counter.sh` + `l70-ticks-punted.jsonl` (15 rows as of 2026-05-05T00:09Z). Doctor field `l70_ticks_punted_24h` per `tests/l70-ticks-punted-counter.sh:71`. |
| knowledge-moat depth metric | **MISSING** | Skill-citation graph is referenced (`feedback_flywheel_owns_continuous_productivity.md` cites it as work-source #7) but no canonical probe/script writes a metric. `skill-discoveries.jsonl` exists but tracks discoveries, not moat depth. |
| skill-gap candidate detection | **PARTIAL** | `skillos-pending-candidates.jsonl` + skillos relay infra captures candidates from worker callbacks where `skills_consulted=...:MISSING` (mobile-eats handoff line 22 shows `platform-compliance:MISSING`). **Missing:** canonical fleet-wide skill-gap rollup metric. |
| founder-bottleneck-volume metric (decisions Joshua made vs total) | **PARTIAL** | `fleet_metrics.founder_dispose_pct` exists in fleet-observatory schema (`tests/fleet-observatory-aggregate.sh:69 green=0.10, red=0.40`) and in `architecture-health-rollup.sh` 30d outputs. Surfaced in `/flywheel:status` line `📊 Architecture Health: … founder_dispose_pct=<N%>`. **Gap:** trending claim "founder_dispose_pct trending down quarterly is paradigm-success" (L98 `AGENTS.md:2407`) lacks a quarterly emission/notification surface. |
| mission-anchor drift detection | **EXISTS** | `mission-lock-age-probe.sh` + `mission-anchor-dispatch-license.sh` + `mission-anchor-license-ledger.jsonl`. Mission-lock metadata required per fleet-conformance probe (`tests/fleet-conformance-probe.sh:43-48`). |
| canonical-paths.json compliance per repo | **EXISTS** | `.flywheel/scripts/canonical-paths.json` + per-repo `canonical-paths.txt` (`tests/daily-report.sh:42`). Path conformance probe at `~/.flywheel/canonical-meta-rules` + `fleet-canonical-rule-freshness-probe.sh`. |
| mobile-eats publishability tracking | **EXISTS** | `mobile-eats-receipt-bridge.sh` produces `📱 Mobile-eats: …` dashboard line; `publishability-bar.sh` doctor probe + `publishability_bar_score` object. **Caveat per alps reboot handoff line 49:** `publishability_bar_score=0` because `.flywheel/scripts/publishability-bar.sh` was reported missing from alps; flywheel-side script may exist but is not propagated everywhere yet. |
| skillos skill-lifecycle ladder tracking | **EXISTS** | `state/packs/registry.json` + `scripts/skillos_pack.py list/doctor/validate`. Lifecycle field per pack (`gated`/`candidate`/`promoted`-eligible). |
| vrtx client-deliverable status | **PARTIAL** | `manifest.yml` phase config + `audits/_msgs/p1-to-p2-*.md` cross-pane message lane. **Missing:** rollup metric for "leads-touched-under-4hr" (north_star) — no automated probe yet. |
| per-repo onboarding-readiness for future repos | **EXISTS** | `flywheel-onboard.sh` + `/flywheel:onboard` + L102 META-RULE inheritance + `daily-report-config.json` opt-in. Future repos (zesttube, zeststream.ai, nango, AaaS, langgraph, agent-harness) inherit by construction. |

---

## 10. Provisional verdict for the planner

### EXISTING_SUBSTRATE_USABLE_AS_IS (7)

1. `/flywheel:fleet-observatory` + `fleet-observatory-aggregate.sh` — the 8-spine composite is THE canonical "single number" per L106. Use as-is.
2. `architecture-health-rollup.sh` — 24h / 7d / 30d / 90d window rollups already write to `~/.flywheel/fleet-perf/`. Use as-is for trend metrics.
3. `~/.local/state/flywheel/cross-orch-coordination.jsonl` (88 rows) + `peer-orch-blocker-watch.sh` — ops-meeting cross-orch escalation surface, L75 5-min rule already enforced.
4. `~/.local/state/flywheel/josh-requests.jsonl` + `josh-request-tick-promote.sh` — bidirectional Joshua-to-fleet inflow channel, surfaced in `/flywheel:status`.
5. `/flywheel:handoff` schema (`handoff.md:45-93`) — closest existing canonical session artifact; meeting can borrow its sections directly (Resume context, In-flight, Pending decisions, Files to read, Closed today, Cross-orch, Substrate concerns).
6. L106 / L98 / L101 / L103 / L104 / L105 doctrine — meeting agenda items are already L-rule-codified.
7. `flywheel-loop doctor --json` — universal data plane; every existing measurement spine reads it; the meeting MUST too (no parallel measurement substrate).

### EXISTING_SUBSTRATE_NEEDS_EXTENSION (8)

1. `architecture-health-rollup.sh` — extend with **per-orch breakdown columns** (currently aggregates fleet; need per-session reliability/faithfulness/leverage/reuse/coordination/drift-authoring vectors per `project_self_sustaining_company_paradigm` table).
2. `fleet-observatory-aggregate.sh` — extend with **trend deltas** vs prior 24h/7d (currently emits a snapshot only).
3. `daily-report.sh` — extend with **fleet-aggregate mode** (currently `--repo <repo>`-only; add `--fleet-aggregate` that consumes per-repo daily reports and emits a Joshua-readable cross-orch narrative).
4. `/flywheel:weeklyreflection` — extend with **cross-orch peer-review structure** (current is single-repo).
5. `peer-orch-blocker-watch.sh` — extend with **2-tick auto-promotion to `/flywheel:plan` per `feedback_two_blocker_ticks_escalate_to_flywheel_plan.md`** (rule exists in memory; mechanical enforcement script not yet wired).
6. Per-repo `daily-report-config.json` — extend with `{ "fleet_meeting_enabled": true, "domain_questions": [...] }` so per-orch specialization (skillos lifecycle / mobile-eats publishability / alps client-deliverable / vrtx phase-1) gets its 1-line slot.
7. `tick-driver-manifest.json` — extend with `event_driven` registration for the daily fleet-meeting primitive (per L116 `AGENTS.md:3271-3275`).
8. `worker-slot-ledger.sh` + `recovery-slo-probe.sh` — extend with **week-over-week capacity/freeze-rate trend** rollup.

### EXISTING_SUBSTRATE_TO_DEPRECATE (1)

1. None outright. **Caveat:** `frozen-pane-detector.sh.v1.bak` is already quarantined; `gap-hunt-probe.sh.bak.20260503T0707/0734` are quarantined backups. The `agent-evaluation` skill pattern is NOT to deprecate but to **strictly fence per L98** (architecture-health frame); explicit guard against per-agent leaderboards.

### BUILD_NEW (4)

1. **`.flywheel/scripts/fleet-ops-meeting-aggregate.sh`** — new synthesizer that consumes (a) every per-repo `<repo>/.flywheel/reports/daily-<date>.md`, (b) `~/.flywheel/fleet-perf/24h.json`, (c) `cross-orch-coordination.jsonl` last 24h, (d) `josh-requests.jsonl` open + stale, (e) per-orch domain-question slot, and emits one canonical artifact at `~/.flywheel/fleet-meetings/<iso-date>.md` plus JSON twin at `~/.flywheel/fleet-meetings/<iso-date>.json`. Runs daily at a fixed UTC time (e.g., 13:00Z = 07:00 MT, before Joshua morning).
2. **`ai.zeststream.fleet-ops-meeting-daily.plist`** — launchd daily plist, `StartCalendarInterval Hour=13 Minute=0`, ProgramArguments invokes the new script. Registered in `~/.local/state/flywheel/plist-registry.jsonl`.
3. **`/flywheel:fleet-ops-meeting`** — slash command at `~/.claude/commands/flywheel/fleet-ops-meeting.md` that (a) on-demand reruns the aggregator, (b) renders the artifact inline, (c) surfaces "Joshua-decision needed" only when L98 architecture-health blockers exist, (d) auto-routes findings via L77 daily-report rules and L75 cross-orch rules.
4. **`.flywheel/scripts/skill-moat-depth-probe.sh`** — fills the §9 MISSING gap. Walks the skill-citation graph (callbacks `skills_consulted=...` field, dispatch-log links, INCIDENTS cross-refs) and emits `skill_moat_depth_score` + top-N skills by inbound citations. Plumb into `flywheel-loop doctor` output.

### HIGHEST_LEVERAGE_GAP_FILL

**The single highest-leverage gap-fill** is item BUILD_NEW #1 + #3 together: a **`fleet-ops-meeting-aggregate.sh` + `/flywheel:fleet-ops-meeting`** pair that *composes existing primitives* into one daily Joshua-readable artifact. Rationale per Donella #4 (self-organization) and #6 (information flows):

- Every measurement spine ALREADY exists (8 fleet-observatory spines + per-repo daily reports + cross-orch ledger + Joshua-requests inflow).
- The meeting protocol is the missing **synthesis surface** that turns 25 data sources into 1 artifact Joshua reads.
- Per L106: "Joshua sees one number when stepping back, not 25 fields."
- Per `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`: "When ALL nine [work-hunt] sources return zero, surface to Joshua as 'session at zero-backlog state, recommend new mission anchor or rest'" — this becomes the natural meeting close-state.
- Per `project_self_sustaining_company_paradigm`: the meeting IS the SpaceX/Tesla command-center surface. Architecture-health, not individual evaluation.
- Per `feedback_two_blocker_ticks_escalate_to_flywheel_plan.md`: the meeting is the natural emit-point for a 2-tick promotion (any blocker that has been red 2 days in a row auto-spawns a `/flywheel:plan`).
- Per L70 / `feedback_orch_punt_is_l70_failure_dispatch_dont_ask.md`: the meeting MUST decide and execute — not present Joshua an A/B/C menu. Joshua-decision only when `architecture_health_metric_unpaired_count > 0` with no programmatic fix or for the 3 legitimate Joshua-disposes pauses (security/destructive/paradigm).
- The meeting's daily cadence then becomes the *forcing function* that wires every existing primitive (L77 daily-report, L101 productivity, L103 conformance, L104 comms, L105 process, L106 8-spine) into a closed measured loop — eliminating the "ship-then-orphan" pattern guarded by L110.

---

## Appendices

### A. Canonical surfaces touched by every section above

- `/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` (3380 lines)
- `/Users/josh/Developer/flywheel/AGENTS.md` (3331 lines)
- `/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md` (3206 lines)
- `/Users/josh/Developer/flywheel/INCIDENTS.md` (681 lines, 23 entries)
- `/Users/josh/Developer/flywheel/README.md`
- `/Users/josh/Developer/flywheel/.flywheel/scripts/` (~140 scripts)
- `~/.claude/commands/flywheel/` (40+ commands)
- `~/.claude/skills/.flywheel/bin/flywheel-loop` (the canonical doctor binary)
- `~/.local/state/flywheel/` (61 JSONL ledgers)
- `~/.flywheel/{loops,fleet-perf,canonical-meta-rules,mem,recovery}` (per-host non-repo state)
- `~/Library/LaunchAgents/{com.flywheel.*,ai.zeststream.*}.plist` (39 plists)
- `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md` (memory anchor)

### B. Receipt counts for the planner

```
total_repos_surveyed=5
socraticode_queries=15
indexed_chunks_observed≈140
grep_sweeps=6
flywheel_l_rules=66
flywheel_install_template_l_rules=65
incidents_entries=23
flywheel_jsonl_ledgers=61
flywheel_scripts=~140 (`.flywheel/scripts/`)
flywheel_local_bin_executables=8 (~/.local/bin/flywheel-*)
launch_agent_plists=39
launch_agents_currently_loaded≈11 (relevant subset)
handoff_section_intersection_universal=2 (resume_context, in_flight_dispatches)
handoff_section_intersection_3of4=3 (pending_decisions, substrate_concerns, files_to_read)
existing_substrate_usable_as_is=7
existing_substrate_needs_extension=8
existing_substrate_to_deprecate=1 (none outright)
build_new=4
```

### C. Plan-space tokens (for the eventual /flywheel:plan run)

- "fleet-ops-meeting" (slash command + plist + script triple)
- "8-spine composite extension with per-orch breakdown"
- "2-tick auto-promotion to /flywheel:plan"
- "skill-moat-depth-probe" (fills §9 MISSING)
- "fleet-aggregate mode for daily-report.sh"
- "weeklyreflection cross-orch peer-review structure"
- "fleet-ops-meeting-aggregate.sh canonical synthesizer"
- "Joshua-decision pause only for: /flywheel:plan Phase 3→4, destructive, security/PHI/paradigm"
- "per-orch domain-question slot via daily-report-config.json extension"
- "founder_dispose_pct quarterly trend emission surface"

End of LANE-D deliverable.
