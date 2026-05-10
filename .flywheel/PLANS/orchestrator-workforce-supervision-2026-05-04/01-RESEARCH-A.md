---
title: "Lane A - Problem-Space Inventory"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A - Problem-Space Inventory

Plan: `orchestrator-workforce-supervision-2026-05-04`
Lane: A - problem-space inventory
Worker: flywheel:4 / Codex
Scope: read-only inventory of workforce-supervision failure modes and missing signals.

## 0. Evidence Ledger

Required readings and probes used:

| evidence | purpose |
|---|---|
| `.flywheel/plans/orchestrator-workforce-supervision-2026-05-04/00-INTENT.md` | Joshua trigger, desired workforce-supervision mesh, existing tool list |
| `.flywheel/AGENTS-CANONICAL.md` | L29, L50, L51, L52 operational doctrine |
| `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_pane_state_ntm_health.md` | pane-state truth-source doctrine |
| `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_must_dispatch.md` | orchestrator action doctrine |
| `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_two_truth_sources_before_decide.md` | two-source decision doctrine, with noted drift from pre-L29 direct-capture wording |
| `/tmp/workforce-ntm-list.json` | live visible NTM sessions |
| `/tmp/workforce-ntm-activity.txt` | live robot activity state |
| `/tmp/workforce-ntm-health.txt` | health state, including activity/health disagreement |
| `/tmp/workforce-session-topology-tail.jsonl` | expected sessions and pane roles |
| `/tmp/workforce-flywheel-dispatch-tail.jsonl` | dispatch, watcher, frozen-pane, callback-reaper events |
| `/tmp/workforce-fuckup-tail.jsonl` | recent trauma classes |

Skills library check:

| skill | decision | why |
|---|---|---|
| `agent-orchestration` | ADOPT | canonical task routing, worker lifecycle, and callback ownership patterns |
| `agent-monitoring` | ADOPT | state, telemetry, alert, and health-signal vocabulary |
| `accretive-cron-orchestration` | ADOPT | recurring watcher/driver patterns and durable tick state |
| `agent-governance` | ADOPT | policy and intervention boundaries for autonomous worker management |
| `observability-platform` | EVALUATE | useful metric-shape vocabulary, but heavier than current plan-space need |
| `agent-evaluation` | EVALUATE | useful for validating supervision quality after mechanisms exist |

Socraticode survey:

- Query: `workforce supervision pane state callback debt stale error text ntm health two truth sources` against `/Users/josh/Developer/flywheel`, limit 10.
- Relevant hits: `AGENTS.md` L57/L67/L80, `INCIDENTS.md` orchestrator-observability-contract-bypass, `tests/verify-callback-delivery.sh`.
- Applied findings: live truth must not rely on cached scrollback; callback delivery must be verified; DID/DIDNT/GAPS must be explicit in closeout.

## 1. Workforce State Taxonomy

The workforce needs a state model that separates worker behavior, pane transport, callback debt, identity, and substrate health. Today those are partially collapsed into `idle` or `error`, which causes false positives and missed recovery opportunities.

| state | definition | primary signals | secondary signals | recovery class |
|---|---|---|---|---|
| `waiting` | pane is reachable and available for dispatch | `ntm activity state=WAITING` | `ntm health is_idle=true` | dispatch next work |
| `idle_untrusted` | health reports idle but activity does not confirm availability | `ntm health is_idle=true` | `ntm activity` absent or contradictory | collect second truth source before dispatch |
| `dispatched_not_started` | dispatch log assigned task, but pane has no matching live activity evidence | dispatch log task row | pane scrollback delta, callback absence | benign ping or re-dispatch after deadline |
| `thinking_moving` | worker appears active and pane output is changing | `ntm activity state=THINKING`, velocity >0 | scrollback byte delta | observe only |
| `thinking_zero_delta` | worker appears active but no output movement | `ntm activity state=THINKING`, velocity=0 | frozen-pane detector live delta | soft status probe, then recovery |
| `generating_moving` | worker is producing output | `ntm activity state=GENERATING`, velocity >0 | scrollback delta | observe only |
| `error_text_live` | current live pane state contains error text | `ntm activity state=ERROR` | capture provenance age and live delta | classify error and recover |
| `error_text_stale` | error text exists in scrollback but pane has moved past it | capture provenance plus newer delta | activity state not ERROR | clear stale-text false positive |
| `exited` | pane process exited or is unreachable | `ntm health status=error/process exited` | topology expected pane role | respawn or mark capacity blocked |
| `capture_unavailable` | pane capture cannot produce live text/provenance | `capture_provenance` unavailable | `ntm copy` failure, #117 provenance absent | transport recovery, not worker judgment |
| `unknown` | required sources disagree or are absent | activity/health/topology mismatch | frozen-pane `UNKNOWN` | collect more sources; fail closed for dispatch |
| `frozen_confirmed` | live pane is stuck beyond threshold with no byte movement | frozen-pane detector v2 | repeated activity zero velocity | interrupt/respawn per policy |
| `callback_pending` | worker task has passed callback deadline without validated DONE/BLOCKED | dispatch log task row | `validate-callback.py`, `ntm logs` | reaper and worker-side verify flow |
| `callback_delivered_unvalidated` | callback text exists but no validation receipt exists | `ntm logs` hit | callback validator missing receipt | validate before integrate |
| `callback_validated_pass` | callback was delivered and schema/evidence passed | validation receipt | evidence file exists | integrate |
| `callback_validated_fail` | callback delivered but malformed or missing evidence | validation receipt fail | no-bead/fuckup fields | auto-open repair bead or re-dispatch |
| `identity_registered` | worker has active agent-mail/registry identity for the project | agent-mail profile | registration token age | normal |
| `identity_missing` | pane is active but has no current identity | registry lookup miss | dispatch preamble absent | registration repair |
| `identity_mismatch` | callback sender, pane, task, or registry identity disagree | callback receipt | dispatch log, agent-mail profile | fail closed and repair identity |
| `mcp_ok` | required MCP servers/tools are reachable | MCP health or successful call | recent tool use | normal |
| `mcp_degraded` | required MCP surface is missing or disconnected | tool failure | fuckup-log `agent-mail-mcp-down` | substrate recovery before worker blame |
| `doctor_blocked` | doctor/prelude error blocks integration or dispatch | doctor JSON / prelude rows | dispatch tail | classify as system blocker |
| `storage_blocked` | storage capacity or disk gate blocks workers | doctor storage gate | fuckup-log storage classes | cleanup/override protocol |
| `cross_session_not_visible` | topology expects session but current NTM list/activity cannot see it | topology row exists, `ntm list` absent | no activity/health output | aggregate dashboard gap; do not infer healthy |

Three-judges lens:

- Validated: the state is backed by at least one live or durable signal.
- Documented: the state has a named definition and recovery class.
- Surfaced: the state appears in a dashboard/doctor/callback receipt, not only in pane prose.

Most current states are partially validated and documented in scattered doctrine, but not surfaced as one workforce view.

## 2. Failure Mode Catalog

| failure mode | observed / expected shape | current detection | current recovery | gap |
|---|---|---|---|---|
| stale-error-text | old error remains in scrollback and triggers a false positive after pane recovers | partial via capture provenance and auto-nudge | ad hoc stale-text clear | needs explicit `error_text_stale` state with provenance age |
| stuck-thinking-too-long | pane reports THINKING with velocity=0 beyond threshold | partial via `ntm activity` and frozen-pane detector | manual/soft nudge only | needs graduated recovery policy and strike ledger |
| callback-never-arrived | dispatch assigned task but pane 1 never receives DONE/BLOCKED | partial via dispatch log, `validate-callback.py`, callback reaper | partial reaper; worker-side verify exists but not universal | needs callback debt queue across sessions |
| capture-unavailable | pane cannot be reliably read, so state cannot be proven | #117 provenance can represent this, not yet dashboarded | manual transport investigation | needs capture health as first-class state |
| registry-drift | expected pane/session identity differs from registry or topology | partial via topology and agent-mail | manual registration repair | needs identity drift dashboard row |
| MCP-disconnected | required MCP tools unavailable mid-worker | fuckup-log has `agent-mail-mcp-down` | manual retry/recovery | needs MCP health signal in workforce view |
| identity-mismatch | worker callback identity does not match pane/task/agent record | partial via validation schema | fail behavior not consistently surfaced | needs fail-closed callback receipt |
| frozen-pane | pane is live but no longer making progress | frozen-pane detector v2 | manual interrupt/respawn | needs policy for UNKNOWN vs confirmed frozen |
| dispatch-stalled | ready work exists but workers are idle or blocked by stale state | watcher v4 and dispatch log | auto-dispatch partial | needs cross-session capacity truth |
| cross-session-blindness | expected sessions are absent from current `ntm list`/activity | manual comparison only | none | needs dashboard to separate absent, hidden, and healthy |
| three-strike-no-recovery | auto-nudge repeats without resolving pane state | partial in auto-nudge logs | manual escalation | needs durable strike count and failover action |
| storage-gate-cascade | storage or doctor gate blocks multiple repos/workers | doctor/fuckup rows | cleanup/override partial | needs workforce-level severity and owner |
| health-activity-disagreement | `ntm health` says idle/exited while activity says THINKING/ERROR | observed in flywheel/skillos/mobile-eats sample | none | needs disagreement state, not winner-take-all |
| topology-stale-row | topology has old sessions/panes not reachable now | topology tail vs live list | none | needs topology age and reachability status |
| doctor-prelude-blocked-with-worker-active | doctor says blocked while workers still hold active tasks | dispatch/prelude/fuckup rows | manual | needs integration gate to avoid overwriting active work |
| validation-reaper-pending | callback validation reaper skips due callback not found | dispatch tail | partial | needs queue of pending task ids and reason |
| silent-idle-after-closeout | worker closes locally but orchestrator stays idle | fuckup-log `orchestrator-idle-after-closeout` | watcher partial | needs post-closeout dispatch trigger |
| callback-delivery-false-positive | worker believes callback sent, but pane 1 did not receive it | worker-side verify doctrine | not universal across dispatches | needs required verify block and callback field |

The current system has many individual detectors, but the problem is composition: no single consumer ranks these modes, applies two-source conflict rules, and decides whether to observe, nudge, recover, re-dispatch, or file a repair bead.

## 3. Gap Analysis

| gap | effect | evidence | criticality | existing substrate | missing substrate |
|---|---|---|---|---|---|
| no unified workforce state machine | supervisors reason from inconsistent labels | activity/health disagreement in `/tmp/workforce-ntm-activity.txt` and `/tmp/workforce-ntm-health.txt` | P0 | NTM activity, health, topology | normalized state and confidence |
| no callback debt ledger across sessions | DONE/BLOCKED absence is discovered late | dispatch tail callback-reaper skip | P0 | dispatch log, validator, verify script | task queue with deadline and validation state |
| cross-session reachability is not proven | alps/picoz can silently fall out of view | topology tail includes sessions absent from `ntm list` | P0/P1 | topology JSONL | live reachability and age checks |
| stale scrollback can masquerade as live error | auto-nudge wastes cycles or interrupts healthy pane | Joshua stale-text nudge plus L67 doctrine | P1 | capture provenance #117 | dashboard state for stale vs live |
| health and activity sources disagree without arbitration | pane dispatch decisions can be wrong | flywheel pane4 health exited vs activity THINKING | P0/P1 | two-source doctrine | conflict state and conservative policy |
| MCP health is not part of worker state | tool outage is blamed on worker progress | fuckup-log `agent-mail-mcp-down` | P1 | MCP errors, fuckup-log | per-tool health in workforce dashboard |
| identity state is separate from pane state | callbacks and reservations can be unverifiable | agent-mail token/continuity fuckups | P1 | agent-mail profiles | identity proof age and mismatch state |
| recovery attempts are not first-class | repeated nudges do not compound into diagnosis | auto-nudge/three-strike concern | P1 | logs | strike ledger and next action |
| storage/doctor gates block workforce indirectly | healthy workers appear stuck on unrelated substrate | storage gate and doctor blocker fuckups | P1 | doctor/fuckup rows | blocker attribution in workforce view |
| DID/DIDNT/GAPS is not attached to all worker outcomes | closeouts lose incomplete-work clarity | L80 surfaced by Socraticode | P1 | doctrine | validator enforcement in callback receipt |

No new beads are filed in this lane because these gaps are the intended problem space for this plan. If Phase 2 narrows any gap out of scope, L52 requires either a bead or explicit no-bead reason.

## 4. Cross-Session Reality

Live `ntm list --json` showed these sessions:

| session | visible now | panes visible | notes |
|---|---:|---:|---|
| `flywheel` | yes | 5 | pane 1 Claude callback/orch, panes 2/3/4 Codex workers, pane 0 human |
| `mobile-eats` | yes | 3 | pane 1 Codex orch/callback, pane 2 worker, pane 0 human |
| `skillos` | yes | 3 | pane 1 Codex orch/callback, pane 2 worker, pane 0 human |
| `clutterfreespaces` | yes | not analyzed | visible but outside named target set |
| `alpsinsurance` | no | unknown | present in topology tail, absent from live list/activity probe |
| `picoz` | no | unknown | present in topology tail, absent from live list/activity probe |

Topology tail claims expected sessions beyond the current live list:

- `alpsinsurance`: orchestrator/callback pane 0, workers 1/2/3, active client protected.
- `picoz`: orchestrator/callback pane 1, workers 2/3, expected pane count 4.

This is the most important cross-session fact: historical topology is not live reachability. A workforce dashboard must show both, with age and proof source:

| required dashboard column | why |
|---|---|
| `session_expected` | from topology or plan registry |
| `session_visible_live` | from current NTM list |
| `activity_sample_age` | prevents stale state reuse |
| `health_sample_age` | separates current proof from cached conclusion |
| `callback_pane` | routes delivery verification |
| `worker_panes` | capacity calculation |
| `last_dispatch_id_by_pane` | links work to pane state |
| `last_callback_validation` | closes callback debt |
| `reachability_status` | `visible`, `missing`, `stale_topology`, `unknown` |

## 5. Criticality Matrix

| rank | class | criticality | why it matters | immediate plan implication |
|---:|---|---|---|---|
| 1 | callback-never-arrived / callback debt | P0 | work can finish without orchestrator knowing, causing repeated redispatches or stale idle | build callback debt as a first-class stock |
| 2 | cross-session-blindness | P0 | whole sessions can disappear from the supervisor's view while topology still claims they exist | aggregate live reachability before capacity decisions |
| 3 | health/activity disagreement | P0/P1 | current probes can make opposite dispatch decisions for the same pane | add conflict state and fail-closed dispatch policy |
| 4 | frozen or stuck-thinking pane | P1 | capacity is consumed while no progress occurs | require zero-delta thresholds and recovery ladder |
| 5 | stale-error-text | P1 | false recovery attempts interrupt or misclassify healthy workers | require capture provenance and text age |
| 6 | MCP-disconnected / identity drift | P1 | worker can be healthy but unable to reserve files, send mail, or prove callback | add substrate health to worker status |
| 7 | storage/doctor gate cascade | P1 | repo-level blockers look like workforce inactivity | attribute blockers to substrate vs worker |
| 8 | DID/DIDNT/GAPS omission | P1/P2 | supervisor cannot distinguish completed scope from dropped scope | enforce closeout fields mechanically |

The top five are enough to explain Joshua's direct complaint: callback fixes exist, but the supervision layer still lacks a durable stock of worker state, callback debt, and recovery proof.

## 6. Required Signals Not Yet Collected

The current probes establish the problem but do not collect enough structured signal for a durable mesh. Missing signals:

| signal | required fields | consumer |
|---|---|---|
| per-pane live sample | session, pane, state, velocity, byte_delta, sampled_at, provenance, capture_age | workforce dashboard and frozen detector |
| source disagreement receipt | session, pane, sources, values, conservative_state, reason | dispatch capacity gate |
| dispatch assignment ledger | task_id, bead_id, session, pane, sent_at, expected_callback_at, callback_pane | callback debt monitor |
| callback validation ledger | task_id, delivery_seen, schema_valid, evidence_valid, no_bead_reason_valid, validated_at | orchestrator integrate step |
| auto-recovery ledger | task_id, session, pane, action, strike_count, cooldown_until, outcome | nudge/retry controller |
| identity proof | session, pane, agent_name, project, token_age_bucket, mismatch_reason | agent-mail and file-reservation checks |
| MCP health | server, tool_family, last_success, last_error_class, affects_sessions | substrate health row |
| topology reachability | session, expected_panes, live_panes, missing_panes, topology_age | cross-session dashboard |
| doctor blocker attribution | repo, blocker_class, blocks_dispatch, blocks_integrate, source_path | supervisor priority |
| storage gate stock | repo, free_bytes, threshold, override_status, affected_tasks | system-wide blocker triage |
| DID/DIDNT/GAPS receipt | did_count, didnt_ids, gaps_ids, no_bead_reason, callback_task_id | closeout integrity |

These signals should be captured as durable receipts, not merely rendered in a pane. The dashboard is a consumer; the receipts are the substrate.

## Closeout

DID:

1. Read the intent and doctrine inputs.
2. Ran skills-library survey and classified relevant skills.
3. Ran Socraticode survey for existing flywheel workforce/callback doctrine.
4. Probed live NTM list/activity/health and compared against topology.
5. Catalogued workforce states, failure modes, gaps, cross-session reality, criticality, and missing signals.
6. Wrote this read-only Lane A report.

DIDNT:

- none

GAPS:

- none outside the dispatched problem space

Ladder: passed. The report uses the three-judges lens, preserves read-only constraints, and leaves implementation/decomposition to later phases.
