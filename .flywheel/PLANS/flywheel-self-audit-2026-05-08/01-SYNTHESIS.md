---
title: "Flywheel Self-Audit Synthesis - 2026-05-08"
type: plan
created: 2026-05-07
bead: flywheel-self
frontmatter_source: scaffold-doc-frontmatter
---

# Flywheel Self-Audit Synthesis - 2026-05-08

Bead: `flywheel-ug399`

Scope: synthesize the seven layer audits required by the plan contract:
plan-space, bead-space, code-space, coordination, orchestrator, hygiene, and
doctrine. The source plan requires the synthesis to deduplicate about 21 raw
fix proposals into one manifest without filing beads
(`.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:39`,
`.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:53`).

Socraticode receipt: 6 searches against `/Users/josh/Developer/flywheel` with
K=10, covering convergence, evidence, dispatch, hot refill, vestigial cleanup,
and picoz. Results confirmed current code/test anchors for convergence
telemetry, EV anchors, hot-pane refill, storage cleanup, and L128 doctrine.

## 1. Cross-Cutting Findings

1. **Convergence must become measured, not narrated.** Plan-space found missing
0.75/0.90 convergence thresholds and proposed a weighted `convergence_score`
(`audits/plan-space.md:92`, `audits/plan-space.md:180`). Bead-space found the
same gap at bead-body quality level (`audits/bead-space.md:128`,
`audits/bead-space.md:223`). Doctrine then consolidated the brenner-wire family
into a single claim, but also warned that close-gate rules must be wired into
three valid doctrine surfaces (`audits/doctrine.md:181`,
`audits/doctrine.md:239`). This is the central picoz lesson: a plan cannot ship
because prose says it converged; it needs counters, thresholds, receipts, and
refusal behavior.

2. **Closure evidence is the spine across plan, bead, code, and coordination.**
L126 evidence packs replaced self-grade in plan and bead close paths
(`audits/plan-space.md:83`, `audits/bead-space.md:134`), code-space found that
UBS-before-commit is documented but not enforced (`audits/code-space.md:66`),
coordination found callback close ordering still inconsistent
(`audits/coordination.md:123`), hygiene surfaced worker-close-without-commit as
state leakage (`audits/hygiene.md:96`), and doctrine elevated it to P0 doctrine
debt (`audits/doctrine.md:140`). The common rule is simple: closed means
evidence, committed scoped work, and a callback that passes a close handler.

3. **EV anchors turn audit packs from receipts into a graph.** Code-space and
doctrine both point at typed evidence as the difference between "proof exists"
and "proof supports this claim" (`audits/code-space.md:76`,
`audits/doctrine.md:171`). The close-gate tests surfaced by Socraticode show
EV anchor resolution, refute contradiction detection, excerpt matching, and
backward compatibility. This belongs in the closure evidence chain rather than
as a separate research nicety.

4. **Event-driven orchestration is now the fleet throughput path.** Coordination
found the dispatch-log, callback envelope, close handler, Agent Mail
reservations, Monitor, and hot-pane refill as load-bearing
(`audits/coordination.md:72`, `audits/coordination.md:87`). Orchestrator found
the same critical path in `/flywheel:tick`, `/loop`, dispatch-log, callback
reap, and same-tick refill (`audits/orchestrator.md:57`,
`audits/orchestrator.md:62`). The 7wr3e + msixq + ka0xt loop-staleness triad
teaches that orchestration maturity is not more polling; it is callback wake,
live prompt reconstruction, and immediate capacity refill
(`audits/orchestrator.md:92`).

5. **DCG prose-trigger discipline is an authoring layer, not a shell bug.**
Hygiene recorded three DCG prose-trigger blocks and classified the fix as
prompt/text generation hygiene (`audits/hygiene.md:106`). Doctrine reached the
same conclusion and proposed packet-authoring filters plus doctrine-broadcast
refusal receipts (`audits/doctrine.md:148`, `audits/doctrine.md:197`). Any
future dispatch or compliance prose that passes through command arguments needs
safe paraphrase or file-body routing.

6. **Vestigial substrate is systemic, not layer-local.** Plan-space found
missing skill aliases and legacy self-grade rows (`audits/plan-space.md:80`).
Bead-space found missing slash-skill paths, raw Beads examples, and markdown
pseudo-beads (`audits/bead-space.md:99`). Coordination found stale wrappers,
callback wording, and Agent Mail sidechannel residue (`audits/coordination.md:93`).
Orchestrator found marker-only loop status and ScheduleWakeup-first flows
superseded by driver proof and Monitor (`audits/orchestrator.md:73`,
`audits/orchestrator.md:78`). Hygiene found missing skill docs, skeleton probes,
and absent watcher pattern-bank files (`audits/hygiene.md:61`). Doctrine found
L127/L128 split-brain and missing L112 headings (`audits/doctrine.md:88`,
`audits/doctrine.md:93`). The cleanup target is a vestigial registry with
owners, sunset criteria, or explicit keep reasons.

7. **Generated artifacts are weaker than authored artifacts unless validated.**
Bead-space found generated fix-bead bodies often lack enough context and
acceptance detail (`audits/bead-space.md:162`, `audits/bead-space.md:238`).
Plan-space found idea-generation surfaces healthy but still missing explicit
human review and structured outputs (`audits/plan-space.md:171`). Doctrine
generalized the lesson: prose rules without doctor/status/close-handler
consumers decay toward vestigial (`audits/doctrine.md:171`). The manifest below
therefore favors validators and close gates over new prose-only templates.

8. **Agent-flywheel.com outcome numbers are missing from local dashboards.** The
external benchmark gives a concrete outcome shape: plan length, bead count, LOC,
agent count, commits, and elapsed time
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:44`).
Orchestrator and doctrine both found that local `/flywheel:status` has rich
fleet health but no comparable outcome-shape line (`audits/orchestrator.md:85`,
`audits/doctrine.md:107`). That leaves Joshua without a quick read on whether
the flywheel is scaling toward the benchmark or just producing local activity.

Themes found: 8.

## 2. Deduplicated Fix-Bead Manifest

Recommendations only. No beads filed.

| ID | Title | Priority | Source audits | Acceptance summary |
|---|---|---|---|---|
| SYN-01 | Reconcile L127/L128 doctrine across all doctrine surfaces and land worker-close commit rule | P0 | Doctrine `audits/doctrine.md:181`, hygiene `audits/hygiene.md:96`, coordination `audits/coordination.md:123` | Root, canonical snapshot, and install template agree on prediction-lock, EV anchors, L128, and worker-close commit doctrine; close handler requires `git_committed=` or a valid no-change/skipped receipt; tests cover dirty scoped changes. |
| SYN-02 | Complete L128 backing checks in close gate | P0 | Doctrine `audits/doctrine.md:250`, plan-space `audits/plan-space.md:139`, code-space `audits/code-space.md:66` | Close gate has one visible matrix for hypothesis slate, prediction lock, structured deltas, convergence telemetry, and EV anchors; failing any required check blocks close with machine-readable reasons. |
| SYN-03 | Add weighted plan and bead convergence scores | P0 | Plan-space `audits/plan-space.md:180`, bead-space `audits/bead-space.md:223`, external guide `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:167` | Plan and bead close gates compute weighted scores with 0.75 advisory and 0.90 auto-advance thresholds; fixtures cover below, advisory, pass, and missing-data states. |
| SYN-04 | Enforce scoped commit plus UBS before worker close | P0 | Code-space `audits/code-space.md:90`, hygiene `audits/hygiene.md:98`, doctrine `audits/doctrine.md:140` | Worker DONE path refuses scoped dirty changes; UBS staged check runs before close or records a scoped bypass receipt; callbacks include commit/no-change/skipped state. |
| SYN-05 | Align reservation release, callback close, and bead close ordering | P0 | Coordination `audits/coordination.md:123`, coordination `audits/coordination.md:205`, doctrine `audits/doctrine.md:255` | Dispatch close handler closes bead, records compliance pack, releases file reservations, and only then accepts final callback; tests cover success, dirty-scope block, and release-on-blocked. |
| SYN-06 | Finish event-driven loop resilience: Monitor, prompt rewrite, hot refill, driver-proof status | P0 | Orchestrator `audits/orchestrator.md:92`, coordination `audits/coordination.md:165`, orchestrator `audits/orchestrator.md:118` | `/loop` wakes on callback rows, re-entry prompts are rebuilt from live state, callback reap refills WAITING panes in the same tick, and loop status reports driver proof rather than marker-only state. |
| SYN-07 | Wire private temp pressure into storage headroom control | P0 | Hygiene `audits/hygiene.md:100`, hygiene `audits/hygiene.md:112`, doctrine `audits/doctrine.md:255` | Tick/doctor reports private temp pressure before disk headroom becomes unsafe; prune remains allowlist-scoped and idempotency-gated; 312GB simulation emits warning and recommended action. |
| SYN-08 | Add content-based bead polishing rounds | P1 | Bead-space `audits/bead-space.md:111`, bead-space `audits/bead-space.md:231` | Bead refinement continues until acceptance criteria and body content stabilize, not for a fixed round count; artifacts record adds, edits, kills, and no-delta streaks. |
| SYN-09 | Upgrade generated bead bodies and eliminate pseudo-bead leakage | P1 | Bead-space `audits/bead-space.md:144`, bead-space `audits/bead-space.md:238`, plan-space `audits/plan-space.md:196` | Generated bodies include scope, files, tests, context, acceptance, and callback shape; markdown-only DAG entries either become real beads or carry explicit non-bead disposition. |
| SYN-10 | Modernize idea-wizard outputs with human review and structured deltas | P1 | Plan-space `audits/plan-space.md:106`, plan-space `audits/plan-space.md:188`, doctrine `audits/doctrine.md:113` | Idea duel surfaces emit ADD/EDIT/KILL JSON deltas plus a human review checkpoint for final 5 strategy selection; legacy aliases point to current command paths. |
| SYN-11 | Add adversarial exhaustive-miss probe to plan-space | P1 | Plan-space `audits/plan-space.md:123`, doctrine `audits/doctrine.md:113`, external guide `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:157` | `/flywheel:plan` has a named adversarial miss pass that assumes the plan missed major issues, records what it found, and labels the technique as prompt pressure rather than evidence. |
| SYN-12 | Add plan-vs-actual drift probe and outcome-shape status line | P1 | Orchestrator `audits/orchestrator.md:84`, orchestrator `audits/orchestrator.md:113`, doctrine `audits/doctrine.md:99` | Tick compares expected plan trajectory with actual beads, callbacks, commits, and idle windows; status renders plan LOC, bead count, closed beads, LOC delta, agents, commits, elapsed time, and drift verdict. |
| SYN-13 | Make staggered multi-agent spawn enforceable | P1 | Coordination `audits/coordination.md:107`, hygiene `audits/hygiene.md:70`, doctrine `audits/doctrine.md:190` | Multi-agent launch wrappers either apply an explicit stagger policy or emit `stagger_not_applicable`; fixtures cover swarm launch and single-pane exemption. |
| SYN-14 | Add doctrine-broadcast consume receipts, unread-age signal, and privacy refusal ledger | P1 | Coordination `audits/coordination.md:140`, coordination `audits/coordination.md:215`, doctrine `audits/doctrine.md:156` | Broadcast sidechannel records send, consume, and refusal counts; doctor/status expose unread age; privacy refusals log counts without echoing sensitive body text. |
| SYN-15 | Add fleet stash-bloat probe and shared recovery-bundle convention | P1 | Hygiene `audits/hygiene.md:86`, hygiene `audits/hygiene.md:125` | Tick reports per-repo stash counts and fleet total with thresholds; recovery-bundle naming is shared across stash, storage, doctrine-sync, and repo-hygiene cleanup classes. |
| SYN-16 | Build a vestigial-surface registry and sunset workflow | P1 | Plan-space `audits/plan-space.md:80`, bead-space `audits/bead-space.md:99`, orchestrator `audits/orchestrator.md:71`, hygiene `audits/hygiene.md:57`, doctrine `audits/doctrine.md:84` | Registry lists missing paths, shims, skeleton probes, stale aliases, and superseded docs with owner, last callsite count, keep/merge/retire disposition, and doctor warning for stale unresolved entries. |
| SYN-17 | Add alternating cross-review gate for high-risk code changes | P2 | Code-space `audits/code-space.md:95`, external guide `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:223` | High-risk code beads can request alternating model or peer review before close; the gate records reviewer, findings, and disposition without blocking low-risk single-file changes. |
| SYN-18 | Add UI/platform split polish receipts where UI exists | P2 | Code-space `audits/code-space.md:100`, external guide `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:202` | UI-bearing work records desktop and mobile validation receipts; non-UI work emits a compact not-applicable receipt. |
| SYN-19 | Add de-slopify/public-artifact pattern audit | P2 | Code-space `audits/code-space.md:66`, doctrine `audits/doctrine.md:265`, external guide `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:197` | Public docs, broadcast packets, and generated plans run a light de-slopify/publishability audit; failures produce actionable edits or explicit waiver receipts. |
| SYN-20 | Fold orphan residue scripts into hygiene targets | P2 | Hygiene `audits/hygiene.md:61`, hygiene `audits/hygiene.md:62`, hygiene `audits/hygiene.md:65` | `session-residue-prune`, watcher-pattern replay, and missing repo-hygiene skill references either become schema-backed hygiene targets or are marked prototype/legacy with compatibility notes. |

Fix beads consolidated: 20/21.

## 3. Priority Ordering

**P0 ship-this-week**

SYN-01, SYN-02, SYN-03, SYN-04, SYN-05, SYN-06, SYN-07.

These are load-bearing because they protect L128 backing, close truth,
callback/refill uptime, and storage substrate safety. They directly address the
known picoz failure modes: post-hoc convergence, closed-without-evidence,
worker-close-without-commit, callback idle leak, and disk pressure blocking the
fleet.

**P1 ship-this-month**

SYN-08, SYN-09, SYN-10, SYN-11, SYN-12, SYN-13, SYN-14, SYN-15, SYN-16.

These are high-leverage but not all must block current close paths. They improve
plan/bead quality, swarm health visibility, cross-orch broadcast consumption,
staggered launch discipline, and cleanup of stale references.

**P2 backlog**

SYN-17, SYN-18, SYN-19, SYN-20.

These should ship selectively as the relevant surfaces are touched. They improve
review breadth, UI receipts, public artifact quality, and hygiene
maintainability, but they do not currently block the mission-critical close or
orchestration loop.

P0 count: 7. P1 count: 9. P2 count: 4.

## 4. Lessons Learned By Layer

**Plan-Space**

Plan-space is strongest when it treats a plan as a falsifiable hypothesis.
Today's brenner wires made that concrete: hypothesis slates, prediction locks,
structured deltas, convergence telemetry, and EV anchors all force plan claims
to survive data. The audit showed the next gap is scoring and adversarial miss
pressure: local plan tools already generate diverse strategies, but still need
explicit weighted convergence thresholds and a named exhaustive-miss pass
(`audits/plan-space.md:92`, `audits/plan-space.md:123`,
`audits/plan-space.md:171`).

**Bead-Space**

Bead-space is the translation layer where good plans either become executable
work or dissolve into vague tickets. The audit found strong Beads substrate and
high-value tooling, but generated bodies still trail authored bodies in context,
acceptance, and proof shape (`audits/bead-space.md:162`,
`audits/bead-space.md:217`). The lesson is that bead quality needs both
content-based polish and close-gate scoring, because every weak bead taxes
coordination and code-space later.

**Code-Space**

Code-space taught restraint. The audit explicitly rejected LOC delta as a strong
proxy and favored native substrate reuse, production callsite quality, and
targeted tests (`audits/code-space.md:76`, `audits/code-space.md:84`). The
missing piece is mechanical enforcement: UBS-before-commit and selective
cross-review should run when risk is high, but not turn every small patch into a
ceremony.

**Coordination**

Coordination matured from "send work to panes" into a receipt system. NTM
transport, dispatch-log rows, callback envelopes, Agent Mail reservations,
shared-surface checks, Monitor wake, and hot refill now define whether work is
actually in motion (`audits/coordination.md:72`,
`audits/coordination.md:165`). The lesson from today's loop-staleness work is
that every callback must be connected to validation, close, release, and refill;
any gap in that chain becomes idle burn.

**Orchestrator**

The orchestrator layer is the mission anchor. The audit showed `/flywheel:tick`,
`/loop`, `/flywheel:dispatch`, `/flywheel:status`, `/flywheel:respawn`,
handoffs, and dispatch-log all on critical path (`audits/orchestrator.md:55`).
7wr3e, msixq, and ka0xt together show the maturity pattern: event wake, prompt
rewrite from live state, and same-tick capacity refill. The remaining
orchestrator gap is not raw activity; it is plan-vs-actual drift and
outcome-shape visibility (`audits/orchestrator.md:84`,
`audits/orchestrator.md:85`).

**Hygiene**

Hygiene is uptime work, not janitorial work. Today's storage pressure and the
312GB private temp incident show that disk headroom failures can corrupt logs,
commits, and dispatch writes before any task logic runs (`audits/hygiene.md:100`,
`audits/hygiene.md:102`). The stash census and DCG prose-trigger incidents show
the same pattern in state and text: residue accumulates silently until it
blocks orchestration. Hygiene needs probes, thresholds, and reversible recovery
bundles, not ad hoc cleanup.

**Doctrine**

Doctrine works when it is wired. L96 caught L127/L128 split-brain; L57 demands
loop driver proof; L91 demands dispatch delivery proof; L120/L126 demand close
evidence. The doctrine audit's strongest lesson is that prose-only doctrine
decays unless a doctor, status line, close handler, or validator consumes it
(`audits/doctrine.md:165`, `audits/doctrine.md:171`). L128 is the right
picoz-killer claim, but it must remain mechanically backed and consistently
propagated.

## 5. Mission Alignment Check

**Mission-aligned items**

- The brenner-wire set plus L128 advances `continuous-orchestrator-uptime-self-sustaining-fleet` by making plan convergence falsifiable before the fleet spends code-space time.
- Monitor wake, prompt rewrite, and hot-pane refill directly reduce idle burn and keep panes hot (`audits/orchestrator.md:92`).
- L126 evidence packs, EV anchors, prediction locks, and worker-close commit doctrine make close state auditable instead of self-claimed.
- Storage/private temp/stash hygiene protects the substrate that carries dispatch logs, commits, receipts, and callbacks (`audits/hygiene.md:102`).
- Vestigial-surface cleanup improves operator trust by aligning docs, commands, skills, and actual scripts.

**Mission-orthogonal items**

- UI/platform split polish receipts are valuable for UI-bearing work but do not affect non-UI orchestration uptime.
- Alternating model review is useful for high-risk code but should stay selective so it does not slow low-risk fleet throughput.
- Public-artifact de-slopify improves external clarity and broadcast quality, but only becomes mission-critical when the artifact is used as dispatch or doctrine substrate.

**Mission-conflicting items**

- Worker-close without commit conflicts with the mission because it creates false progress and dirty-tree residue (`audits/hygiene.md:96`, `audits/doctrine.md:140`).
- Marker-only loop status conflicts with the mission because it claims uptime without a driver (`audits/orchestrator.md:76`).
- Split-brain doctrine conflicts with the mission because different agents receive different rules (`audits/doctrine.md:165`).
- Stale aliases, missing skill paths, and pseudo-beads conflict with the mission when they route workers away from the real substrate (`audits/bead-space.md:99`, `audits/hygiene.md:61`).

No active shipped capability should be reversed. The reversal target is stale
claims: remove or rewrite surfaces that claim active behavior without driver
proof, close proof, or an implemented backing script.

## 6. agent-flywheel.com Adoption Decisions

| Gap | Tier | Decision | Local disposition |
|---|---|---|---|
| Convergence thresholds and score bands | Tier 1 | ADOPT-MODIFIED | xhfbw shipped convergence telemetry and L128 binds the doctrine, but local plan/bead gates should use weighted scores rather than copying raw external percentages unchanged. Covered by SYN-02 and SYN-03. |
| Bead polishing rounds by content | Tier 1 | ADOPT | Bead-space found the exact missing behavior. Covered by SYN-08. |
| Idea-wizard 30 -> 5 -> 15 strategy shape | Tier 1 | ADOPT-MODIFIED | Local idea surfaces already approximate the pattern; adopt the strategy funnel with explicit human review and structured deltas rather than changing every local command name. Covered by SYN-10. |
| UBS before every commit | Tier 2 | ADOPT-MODIFIED | Use staged/scoped enforcement for worker close and high-risk code paths, with bypass receipts for safe exceptions. Covered by SYN-04. |
| Platform split polish | Tier 2 | ADOPT-MODIFIED | Apply to UI-bearing work only; non-UI work records not-applicable. Covered by SYN-18. |
| Plan-vs-actual drift probe | Tier 2 | ADOPT | Orchestrator and doctrine both found this missing. Covered by SYN-12. |
| "Lie to them" exhaustive re-review | Tier 3 | ADOPT-MODIFIED | Adopt as an adversarial miss probe, clearly labeled as prompt pressure rather than factual evidence. Covered by SYN-11. |
| De-slopify pattern audit | Tier 3 | ADOPT-MODIFIED | Local de-slopify exists as a skill; wire it selectively into public artifacts, broadcast packets, and generated plans. Covered by SYN-19. |
| Stagger 30s+ swarm starts | Tier 3 | ADOPT | Coordination and hygiene both found missing enforcement. Covered by SYN-13. |
| Outcome-shape benchmark | Tier 3 | ADOPT | Add a local status line using local sources and compare trend shape rather than treating the external exemplar as a hard target. Covered by SYN-12. |

Tier-1 adoption summary: ADOPT=1, ADOPT-MODIFIED=2, SKIP=0.

No Tier-1/2/3 gap is a pure skip. The modifications are local substrate choices:
we keep L-rules, close gates, NTM/dispatch-log, Agent Mail reservations, and
compliance packs as the implementation mechanism instead of copying the public
stack's exact orchestration surface.
