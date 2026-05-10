---
title: "Orchestrator Layer Audit - 2026-05-08"
type: plan
created: 2026-05-07
bead: flywheel-self
frontmatter_source: scaffold-doc-frontmatter
---

# Orchestrator Layer Audit - 2026-05-08

Bead: `flywheel-up0uw`

Scope source: `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:15` defines the orchestrator layer as `/flywheel:tick`, `/flywheel:dispatch`, `/flywheel:respawn`, `/flywheel:status`, `/flywheel:loop`, `/loop`, peer-orch handoff, and callback reap discipline. The audit contract requires inventory, load-bearing, vestigial, external-gap, lessons, and fix-bead-manifest sections at `00-PLAN.md:21-28`; process requires Socraticode K=10, source reads, gap cross-reference, today's evidence, 6-section output, and compliance pack at `00-PLAN.md:30-37`.

Socraticode preflight: 5 K=10 queries against `/Users/josh/Developer/flywheel`, covering `tick dispatch callback reap respawn loop handoff monitor`, `hot pane refill`, `loop monitor dynamic mode`, `peer orchestrator handoff`, and `manual respawn token limit pane resilience`. Results surfaced the same load-bearing loci as grep: L57/L70/L71/L91/L101/L115/L120 doctrine, hot-pane refill test, `/loop` Monitor test, peer-orch handoff rows, and respawn boot-window incident.

Grep callsite counts from `rg -n --fixed-strings <surface> . ~/.claude/commands ~/.claude/skills/.flywheel`:

| Surface | Count |
|---|---:|
| `/flywheel:tick` | 302 |
| `/flywheel:dispatch` | 117 |
| `/flywheel:respawn` | 61 |
| `/flywheel:status` | 209 |
| `/flywheel:loop` | 104 |
| `/loop` | 501 |
| `auto-refill-decision-log` | 3 |
| `peer-orch-respawn-permit` | 91 |
| `peer-orch-drift-probe` | 30 |
| `.flywheel/handoffs` | 72 |

## 1. Inventory

1. `/flywheel:tick` command surface. It is explicitly the heartbeat that reads receipts, checks invariants, reaps callbacks, and dispatches work (`~/.claude/commands/flywheel/tick.md:1-3`). Its canonical phase order is `INIT -> RESEARCH -> PLAN -> BEADS -> DISPATCH -> VALIDATE -> INTEGRATE -> LEARN`, with `VALIDATE` first-class before integration (`~/.claude/commands/flywheel/tick.md:27-37`).
2. `/flywheel:tick` awareness and coordinator preflight. Step 1a reads MISSION/GOAL/STATE plus recent receipts and doctrine drift (`~/.claude/commands/flywheel/tick.md:65-89`). Step 1b reads the NTM coordinator digest before learning-ledger parsing (`~/.claude/commands/flywheel/tick.md:91-107`).
3. `/flywheel:tick` worker-state gate. Step 3 requires `ntm --robot-activity` before dispatch/refill and treats WAITING as the only dispatchable state (`~/.claude/commands/flywheel/tick.md:247-280`).
4. `/flywheel:tick` stuck/frozen recovery path. Step 3a adds frozen-pane detector + recovery receipts (`~/.claude/commands/flywheel/tick.md:282-347`), and Step 3b runs the Codex template/input stuck detector without automatic respawn from the detector itself (`~/.claude/commands/flywheel/tick.md:349-381`).
5. `/flywheel:tick` fleet/self diagnosis. Step 4 scans monoculture, doctor-fail rate, self-tickability, fleet coverage, stale overrides, and auto-bead/dispatch follow-up (`~/.claude/commands/flywheel/tick.md:382-414`).
6. `/flywheel:tick` value and drift probes. The tick records leverage, gap hunt, value-gap, and related observability fields in the receipt (`~/.claude/commands/flywheel/tick.md:503-577`). Peer-orch mission drift is a close hook with OK/WARN/CRITICAL thresholds and receipt fields (`~/.claude/commands/flywheel/tick.md:1194-1225`).
7. `/flywheel:tick` callback reap. Step 7 reads `dispatch-log.jsonl`, marks callbacks, flags overdue work, and routes callback validation before summary/integration (`~/.claude/commands/flywheel/tick.md:997-1010`).
8. `/flywheel:tick` hot-pane refill. Step 7b requires immediate refill after callback reap when a pane is WAITING and safe ready work exists (`~/.claude/commands/flywheel/tick.md:1012-1035`). The hot-refill subsection calls `.flywheel/scripts/auto-refill-decision-log.sh`, rechecks pane state, reads ready work, dispatches in the same tick, and appends `event="auto_refill_after_reap"` (`~/.claude/commands/flywheel/tick.md:1037-1087`).
9. `flywheel:tick` compatibility skill note. `~/.claude/skills/.flywheel/skills/flywheel:tick.md` points back to the command surface and repeats doctrine-version awareness plus hot-refill requirements (`~/.claude/skills/.flywheel/skills/flywheel:tick.md:1-23`).
10. `flywheel-loop` portable binary. It exposes `doctor`, `tick`, `validate-callback`, `register-session`, and `fuckup log` surfaces (`~/.claude/skills/.flywheel/bin/flywheel-loop:52-71`). Its doctor logic includes callback validation counters and worker callback verification in the JSON health packet (`~/.claude/skills/.flywheel/bin/flywheel-loop:5403-5720`, `~/.claude/skills/.flywheel/bin/flywheel-loop:5808-5837`).
11. `/flywheel:dispatch`. The command is the canonical worker-send wrapper, replacing manual send with pane idle checks, dispatch-log rows, and callback contract (`~/.claude/commands/flywheel/dispatch.md:1-4`). It forbids bypassing `ntm send` transport (`~/.claude/commands/flywheel/dispatch.md:14-32`).
12. `/flywheel:dispatch` preflight and packet materializer. It gates on mission anchor and mission fitness (`~/.claude/commands/flywheel/dispatch.md:34-75`), then consults the NTM coordinator capacity oracle (`~/.claude/commands/flywheel/dispatch.md:76-107`), topology and robot-activity state (`~/.claude/commands/flywheel/dispatch.md:108-150`), and canonical dispatch-packet materializer with callback/file-discipline blocks (`~/.claude/commands/flywheel/dispatch.md:152-182`).
13. `/flywheel:dispatch` delivery/close handling. It records schema-v2 dispatch rows and send status (`~/.claude/commands/flywheel/dispatch.md:283-357`), performs post-send delivery validation (`~/.claude/commands/flywheel/dispatch.md:358-389`), and routes DONE callbacks through close-handler/gated bead close (`~/.claude/commands/flywheel/dispatch.md:398-412`).
14. `/flywheel:respawn`. The command collapses manual pane recovery into snapshot, respawn, relaunch, resume prompt, and fuckup logging (`~/.claude/commands/flywheel/respawn.md:1-33`). Peer-orch targets first run the permit gate and self-orch recovery is refused (`~/.claude/commands/flywheel/respawn.md:37-52`).
15. `/flywheel:respawn` boot-window guard. It relaunches agents, waits 15-20 seconds, then verifies with direct robot-tail evidence before classifying stale scrollback errors (`~/.claude/commands/flywheel/respawn.md:110-151`), and logs the recovery to fuckup-log (`~/.claude/commands/flywheel/respawn.md:165-173`).
16. `peer-orch-respawn-permit.sh`. The script is the policy wrapper for peer orchestrator recovery and delegates health/respawn mechanics to NTM (`.flywheel/scripts/peer-orch-respawn-permit.sh:20-27`). It refuses self/primary/protected targets and only permits recovery with freeze evidence (`.flywheel/scripts/peer-orch-respawn-permit.sh:134-170`).
17. `/flywheel:status`. This is the compact tactical dashboard for panes, dispatches, callbacks, beads, learning signals, and gate state (`~/.claude/commands/flywheel/status.md:1-9`). It uses robot-activity as primary pane truth (`~/.claude/commands/flywheel/status.md:17-35`) and renders coordinator, watcher, fleet productivity, conformance, comms, process, mission fitness, dispatch fitness, NTM coverage, peer drift, recovery SLO, and architecture health lines (`~/.claude/commands/flywheel/status.md:36-149`).
18. `/flywheel:loop`. This command manages agentic loop activation/stop/status/revive, tier selection, state-file lifecycle, and substrate registry while delegating phase pipeline semantics to `flywheel-end-to-end` (`~/.claude/commands/flywheel/loop.md:1-23`). It distinguishes CC self-loop from Codex/other external launchd drivers (`~/.claude/commands/flywheel/loop.md:57-68`).
19. `/flywheel:loop` Codex driver pattern and watcher behavior. Codex loop scripts must contain `ntm send --file` and log `event:"ntm_dispatch_sent"` (`~/.claude/commands/flywheel/loop.md:70-100`). Watcher subcommands install idle-worker feeder LaunchAgents but explicitly do not prove loop health (`~/.claude/commands/flywheel/loop.md:102-150`).
20. `/loop` global command. It routes Joshua's `/loop` to `flywheel-loop`, not Anthropic cron habits (`~/.claude/commands/loop.md:7-31`). Dynamic mode now mandates a persistent `Monitor` on dispatch-log callbacks when workers are THINKING and treats `ScheduleWakeup` as fallback heartbeat (`~/.claude/commands/loop.md:33-60`).
21. `/loop` closeout and wake-latency contract. It requires a structured v2 receipt, an outcome record, and callback append-to-reap <=30s, with >2min treated as a monitor wake bug (`~/.claude/commands/loop.md:61-94`).
22. `/flywheel:handoff` plus `.flywheel/handoffs/`. Handoff is orchestrator-only, observation-based, and writes accretive files under `.flywheel/handoffs/<iso-date>-<HHMM>-<reason>.md` (`~/.claude/commands/flywheel/handoff.md:8-16`, `~/.claude/commands/flywheel/handoff.md:45-93`). It also updates STATE.md, publishes a condensed cache, and sends agentmail (`~/.claude/commands/flywheel/handoff.md:95-193`).
23. `dispatch-log.jsonl` as event substrate. Today's relevant rows include mobile-eats peer handoff, ALPS loop-staleness note, 7wr3e dispatch/callback, ka0xt dispatch/callback, and plan/bead-space audit callbacks (`.flywheel/dispatch-log.jsonl:1971-1982`).
24. `auto-refill-decision-log.sh`. The helper reads live activity, ready beads, fleet capacity, and dispatch-log state (`.flywheel/scripts/auto-refill-decision-log.sh:77-92`, `.flywheel/scripts/auto-refill-decision-log.sh:189-227`), emits `auto_refill_after_reap` decision rows (`.flywheel/scripts/auto-refill-decision-log.sh:241-290`), and computes callback-to-next-dispatch windows over 2 minutes (`.flywheel/scripts/auto-refill-decision-log.sh:319-359`).
25. `peer-orch-drift-probe.sh`. The probe reads peer MISSION anchors plus recent dispatch rows, scores drift percentage, and can alert orchestrators (`.flywheel/scripts/peer-orch-drift-probe.sh:1-4`, `.flywheel/scripts/peer-orch-drift-probe.sh:25-42`, `.flywheel/scripts/peer-orch-drift-probe.sh:96-129`, `.flywheel/scripts/peer-orch-drift-probe.sh:190-218`).
26. Test surfaces. `tests/test_hot_pane_refill_after_callback_reap.sh` proves same-tick refill, capacity skip, no-ready skip, and >2min idle-window metric (`tests/test_hot_pane_refill_after_callback_reap.sh:42-111`). `tests/test_loop_dynamic_mode_arms_monitor.sh` verifies the `/loop` Monitor mandate and allowed tools (Socraticode hit: lines 1-86).

Inventory count: 26.

## 2. Load-bearing

1. `/flywheel:tick` is critical path and highly referenced (302 grep hits). It owns phase selection, callback reap, validation routing, dispatch/refill, receipt fields, and next tick scheduling (`~/.claude/commands/flywheel/tick.md:27-37`, `~/.claude/commands/flywheel/tick.md:997-1107`). Socraticode K=10 returned this as the primary locus for `callback reap`, `hot pane refill`, `dispatch`, and `loop monitor` queries.
2. `/loop` global command is critical path for human shorthand and high-frequency orchestration (501 grep hits). The 7wr3e patch made dynamic-mode event wake load-bearing: Monitor watches callback rows and fallback ScheduleWakeup rewrites prompt from live state instead of replaying stale args (`~/.claude/commands/loop.md:33-60`). Today's dispatch log confirms 7wr3e shipped it with `monitor_mandatory=yes` (`.flywheel/dispatch-log.jsonl:1974`, `.flywheel/dispatch-log.jsonl:1978`).
3. `/flywheel:dispatch` is critical path and highly referenced (117 grep hits). It is the only acceptable worker-send wrapper because it layers mission fitness, coordinator oracle, topology, robot-activity, packet materialization, strict preflight, dispatch-log rows, delivery validation, and close-handler routing (`~/.claude/commands/flywheel/dispatch.md:34-150`, `~/.claude/commands/flywheel/dispatch.md:152-182`, `~/.claude/commands/flywheel/dispatch.md:258-389`, `~/.claude/commands/flywheel/dispatch.md:398-412`).
4. `dispatch-log.jsonl` is the orchestrator event bus, not just a log. `/loop` Monitor tails it (`~/.claude/commands/loop.md:41-53`), `/flywheel:dispatch` writes it (`~/.claude/commands/flywheel/dispatch.md:283-320`), `/flywheel:tick` reads it for callbacks and refill (`~/.claude/commands/flywheel/tick.md:997-1087`), and today's peer-orch evidence is encoded there (`.flywheel/dispatch-log.jsonl:1971-1982`).
5. Callback validation/reap discipline is critical path. Tick refuses unvalidated callbacks as integrate-ready (`~/.claude/commands/flywheel/tick.md:33-37`), Step 7 routes callback bodies through validation before close/integration (`~/.claude/commands/flywheel/tick.md:997-1010`), dispatch has a DONE close handler (`~/.claude/commands/flywheel/dispatch.md:398-412`), and `flywheel-loop doctor` emits callback validation and worker callback verification counters (`~/.claude/skills/.flywheel/bin/flywheel-loop:5403-5720`, `~/.claude/skills/.flywheel/bin/flywheel-loop:5808-5837`).
6. Hot-pane refill is now critical path despite only 3 direct grep hits for the helper name, because it closes the callback-to-idle leak. Tick mandates it (`~/.claude/commands/flywheel/tick.md:1037-1087`), the compatibility shim repeats it (`~/.claude/skills/.flywheel/skills/flywheel:tick.md:17-23`), tests prove dispatch/skip/metric behavior (`tests/test_hot_pane_refill_after_callback_reap.sh:42-111`), and ka0xt landed it as Change 3 closing the ALPS sister bead (`.flywheel/dispatch-log.jsonl:1977`, `.flywheel/dispatch-log.jsonl:1980`).
7. `/flywheel:status` is load-bearing operator observability (209 grep hits). It is the single tactical dashboard (`~/.claude/commands/flywheel/status.md:1-9`) and now renders fleet/process/mission/dispatch/recovery/architecture lines (`~/.claude/commands/flywheel/status.md:73-149`). Socraticode surfaced status lines under fleet comms, recovery SLO, architecture-health, and dispatch fitness doctrine.
8. `/flywheel:loop` is load-bearing lifecycle control (104 grep hits). It encodes marker-vs-driver doctrine (`~/.claude/commands/flywheel/loop.md:57-100`), tier/interval semantics (`~/.claude/commands/flywheel/loop.md:43-56`), watcher install/status behavior (`~/.claude/commands/flywheel/loop.md:102-150`), and start verification (`~/.claude/commands/flywheel/loop.md:204-264`).
9. `/flywheel:respawn` plus peer permit is load-bearing resilience. `/flywheel:respawn` handles capture, relaunch, resume, and learning log (`~/.claude/commands/flywheel/respawn.md:21-33`, `~/.claude/commands/flywheel/respawn.md:153-173`); `peer-orch-respawn-permit` has 91 grep hits and gates peer orchestrator recovery with topology/protected-session/freeze evidence (`.flywheel/scripts/peer-orch-respawn-permit.sh:134-187`).
10. `.flywheel/handoffs/` is load-bearing across compaction and peer-orch digest paths (72 grep hits). The command writes accretive handoffs with in-flight dispatches, open beads, pending decisions, learning state, and resume sequence (`~/.claude/commands/flywheel/handoff.md:45-93`), and today's rows show both mobile-eats and ALPS peer evidence entering dispatch-log for synthesis (`.flywheel/dispatch-log.jsonl:1971-1972`).
11. `peer-orch-drift-probe.sh` is load-bearing but incomplete for strategic drift. It has 30 grep hits and tick Step 8f wires it as a mission-alignment close hook (`~/.claude/commands/flywheel/tick.md:1194-1225`). Its implementation scores recent dispatch rows against mission anchors and writes alerts (`.flywheel/scripts/peer-orch-drift-probe.sh:96-129`, `.flywheel/scripts/peer-orch-drift-probe.sh:190-218`).

Load-bearing count: 11.

## 3. Vestigial

1. `~/.claude/skills/loop/SKILL.md` is referenced by the dispatch packet as bundled `/loop`, but it does not exist on disk. The active bundled `/loop` source is `~/.claude/commands/loop.md` (`~/.claude/commands/loop.md:1-7`), and available loop-like skills are `human-in-the-loop`, `lean-formal-feedback-loop`, `loop-enforcement`, and `swarm-operator-loop`. Sunset candidate: remove or rewrite references to the missing skill path.
2. `~/.claude/skills/.flywheel/skills/flywheel:tick.md` is a 23-line shim with no behavior of its own; it points to the canonical command surface and repeats two fragments (`~/.claude/skills/.flywheel/skills/flywheel:tick.md:1-23`). With the full command at `~/.claude/commands/flywheel/tick.md`, this should either become generated metadata or be retired.
3. `/flywheel:loop revive` remains a skeletal Phase C behavior. It lists selection steps (`~/.claude/commands/flywheel/loop.md:286-292`) while the constraints say `revive` is Phase C and still needs keepalive plist + reboot test (`~/.claude/commands/flywheel/loop.md:312-313`). Sunset or gate it until implemented.
4. `/flywheel:loop status` still says to show only loop files, tier, interval, active/stopped, and autoloop state (`~/.claude/commands/flywheel/loop.md:277-284`), while the same document says watcher health is not loop health and status should show both driver proof and watcher coverage (`~/.claude/commands/flywheel/loop.md:149-150`). This status path is superseded by L57 driver-proof doctrine and should be rewritten, not trusted as sufficient.
5. `/flywheel:tick` Step 7 still includes a legacy output-file existence probe such as `/tmp/autoloop_fix_*.md` (`~/.claude/commands/flywheel/tick.md:999-1004`). That is weaker than current dispatch-log callback rows, callback validation receipts, and Monitor-driven callback wake. Sunset candidate: replace output-file heuristics with callback evidence/receipt primary sources.
6. `ScheduleWakeup` as the primary `/loop` recurrence mechanism is now vestigial in dynamic mode. The active command says Monitor is required when workers are in flight and ScheduleWakeup is fallback only (`~/.claude/commands/loop.md:33-60`). Any older prompt replay or fixed-cadence-only flow should be treated as superseded.

Vestigial count: 6.

## 4. Missing per agent-flywheel.com gap analysis

1. Strategic drift / "come to Jesus moments". The external guide treats swarm health as steady bead progress, low idle burn, zero lock conflicts, steady pushes, comprehensive coverage, and no hard strategic course-corrections (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-95`). The local gap analysis names the missing inverse: regular plan-vs-actual drift checks in tick (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:172-175`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:228-232`). We have mission/dispatch fitness and peer-orch drift (`~/.claude/commands/flywheel/status.md:104-117`, `~/.claude/commands/flywheel/tick.md:1194-1225`), but no explicit "current plan expected X by now; actual dispatch/commit/bead trajectory says Y" probe in `/flywheel:tick`.
2. Outcome-shape benchmark. The guide's concrete exemplar is 5,500-line plan -> 347 beads -> 11,000 LOC -> 25 agents -> 204 commits -> about 5h to ship (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:44-56`). The local gap analysis says we do not track plan-LOC/bead-count/commit-count ratios and recommends adding them to `/flywheel:status` (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:187-190`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:233-237`). Current status is rich on fleet health but lacks a comparable outcome-shape line (`~/.claude/commands/flywheel/status.md:188-269`).
3. "Clockwork deity" framing. The guide says the human designs the machine, launches the swarm, then tends it (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:248-256`). Our doctrine aligns operationally: mission-fitness gates and loop/dispatch surfaces keep Joshua out of implementation while flywheel owns orchestration (`~/.claude/commands/flywheel/dispatch.md:34-75`, `~/.claude/commands/flywheel/loop.md:8-23`, `~/.claude/commands/loop.md:96-107`). The gap is presentation: `/flywheel:status` and `/loop` do not yet surface "Joshua is designer/tender; workers implement; flywheel owns next action" as a compact state frame.

Tier gaps addressed: 3.

## 5. Lessons learned (today's evidence)

The loop-staleness triad shows the orchestrator layer has moved from timer-driven supervision toward event-driven throughput control, but the control loop is only mature when all three legs are present:

1. Monitor wake reduces callback latency. 7wr3e changed `/loop` dynamic mode so in-flight workers arm a persistent dispatch-log Monitor, wake on callback rows, and use ScheduleWakeup only as fallback (`~/.claude/commands/loop.md:33-60`). Dispatch-log confirms 7wr3e was sent and returned DONE with `monitor_mandatory=yes` (`.flywheel/dispatch-log.jsonl:1974`, `.flywheel/dispatch-log.jsonl:1978`).
2. Prompt rewrite prevents stale re-entry. msixq is queued to rewrite `/loop` re-entry from live `ntm --robot-activity`, dispatch-log, and `br ready` state instead of replaying old args; the current `/loop` command already states the desired behavior (`~/.claude/commands/loop.md:54-59`), while the bead remains open in `.beads/issues.jsonl:802`.
3. Hot-pane refill prevents recovered capacity from cooling. ka0xt shipped the tick-side same-turn refill after callback reap (`.flywheel/dispatch-log.jsonl:1977`, `.flywheel/dispatch-log.jsonl:1980`). Tick now calls `auto-refill-decision-log.sh`, rechecks WAITING state, reads ready beads, dispatches through `/flywheel:dispatch`, and logs `auto_refill_after_reap` (`~/.claude/commands/flywheel/tick.md:1037-1087`). Tests prove dispatch, capacity skip, no-ready skip, and >2min warning (`tests/test_hot_pane_refill_after_callback_reap.sh:42-111`).

Peer-orch evidence mattered because it prevented local optimism. Mobile-eats sent a real worker-close-without-commit trauma: 7 of 8 worst closed beads had implementation in dirty tree with no close commit (`.flywheel/dispatch-log.jsonl:1971`). ALPS sent a loop-staleness note tied to `alps-josh-2u7zm` and caused three flywheel beads, with Change 1 prioritized for same-day ship (`.flywheel/dispatch-log.jsonl:1972`). That is the desired cross-orch information flow: peer pain becomes local orchestrator repair, not a handoff paragraph that dies at compaction.

The pane 2/4 token-limit and manual-respawn pattern reinforces that `/flywheel:respawn` is not a luxury wrapper. It encodes the actual recovery sequence: snapshot first, respawn shell, relaunch agent with auto-yes, wait 15-20 seconds, verify with robot-tail instead of stale `ERROR` patterns, inject resume, and log to fuckup substrate (`~/.claude/commands/flywheel/respawn.md:21-33`, `~/.claude/commands/flywheel/respawn.md:110-173`). Manual recovery remains useful as a break-glass path, but the mature orchestrator state is recovery-as-surface with evidence and learning records.

Net lesson: orchestrator maturity is not "more polling." It is shorter evidence loops: event wakes, live-state prompt construction, immediate capacity refill, delivery validation, and recovery receipts. The remaining waste is mostly measurement shape: plan-vs-actual drift and outcome-shape benchmarks are not yet first-class dashboard/tick surfaces.

## 6. Fix-bead manifest

Recommendations only. No beads filed.

1. Title: `[orchestrator] add plan-vs-actual drift probe to /flywheel:tick`
   Priority: P1
   Scope: Add a read-only tick close hook that compares current plan/STATE expected lane, ready/in-flight/closed beads, dispatch-log callbacks, commits since plan start, and idle windows. Emit `plan_actual_drift_status`, `expected_next`, `actual_next`, `drift_reason`, and `come_to_jesus_risk` in tick receipt and status.
   Acceptance: Synthetic fixture with expected plan lane `DISPATCH`, no callbacks for >2 windows, and ready beads present returns WARN/CRITICAL; healthy fixture returns OK; `/flywheel:status` renders one compact drift line.

2. Title: `[status] add outcome-shape benchmark line`
   Priority: P2
   Scope: Extend `/flywheel:status` with a compact ratio line: plan LOC, bead count, closed beads, LOC delta, agent count, commits, elapsed time, idle burn, and comparison to the agent-flywheel exemplar. Data sources should be git, br, dispatch-log, and plan files; no new datastore.
   Acceptance: Status renders `Outcome shape: plan=<N>loc beads=<N> closed=<N> loc=<+/-N> agents=<N> commits=<N> elapsed=<T>`; missing fields degrade to `(no data)`; fixture covers no-plan, active-plan, and completed-plan states.

3. Title: `[loop-status] rewrite /flywheel:loop status around driver proof`
   Priority: P1
   Scope: Replace the marker-only loop status table with L57-compliant driver classification: VERIFIED, MARKER_ONLY, STALE, MISSING_DRIVER, NOT_APPLICABLE_CC, UNKNOWN. Include watcher coverage separately, and link to last `ntm_dispatch_sent` and pane prompt evidence.
   Acceptance: Fixtures for active marker with no driver, stale driver, verified Codex launchd prompt, and CC Skill loop proof all classify correctly; command refuses to print "loop active" without driver verdict.
