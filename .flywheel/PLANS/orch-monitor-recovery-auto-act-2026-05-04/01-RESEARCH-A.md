---
title: "Lane A: Problem-Space Failure-Class Taxonomy — orch-monitor-recovery-auto-act"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A: Problem-Space Failure-Class Taxonomy — orch-monitor-recovery-auto-act

## Executive Summary

1. Inventoried 13 orchestrator-monitoring failure classes, covering the required 10 classes plus velocity-zero chevron, cross-fleet storm, and callback-orphan gaps.
2. Today exposed at least 10 missed recovery/supervision opportunities: skillos:1 frozen 13m, alps:1 blocker uncommunicated, and flywheel workers idle while peer-orch work existed.
3. Top missing gates: observe-to-act router, protected-session Josh-notify override path, and peer-mesh fallback when flywheel:1 itself is down.
4. Existing probes mostly measure state; few own the escalation/recovery decision, protected-session refusal, same-tick notification, and durable ledger.
5. Lane B/C should design an orch-supervisor CLI that composes existing probes, emits timeout-safe JSON, and routes recovery/notify/no-touch actions with audit receipts.

## Scope And Evidence

Plan: `orch-monitor-recovery-auto-act-2026-05-04`

Role: Lane A, problem-space inventory only.

Output paths:

- `/tmp/orchmon-lane-a.md`
- `.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/01-RESEARCH-A.md`

Read-only discipline:

- No source implementation files modified.
- No bead DB writes.
- No git commit performed.
- Plan artifact write only.

Evidence probes used:

- `/tmp/dispatch_orchmon_lane_a.md`
- `~/.claude/skills/donella-meadows-systems-thinking/SKILL.md`
- `~/.claude/skills/agent-fleet-management/SKILL.md`
- `~/.claude/skills/flywheel-recovery/SKILL.md`
- `~/.claude/skills/protected-session-recovery/SKILL.md`
- `~/.claude/skills/sla-monitoring/SKILL.md`
- `~/.claude/skills/escalation-management/SKILL.md`
- `~/.claude/skills/canonical-cli-scoping/SKILL.md`
- `.flywheel/scripts/frozen-pane-detector.sh`
- `.flywheel/scripts/frozen-pane-detector-fleet.sh`
- `.flywheel/scripts/stale-error-auto-ping.sh`
- `.flywheel/scripts/peer-orch-productivity-watch.sh`
- `.flywheel/scripts/peer-orch-blocker-watch.sh`
- `.flywheel/scripts/recovery-slo-probe.sh`
- `.flywheel/scripts/fleet-process-gap-detector.sh`
- `.flywheel/scripts/fleet-comms-health-probe.sh`
- `~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh`
- `~/.claude/skills/.flywheel/scripts/protected-session-recovery.sh`
- `~/.flywheel/canonical-meta-rules/sync.sh`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_xpane_recovery_recommendations_must_verify_canonical_flags_and_protections.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_single_capture_misses_freeze.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_is_the_killer_not_codex.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrators_kill_panes_without_respawn.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`

Live probe receipts:

- `/tmp/orchmon-peer-productivity.json`: `peer-orch-productivity-watch/v1`, status `pass`, 5/5 sessions productive at probe time.
- `/tmp/orchmon-comms.json`: `fleet-comms-health/v1`, status `green`; per-session scores were green.
- `/tmp/orchmon-process.json`: `fleet-process-gap-detector/v1`, `open_gap_count=33`, `stuck_class_count=24`, `process_health_score=0`.
- `/tmp/orchmon-recovery-slo.json`: `recovery-slo-probe/v1`, status `green`, no eligible recovery rows, p95 `0`.
- `/tmp/orchmon-blocker-watch.json`: `peer-orch-blocker-watch/v1`, status `pass`, `stale_blockers_count=0`, `checked_rows=63`.
- `/tmp/orchmon-frozen-doctor.json`: `frozen-pane-detector.v2`, detector health `healthy`, policy threshold `90s`, recovery SLO `180s`.
- Fleet conformance and observatory aggregate live runs hung in nested doctor calls and were killed. This is itself evidence that auto-act must consume timeout-safe cached observations, not unbounded nested doctors.

Socraticode survey:

- Query 1: `"peer orch monitoring recovery auto act frozen pane protected sessions calling in sick"`
- Query 2: `"fleet observatory aggregate peer productivity recovery SLO identity drift process gap comms health"`
- Relevant substrate surfaced: L75 peer-orch blocker coordination, L99 worker recovery SLO, L101 continuous fleet productivity, L103 conformance, L104 comms, L105 process gap, L106 observatory, and frozen-pane detector self-test patterns.

## Skills Adopted And Evaluated

- `donella-meadows-systems-thinking` — adopted. The missing leverage point is not another reminder; it is the observe-to-act feedback loop and protected-session routing rule.
- `agent-fleet-management` — adopted. Distinguishes real idle from apparent idle; fleet capacity must be measured against ready work, blockers, identity, and substrate health.
- `flywheel-recovery` — adopted. Supplies snapshot/restore/manifest discipline for orchestrator recovery.
- `protected-session-recovery` — adopted. Supplies protected-session refusal and explicit operator authorization shape.
- `sla-monitoring` — adopted. Supplies metric/target/window/escalation framing for recovery SLOs.
- `escalation-management` — adopted. Supplies severity routing and escalation cadence discipline.
- `canonical-cli-scoping` — adopted. Any Lane C supervisor CLI needs doctor/health/repair, validate/audit/why, `--json`, `--dry-run`, audit records, and stable exit codes.
- `agent-monitoring` — adopted from skills-best-practices result. Use as general monitoring/health posture reference.
- `loop-enforcement` — evaluated. Useful for tick-driver drift, but not sufficient for cross-session recovery auto-act.
- `agent-governance` and `agent-lifecycle` — evaluated. Useful for ownership lifecycle, but the immediate gap is operational recovery routing.
- `skills_library_gap` — no single skill currently binds orchestrator monitoring, protected-session recovery, peer-mesh failover, and automatic action into one reusable pattern. Lane C should consider a new `orch-monitor-auto-act` skill after design converges.

## Protected Session Policy

Protected sessions identified in existing recovery substrate:

- `alpsinsurance`
- `picoz`
- `skillos`

Policy:

- Auto-recover is refused for protected sessions.
- Same-tick Josh notification is required when frozen/dead/protected criteria are met.
- Recovery may proceed only after explicit evidence-based override.
- Velocity-zero with visible Codex chevron is a no-touch class even outside protected sessions; it escalates, never kills.

Existing protected-session recovery flag shape:

```text
--force-recover --operator-authorized --evidence-source joshua-confirmed --reason "<reason>"
```

Proposed supervisor shorthand for Lane C:

```text
--joshua-confirmed="<reason>"
```

The shorthand should expand to the existing canonical flags and write the raw reason to a recovery ledger, never to pane text.

## Per-Class Taxonomy

```yaml
- class: frozen-orch
  definition: >
    Orchestrator pane remains visually/live-process present but stops making progress across
    multi-frame capture, stable hash, and no recent dispatch/callback movement.
  detection_signal:
    probe_or_command: ".flywheel/scripts/frozen-pane-detector.sh --session <session> --json"
    jq_filter: ".candidates[]? | select((.classification == \"frozen\") or (.is_frozen == true) or ((.timer_delta_seconds // 0) == 0 and (.byte_delta // 999999) < 100))"
    threshold: ">=90s detector threshold; recovery SLO breach at >180s"
  severity: P0
  slo_seconds: 180
  reachable_today_via: "frozen-pane-detector.v2 and frozen-pane-detector-fleet wrapper"
  why_missed_today:
    observability_gap: "partial: detector exists, but supervisor did not run it as authoritative orch gate"
    gate_gap: "no observe-to-act router owns orch recovery decision"
    ledger_gap: "worker recovery ledger exists, but orch-level frozen/no-touch/notify receipt is not complete"
  joshua_blocker:
    any_level: false
    trigger: "Only if target session is protected or peer mesh cannot safely classify"
  recovery_owner: "flywheel:1"
```

```yaml
- class: velocity-zero-chevron-visible
  definition: >
    Pane has no apparent output velocity but shows a clean Codex chevron/prompt or otherwise
    indicates the agent is alive. This is a dangerous false-positive for recovery.
  detection_signal:
    probe_or_command: "ntm copy <session>:<pane> -l 80 plus frozen-pane-detector multi-frame probe"
    jq_filter: ".candidates[]? | select((.codex_chevron_visible == true) and ((.byte_delta // 0) == 0))"
    threshold: "Any chevron-visible no-progress candidate requires no-touch escalation, not kill/relaunch"
  severity: P0
  slo_seconds: 180
  reachable_today_via: "memory-backed classifier plus frozen-pane/stale-error probes"
  why_missed_today:
    observability_gap: "Codex-chevron truth is not normalized into one JSON field across all panes"
    gate_gap: "no hard no-touch gate in fleet-level action router"
    ledger_gap: "no durable do_not_touch_event receipt for future auditors"
  joshua_blocker:
    any_level: true
    trigger: "If work is blocked and chevron-visible state persists beyond SLO, escalate with evidence; do not recover autonomously"
  recovery_owner: "flywheel:1"
```

```yaml
- class: dead-codex
  definition: >
    Codex process exits or is replaced by shell, or robot activity reports ERROR with no
    clean prompt/progress evidence after recapture.
  detection_signal:
    probe_or_command: "ntm health <session> --json; ntm logs/robot activity; .flywheel/scripts/stale-error-auto-ping.sh --json"
    jq_filter: ".panes[]? | select(.current_command == \"zsh\" or .current_command == \"bash\")"
    threshold: "Process shell-only or ERROR persists across 2 captures separated by >=5s"
  severity: P0
  slo_seconds: 180
  reachable_today_via: "ntm health, stale-error-auto-ping, recovery relaunch doctrine"
  why_missed_today:
    observability_gap: "robot ERROR can be stale; command-state and pane-prompt evidence are not fused"
    gate_gap: "respawn alone is shell-only; relaunch-and-verify is not wired as one action"
    ledger_gap: "no unified codex_relaunch_event ledger across sessions"
  joshua_blocker:
    any_level: false
    trigger: "Protected sessions still require Josh authorization"
  recovery_owner: "flywheel:1"
```

```yaml
- class: idle-with-work-available
  definition: >
    Peer orchestrator or worker is not advancing while ready work, doctor errors, blockers,
    or plan next-actions exist and no true Joshua blocker is recorded.
  detection_signal:
    probe_or_command: ".flywheel/scripts/peer-orch-productivity-watch.sh --fleet --json"
    jq_filter: "(.sessions // .rows)[]? | select(.productivity_state == \"idle_with_work_available\" or ((.ready_count // 0) > 0 and (.active_workers // 0) == 0))"
    threshold: ">=300s idle while work exists"
  severity: P1
  slo_seconds: 300
  reachable_today_via: "peer-orch-productivity-watch/v1"
  why_missed_today:
    observability_gap: "probe exists; live sample was green, but historic miss was not replayed from ledger"
    gate_gap: "watcher escalates, but does not select and dispatch next actionable work"
    ledger_gap: "idle decisions are not always written as no_bead_reason or productivity receipt"
  joshua_blocker:
    any_level: false
    trigger: "Only if ready work is explicitly blocked by current Joshua question"
  recovery_owner: "flywheel:1"
```

```yaml
- class: blocker-stuck
  definition: >
    Peer orchestrator names a flywheel-class blocker and flywheel:1 does not acknowledge,
    route, or clear it inside the coordination SLO.
  detection_signal:
    probe_or_command: ".flywheel/scripts/peer-orch-blocker-watch.sh --doctor --json"
    jq_filter: ".stale_blockers_count > 0 or ((.peer_orch_blocker_age_seconds // 0) >= 300)"
    threshold: ">=300s without flywheel:1 ack"
  severity: P0
  slo_seconds: 300
  reachable_today_via: "peer-orch-blocker-watch/v1, L75 doctrine fields"
  why_missed_today:
    observability_gap: "depends on peers writing structured blocker rows; prose blockers can bypass it"
    gate_gap: "ack detection exists, but no automatic route-to-owner or same-tick re-dispatch"
    ledger_gap: "blocker resolution receipt is not mandatory for every peer-orch blocker"
  joshua_blocker:
    any_level: false
    trigger: "Only when blocker is truly external after L48 probe ledger"
  recovery_owner: "flywheel:1"
```

```yaml
- class: no-tick-3d
  definition: >
    Repo/session loop has not produced a valid tick or closeout receipt for three days,
    despite being installed or active.
  detection_signal:
    probe_or_command: "fleet conformance probe or find ~/.local/state/flywheel-loop for stale last_tick receipts"
    jq_filter: ".sessions[]? | select((.last_tick_age_seconds // 0) >= 259200)"
    threshold: ">=259200s stale tick marker; act within 300s once detected"
  severity: P1
  slo_seconds: 300
  reachable_today_via: "fleet-conformance-probe partially; live run hung in nested doctor"
  why_missed_today:
    observability_gap: "probe is not timeout-safe enough for an auto-act loop"
    gate_gap: "no automatic owner assignment for stale loop sessions"
    ledger_gap: "no stale_tick_event ledger with reason and next owner"
  joshua_blocker:
    any_level: false
    trigger: "Only if repo is intentionally parked by Joshua"
  recovery_owner: "flywheel:1"
```

```yaml
- class: canonical-drift-N
  definition: >
    A repo's canonical doctrine surfaces drift by N rules or template sections across
    root AGENTS, AGENTS-CANONICAL, template, README, or other registered surfaces.
  detection_signal:
    probe_or_command: "~/.flywheel/canonical-meta-rules/sync.sh --fleet-check-three-surface --json"
    jq_filter: ".results[]? | select((.missing_rules_count // 0) > 0 or (.drift_count // 0) > 0)"
    threshold: "N>0 warning; N>=3 or protected repo drift is P0/P1"
  severity: P1
  slo_seconds: 300
  reachable_today_via: "canonical sync, process gap detector, conformance surfaces"
  why_missed_today:
    observability_gap: "drift is visible; process sample had 33 open gaps and top three-surface drift rows"
    gate_gap: "no auto-patch/dispatch route consistently follows drift detection"
    ledger_gap: "drift repair receipts are split across process, commit, and callback surfaces"
  joshua_blocker:
    any_level: false
    trigger: "Only if doctrine change itself needs Joshua decision"
  recovery_owner: "flywheel:1"
```

```yaml
- class: flywheel:1-itself-down
  definition: >
    Primary flywheel orchestrator pane is dead, frozen, unreachable, or unable to receive
    callbacks while peer orchestrators continue to need fleet supervision.
  detection_signal:
    probe_or_command: "peer mesh ntm health flywheel --json plus callback-pane liveness probe"
    jq_filter: ".panes[]? | select(.pane_index == 1 and (.current_command == \"zsh\" or .status != \"running\"))"
    threshold: ">=180s no liveness/callback evidence"
  severity: P0
  slo_seconds: 180
  reachable_today_via: "manual ntm health only; no dedicated peer-mesh supervisor"
  why_missed_today:
    observability_gap: "peers do not share an agreed flywheel:1 liveness fact"
    gate_gap: "no peer-mesh failover owner or broadcast rule when flywheel:1 is down"
    ledger_gap: "no peer_mesh_takeover_event ledger"
  joshua_blocker:
    any_level: true
    trigger: "If peer mesh cannot restore or agree on successor within SLO"
  recovery_owner: "peer_mesh"
```

```yaml
- class: substrate-corrupt
  definition: >
    Required orchestration substrate is corrupt or unusable: beads DB, Agent Mail identity,
    ntm routing, state ledgers, SQLite WAL, or canonical registry.
  detection_signal:
    probe_or_command: "flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json"
    jq_filter: ".beads_db_health == \"fail\" or .agent_mail_health.status == \"fail\" or .ntm_health.status == \"fail\" or ([.errors[]? | select((.code // \"\") | test(\"beads|sqlite|agent_mail|ntm|identity\"))] | length) > 0"
    threshold: "Any P0 substrate corruption, or >1 critical substrate warning"
  severity: P0
  slo_seconds: 60
  reachable_today_via: "doctor fields, process gap detector, identity/comms probes"
  why_missed_today:
    observability_gap: "doctor can hang when nested through aggregate; needs cached timeout-safe fact"
    gate_gap: "repair tool selection is not automated from the doctor code"
    ledger_gap: "repair dry-run/apply receipts are not unified"
  joshua_blocker:
    any_level: true
    trigger: "If repair is destructive, protected, credential-shaped, or lacks L48 probe ledger"
  recovery_owner: "flywheel:1"
```

```yaml
- class: PROTECTED_SESSION-but-frozen
  definition: >
    Protected session is frozen/dead by multi-frame proof. Automatic recovery is forbidden,
    but same-tick Josh notification is mandatory.
  detection_signal:
    probe_or_command: "grep PROTECTED_SESSIONS ~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh plus frozen-pane-detector"
    jq_filter: ".candidates[]? | select((.session | IN(\"alpsinsurance\",\"picoz\",\"skillos\")) and (.classification == \"frozen\" or .is_frozen == true))"
    threshold: "Any protected frozen candidate after 2-frame confirmation"
  severity: P0
  slo_seconds: 180
  reachable_today_via: "protected-session-recovery skill, protected list, frozen detector"
  why_missed_today:
    observability_gap: "protected status and frozen status are not joined in one supervisor field"
    gate_gap: "auto-recover refusal exists; Josh-notify same tick is not mechanically wired"
    ledger_gap: "no protected_refusal_notify_event receipt"
  joshua_blocker:
    any_level: true
    trigger: "Always, unless Joshua has already provided explicit protected-session recovery authorization"
  recovery_owner: "joshua"
```

```yaml
- class: identity-rotation-mid-flight
  definition: >
    Worker/orchestrator identity changes while a dispatch is active, leaving callbacks,
    file reservations, Agent Mail tokens, or ownership chains ambiguous.
  detection_signal:
    probe_or_command: "flywheel-loop doctor --json; inspect ~/.local/state/flywheel/agent-mail/sessions/*.json"
    jq_filter: "(.identity_rotation_count_24h // 0) > 0 or (.orphan_tokens_unswept_count // 0) > 0 or (.identity_chain_max_length // 1) > 1"
    threshold: "Any active-dispatch identity rotation or orphan token row"
  severity: P1
  slo_seconds: 300
  reachable_today_via: "identity registry doctor fields, comms health probe"
  why_missed_today:
    observability_gap: "identity drift fields exist but are not tied to active work ledgers"
    gate_gap: "no pause/reroute rule for callbacks after identity rotation"
    ledger_gap: "identity handoff receipts are not consistently required"
  joshua_blocker:
    any_level: false
    trigger: "Only if canonical token vault cannot resolve without raw-token exposure"
  recovery_owner: "flywheel:1"
```

```yaml
- class: cross-fleet-failure-storm
  definition: >
    Three or more sessions degrade in the same tick window, indicating shared substrate,
    doctrine, identity, comms, or process collapse rather than isolated pane failure.
  detection_signal:
    probe_or_command: ".flywheel/scripts/fleet-observatory-aggregate.sh --json, or compose process/comms/conformance probes"
    jq_filter: "([.sessions[]? | select(.status != \"green\" and .status != \"pass\")] | length) >= 3"
    threshold: ">=3 degraded sessions in one tick"
  severity: P0
  slo_seconds: 60
  reachable_today_via: "fleet observatory concept exists; live aggregate hung without timeout-safe doctor"
  why_missed_today:
    observability_gap: "aggregate can hang; no cached bounded snapshot guarantees"
    gate_gap: "no storm circuit breaker or incident-mode router"
    ledger_gap: "no fleet_storm_event linking all affected sessions"
  joshua_blocker:
    any_level: true
    trigger: "If storm includes protected sessions, credentials, or all peer recovery owners"
  recovery_owner: "peer_mesh"
```

```yaml
- class: cross-session-callback-orphan
  definition: >
    Worker completes or blocks but callback is sent to the wrong pane/session, not verified,
    or cannot be correlated to the dispatch owner.
  detection_signal:
    probe_or_command: "verify-callback-delivery plus dispatch ledger scan"
    jq_filter: "(.cross_session_callback_orphan_count // 0) > 0 or (.worker_callback_not_verified_count // 0) > 0"
    threshold: "Any unverified callback older than callback SLO"
  severity: P1
  slo_seconds: 300
  reachable_today_via: "callback verification substrate exists; orphan-specific fleet field is incomplete"
  why_missed_today:
    observability_gap: "callback delivery is verified per task, but not aggregated as supervision state"
    gate_gap: "no auto-retry/route when callback receiver is wrong or dead"
    ledger_gap: "missing callback_orphan_event receipt"
  joshua_blocker:
    any_level: false
    trigger: "Only if all callback routes are dead"
  recovery_owner: "flywheel:1"
```

## Today’s Failure Mapping

### skillos:1 frozen for 13 minutes

Mapped classes:

- `PROTECTED_SESSION-but-frozen`
- `frozen-orch`
- `velocity-zero-chevron-visible` if prompt/chevron was present
- `flywheel:1-itself-down` only if flywheel:1 failed to supervise during the same window

Expected behavior:

- Multi-frame detector confirms frozen state.
- Protected-session join sees `skillos` in protected list.
- Auto-recover is refused.
- Josh notification fires same tick with evidence summary and explicit override flag shape.
- Ledger writes `protected_refusal_notify_event`.

What missed:

- Protected status and frozen classification were not fused as a single doctor/action fact.
- Existing protected-session script enforces apply-time safety, but no same-tick notify gate consumes it.
- Frozen detector is available, but not continuously authoritative for peer-orch panes.

### alps:1 Vercel deploy blocker uncommunicated

Mapped classes:

- `blocker-stuck`
- `idle-with-work-available`
- `PROTECTED_SESSION-but-frozen` only if blocker co-occurred with a frozen pane
- `cross-session-callback-orphan` if callback or escalation went to the wrong owner

Expected behavior:

- Peer-orch writes structured blocker row with `blocker_type=flywheel_class` or `external`.
- `peer-orch-blocker-watch` sees no flywheel:1 ack after 300s.
- flywheel:1 routes owner or escalates with L48 probe ledger.
- Protected-session policy prevents destructive recovery if `alpsinsurance` recovery is involved.

What missed:

- Prose blockers can bypass the blocker-watch ledger.
- Same-tick route-to-owner is not automatic.
- Communication failure did not promote to a durable recovery/escalation receipt.

### Two flywheel Codex workers idle while peer orch was down

Mapped classes:

- `idle-with-work-available`
- `flywheel:1-itself-down`
- `cross-fleet-failure-storm`
- `cross-session-callback-orphan` if dispatch receipts were missing

Expected behavior:

- Productivity watch identifies ready work or peer-orch outage.
- Peer mesh detects flywheel:1 supervision gap if pane 1 is not responding.
- Idle workers receive next actionable safe work or a recovery lane.

What missed:

- The productivity probe measured current productivity but did not own historical replay/action.
- There is no peer-mesh fallback when the primary supervisor is itself impaired.
- Available worker capacity is not automatically coupled to peer-orch recovery queues.

## Cross-Cutting Findings

1. Measurement is ahead of action. Frozen, productivity, blocker, process, comms, recovery SLO, and conformance probes exist, but no single router turns observations into recover/notify/refuse/dispatch decisions.
2. Protected sessions have apply-time refusal, not full incident flow. The hard part now is same-tick Josh notification plus evidence ledger, not the refusal itself.
3. Single-truth liveness is unsafe. Robot ERROR, single pane capture, and velocity-zero are all insufficient; the classifier needs multi-frame hash, command state, chevron state, dispatch/callback ledger, and protected-session status.
4. The fleet has worker recovery SLOs but not orch recovery SLOs. Lane C should create explicit orch-level p50/p95/breach fields and not overload worker recovery metrics.
5. Fleet aggregate must be bounded. Live conformance/observatory aggregate probes hung in nested doctor calls; auto-act needs cached, timeout-limited inputs.
6. Ledger gaps are the common loss point. If no-touch, notify, recovery, peer-mesh takeover, and storm events are not durable rows, the next tick cannot tell whether inaction was intentional or missed.
7. Joshua blockers must be typed, not inferred. Protected-session recovery, destructive substrate repair, full mesh failure, and velocity-zero-chevron escalation are Joshua blocker classes; routine dead Codex or idle work are not.
8. Cross-fleet storm needs a circuit breaker. Three degraded sessions in one tick should switch the system from per-pane repair into incident-mode routing.
9. The current top process gaps are doctrine/process drift, not pane death. `/tmp/orchmon-process.json` showed `open_gap_count=33`, so auto-act must not only restart panes; it must route process repairs.
10. Existing CLI surfaces need composition, not replacement. Lane C should keep current probes as facts and design a supervisor that composes them with stable schema and action policy.

## Recommendations For Lane B/C

1. Define `orch-supervisor/v1` as a composition layer over current probes. It should not reimplement detectors; it should normalize them into action facts.
2. Required command surface: `doctor`, `health`, `repair`, `validate`, `audit`, `why`, `schema`, `--json`, `--dry-run`, `--apply`, `--joshua-confirmed=<reason>`, and stable exit codes.
3. Add a policy matrix with actions: `NO_TOUCH_ESCALATE`, `NOTIFY_JOSH`, `RECOVER_LOCAL`, `ROUTE_PEER_MESH`, `DISPATCH_WORK`, `BLOCK_ON_SUBSTRATE`, and `INCIDENT_MODE`.
4. Add `orch_recovery_event/v1` ledger with event types: `frozen_detected`, `dead_codex_relaunched`, `protected_refusal_notify`, `do_not_touch_chevron`, `peer_mesh_takeover`, `storm_detected`, `substrate_repair_dryrun`, `callback_orphan_retry`.
5. Make protected-session status a first-class join key in every recovery candidate, not an afterthought at apply time.
6. Add timeout-safe cached aggregate reads. Auto-act should fail closed on stale aggregate data and fall back to direct bounded probes.
7. Add peer-mesh fallback for `flywheel:1-itself-down`: peer sessions can detect primary supervisor loss, nominate owner, and notify Josh if the mesh cannot agree.
8. Add a cross-fleet storm detector: 3+ sessions degraded in one tick triggers incident mode and suppresses isolated noisy repairs until shared cause is classified.
9. Require every no-touch outcome to be ledgered. The system should prove it intentionally avoided touching velocity-zero chevron or protected sessions.
10. Separate Joshua blockers from flywheel-owned blockers mechanically. `joshua_blocker=true` should require a class-specific trigger and evidence field.
11. Use `protected-session-recovery` as the apply backend for protected recovery only after explicit authorization.
12. Use `flywheel-recovery` snapshot manifest discipline for non-protected relaunch/recovery.
13. Use `sla-monitoring` to define orch recovery SLOs: detection, decision, action, verification, and callback/notification.
14. Add test fixtures for today’s exact failures: skillos protected frozen, alps blocker uncommunicated, and idle flywheel workers while peer orch is down.
15. Add a dogfood test that intentionally feeds stale robot ERROR plus visible chevron and verifies `NO_TOUCH_ESCALATE`, not recovery.

## Lane A Metrics

- `classes_inventoried=13`
- `classes_with_existing_probe=11`
- `classes_with_gate_gap=13`
- `classes_with_ledger_gap=8`
- `joshua_blocker_classes=4`
- `today_failures_mapped=yes`
- `top_3_gates_missing=observe_to_act_router,protected_notify_override,peer_mesh_flywheel_down`
- `commits_total=0`

## Ladder Check

- Output file exists at `/tmp/orchmon-lane-a.md`: yes.
- Plan artifact exists at `.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/01-RESEARCH-A.md`: yes after mirror.
- At least 10 classes inventoried: yes, 13.
- Required classes included: yes.
- Protected sessions included: yes, `alpsinsurance`, `picoz`, `skillos`.
- Velocity-zero chevron-visible no-touch rule included: yes.
- Cross-fleet failure storm included: yes.
- Today’s skillos/alps failures mapped: yes.
- Skills cited with adopt/evaluate decisions: yes.
- Read-only discipline maintained: yes.
- Git commit performed: no.
- Self-grade: W.
