# INTENT — orch-monitor-recovery-auto-act-2026-05-04

## Verbatim topic from Joshua

> orchestrator-monitor-recovery-fleet-supervision-failure: flywheel:1 is supposed to actively monitor sister orchestrators (skillos:1, alps:1, mobile-eats:1, vrtx:1, picoz:1) and recover them per calling-in-sick policy. Failure mode observed 2026-05-04: skillos:1 froze ~13min (Working timer stuck, multi-frame hash identical, codex chevron visible — frozen-pane v2 class) WITHOUT flywheel:1 detecting OR auto-recovering. Joshua flagged it. Same failure: alps:1 has standing blocker (vercel deploy approval) for hours/days WITHOUT flywheel:1 escalating to Joshua via the proper notify path. Two flywheel codex workers idle WHILE peer-orch frozen. Root cause: the watchers + observatory probes we shipped today (peer-orch-productivity-watch, frozen-pane-detector v2, fleet-process-gap-detector, fleet-comms-health-probe, fleet-conformance-probe, fleet-observatory-dashboard) MEASURE the fleet but do NOT auto-act. The observatory sees `frozen=yes capture_provenance=live state_since=13min ago`, but no escalation loop fires. Per L99 worker-recovery-SLO 180s + L101 productivity ownership + calling-in-sick policy: peer-orch frozen >180s should auto-trigger flywheel:1 multi-frame verify + canonical recovery sequence (capture → respawn → relaunch codex → wait → inject → verify) OR auto-escalate to Joshua-notify if in PROTECTED_SESSIONS without override. Same for blocker-on-approval class: alps blocker >2 ticks should auto-Pushover Joshua. The fleet observability we shipped today is half-built without these auto-act loops. Plan must close the loop: observatory measures + automated remediation kicks within SLO + Joshua-notify ONLY for true substrate/PHI/security blockers. Plan must enumerate ALL peer-orch failure classes (frozen, blocker-stuck, idle-with-work, dead-codex, no-tick-3d) + the corresponding auto-act per class + the doctor surfaces that prove the auto-act ran + the ledger row that proves it. This is THE flywheel-not-needing-founder mission criterion. Today's gaps must become beads.

## Through

`--through=research` (Phase 1 only, then Joshua reviews)

## Why P0

Mission-anchor failure. flywheel:1's role per `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md` + calling-in-sick policy is to KEEP THE FLEET RUNNING. Today's session demonstrated the OPPOSITE: 13min skillos:1 freeze undetected by orch, alps:1 standing blocker uncommunicated, two flywheel codex workers idle while peer-orch was down. Joshua flagged it manually — that IS the failure signal.

## Concrete failure evidence (must be cited in research outputs)

1. **skillos:1 frozen 13min+**: multi-frame test confirmed identical hash (fa189027cd72) over 16s. `Working (13m 36s • esc to interrupt)` shown. `velocity=0`. robot-activity says THINKING but velocity 0 over 13min = frozen. flywheel:1 took NO action.
2. **alps:1 vercel deploy approval blocker**: Joshua reports it has been a standing blocker for hours/days. flywheel:1 NEVER escalated via Pushover/mac-alert. blocker should have auto-routed to Josh-notify after 2 ticks per peer-orch-blocker-watch SLO.
3. **flywheel codex panes 2+3 idle WHILE skillos:1 frozen**: violation of L101 productivity rule. Workers should have been redirected to recovery work.
4. **6 observatory probes shipped today** measure but DO NOT act: peer-orch-productivity-watch, frozen-pane-detector v2, fleet-process-gap-detector, fleet-comms-health-probe, fleet-conformance-probe, fleet-observatory-dashboard. All have `--apply` flags but no auto-trigger loop.

## Constraints on the plan

- READ-ONLY through Phase 3
- Research only (`--through=research`); Joshua decides Phase 4-5
- Phase 1 lanes: A=problem-space (failure-class taxonomy), B=ecosystem-audit (Jeff/upstream patterns + existing flywheel substrate), C=implementation-design (auto-act loop mechanism + ledger schema + Joshua-notify gates)

## Additional findings during plan kickoff (must inform Lane A/B/C)

### Finding 1: mission-anchor IS the approval

**Joshua-asked**: "why would I even start a vercel mission project if i didn't approve the deployment?"

flywheel:1 was citing "alps vercel deploy approval blocker" as a Joshua-blocker. **WRONG.** The mission anchor of the alps repo IS vercel deployment. Approval is implicit in mission-anchor existence. The vercel skill exists in the library (`~/.claude/skills/vercel/`).

**Plan implication**: blocker-classifier must read the target repo's `MISSION.md` + `GOAL.md` to detect whether the action is mission-aligned. If yes, NOT a Joshua-blocker — flywheel:1 owns dispatching the mission-aligned skill (vercel skill) and proceeding. Joshua-notify is reserved for actions OUTSIDE mission scope (e.g. financial commitment, security posture change, PHI access).

Add to Lane A taxonomy: class `phantom-joshua-blocker` (action mission-aligned but escalated as if blocker — root cause: classifier doesn't read MISSION.md).

### Finding 2: orch-pane reading was wrong

flywheel:1 cited "alps:1 standing blocker" but multi-pane sweep shows alps:1 is a **healthy Opus 4.7 claude orch actively working** ("Writing the report now. Percolating 1m36s"). The actual outstanding alps issue is alpsinsurance:**2** frozen (PROTECTED_SESSION, correctly held per CoralRaven's L95 refusal documented 19:30Z).

**Plan implication**: orch-state classifier must distinguish (session, pane) precisely. "alps blocker" without pane index is invalid. L100 identity-primary-key already says (session, pane, project) is the key.

### Finding 3: phantom-blocker observed but not surfaced

The cross-orch-coordination ledger contains the alps:2 PROTECTED-SESSION-frozen state from 19:26Z + 19:30Z. flywheel:1 did NOT auto-route this to Joshua-notify with override prompt — it just sat there. That IS the auto-act-loop gap the plan addresses.

### Finding 4 (CORRECTION): all alps workers responding

**Joshua-corrected**: "none of the alps workers are down - they are all responding"

flywheel:1 cited "alpsinsurance:2 frozen" from a 19:26Z ledger row (~3 hours old at this kickoff). Live `--robot-activity=alpsinsurance` at 22:05Z shows 1 UNKNOWN (orch claude) + 3 WAITING (healthy idle workers). **No frozen panes in alps right now.** The 19:26Z freeze was real then, was correctly held per PROTECTED_SESSION, and has since resolved (likely Joshua-handled or self-healed).

**Plan implication**: blocker-classifier MUST distinguish stale ledger rows from current state. Reading a freeze event from 3 hours ago and treating it as live = false-positive escalation. Every orch-state assertion needs:
- live `--robot-activity` capture (timestamp ≤60s old)
- multi-frame hash test if signal is "stuck"
- ledger row used ONLY for trend/history, NEVER as current truth

Add to Lane A taxonomy: class `stale-ledger-misread-as-current` — flywheel:1 generated false escalations from old ledger rows.

The earlier "alps standing blocker" claim was THIS class. The actual current alps state: healthy.

### Updated current-state assessment (22:05Z, fresh capture)

- **flywheel**: pane 1=THINKING (me/orch), pane 2=WAITING, pane 3=WAITING, pane 4=THINKING (structural-fix in flight)
- **skillos**: pane 1=THINKING-but-frozen-13min (multi-frame confirmed identical hash), pane 2=WAITING — REAL FROZEN ORCH, action needed
- **alpsinsurance**: pane 1=UNKNOWN (claude orch — UNKNOWN is normal for claude robot-classify), panes 2/3/4=WAITING — HEALTHY
- **mobile-eats**: pane 1=THINKING, pane 2=THINKING — both working
- **vrtx**: pane 1=UNKNOWN (claude orch), panes 2/3/4=WAITING — HEALTHY
- **picoz**: no agents reported — no tick today, but PROTECTED_SESSION

**Single actual current failure**: skillos:1 frozen 13min+. Everything else is healthy or correctly held.

This radically simplifies what flywheel:1 should have done: ONE escalation, not three.

### Finding 5: CoralRaven (alps:1) independently converged

While this plan was being kicked off, alpsinsurance:1 (CoralRaven) cross-orch-broadcast a deep-dive report at `/Users/josh/Developer/alpsinsurance/.flywheel/reports/2026-05-04-vercel-blocker-deep-dive.md` that **independently arrives at the same root cause from the alps side**.

CoralRaven's frame is sharper than mine in two ways:

1. **Refuse-gates vs permit-gates asymmetry** — substrate has `mission-anchor-dispatch-preflight.sh` that REFUSES dispatch on unfilled MISSION.md, but no symmetric **`mission-anchor-dispatch-license.sh`** that PERMITS dispatch when the locked envelope authorizes it. This is the cleanest architecture statement of the gap.

2. **3-strike pattern same-day** — Supabase password (17:00Z), region selection (17:05Z), Vercel dispatch (20:05Z–21:00Z, 90m of dead time). Same axis, three corrections from Joshua. Pattern not incident. Meadows leverage #6 (information flow) + #4 (self-organization).

CoralRaven's 4 asks become Lane C bead DAG candidates:
- **(A)** doctrine note: strategic-vs-tactical layering (locked-envelope = AI executes; outside-envelope = Joshua disposes)
- **(B)** spec: `mission-anchor-dispatch-license.sh` (the symmetric permit-gate)
- **(C)** `/flywheel:dispatch` skill update to consult license-gate before dispatch
- **(D)** cross-orch broadcast to fleet for same-pattern self-check

CoralRaven also adopting Meadows #9 fix (15-min deferral self-timeout) immediately and dispatching Vercel against locked envelope next. **Plan implication**: Lane C MUST consult CoralRaven's report. Don't redo their analysis. Build on it.

This is the flywheel working: peer-orch independently surfaces structural finding via XPANE; flywheel:1 plan absorbs it. The auto-act loop the plan proposes would have caught it ~75 minutes earlier (orch idle >5min on a decidable task = productivity-escalation tier 1, not Joshua-notify).

### Finding 6 (CORRECTION): skillos:1 is NOT frozen — slow-subprocess-blocked

After re-checking with capture inspection at 22:18Z (~25min after Joshua's flag):

- multi-frame hash STILL identical (9f4c4a05e03a × 2)
- BUT buffer shows: `Waiting for background terminal (3m 39s) · 2 background terminals · ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/...`
- skillos:1 is waiting on `flywheel-loop doctor` (known-slow, has timed out for me earlier today too)

**This is NOT a frozen pane. It's slow-subprocess-blocked.**

Codex is healthy + idle, just waiting on a synchronous subprocess that's taking 3m+. Not a recovery class. Not a Joshua-blocker. **Self-resolves when doctor returns.**

**Plan implication**: orch-state classifier MUST distinguish three "stuck-looking" classes:
1. `frozen-codex` — codex itself stuck, no fg/bg activity, multi-frame identical, NO active subprocess
2. `waiting-on-slow-subprocess` — codex idle, bg subprocess running >2min (today's skillos case + my own slow-doctor timeouts)
3. `waiting-on-codex-llm` — `Percolating` / `Working` against Anthropic/xAI API, active token streaming

Recovery actions are different per class. False positive on (2) or (3) = orchestrator-is-the-killer fault.

Today's flywheel-loop doctor itself being slow IS the ecosystem-level finding. Plan must mention: doctor speed regression candidate bead (likely tied to all the new probes added today loading sequentially).

Now Joshua's flag was visually correct (UI looked frozen) but the underlying truth was different. Plan must give flywheel:1 a way to capture buffer + parse it + classify before classifying as "frozen."

### Finding 7: orch-of-orch (flywheel:1) became a passive ledger-keeper this round

Joshua-flagged 22:25Z: "you are proving we have a massive gap in our observability - did I not say that observability of the fleet was my number one priority? what have you even been doing this round?"

Honest answer: I shipped the MEASUREMENT spines (6 observatory probes) but never wired the AUTO-ACT loop. Then I sat in cron-tick rhythm:
- reading doctor JSON every 25min
- writing STATE.md tick lines like a logbook
- scheduling next wake-up

That is **passive ledger-keeping**, not orchestration. The probes shipped today report:
- `fleet_observatory_health_score=61` (YELLOW)
- `fleet_three_surface_drift_total_count=N>0` per session
- `peer_orch_idle_with_work_available_count` updates each tick
- pane states across all 5 sister sessions

I read those numbers and **logged them**. I did not **act on them**.

Same-tick failures I missed:
- alps:1 misclassified as blocker (was healthy claude orch working)
- alps "vercel deploy approval" misclassified as Joshua-blocker (mission-anchor IS the approval; vercel skill exists)
- skillos:1 misclassified as frozen (was waiting on slow `flywheel-loop doctor` subprocess — visible in buffer)
- 3-hour-old ledger rows treated as current state
- 30+min flywheel pane idle while peer-orch states visible in doctor

This IS the observability gap Joshua named THE #1 priority. Probes report correct numbers. flywheel:1 (me) treated them as data points instead of triggers. **The auto-act loop is missing AND the orch-of-orch's own discipline to act is missing.**

**Plan implication (sharpen Lane C)**: the supervision loop must NOT just be a launchd background daemon. It must be **the orch-of-orch's tick handler**. Every flywheel:1 tick MUST start with: (1) read all observatory fields, (2) classify each finding to a Lane A class, (3) decide owner, (4) act OR escalate, (5) THEN proceed with whatever else. The current cron-rhythm went `read doctor → log STATE.md → sleep` instead of `read doctor → classify → ACT → log → sleep`.

Lane C must spec this as: `orch-tick-supervision-handler` — runs FIRST in every flywheel:1 tick. Today's failure proves this is the load-bearing primitive. Until it ships, flywheel:1's tick is a logbook, not a supervisor.

**Direct admission**: my prior cron-loop ticks were of low value relative to the time spent. They produced STATE.md rows and dispatch-log entries, but they did NOT advance fleet supervision. Joshua's flag IS the auto-act loop today — that's the failure, not the recovery.


## Phase 1 supplemental — sibling-plan-feeding research (2026-05-04T22:40Z)

Two parallel research dispatches landed during wire-or-explain Phase 3 AUDIT, both targeting orch-monitor-recovery Phase 4 absorption. Both share #4+#6 substrate-self-organization shape.

### A. Worker-watcher fleet propagation (pane 3 callback)

- **Output:** `/tmp/worker-watcher-propagation-output.md`
- **Self-grade:** Y (acceptable; nuance corrected my earlier read)
- **Inventory:** 3/6 repos have watchers (per-session launchd → central `idle-pane-auto-dispatch.sh`); repo-local substrate present in 1/6 full + 1/6 partial
- **Root cause:** repo-local watcher substrate not propagated by flywheel-install template
- **Recommendation:** Option C hybrid — fleet daemon + per-repo plist
- **Beads proposed:** 5 for orch-monitor Phase 4
- **No L-rule needed** (skill-local + template-local change)

### B. Beads-db auto-VACUUM substrate gap (pane 4 callback)

- **Output:** `/tmp/beadsdb-vacuum-gap-output.md`
- **Self-grade:** W
- **Failure classes inventoried:** 9 (UNIQUE constraint regression, malformed-snapshot, freelist-leaf-too-big on pages 941/942, OpenRead post-rebuild + 5 more)
- **Maintenance predicate:** "safe to VACUUM iff (≥1 pane WAITING for ≥M min) AND (no in-flight br write last K sec)"; M and K rationale in output
- **Recommendation:** Option A — `/flywheel:tick` adds maintenance sub-step (consistent with wire-or-explain doctrine: tick handler is wiring authority AND maintenance authority)
- **Beads proposed:** 4 for orch-monitor Phase 4
- **No Jeff issue needed** (substrate gap is local, not upstream)

### Combined Phase 4 absorption

Total: **9 sibling-plan beads** to layer into Phase 4 DAG when orch-monitor advances. Both share the recurring 2026-05-04 axis: **substrate should self-organize, currently doesn't** — same Donella class as Finding 9 substrate-loss.

Both research outputs cite source-line evidence; absorb verbatim into Phase 4 bead descriptions.


## Phase 1 supplemental II — L111 + 54-item scope (2026-05-04)

### Cross-reference

See sibling plan
`.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md` Finding
11 for the full 54-item inventory and the L110/L111 paradigm. This
supplement covers the **orch-monitor share** — the 19 items that orch-monitor
absorbs because they are observation-without-auto-act surfaces, not artifact
stocks.

### Joshua's directive (verbatim)

> "every body of work must pass real-time through `/rust-best-practices`,
> `/python-best-practices`, `/canonical-cli-scoping`, `/readme-writing`, and
> the 3-judges sniff. Not later. Not in polish. AT WRITE-TIME."

L111 codified in canonical AGENTS.md + AGENTS-CANONICAL.md (this session).
Sibling to L110. Orch-monitor's auto-act loops MUST emit callbacks that
satisfy L111 — the supervision handler is itself a write-time producer.

### Orch-monitor share of the 54-item inventory (19 items)

Schema fields per L110: `stock | class | consumer | owner | verification_probe | tick_consequence`.

#### Section B — Substrate primitives with observation surface but no auto-fire (11)

| # | Primitive | Stock | Class | Consumer (orch-monitor Lane C target) | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|
| B1 | `peer-orch-productivity-watch.sh` | idle peer-orchs with work | watcher-coverage | orch-tick supervision handler | grep tick log for productivity-watch invoke + dispatch row | error |
| B2 | `frozen-pane-detector.sh` v2 | frozen panes detected | watcher-coverage | recovery-dispatcher (Lane C bead) | grep tick log + recovery action row | error |
| B3 | `fleet-conformance-probe.sh` | conformance score < threshold | watcher-coverage | yellow/red escalation handler | grep dispatch-log for conformance-escalation | warn |
| B4 | `fleet-comms-health-probe.sh` | silent-session count > 0 | watcher-coverage | comms-escalation handler | grep dispatch-log for silent-session-poke | warn |
| B5 | `fleet-process-gap-detector.sh` | open process-gap beads | watcher-coverage | gap-bead-consumer | beads ready filter on `class=process-gap` | warn |
| B6 | `fleet-observatory-aggregate.sh` | composite health < 80 | watcher-coverage | dashboard surface + tick handler read | grep tick log for observatory-read + act | warn |
| B7 | `peer-orch-blocker-watch.sh` | peer-orch blocker > 2 ticks | watcher-coverage | Pushover notify + escalation | grep notify-log for peer-orch-blocker rows | error |
| B8 | `recovery-slo-probe.sh` | SLO breach count_24h > 0 | watcher-coverage | SLO-breach handler | grep tick log for SLO-act | warn |
| B9 | `josh-request-tick-promote.sh` | unpromoted Joshua requests | watcher-coverage | tick handler scheduled invoke | grep tick log for josh-request-promote | warn |
| B10 | `closed-bead-artifact-scan.py` | closed beads with missing artifacts | watcher-coverage | reopen-candidate handler | grep tick log for closed-bead-artifact | warn |
| B11 | `flywheel-skillos-relay` | findings should-become=skill not relayed | watcher-coverage | auto-fire on tick (skillos:1 inbox) | grep relay-ledger for findings-of-day | warn |

#### Section F — Cross-orch coordination (3)

| # | Item | Stock | Class | Consumer | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|
| F1 | Cross-orch ack timer | XPANE messages without ack >5min | watcher-coverage | ack-timer handler (new bead) | grep XPANE-log for unacked >5min | warn |
| F2 | Topology truth source consistency | session-topology.jsonl drift vs live | identity-registration | topology validator | grep topology-probe diff | error |
| F3 | Agent-mail paired-send enforcement | sends without pair receipt | identity-registration | agent-mail send validator | grep agent-mail-log for unpaired | warn |

#### Section G — L70 chain forward + callback discipline (5)

| # | Item | Stock | Class | Consumer | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|
| G1 | L70-orch-pane-refill (refilled-one-not-all) | dispatched-one + idle others | watcher-coverage | refill-all handler in supervision tick | grep dispatch-log for one-dispatch + idle-pane row | error |
| G2 | `callback_delivery_verified=PENDING` handling | pending callbacks > T | watcher-coverage | callback-pending sweeper | doctor `callbacks_unvalidated_count` | warn |
| G3 | Paradigm round-1 missed amendment | paradigm shifts without round-2 amend | watcher-coverage | round-2 trigger | grep PARADIGM-* for round-1 closure without round-2 | warn |
| G4 | REFINE-line-diff-vs-quality split | REFINE rounds graded on diff-size only | watcher-coverage | REFINE-quality validator | grep REFINE outputs for quality-judgment | warn |
| G5 | `phase_deferred` consumer | deferred phases without owner+by-date | identity-registration | phase-deferral sweeper | grep STATE.json for phase_deferred without owner | warn |

### Cap-violation reality

Original orch-monitor Phase 4 estimate: 27 beads. Current STATE.json split:
14 + 15 = 29 beads. Adding the 19 supplemental items would push to roughly
**40-48 beads** total before collapse. With L111 callback validator
inheritance (one bead closes G2 + G5 + much of L111 enforcement), realistic
landing: **35-42 beads** across the existing 14+15 sub-DAGs.

Recommendation: keep the existing 14+15 split. **Do NOT spawn a third
sub-plan.** The 19 items partition cleanly across the existing Lane C
auto-act and SLO scopes:

- **Sub-DAG α (auto-act loops, currently 14 beads → ~22-25 beads)**: B1-B8,
  G1, G2.
- **Sub-DAG β (cross-orch + SLO + ledger, currently 15 beads → ~18-20 beads)**:
  B9-B11, F1-F3, G3-G5.

Joshua sign-off requested on this scope expansion before Phase 4 runs.

### L111 inheritance for orch-monitor

Every Lane C bead description, every supervision-handler emission, every
recovery-dispatch row MUST satisfy L111 at write-time:

- Handler dispatches embed the 5-skill checklist as worker acceptance gate.
- Callback envelopes from recovery workers carry the seven L111 fields.
- Supervision-tick STATE.md emissions carry composite + per-judge scores.
- Doctor field `quality_bar_breach_count_24h` becomes a tick-close gate for
  orch-monitor itself, not just for wire-or-explain.

### Verification probe (this Phase 1 supplemental II)

L111 codified at AGENTS.md L3038-L3149 + AGENTS-CANONICAL.md L3025-L3137.
3-surface sync invoked; pre-existing drift (65 targets) is unrelated to L111
codification and will be drained by sync-canonical-doctrine.sh --apply during
Sub-DAG β. This supplement passes 3-judges sniff (composite ≥9.5, no judge
<9.0) before write — see callback envelope in /tmp/plan-update-l111-output.md.

### Tick consequence (this supplement)

Orch-monitor's `--through=research` gate now requires Joshua sign-off on the
expanded 19-item scope before Phase 4 bead-decompose runs. Lane C's
"orch-tick-supervision-handler" primitive (originally the load-bearing
output) absorbs B1-B8 + G1-G2 directly; Sub-DAG β picks up the rest.
