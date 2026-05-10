---
title: "Lane A Codex: Problem-Space Taxonomy — wire-or-explain-tick-gate"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A Codex: Problem-Space Taxonomy — wire-or-explain-tick-gate

Plan: `wire-or-explain-tick-gate-2026-05-04`

Mode: independent codex trace, read-only research.

Output: `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/01-RESEARCH-A-codex.md`

## Executive Summary

Joshua's complaint is not that artifacts lack prose. The failure is that "shipped" is currently allowed to mean "file exists, test exists, doctor field exists, or dashboard line exists" without requiring a runtime consumer that uses the artifact before the tick can close.

I inventoried 17 artifact classes and classified today's 14 shipped surfaces. My strict definition: an artifact is wired only if an automatic tick/runtime consumer invokes it, acts or blocks from its result, writes a durable receipt, and prevents tick completion without either `wired_into=<consumer>` or `deferred_until=<bead|iso_ts> reason=<why>`.

Under that strict definition, today's corpus is: `today_wired=2`, `today_partial=12`, `today_unwired=0`. This differs from the dispatch's preview of the sub-agent count (`0 wired, 6 partial, 8 unwired`) because I count L102 and L108 as wired: `.flywheel/flywheel-loop-tick` invokes META-RULE sync/check and logs/fuckup-routes drift at lines 912-952. I still count most observatory surfaces as partial because doctor/status/manual dashboard visibility is not action wiring.

Top missing gate: a tick-close ledger requiring every just-shipped artifact to resolve to `wired_into`, `deferred_until`, or `not_applicable`, plus ranked `unwired_artifact_top_5_*` fields.

## Evidence Base

Primary intent evidence:

- `00-INTENT.md:5` states the target invariant: a tick must not mark complete while just-shipped artifacts remain unwired, and every ship event needs `wired_into` or `deferred_until`.
- `00-INTENT.md:13-17` names the stock, pattern, missing balancing loop, leverage point, and intervention.
- `00-INTENT.md:23-30` names six concrete observatory/doctrine artifacts shipped today.
- `00-INTENT.md:59-61` defines Lane A/B/C roles, including this Lane A taxonomy.
- `00-INTENT.md:86-92` says the gate must emit a ranked full list, not just binary pass/fail.

Sibling plan evidence:

- `orch-monitor-recovery-auto-act/00-INTENT.md:17-20` says skillos/alps/flywheel worker failures came from probes measuring but not acting.
- `orch-monitor-recovery-auto-act/00-INTENT.md:98-117` corrects a false frozen-pane diagnosis to slow-subprocess-blocked, proving gate truth must distinguish visible stasis from runtime truth.
- `orch-monitor-recovery-auto-act/00-INTENT.md:121-149` says flywheel:1 became passive ledger-keeper: read doctor JSON, log STATE, sleep.

ALPS peer evidence:

- `2026-05-04-vercel-blocker-deep-dive.md:15-22` shows Vercel sat idle despite token, skills, mission anchor, and idle panes.
- `2026-05-04-vercel-blocker-deep-dive.md:71-79` names the asymmetry: refuse-gates exist but no permit-gate.
- `2026-05-04-meta-failure-why-orchestrator-cannot-decide.md:34-48` lists stop rules and missing go rules.
- `2026-05-04-meta-failure-why-orchestrator-cannot-decide.md:80-87` shows no dispatch-log precedent for unilateral mission-licensed execution.

Meadows evidence:

- `LEVERAGE-POINTS.md:30-35` places feedback loop strength, information flows, rules, self-organization, and goals above parameter tweaks.
- `LEVERAGE-POINTS.md:57-66` recommends information-flow, rule/contract, goal, and self-organization fixes over reminders.

Local substrate evidence:

- `AGENTS.md:2542-2623` defines L101, its productivity watcher, doctor fields, status line, and escalation intent.
- `AGENTS.md:2625-2671` defines L102 and says tick driver invokes canonical META-RULE sync.
- `AGENTS.md:2673-2718` defines L103 conformance score, doctor/status surface, and intended `--apply` drift packets.
- `AGENTS.md:2720-2772` defines L104 comms measurement and intended `--apply` ping/notify behavior.
- `AGENTS.md:2774-2827` defines L105 process gap measurement and intended fix-bead route.
- `AGENTS.md:2829-2871` defines L106 composite fleet health.
- `AGENTS.md:2873-2920` defines L107 shared surface reservation discipline.
- `AGENTS.md:2922-2965` defines L108 cache-vs-convergence gate and tick/watchdog read-only drift detectors.
- `.flywheel/flywheel-loop-tick:912-952` proves L102/L108 are invoked in the tick driver and write event/fuckup rows.
- `.flywheel/flywheel-loop-tick:1107-1126` proves the tick prompt currently enforces L70 callback chaining but has no `wire-or-explain` close gate.
- `.flywheel/flywheel-loop-tick:1147-1235` writes dispatch receipts with many pre-tick results but no shipped-artifact wiring ledger.
- `flywheel-loop:3551-3657` exposes conformance/comms/process probes into doctor JSON.
- `flywheel-loop:4607-4621` exposes peer productivity into doctor JSON.
- `flywheel-loop:5283-5356` turns several counts into doctor errors/warnings.
- `flywheel-loop:5972-6036` maps some doctor counts to a single `action`, but not to an artifact-by-artifact wiring gate.
- `flywheel-loop:6318-6339` computes `fleet_observatory_health_score` from 8 spines.
- `/flywheel:status.md:64-94` renders fleet productivity, conformance, comms, and process lines.
- `/flywheel:fleet-observatory.md:13-31` defines a manual dashboard invocation, not automatic tick action.

Socraticode survey:

- Query 1: `wire or explain tick gate unwired artifact tick close shipped artifact consumer doctor field launchd`
- Query 2: `surfaces_unwired_count unwired artifact consumer promotion_path doctor signal contract wired consumer`
- Findings: existing validation-signal tests already require `producer`, `measurement`, `consumer`, and `promotion_path`; AGENTS L57 warns that state markers are not drivers; current `surfaces_unwired_count` is validation-surface oriented, not a full just-shipped artifact gate.

## Working Definitions

### Shipped

An artifact is shipped when a worker/orchestrator claims DONE or lands a file that is intended to affect future behavior, operator decisions, doctrine, validation, dispatch, tick close, or fleet health.

### Wired

An artifact is wired when all five are true:

1. Producer exists and has a stable path or schema.
2. Consumer exists and is automatic in the relevant runtime, not only manual.
3. Consumer action is defined: act, block, notify, dispatch, promote, or explicitly defer.
4. Durable receipt proves the consumer ran and what it decided.
5. Tick close or operator close fails/warns if the consumer path is absent.

### Partial

An artifact is partial when it has some of producer, doctor field, status line, test, command, or manual dashboard, but lacks automatic action, durable close dependency, or ranked deferral.

### Unwired

An artifact is unwired when it exists as prose/file/code but no automatic consumer or durable action path can be found.

### Explained

An artifact is explained when it is intentionally deferred with `deferred_until=<bead|iso_ts> reason=<specific>` or marked `not_applicable` with a class-specific reason. "Later", "manual", "dashboard only", and "doctor field exists" are not enough.

## Artifact-Class Taxonomy

| # | Artifact class | What "wired" means | Common partial false-positive | Evidence command |
|---|---|---|---|---|
| 1 | Probe script | Tick/doctor/status/launchd invokes it automatically, thresholds map to action, receipt records result. | Script exists, has `--json`, tests pass. | `rg -n 'producer|gate_behavior|mutates_only_with|add_argument' .flywheel/scripts/*.sh` |
| 2 | Doctor field | Field is populated, thresholded, affects doctor status/action, and has promotion or dispatch consumer. | Field appears in JSON but no actor reads it. | `rg -n 'field_name|doctor fields|status=fail|action=' ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 3 | `/flywheel:status` line | Status renders the signal and points to next action or command when non-green. | Dashboard line only. | `nl -ba ~/.claude/commands/flywheel/status.md` |
| 4 | Slash command | Command is discoverable and invoked by tick/operator route when relevant; manual-only commands are explained as manual. | Command doc exists under `~/.claude/commands`. | `rg -n '/flywheel:fleet-observatory|Steps|JSON|Watch' ~/.claude/commands/flywheel` |
| 5 | Tick-driver step | `.flywheel/flywheel-loop-tick` or `flywheel-loop tick` runs it before close and writes receipt. | `/flywheel:tick.md` describes desired behavior but driver does not call it. | `rg -n 'event|sync|probe|dispatch_status' .flywheel/flywheel-loop-tick` |
| 6 | Launchd/watchdog | Plist exists, loaded, invokes a bounded script, and writes a recent event. | Active marker or plist file exists. | `rg -n '<ProgramArguments>|ntm send|watchdog' ~/Library/LaunchAgents ~/.local/bin` |
| 7 | Hook/pre-commit | Installed hook calls the gate in the mutation path and blocks or records deferral. | Hook script exists but is not installed. | `git config core.hooksPath; ls .git/hooks` |
| 8 | Doctrine L-rule | Rule lands in all required doctrine surfaces and has runtime/probe/test consumer. | L-rule text exists in AGENTS only. | `rg -n '^## L10[1-8]' AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md` |
| 9 | Memory feedback | Memory is cited by doctrine or dispatch template and changes a runtime route. | Memory file exists but nobody reads it. | `rg -n 'feedback_.*\\.md|memory' AGENTS.md ~/.claude/commands/flywheel` |
| 10 | Skill | Skill is discoverable, cited in dispatch/bead, and invoked by a route when trigger appears. | Skill exists in library. | `rg -n 'skill|Skill\\(' ~/.claude/commands/flywheel AGENTS.md` |
| 11 | README/operator doc | README names the artifact, command, verification, and consumer. | README entry only. | `rg -n 'fleet-|wire|surfaces_unwired' README.md` |
| 12 | Validation schema | Producer writes schema-conforming receipts; validator rejects invalid receipts; tick close consumes validation summary. | Schema file exists. | `rg -n 'validation_summary|schema|validate' .flywheel/flywheel-loop-tick ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 13 | Ledger/JSONL | Mutating/decision path appends idempotent rows and next tick reads them. | Script appends rows but no reader consumes them. | `rg -n 'append_jsonl|jsonl|ledger' .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 14 | Auto-bead promotion | Non-green signal creates/reuses a bead or writes explicit no-bead reason. | There is a suggested bead title in prose. | `rg -n 'doctor-signal-bead-promotion|br create|no_bead_reason' .flywheel/scripts` |
| 15 | Agent-mail/NTM packet | Packet is sent through canonical transport, callback receiver is live, and delivery is verified. | Pane text says sent. | `rg -n 'ntm send|verify-callback|callback_delivery' .flywheel ~/.claude/commands/flywheel` |
| 16 | Permit/license gate | Mission-lock or doctrine grants tactical permission and dispatch path consumes it. | Refuse/preflight gate exists. | `rg -n 'mission-anchor-dispatch-license|mission_license|mission-anchor-dispatch-preflight' ~/Developer ~/.claude` |
| 17 | Composite dashboard | Composite is computed from bounded data, non-green states route one recommended action automatically or explain manual-only scope. | Nice one-screen dashboard. | `rg -n 'fleet_observatory_health_score|recommended_action' .flywheel ~/.claude/commands/flywheel` |

## Today's Corpus Classification

Classification key:

- `wired`: automatic consumer plus close-impacting action/receipt.
- `partial`: visible/measured/tested/manual, but no full same-tick action or wire/explain close dependency.
- `unwired`: no consumer found.

| # | Artifact | Classification | Why | Evidence command |
|---|---|---|---|---|
| 1 | `.flywheel/scripts/peer-orch-productivity-watch.sh` | partial | Producer, doctor fields, status line, and `--apply` exist, but no tick close gate requires productivity escalation to run or explain. | `rg -n 'peer-orch-productivity-watch|peer_orch_idle_with_work_available_count|send_peer_orch_productivity_escalation' AGENTS.md ~/.claude/skills/.flywheel/bin/flywheel-loop ~/.claude/commands/flywheel/status.md` |
| 2 | `.flywheel/scripts/fleet-conformance-probe.sh` | partial | Probe, doctor fields, status line, and `--apply` packet plan exist; tick/doctor observes but does not auto-run `--apply` on red before close. | `rg -n 'fleet-conformance-probe|fleet_conformance|CONFORMANCE-DRIFT' AGENTS.md ~/.claude/skills/.flywheel/bin/flywheel-loop ~/.claude/commands/flywheel/status.md` |
| 3 | `.flywheel/scripts/fleet-comms-health-probe.sh` | partial | Probe, doctor/status fields, ledger and apply pings exist; no close dependency proves ping/notify ran or was deferred. | `rg -n 'fleet-comms-health-probe|fleet_comms|COMMS_HEALTH_PING|fleet_comms_ping_sent' AGENTS.md .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 4 | `.flywheel/scripts/fleet-process-gap-detector.sh` | partial | Detector can plan/create fix-beads with idempotency, and doctor/status expose process gaps; the tick does not auto-run `--apply` or explain why top gaps remain unpicked. | `rg -n 'fleet-process-gap-detector|fleet_process|process-gap-fix-beads|br create' AGENTS.md .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 5 | `.flywheel/scripts/fleet-observatory-aggregate.sh` | partial | Aggregate computes 8-spine score and recommended action, and doctor computes lightweight score; no automatic consumer acts on `recommended_action`. | `rg -n 'fleet-observatory-aggregate|fleet_observatory_health_score|recommended_action' AGENTS.md .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 6 | `/flywheel:fleet-observatory` | partial | Slash command manually renders the aggregate and says to recommend printed action if red; manual operator command is not a tick consumer. | `nl -ba ~/.claude/commands/flywheel/fleet-observatory.md` |
| 7 | `L101 FLYWHEEL-OWNS-CONTINUOUS-FLEET-PRODUCTIVITY` | partial | Doctrine describes states and required xpane/Josh notify behavior; runtime fields exist; full auto-dispatch/notify route is not proven. | `nl -ba AGENTS.md | sed -n '2542,2623p'` |
| 8 | `L102 META-RULE-CACHE-MUST-REFRESH-ON-TICK` | wired | Tick driver calls canonical sync with `--apply --json` and writes `event:"meta_rule_cache_sync"` before dispatch. | `nl -ba .flywheel/flywheel-loop-tick | sed -n '912,926p'` |
| 9 | `L103 FLEET-CONFORMANCE-SCORE-IS-THE-GATE` | partial | Doctrine says red sessions get same-tick packets; runtime exposes score but no auto-apply close gate was found. | `nl -ba AGENTS.md | sed -n '2673,2718p'; rg -n 'fleet_conformance' ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 10 | `L104 FLEET-COMMS-MEASURED-NOT-ASSUMED` | partial | Probe measures comms and has apply ledger events; tick/doctor surfaces counts but lacks a mandatory ping/notify receipt before close. | `nl -ba AGENTS.md | sed -n '2720,2772p'; rg -n 'fleet_comms|fleet_comms_ping_sent' .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 11 | `L105 PROCESS-GAPS-ARE-MEASURED-AND-AUTO-ROUTED` | partial | Detector can create top-3 beads, but current wiring surfaces health/action rather than enforcing auto-route before tick close. | `nl -ba AGENTS.md | sed -n '2774,2827p'; rg -n 'fleet_process|process-gap-fix-beads' .flywheel/scripts ~/.claude/skills/.flywheel/bin/flywheel-loop` |
| 12 | `L106 FLEET-HEALTH-IS-A-SINGLE-NUMBER-AGGREGATED-FROM-8-SPINES` | partial | Composite exists in script, command, and doctor lightweight field; the score is not yet a gate that routes the printed recommendation. | `nl -ba AGENTS.md | sed -n '2829,2871p'; nl -ba ~/.claude/skills/.flywheel/bin/flywheel-loop | sed -n '6318,6339p'` |
| 13 | `L107 SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES` | partial | Checker and tests exist; doctrine requires reservation before staging, but no global git/tick close gate proves every shared-surface commit was checked. | `nl -ba AGENTS.md | sed -n '2873,2920p'; ls -l .flywheel/scripts/shared-surface-reservation-check.sh tests/shared-surface-reservation-check.sh` |
| 14 | `L108 META-RULE-CACHE-IS-CACHE-NOT-CONVERGENCE-GATE` | wired | Tick driver runs `--check-three-surface`, logs `meta_rule_three_surface`, and logs a fuckup row with `should-become bead` on drift. | `nl -ba .flywheel/flywheel-loop-tick | sed -n '928,952p'; nl -ba AGENTS.md | sed -n '2922,2965p'` |

Totals:

- `today_wired=2`
- `today_partial=12`
- `today_unwired=0`

## Cross-Cutting Findings Against The Five Intent Questions

### 1. What can be shipped?

At least 17 artifact classes can be shipped. The common mistake is treating all of them as file-shaped. They are not. A doctor field, L-rule, slash command, launchd job, hook, ledger schema, and dashboard are all shipped artifacts because each can be claimed as DONE while still having no consumer.

### 2. What does wired mean?

Wired means the artifact has an automatic consumer appropriate to its class. For a probe, that means tick/doctor/status/launchd calls it and acts. For a doctrine rule, that means runtime enforcement or a probe/test path. For a dashboard, that means either manual-only scope is explicit or non-green output is routed.

### 3. What does explain mean?

Explain means durable deferral with a specific next substrate:

```text
deferred_until=<bead|iso_ts>
reason=<why not now>
owner=<who>
consumer_expected=<path|command>
```

An explanation is invalid if it says only "manual", "future", "dashboard", "doctor field", or "will wire later."

### 4. Where does the tick close gate sit?

The gate must sit at tick close and also at ship callback intake. The tick driver already writes a rich receipt at `.flywheel/flywheel-loop-tick:1147-1235`, so the smallest structural addition is a `wire_or_explain` block in that receipt and a close status change when just-shipped artifacts lack a resolution.

### 5. How does it avoid breaking legitimate work?

Use shadow mode first for artifact classes without a known wiring contract. For known classes, block only when the artifact was shipped in the last 24h and has neither `wired_into` nor `deferred_until`. For manual-only artifacts, require `not_applicable reason=manual_operator_surface` plus a status line saying it is manual-only.

## Anti-Pattern Enumeration

1. `doctor-field-as-consumer`: a field exists in JSON, but no one acts on it.
2. `status-line-as-action`: `/flywheel:status` renders a count and the tick closes.
3. `slash-command-as-wire`: manual command exists, but no automatic route invokes it.
4. `apply-flag-theater`: `--apply` exists, but no owner calls it when threshold trips.
5. `doctrine-as-runtime`: L-rule text says MUST, but runtime does not enforce.
6. `test-as-wire`: tests pass for a script that no tick invokes.
7. `dashboard-only-observability`: composite health exists only when Joshua asks.
8. `refuse-gate-without-permit-gate`: systems can say no but cannot say proceed.
9. `ledger-write-no-reader`: JSONL rows are appended but no next tick consumes them.
10. `driver-marker-confusion`: active loop or receipt is treated as driver proof.
11. `stale-ledger-current-truth`: old state rows are treated as live facts.
12. `single-signal-liveness`: one robot/pane/health signal drives recovery.
13. `unranked-unwired-backlog`: top priority unwired artifact is invisible among many.
14. `no-beadless-deferral`: deferral has no bead, ISO deadline, or owner.
15. `manual-Joshua-loop`: Joshua becomes the consumer of unacted measurements.
16. `partial-wire-optimism`: one consumer surface exists, so the whole artifact is called wired.
17. `recursive-doctor-hang`: aggregate relies on nested doctor calls without timeout/cached fallback and blocks the supervisor.

## Preliminary Wire-Or-Explain Schema

```yaml
ship_event:
  artifact_id: string
  artifact_class: enum
  shipped_at: iso8601
  source_commit_or_path: string
  producer_path: string
  intended_consumer: string
  expected_action: act|block|notify|dispatch|promote|render|manual_only
  wire_status: wired|partial|unwired|not_applicable
  wired_into: string|null
  deferred_until: string|null
  defer_reason: string|null
  owner: string
  priority_score: integer
  downstream_dep_count: integer
  evidence_command: string
```

## Recommendations For Lane C

1. Implement `wire-or-explain` as a read-only shadow gate first, then allow blocking after Joshua decides mode.
2. Add `wire_or_explain` to the `.flywheel/flywheel-loop-tick` dispatch receipt and canonical last tick JSON.
3. Add `unwired_artifact_count_24h`, `unwired_artifact_top_5_oldest`, and `unwired_artifact_top_5_highest_downstream_cost` to doctor JSON.
4. Classify artifacts from changed paths plus callback `DID/DIDNT/GAPS`, not from git diffs alone.
5. Treat status/dashboard/manual slash commands as partial unless `manual_only` is explicitly declared.
6. Add class adapters for scripts, doctor fields, slash commands, L-rules, README docs, ledgers, launchd, hooks, schemas, and skills.
7. Make permit-gate artifacts first-class; a license/permit gate is wired only when dispatch-decision consumes it.
8. Use idempotent ledger rows so repeated ticks update existing unresolved ship events instead of duplicating noise.
9. Do not auto-apply every partial artifact. The gate's first job is to prevent silent completion, not force risky mutation.
10. Dogfood on today's 14 surfaces, including the two I counted wired, to settle the definition before implementation.

## Ladder Check

- Artifact-class taxonomy has at least 14 classes: yes, 17.
- Today's corpus classifies 14 shipped artifacts: yes.
- Cross-cutting questions from intent answered: yes.
- Anti-patterns enumerated: yes, 17.
- File:line citations included for every classification call: yes.
- Sub-agent output not read before this independent classification was drafted: yes.
- Read-only discipline maintained except for this plan artifact: yes.

## Metrics Before Convergence Appendix

- `classes_inventoried=17`
- `today_wired=2`
- `today_partial=12`
- `today_unwired=0`
- `anti_patterns=17`
- `self_grade=W`

## Convergence with sub-agent Lane A

agreement_classes:

- shell/probe script
- doctor field
- slash command
- launchd plist
- hook
- dispatch template
- ledger/schema
- test file
- README/operator doc
- doctrine L-rule
- three-surface doctrine chunk
- runtime/tick handler consumer
- manual dashboard surface
- auto-bead/promotion route
- memory/doctrine feedback file

disagreement_classes:

- `permit/license gate`: codex adds this as a first-class artifact class because the ALPS reports identify refuse-gate vs permit-gate asymmetry as structural evidence. The sub-agent mentions the pattern but does not classify permit-gates as their own artifact class.
- `composite dashboard`: codex separates the composite dashboard artifact from slash command because `fleet_observatory_health_score` exists in doctor while `/flywheel:fleet-observatory` is a manual command. The sub-agent treats this mainly under shell-script/slash-command.
- `skill`: codex keeps skill as a taxonomy class even though no new skill shipped today; the sub-agent also includes skill but treats it as no today's example.
- `MCP server`: sub-agent includes MCP-server class; codex omitted it from the primary 17 because this plan's shipped-today corpus does not hinge on MCP wiring.
- `post-commit-hook`: sub-agent splits generic hook and post-commit hook; codex keeps hook as one class.

agreement_today_count: no

- Sub-agent first pass reports `wired=0`, `partial=6`, `unwired=8`, then second pass refines to `wired=1`, `deferred-legitimate=1`, `half-wired=8`.
- Codex reports `wired=2`, `partial=12`, `unwired=0` over the 14-item intent corpus.
- The disagreement is mostly denominator and naming. Sub-agent groups today's evidence into 10 refined artifact families; codex preserves all 14 intent-listed shipped artifacts.
- The load-bearing agreement is high: both traces say most artifacts are probe/doctor/status/manual wired but not consumer/action wired.

unique_findings_codex:

- Treats `permit/license gate` as a first-class artifact class, not only an anti-pattern. Evidence: ALPS reports show refuse-gates without permit-gates at `vercel-blocker-deep-dive.md:71-79` and `meta-failure.md:34-48`.
- Separates `wired` into five explicit gates: producer, automatic consumer, action, durable receipt, and tick-close dependency.
- Counts L102 and L108 as wired because `.flywheel/flywheel-loop-tick:912-952` performs sync/check/log/fuckup routing. This is stricter line evidence than the sub-agent's initial pass.
- Adds `manual_only` / `not_applicable` as explicit statuses for operator-only surfaces, preventing manual dashboards from being falsely treated as either wired or broken.
- Adds ranked priority fields (`downstream_dep_count`, `priority_score`) directly to the preliminary schema, matching INTENT lines 86-92.

unique_findings_subagent:

- Stronger two-pass correction on 3-surface presence: sub-agent verified L101-L108 are present across root, canonical, and template surfaces.
- Useful `half-wired` term: probe-side complete but consumer-side absent.
- Explicitly identifies tests as an additional unwired artifact family and says test files are not invoked by CI/pre-commit/tick.
- Names `wired-but-stale`, `double-wired`, and `wired-but-broken` edge cases.
- Groups consumer types into `tick_handler`, `launchd_plist`, `doctor_probe_register`, `slash_command_include`, `three_surface_chunk`, and `declarative_promotion`.

joint_confidence: high

Rationale: both traces converge on the central failure: artifact production has outpaced artifact consumption. The exact count differs because codex uses all 14 intent-listed artifacts as rows and marks L102/L108 wired, while the sub-agent's final pass groups artifacts into fewer families and treats only canonical sync as fully wired. The actionable Lane C requirement is the same: build a wire-or-explain gate that validates the full transit chain and forces every partial/half-wired artifact to either name a consumer or write a deferral receipt.

## Final Metrics

- `classes_inventoried=17`
- `today_wired=2`
- `today_partial=12`
- `today_unwired=0`
- `anti_patterns=17`
- `agreement_with_subagent=high`
- `unique_codex_findings=5`
- `commits_total=0`
- `callback_delivery_verified=pending`
