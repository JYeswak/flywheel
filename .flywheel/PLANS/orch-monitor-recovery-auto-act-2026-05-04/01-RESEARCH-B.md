---
title: "Phase 1 Lane B - Ecosystem Audit"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Lane B - Ecosystem Audit

Plan: orch-monitor-recovery-auto-act-2026-05-04
Lane: B, ecosystem audit
Worker: flywheel:3 / MagentaPond
Generated: 2026-05-04
Output mirror: /tmp/orchmon-lane-b.md
Socraticode queries: 5
Indexed chunks observed: 198092

## 1. Executive Summary

1. Lane B verdict: the substrate already has most raw primitives needed for auto-action.
2. The missing primitive is a fleet supervisor that consumes those primitives as one closed loop.
3. Current observatory state is measurement-rich and action-poor at the fleet level.
4. `frozen-pane-detector.sh` can recover narrow frozen/queued Codex states with leases, cooldowns, idempotency keys, and recovery ledgers.
5. `frozen-pane-detector-fleet.sh` installs a disabled-by-default launchd wrapper and scheduled cycles remain observation-only by design.
6. `peer-orch-productivity-watch.sh` can send xpane productivity escalation packets with `--apply`.
7. `peer-orch-productivity-watch.sh` can notify Joshua for `true_josh_blocker` cases with `notify` and macOS notification fallback.
8. `fleet-comms-health-probe.sh` can ping silent sessions and notify only for token-expired substrate corruption with `--apply`.
9. `fleet-process-gap-detector.sh` can file fix beads with `--apply --idempotency-key`.
10. `fleet-observatory-aggregate.sh` computes a composite score and `recommended_action`, but it has no apply mode and no consumer that executes the recommendation.
11. `recovery-slo-probe.sh` measures L99 p95 recovery latency and breach count, but it only observes ledger rows after another primitive writes them.
12. `fleet-watcher-coverage-probe.sh` exposes watcher coverage and idle-ready counts, but it does not repair missing watchers or dispatch work.
13. Launchd surfaces exist for idle watchers, loop ticks, fleet health, Agent Mail, and frozen-pane observation.
14. The loaded launchd snapshot showed idle watchers for flywheel, alps, skillos, mobile-eats, and vrtx loaded, but the frozen-pane fleet detector installed and not loaded.
15. Current point-in-time probes were green for productivity, comms, and aggregate observatory, while process-gap detector still reported high process debt.
16. That green state does not refute the plan intent; it shows the issue is intermittent failure handling and missing auto-act wiring.
17. The plan intent cites real misses: skillos:1 frozen 13+ minutes, alps deploy approval blocker, idle flywheel panes, and observatory probes that measured without acting.
18. AGENTS L99 requires worker recovery within 180 seconds and names frozen-pane-detector v2, idle-state-probe, L95, and L91 as the tuned detection stack.
19. AGENTS L101 says flywheel:1 owns continuous productivity and true blockers must notify Joshua immediately.
20. Lane B found L101 partially implemented in `peer-orch-productivity-watch.sh`, but not composed into an always-on supervisor that also handles frozen panes and dead workers.
21. Donella map: the current system has strong information flows (#6), some rules (#5), and localized self-organization (#4).
22. The missing leverage is a higher-level rule and self-organization loop: "when observatory state crosses action thresholds, execute the safe bounded primitive."
23. Jeff/upstream prior art strongly supports supervision trees, restart budgets, circuit breakers, durable audit, recoverable state, and explicit safety policies.
24. The strongest ADOPT pattern is a bounded supervisor loop with per-pane restart budget, idempotency ledger, protected-session gate, and post-action reprobe.
25. The strongest EXTEND pattern is existing flywheel observatory probes as decision inputs, not as more dashboard lines.
26. The strongest AVOID pattern is a generic daemon that restarts panes from one signal or one session name.
27. Lane C should design an `orch-monitor-supervisor` that runs in shadow mode first, reads existing probes, classifies failure class, plans exactly one action, executes only with gates, writes one ledger row, and re-probes.
28. Lane C should not build new frozen detection, new Agent Mail identity, new watcher coverage logic, or a new dashboard.
29. The supervisor should be narrow: consume existing JSON fields and call existing apply-capable scripts.
30. The supervisor should expose dry-run by default, explicit `--apply`, `--idempotency-key`, `--allow-protected-recovery`, and `--no-notify`.
31. It should support a protected-session decision table instead of hard-coded session names.
32. It should degrade to notify-only when snapshot/work-loss audit is nonzero or truth is degraded.
33. It should use `ntm` only for pane operations.
34. It should treat "Joshua noticed first" as an SLO breach and create durable evidence.
35. Self-grade for Lane B: Y.

## 2. Substrate Inventory Table

| # | Primitive | Path | Current role | Apply mode | Already wired | Gap for this plan |
|---|---|---|---|---|---|---|
| 1 | Frozen pane detector v2 | `.flywheel/scripts/frozen-pane-detector.sh` | Detects frozen, unknown, template-stub, and queued-not-submitted pane states | Yes: `--auto-recover`; `--dry-run` optional | Used by detector fleet wrapper and tests | Not consumed by an orchestrator-level supervisor for all failure classes |
| 2 | Frozen recovery leases | `~/.local/state/flywheel-loop/frozen-pane-recovery-leases/` | Prevents concurrent recovery of the same pane | Internal to detector | Local primitive only | Lane C should reuse, not duplicate |
| 3 | Frozen recovery ledger | `~/.local/state/flywheel-loop/frozen-pane-recovery-ledger.jsonl` | Stores recovery, queued-submit recovery, latency, and idempotency evidence | Written by detector apply | Read by SLO probe | Needs fleet supervisor row linking decision -> action -> reprobe |
| 4 | Frozen pane samples | `~/.local/state/flywheel-loop/frozen-pane-samples/` | Durable scrollback evidence for classifications | Written by detector | Local primitive only | Supervisor should link sample paths in its ledger |
| 5 | Frozen detector self-test | `tests/frozen-pane-detector-self-test.sh` | Regression coverage for detection and recovery actions | Test only | Yes in test suite | Lane C should add supervisor fixtures around it |
| 6 | Frozen detector SLO thresholds | `tests/frozen-pane-detector-slo-thresholds.sh` | Verifies 90s/60s recovery-related thresholds | Test only | Yes in test suite | Supervisor should preserve L99 180s envelope |
| 7 | Frozen fleet wrapper | `.flywheel/scripts/frozen-pane-detector-fleet.sh` | Launchd wrapper, budgets, stop/fatal gates, observation cycles | Limited: install/uninstall/repair apply; cycle apply blocks recovery by design | Plist installed, disabled, not loaded in current probe | Needs a supervisor consumer to call base detector apply when safe |
| 8 | Frozen fleet launchd | `~/Library/LaunchAgents/ai.zeststream.frozen-pane-detector-fleet.plist` | 30s scheduled observation surface | Disabled by design | Installed but not loaded at probe time | Needs explicit enablement decision or supervisor scheduling path |
| 9 | Recovery SLO probe | `.flywheel/scripts/recovery-slo-probe.sh` | Measures p50/p95 recovery latency and 180s breaches | No | Doctor/status surface | SLO-only; no active recovery |
| 10 | Idle state probe | `.flywheel/scripts/idle-state-probe.sh` | Classifies waiting panes into dispatching/cooldown/light_queue/saturated/etc. | No | Idle watcher and doctor/status | Does not dispatch by itself |
| 11 | Idle pane auto dispatch | `.flywheel/scripts/idle-pane-auto-dispatch.sh` | Promotes ready beads into idle worker panes with L50/L51/L52 callback requirements | Yes: `--apply` sends dispatch | Loaded via idle-pane-watch plists for several sessions | Handles idle-with-work, not frozen/dead workers |
| 12 | Idle watcher plists | `com.zeststream.flywheel-idle-pane-watch`, `ai.zeststream.*-idle-pane-watch` | Periodic idle auto-dispatch drivers | Apply inside script | Loaded for flywheel/alps/skillos/mobile-eats/vrtx | No cross-class supervision |
| 13 | Peer blocker watch | `.flywheel/scripts/peer-orch-blocker-watch.sh` | Detects stale cross-orch blocker ledger rows | No | Doctor/status field | No notify/recovery path by itself |
| 14 | Peer productivity watch | `.flywheel/scripts/peer-orch-productivity-watch.sh` | Classifies productive, idle_with_work_available, substrate_blocked, true_josh_blocker | Yes: sends xpane packets or Josh notify | Status/doctor surface and tests | Not always-on as the top-level supervisor for all lane A classes |
| 15 | Productivity ledger | `~/.local/state/flywheel/productivity-escalations.jsonl` | Stores productivity escalation sent and true blocker notify rows | Written by productivity apply | Read by comms health | Needs dedupe key and escalation result lifecycle for supervisor |
| 16 | Fleet comms health | `.flywheel/scripts/fleet-comms-health-probe.sh` | Scores token freshness, cross-orch packet age, unread escalations, pending productivity, identity liveness, classifier agreement | Yes: ping silent sessions; notify token-expired corruption | Doctor/status and tests | Applies comms repair only, not worker recovery |
| 17 | Comms health ledger | `~/.local/state/flywheel/fleet-comms-health.jsonl` | Stores comms pings, token-expired notify, false-positive classifier rows | Written by comms apply | Probe-local | Needs unified action ledger correlation |
| 18 | Cross-orch coordination ledger | `~/.local/state/flywheel/cross-orch-coordination.jsonl` | Durable coordination packets and blocker evidence | Written by other primitives | Read by blocker/comms | Supervisor should consume but not replace |
| 19 | Fleet conformance probe | `.flywheel/scripts/fleet-conformance-probe.sh` | Scores fleet conformance axes and can send drift packets | Yes, with dry-run/apply flags | Status/doctor and tests | Current live probe was too slow for Lane B; treat as support, not main recovery primitive |
| 20 | Fleet process gap detector | `.flywheel/scripts/fleet-process-gap-detector.sh` | Aggregates recurring process failures into top gaps and optional fix-bead plans | Yes: requires `--apply --idempotency-key` | Doctor/status and tests | It files structural beads; it does not fix frozen workers now |
| 21 | Process gap state | `~/.local/state/flywheel/process-gap-detector/` | Process gap cache and fix-bead ledger | Written by process detector | Probe-local | Useful for supervisor "file structural fix" fallback |
| 22 | Fleet observatory aggregate | `.flywheel/scripts/fleet-observatory-aggregate.sh` | Composite eight-spine fleet score and recommended action | No | Status/doctor surface and tests | Core missing consumer: recommendation is not executed |
| 23 | Fleet watcher coverage probe | `.flywheel/scripts/fleet-watcher-coverage-probe.sh` | Reports watcher coverage, idle ready workers, dispatch age | No | Status/doctor | Does not install/repair watcher holes |
| 24 | Fleet canonical rule freshness | `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` | Checks canonical doctrine freshness across sessions | No | Status/doctor | Not part of worker recovery except as process debt signal |
| 25 | Fleet L-rule lag probe | `.flywheel/scripts/fleet-l-rule-lag-probe.sh` | Reports lagging sister repos | No | Status/doctor | Process debt only |
| 26 | Agent Mail identity registry | `~/.local/state/flywheel/agent-mail/sessions/*.json` | Durable session:pane identity and token vault pointers | Mutated by resolver/preallocator | Used by comms, dispatch templates, callbacks | Supervisor must carry identity_resolved and token_path only, never raw tokens |
| 27 | Identity history | `.flywheel/scripts/identity-history.sh` | Audits identity rotations and predecessor chain | No | Doctor/status | Protected recovery should preserve predecessor chain |
| 28 | Orchestrator worker manifest | `.flywheel/scripts/orch-worker-identity-manifest.sh` | Derived worker identity manifests from topology and registry | No | Dispatch template input | Supervisor should read manifest when choosing target pane identity |
| 29 | NTM fleet health | `.flywheel/scripts/ntm-fleet-health.sh` and launchd `ai.zeststream.ntm-fleet-health` | Fleet health heartbeat/launchd surface | Observation | Loaded | Does not auto-act on frozen-worker SLO breach |
| 30 | Flywheel loop driver plists | `ai.zeststream.*-flywheel-loop.plist` | Repo-local loop tick dispatch drivers | Apply via plist installation elsewhere | Several loaded; skillos loop had nonzero launchctl status in snapshot | Driver health is an input; recovery remains separate |
| 31 | Protected session recovery skill | `~/.claude/skills/protected-session-recovery/scripts/protected-session-recovery.sh` | Snapshot, work-loss audit, explicit evidence gate, ntm R3 relaunch workaround | Yes, gated | Skill exists, wrapper exists | Supervisor should call dry-run for protected cases and notify-only unless flags authorize |
| 32 | Flywheel recovery skill | `~/.claude/skills/flywheel-recovery` | Recovery guidance and repair patterns | Skill/reference | Human/agent consulted | Lane C should cite as fallback, not create new recovery doctrine |
| 33 | Notify binary | `~/.local/bin/notify` | Pushover/mac alert path from scripts | Apply side effect | Used by productivity and comms scripts | Needs unified policy: true Josh blockers and protected recovery only |
| 34 | Halt disease watchdog | `.flywheel/scripts/halt-disease-watchdog.sh` | Detects halt-like idle/doctor/ready-work violations | Observation | Test surfaces exist | Candidate signal for supervisor, not direct recovery primitive |
| 35 | Dispatch delivery receipt L91 | AGENTS L91, dispatch templates | Four-state delivery and callback receipts | Doctrine | Enforced in dispatches | Supervisor actions need their own delivery receipt shape |

Point-in-time probe notes from Lane B:

- `frozen-pane-detector-fleet.sh --doctor --json`: PASS, daemon installed, daemon_loaded=false, disabled_by_default=true, cadence=30, global budget=4/hour, per-pane budget=1/hour.
- `recovery-slo-probe.sh --json`: green, p95=0, breach_count=0, measured_recovery_count=0 in the current 24h window.
- `peer-orch-productivity-watch.sh --fleet --json`: pass, total=5, productive=5, idle-with-work=0, substrate-blocked=0, true-josh-blocker=0 at probe time.
- `fleet-comms-health-probe.sh --fleet --json`: green, total=5, healthy=5, min_score=100 at probe time.
- `fleet-observatory-aggregate.sh --json`: green, health_score=100, spines_aggregated=8 at probe time.
- `fleet-watcher-coverage-probe.sh --json`: coverage 4/5, last dispatch age about 648 seconds at probe time.
- `fleet-process-gap-detector.sh --json --max-gaps 5`: open_gap_count=33, stuck_class_count=24, process_health_score=0, top gaps were three-surface drift classes.
- `fleet-conformance-probe.sh --fleet --json` was stopped after more than 40 seconds because child doctor probes were still running; Lane C should avoid blocking the supervisor on slow full-fleet doctors.

## 3. Jeff / Upstream Patterns Table

| # | Source | Evidence | Adopt / Evaluate / Avoid | Application to Lane C |
|---|---|---|---|---|
| 1 | `mcp_agent_mail` | `/Users/josh/Developer/jeff-corpus/mcp_agent_mail/README.md:188` to `:225` | ADOPT | Keep Beads as task authority and Agent Mail for reservations, messages, and audit. Supervisor actions should thread by bead or action id. |
| 2 | `beads_rust` / Beads convention | `/Users/josh/Developer/jeff-corpus/mcp_agent_mail/README.md:204` to `:231` | ADOPT | Structural fixes should become beads; recovery events should not become ad hoc chat. |
| 3 | `ntm` safety/policy | `/Users/josh/Developer/jeff-corpus/ntm/README.md:190` to `:211` | ADOPT | Recovery operations need policy checks, durable approval style, and no direct multiplexer calls. |
| 4 | `ntm` recoverable state | `/Users/josh/Developer/jeff-corpus/ntm/README.md:238` to `:245` and `:361` to `:388` | ADOPT | Supervisor must write checkpoints/audit/receipts, and every action must be replayable/idempotent. |
| 5 | `agentic_coding_flywheel_setup` | `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md:16` | ADOPT | Reuse existing flywheel setup patterns, but do not import a parallel loop system. |
| 6 | `destructive_command_guard` | `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md:18` | ADOPT | Recovery must stay gated, dry-run first, and explicit about destructive/relaunch actions. |
| 7 | `frankenterm` swarm runtime | `/Users/josh/Developer/jeff-corpus/frankenterm/docs/architecture.md:97` to `:134` | EVALUATE | It validates a modular fleet launcher, scheduler, work queue, and mission loop design; adopt shape, not implementation. |
| 8 | `frankenterm` pipeline recovery | `/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core/src/swarm_pipeline.rs:1138` to `:1190` | ADOPT | Build `classify -> plan -> apply -> compensate/reprobe` around existing primitives. |
| 9 | `franken_node` supervision tree | `/Users/josh/Developer/jeff-corpus/franken_node/docs/specs/section_10_11/bd-3he_contract.md:1` to `:43` | ADOPT | Use restart strategy plus sliding-window budget plus bounded escalation plus health report. |
| 10 | `asupersync` supervision config | `/Users/josh/Developer/jeff-corpus/asupersync/src/supervision.rs:426` to `:450` | ADOPT | Carry restart policy, max_restarts, window, backoff, escalation, and storm threshold in config. |
| 11 | `asupersync` restart tracker | `/Users/josh/Developer/jeff-corpus/asupersync/src/supervision.rs:2443` to `:2467` | ADOPT | Deterministic restart verdicts from virtual/event timestamps are better than wall-clock-only logic. |
| 12 | `remote_compilation_helper` circuit breaker | `/Users/josh/Developer/jeff-corpus/remote_compilation_helper/docs/adr/003-circuit-breaker.md:20` to `:75` | ADOPT | Add closed/open/half-open behavior for panes after repeated failed recovery. |
| 13 | `ntm` resilience monitor | `/Users/josh/Developer/jeff-corpus/ntm/internal/resilience/monitor.go:53` to `:73` | EVALUATE | NTM has an autoRestart monitor pattern, but flywheel should not bypass its existing L-rules. |
| 14 | `flywheel_gateway` services | `/Users/josh/Developer/jeff-corpus/flywheel_gateway/docs/architecture.md:91` to `:110` | EVALUATE | Gateway has supervisor, notifications, reservations, metrics, and safety modules; use as concept map. |
| 15 | `frankensearch` repair orchestrator | Socraticode hit: `frankensearch-core/src/repair.rs` corruption detection, attempts, service state transitions | EVALUATE | Repair orchestration shape is useful for state-machine rows; do not add search dependency. |
| 16 | `frankensqlite` | Inventory says SKIP at `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md:38` | AVOID | Do not introduce a new DB substrate for this supervisor; JSONL ledgers are enough. |
| 17 | `franken_agent_detection` | Inventory says SKIP at `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md:122` | AVOID | Existing frozen/idle/ntm classifiers are more specific and already wired. |
| 18 | `cubcode` | Not found as a local repo in `/Users/josh/Developer` or the Jeff inventory scan | AVOID | No evidence to adopt for this lane. |
| 19 | `swarm-operator-loop` | Appears as a learning-matrix pattern, not as a local repo; matrix emphasizes audit, callback, doctor, repair, fixture traits | EVALUATE | Useful as vocabulary only; do not depend on absent code. |

## 4. Cross-Cutting Findings

1. Finding B1: there are many probe producers and too few action consumers.
2. Evidence: fleet observatory aggregates eight spines and emits `recommended_action`, but has no `--apply`.
3. Evidence: productivity and comms probes do have `--apply`, but each owns one axis.
4. Risk: flywheel can show green while a frozen pane incident was already missed earlier in the day because no fleet supervisor tied samples to action.
5. Recommendation: Lane C should define a small action consumer over existing probe JSON.

6. Finding B2: recovery safety exists in pieces, but not in one decision table.
7. Evidence: base frozen detector has idempotency keys, cooldowns, leases, cross-session allow gate, and recovery ledger.
8. Evidence: protected-session-recovery has snapshot, work-loss audit, explicit authorization, and evidence-source gates.
9. Evidence: productivity watch distinguishes xpane action from true Josh blocker notification.
10. Gap: no single table maps class -> safe action -> protected gate -> notification.
11. Recommendation: Lane C should make the table the contract, not bury it in branch logic.

12. Finding B3: launchd is present, but launchd is not the whole supervisor.
13. Evidence: idle watcher plists are loaded for five sessions.
14. Evidence: frozen detector fleet plist is installed but disabled and not loaded.
15. Evidence: loop plists are loaded for several repos, with skillos loop showing a nonzero launchctl status in snapshot.
16. Gap: launchd can trigger a script, but the script needs a bounded action policy.
17. Recommendation: supervisor should be launchd-capable, but testable without launchd.

18. Finding B4: current detectors already encode L99/L101 intent; the missing part is escalation closure.
19. Evidence: AGENTS L99 says recovery within 180s and measured continuously (`AGENTS.md:2472` to `:2480`).
20. Evidence: AGENTS L101 says idle-with-work triggers xpane escalation and true blockers notify Joshua (`AGENTS.md:2597` to `:2601`).
21. Gap: the fleet plan asks for continuous reaction across frozen/dead/blocker/idle classes, not just one watcher's class.
22. Recommendation: supervisor should be the only owner of cross-class escalation closure.

23. Finding B5: slow full-fleet doctor calls are a supervisor hazard.
24. Evidence: Lane B stopped `fleet-conformance-probe.sh --fleet --json` after it exceeded the working budget and spawned slow per-repo doctor probes.
25. Risk: if the supervisor blocks on slow doctor, it can miss the 180s recovery SLO.
26. Recommendation: cache or timebox heavy probes; use last known doctor values where possible; never let conformance block frozen recovery.

27. Finding B6: current ledgers are fragmented by lane.
28. Evidence: frozen recovery, productivity escalation, comms health, process-gap fix beads, cross-orch coordination, and file reservations all have separate ledgers.
29. Gap: no root action id connects the original failure, planned action, mutation, notification, and reprobe.
30. Recommendation: add `orch-monitor-actions.jsonl` with stable `action_id` and references to child ledgers.

31. Finding B7: protected session recovery should be evidence-based, not name-based.
32. Evidence: protected-session-recovery skill explicitly says evidence-based policy, snapshot capture, work-loss audit, and explicit authorization.
33. Gap: existing frozen detector can recover non-protected control session panes, but supervisor must decide when to switch to protected mode.
34. Recommendation: use `pending_work_loss_count`, project/client flags, current prompt queue, dirty worktree evidence, and session role, not only `session in PROTECTED_SESSIONS`.

35. Finding B8: notify policy exists, but should remain sparse.
36. Evidence: productivity watch notifies true Josh blockers; comms probe notifies token-expired-beyond-recovery; storage doctrine uses high-priority notify for hard blockers.
37. Risk: a generic auto-act loop could spam Joshua.
38. Recommendation: only notify for true Josh blocker, protected recovery blocked by evidence, recovery budget exhausted, or SLO breached and no autonomous action allowed.

39. Finding B9: Agent Mail reservation worked through local shared-surface reservation; MCP reservation requires token-mediated auth.
40. Evidence: `file_reservation_paths` returned registration-token-required for MagentaPond in this MCP session.
41. Evidence: `flywheel-loop identity --session flywheel --pane 3 --json` resolved MagentaPond with token_path and active status.
42. Safety decision: no raw token was printed or passed through pane-visible text.
43. Recommendation: Lane C should use the durable resolver and a non-rendering token bridge or existing MCP session auth, not ad hoc registration.

## 5. Prior-Art-From-Today Gap Analysis

1. Core failure from intent: skillos:1 frozen for 13+ minutes while flywheel:1 did not act.
2. Existing coverage: frozen detector v2 can classify identical live scrollback/timer cases and recover with idempotency.
3. Existing coverage: L99 sets 180s SLO and thresholds at 90s detection and 30s cadence.
4. Missing coverage: frozen fleet wrapper scheduled cycles are observation-only and currently disabled/not loaded.
5. Required Lane C bridge: if detector says frozen and truth is healthy, call base detector `--auto-recover` with idempotency key unless protected gate blocks.

6. Core failure from intent: alps approval blocker sat for hours/days with no Pushover/mac-alert.
7. Existing coverage: productivity watch can classify `true_josh_blocker` and notify via `notify` plus macOS notification.
8. Existing coverage: blocker watch tracks stale blocker age and stale rows.
9. Missing coverage: no supervisor periodically turns stale blocker rows into the productivity watch apply path.
10. Required Lane C bridge: if blocker age > threshold and classification is true Josh blocker, call productivity apply or direct notify path once with dedupe.

11. Core failure from intent: flywheel panes 2+3 were idle while skillos:1 was frozen.
12. Existing coverage: idle-state-probe and idle-pane-auto-dispatch can dispatch ready beads to waiting panes.
13. Existing coverage: watcher coverage probe shows which sessions have idle watchers and last dispatch age.
14. Missing coverage: idle availability is not automatically paired with frozen-session recovery as a work source.
15. Required Lane C bridge: if one session is frozen and flywheel has idle panes, dispatch a recovery/support bead or supervisor packet.

16. Core failure from intent: six observatory probes shipped today measure but do not auto-act.
17. Existing coverage: fleet-comms and productivity have apply modes; process detector can file beads; frozen base detector can recover.
18. Existing coverage: aggregate gives health score and recommended action.
19. Missing coverage: aggregate recommendation is not consumed.
20. Required Lane C bridge: supervisor should consume aggregate for priority ordering, but action should be based on specific underlying fields.

21. Core failure from intent: `Joshua detected before fleet detected` should become evidence.
22. Existing coverage: L99 says this creates INCIDENTS row plus structural fix bead.
23. Missing coverage: no script appears to ingest "Joshua noticed first" as a first-class event.
24. Required Lane C bridge: add a manual/automatic SLO breach ledger row with `detected_by=Joshua|fleet` and file fix bead when Joshua wins.

25. Core failure from intent: multi-pane worker frozen detection should include same status over two ticks and unchanged time.
26. Existing coverage: frozen detector has timer-identical/queued not submitted logic and live delta sampling.
27. Existing coverage: comms probe includes multi-frame liveness classifier as one axis.
28. Missing coverage: watcher-level supervisor does not yet combine two-tick stable status with recovery action.
29. Required Lane C bridge: supervisor should require two samples for ambiguous states but allow timer-identical fast path when frozen detector reports it.

## 6. External Pattern Survey

1. systemd service restart policies.
2. Official source: freedesktop systemd service docs, `Restart=`, `RestartSec=`, and start-rate limiting via `StartLimitIntervalSec`/`StartLimitBurst`: https://www.freedesktop.org/software/systemd/man/systemd.service.html
3. Useful pattern: restart is allowed, but bounded by start-rate limits and delays.
4. Fit for Lane C: per-pane and global recovery budgets already exist; expose them as supervisor config.
5. Avoid: systemd-style blind `Restart=always` for pane work because panes carry user/session state.

6. Kubernetes probes.
7. Official source: Kubernetes liveness, readiness, startup probes: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
8. Useful pattern: liveness restarts unhealthy containers; readiness removes endpoints without restart; startup prevents premature liveness.
9. Fit for Lane C: split `pane_liveness`, `work_loss_readiness`, and `truth_source_startup/degraded` before recovery.
10. Avoid: restarting on readiness failure; for us readiness failure should notify/block, not mutate.

11. Erlang/OTP supervisors.
12. Official source: Erlang supervisor principles: https://www.erlang.org/doc/system/sup_princ.html
13. Useful pattern: supervisors define child specs, restart strategies, restart intensity, and escalation.
14. Fit for Lane C: map each pane/session to a child spec with strategy `one_for_one`, bounded intensity, and escalation target.
15. Avoid: one-for-all restarts across sessions; flywheel panes are not interchangeable child processes.

16. AWS Auto Scaling health checks.
17. Official source: Amazon EC2 Auto Scaling health checks: https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-checks-overview.html
18. Useful pattern: health check sources can mark capacity unhealthy and replacement happens after checks agree.
19. Fit for Lane C: require independent truth sources before replacement/recovery and write replacement/recovery lifecycle rows.
20. Avoid: treating pane replacement as capacity replacement without preserving work/session context.

21. PagerDuty escalation policies.
22. Official source: PagerDuty escalation policy basics: https://support.pagerduty.com/main/docs/escalation-policies
23. Useful pattern: escalation stops once acknowledged, resolved, or timed out/escalated.
24. Fit for Lane C: notify rows need ack/resolution states and no repeat notification while an active incident is unacked.
25. Avoid: repeating Pushover/mac alerts on every tick without dedupe.

26. Google SRE alerting.
27. Official source: Google SRE Monitoring Distributed Systems and Practical Alerting: https://sre.google/sre-book/monitoring-distributed-systems/ and https://sre.google/sre-book/practical-alerting/
28. Useful pattern: alert on symptoms or imminent real problems; if a response is predictable, automate it.
29. Fit for Lane C: frozen pane and true blocker are symptoms; if safe recovery is predictable, automate; if not, notify with exact runbook.
30. Avoid: adding more dashboards for operator interpretation where the action is deterministic.

31. OpenTelemetry semantic conventions.
32. Official source: OpenTelemetry semantic conventions: https://opentelemetry.io/docs/specs/semconv/
33. Useful pattern: stable names and attributes make events queryable across metrics, logs, and traces.
34. Fit for Lane C: define stable fields for `failure_class`, `action_id`, `idempotency_key`, `protected_gate`, `planned_action`, `actual_action`, and `reprobe_status`.
35. Avoid: free-form action logs that cannot be joined to child ledgers.

## 7. Recommendations For Lane C

1. Build or specify `orch-monitor-supervisor.sh` as the smallest viable top-level loop.
2. Inputs: frozen detector JSON, productivity watch JSON, blocker watch JSON, comms health JSON, watcher coverage JSON, recovery SLO JSON, aggregate JSON, and latest topology.
3. Output: `~/.local/state/flywheel/orch-monitor-actions.jsonl`.
4. Default mode: `--dry-run --json`.
5. Apply mode: `--apply --idempotency-key <stable-key> --json`.
6. Dedupe key: `session:pane:failure_class:fingerprint`.
7. Stable action id: sha256 over plan id, session, pane, failure class, fingerprint, and action version.
8. Required fields: `action_id`, `ts`, `failure_class`, `session`, `pane`, `detector_sources`, `planned_action`, `actual_action`, `idempotency_key`, `budget_verdict`, `protected_gate`, `notify_verdict`, `child_ledger_refs`, `reprobe`.
9. Do not block on slow full-fleet doctor calls; enforce per-probe timeout and cached fallback.
10. Use aggregate score only for prioritization, not as mutation evidence.

11. Failure class table:
12. `frozen_worker`: run frozen detector base `--auto-recover` if live truth healthy, budget ok, not protected, and idempotency unseen.
13. `queued_not_submitted`: run frozen detector base queued recovery, usually bare Enter, if detector says recovery_allowed.
14. `dead_codex`: run protected-session-recovery dry-run first; apply only if work-loss audit zero and operator-authorized or policy allows non-protected pane.
15. `idle_with_work_available`: call idle auto-dispatch or productivity watch apply to send escalation packet.
16. `true_josh_blocker`: call notify path once and write cross-orch ledger row.
17. `substrate_blocked`: file or dispatch substrate repair bead, not notify Joshua unless L48 ledger exhausts all rungs.
18. `watcher_missing`: file process gap or repair/install watcher, depending on existing apply primitive.
19. `recovery_slo_breach`: file structural fix bead and notify only if no autonomous remediation remains.
20. `comms_silent`: call comms health apply ping, not recovery.
21. `token_expired_beyond_recovery`: notify Joshua and file identity substrate fix bead.

22. Protected-session gate:
23. Run snapshot capture before mutation.
24. Run work-loss audit before mutation.
25. Block if queued prompt visible.
26. Block if dirty worktree visible.
27. Block if session is client-bearing and no explicit policy permits recovery.
28. Block if source truth degraded.
29. Block if per-pane budget exhausted.
30. Block if global budget exhausted.
31. Block if idempotency replay detected.
32. When blocked, write notify-only action with exact human-visible reason.

33. Budgets:
34. Start with frozen fleet wrapper defaults: global 4 recoveries/hour and 1 per pane/hour.
35. Add circuit breaker: 3 failed recoveries in 24h opens pane circuit.
36. Half-open after one successful non-mutating reprobe window.
37. Escalate to structural bead after circuit opens.
38. Never recover `UNKNOWN` classifications.
39. Never recover template-stub prompt classifications.
40. Never decrement L60 signals silently.

41. Reprobe contract:
42. After any mutation, sleep bounded interval and re-run the same detector.
43. Success requires failure class absent and pane liveness healthy.
44. Failure writes `reprobe_status=failed` and opens/advances circuit breaker.
45. Unknown reprobe writes `reprobe_status=unknown` and blocks further mutation.
46. Notify only when reprobe failure leaves no safe autonomous next step.

47. Test plan for Lane C:
48. Fixture: frozen non-protected pane -> planned recovery in dry-run.
49. Fixture: frozen non-protected pane with idempotency seen -> no-op replay.
50. Fixture: frozen protected pane with queued prompt -> notify-only blocked recovery.
51. Fixture: queued-not-submitted -> bare Enter planned, no respawn.
52. Fixture: idle_with_work_available -> xpane productivity escalation planned.
53. Fixture: true_josh_blocker -> single notify row and no duplicate on next tick.
54. Fixture: stale comms -> comms ping, not pane restart.
55. Fixture: slow conformance doctor -> supervisor continues using cached value.
56. Fixture: budget exhausted -> circuit/escalation row, no mutation.
57. Fixture: recovery success -> child ledger ref plus successful reprobe.
58. Fixture: recovery failure -> structural fix bead plan.

59. Files Lane C should likely own:
60. `.flywheel/scripts/orch-monitor-supervisor.sh`
61. `tests/orch-monitor-supervisor.sh`
62. `.flywheel/scripts/README.md`
63. `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md` only if adding a new canonical L-rule.
64. `/Users/josh/.claude/commands/flywheel/status.md` only if adding one compact line, after existing observatory/process/comms lines.
65. Avoid editing existing detectors unless tests prove a detector bug.

66. Donella leverage map:
67. #6 information flows: supervisor consumes existing probes and emits unified action ledger.
68. #5 rules: explicit class-to-action table and protected-session gate.
69. #4 self-organization: flywheel:1 can recover/dispatch/notify without Joshua interpreting dashboards.
70. #3 goals: fleet goal becomes "continuous productive recovery under L99/L101", not "green dashboards."

71. Final Lane B recommendation:
72. Proceed to Lane C with a composition-first design.
73. Do not build another detector.
74. Do not build another dashboard.
75. Do not add another identity surface.
76. Reuse frozen detector apply, productivity apply, comms apply, process bead apply, protected-session-recovery dry-run/apply, and existing launchd/plist topology.
77. Add one supervisor ledger and one action decision table.
78. Shadow mode first; apply behind explicit flag; load/launchd only after fixtures and dry-run receipts pass.
79. Callback metrics to report from Lane B: substrate_primitives_audited=35, has_apply_mode=8, already_wired=10, gap_count=9, jeff_patterns_adopted=7, evaluated=7, avoided=4.
80. Lane B complete.
