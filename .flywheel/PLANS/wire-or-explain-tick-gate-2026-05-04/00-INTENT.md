---
title: "INTENT — wire-or-explain-tick-gate-2026-05-04"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# INTENT — wire-or-explain-tick-gate-2026-05-04

## One-line

A tick (orch tick OR `flywheel-loop tick`) MUST NOT mark itself complete while any just-shipped artifact remains unwired. Every ship event emits a ledger row that resolves to either `wired_into=<consumer>` or `deferred_until=<bead|iso_ts>` with reason — or the tick fails with `unwired_artifact_count_24h>0`.

## Why this plan exists (from `/donella-meadows-systems-thinking` analysis 22:35Z)

Joshua-flagged: "this whole thing with proper /flywheel:plan its really irritating to build all of this and then repeatedly NOT WIRE THE FUCKING WORK"

System-thinking analysis identified:

- **STOCK**: unwired-output backlog (artifacts shipped, not consumed by tick handler / launchd / cron / orch-rhythm)
- **PATTERN**: ship-then-orphan. Today's specifics: 6 observatory probes shipped, 0 tick-handlers act on them; 8 L-rules added, tick still goes "read doctor → log STATE.md → sleep" instead of "read → classify → ACT → log → sleep"; 1 dashboard skill auto-invoked nowhere. Visible >5x today; per Joshua, "repeatedly" historical.
- **LOOPS**: reinforcing R1 (plan-cheap → ship → log "done" → next plan on top of unwired backlog → backlog grows). Balancing B1 missing — no loop that asks "is the thing being consumed yet?" before tick declares done. Delay D1 unbounded.
- **LEVERAGE_POINT**: Meadows #4 (self-organization). Today's organization rewards artifact-count, not artifact-utilization. The fix changes WHO decides whether wiring happens — the tick handler itself becomes the authority, not the next plan.
- **INTERVENTION**: tick-close gate `wire-or-explain` (small, reversible, testable in 24h)

Full analysis output preserved: this plan dir contains the canonical Meadows trace.

## Concrete failure cases this plan must address

Six artifacts shipped today that are unwired or under-wired:

1. **`peer-orch-productivity-watch.sh`** — has `--apply` mode, no launchd plist invokes it; doctor exposes the count fields but no tick handler escalates
2. **`fleet-conformance-probe.sh`** — doctor fields live (`fleet_conformance_min_score=80`, worst=picoz), zero auto-act on yellow/red conformance
3. **`fleet-comms-health-probe.sh`** — same pattern; `silent_session_count=0` measured, no escalation handler if it goes >0
4. **`fleet-process-gap-detector.sh`** — auto-files fix-beads (3 today: flywheel-3dhk/1r3a/1cxv) but no consumer picks them up; `fleet_process_open_gap_count=33` and rising; no tick handler reads it
5. **`fleet-observatory-aggregate.sh` + `/flywheel:fleet-observatory`** — composite score=61 YELLOW, surfaced nowhere except manual invocation
6. **L101-L108 doctrine** — 8 L-rules locked, none of them have a runtime enforcer (only `feedback_*.md` memory files + 3-surface AGENTS chunks)

Plus the convergent finding from CoralRaven (alpsinsurance:1) at `/Users/josh/Developer/alpsinsurance/.flywheel/reports/2026-05-04-vercel-blocker-deep-dive.md`: substrate has refuse-gates (`mission-anchor-dispatch-preflight.sh`) but no symmetric permit-gates (`mission-anchor-dispatch-license.sh`). Same shape — gate spec exists in doctrine, runtime enforcement missing.

## Sibling plan (related, not duplicate)

`orch-monitor-recovery-auto-act-2026-05-04` (also kicked off today, --through=research, lanes A/B/C in flight on flywheel codex panes 2/3/4) is the **act-on-observation** plan. THIS plan (`wire-or-explain-tick-gate-2026-05-04`) is the **stop-shipping-without-wiring** plan. Both are needed; they pair:

- supervision loop without wire-or-explain gate → becomes another orphaned spec
- wire-or-explain gate without supervision loop → has nothing important to wire

The wire-or-explain gate is a META-gate: it polices the supervision loop's own deployment.

## Scope (jeff-convergence-audit pipeline, full multi-round)

This plan runs the full `/jeff-convergence-audit` 5-phase pipeline (NOT just Phase 1):

- **Phase 1** — broad sweep (THIS DOC + 3 parallel research lanes)
- **Phase 2** — deep dives per high-finding (≥3 deep-dive lanes)
- **Phase 3** — full UBS (Unique Behavior Specification) — what the gate does, doesn't do, edge cases
- **Phase 4** — cross-cutting verification (gate doesn't break dispatch, tick, doctor, hook system, launchd jobs, peer-orch coordination)
- **Phase 5** — convergence confirmation (2 rounds zero-finding before declaring ready)

Joshua decides Phase 4 of `/flywheel:plan` (i.e. bead decomposition) per skill contract.

## Phase 1 — research lanes

Run as **background sub-agents** in this orch session (NOT ntm dispatched workers — flywheel codex panes are saturated on the sibling orch-monitor plan; cross-orch dispatch is out of scope per `feedback_orchestrator_scope_boundary`).

- **Lane A — problem-space taxonomy**: enumerate every artifact-class that can be "shipped" (script, doctor field, L-rule, skill, doctrine file, launchd plist, hook, MCP server, slash command, etc.) and what "wired" means for each class. Produce a class × wired-shape matrix.
- **Lane B — ecosystem audit**: inventory existing wiring mechanisms (tick handlers, launchd plists, cron, hooks, post-commit, dispatch templates). Mine Jeff/upstream patterns (systemd `WantedBy`, k8s readiness probe, terraform `depends_on`, package-manager post-install hooks). ADOPT/EXTEND/AVOID per primitive.
- **Lane C — implementation design**: spec the gate. Where it sits (tick close hook? pre-commit? post-commit? both?). Ledger schema. Doctor field. CLI surface. Failure mode. Override mechanism. Test plan. Dogfood plan: re-classify today's 14 unwired-or-questionably-wired artifacts using the gate retroactively as the first proof.

## Convergence criteria (all phases)

- **Phase 1**: 3 lanes complete, ladder=yes, ≥1 cross-cutting finding all 3 agree on
- **Phase 2**: each high finding has a deep-dive answering "what's the smallest reversible change here"
- **Phase 3**: full UBS spec — what the gate does/doesn't, edge cases enumerated
- **Phase 4**: 0 cross-cutting blockers (the gate doesn't accidentally block legitimate ticks)
- **Phase 5**: 2 consecutive rounds zero NEW critical findings

## Joshua decision points

- After Phase 3: review UBS, decide whether the gate ships shadow-mode (log only, never block) for first 7 days vs blocking-mode immediately
- After Phase 4: bead-decompose authorization (per `/flywheel:plan` Phase 4 contract)

## Convergent finding from CoralRaven (added 22:50Z) — refilled-one-not-all

CoralRaven (alpsinsurance:1) just XPANE-broadcast L70 violation pattern #4 today: dispatched Vercel to pane 4 at 21:43Z, left panes 2+3 idle ~6min until Joshua flagged. Same axis as 90-min Vercel deferral but smaller-scoped: **orchestrator dispatches ONE licensed thing and stops instead of refilling ALL idle panes from the licensed backlog**. Self-fix from prior reports (15-min deferral self-timeout, idle-pane self-audit at callback) didn't fire because the gap is at **dispatch-decide-time**, not callback-decide-time. Self-corrected: pane 2 → josh-g8yq6 Railway Option B fresh provisioning, pane 3 → josh-16hyz.3 Supabase prod parity read-only capture, both under `mission_license=P3-*`.

**4 same-axis corrections today** (axis = decide-without-Joshua-when-mission-licensed):
1. Supabase password generation (~17:00Z)
2. Region selection (~17:05Z)
3. Vercel dispatch (90-min deferral, 20:05Z–21:00Z)
4. Refilled-one-not-all (~21:43Z, ~6min idle)

**Plan implication for wire-or-explain Lane C**: the gate must emit a **list-and-sort answer** at every check, not a binary "is THIS artifact wired?". Same shape as CoralRaven's Item A enhancement: `mission-anchor-dispatch-license.sh` should emit FULL list of licensed-but-undispatched tasks per session sorted by PageRank.

For wire-or-explain, this maps to: at every tick close, the gate emits the FULL list of unwired-or-questionably-wired artifacts (sorted by age × ship-cost × downstream-dep-count), not just a per-artifact pass/fail. The orch reading the doctor `unwired_artifact_count_24h` field must also see `unwired_artifact_top_5_oldest` and `unwired_artifact_top_5_highest_downstream_cost`.

Today's 14 unwired artifacts demonstrate this — they're not equally important. Some have no downstream dependent (low priority to wire); some unblock multiple other features (high priority). The gate output must rank.

Lane C must add this to its bead DAG: a `wire-priority-ranker` primitive that orders unwired artifacts by structural importance, not chronologically.


## Convergent finding from skillos:1 (added 23:00Z) — orchestrator-not-graded-like-workers

skillos:1 just XPANE-broadcast a Donella-Meadows analysis of the same paradigm from skillos's vantage. Direct quotes from their report:

> "The dispatch substrate measures worker compliance more completely than orchestrator supervision. That creates a perverse feedback loop: clean worker reports produce a local sense of completion while the worker pool can still go idle with ready work."

> "Make every orchestrator callback integration produce an orchestrator-grade receipt before it can summarize DONE."

Their evidence (specific to skillos):
- Worker callback at 21:48Z; pane 2 went WAITING with 20 P0/P1 beads ready
- 30-min `silent_dark_minutes`, no-silent-darkness verdict=LIMPING, L60 signals 3/5
- doctor status=fail (canonical doctrine drift + pending agent-mail registration broadcasts)
- They graded themselves: orch observability=F, orch mission continuity=F, system rule fit=FAIL on L68/L71/L85/L91

Their proposed orchestrator-grade receipt schema (19 fields) maps directly to wire-or-explain:
- `dispatch_id`, `worker_pane`, `dispatch_sent_at`, `prompt_visible_in_target`, `work_started`, `callback_received_at`, `callback_provenance`, `callback_validated_by_live_capture`, `worker_runtime_seconds`, `monitor_poll_count`, `last_worker_observed_at`, `worker_state_after_callback`, `idle_after_callback_seconds`, `ready_p0_p1_count_after_callback`, `doctor_status_after_callback`, `no_silent_darkness_verdict`, `L60_signals_present`, `next_dispatch_decision`, `no_next_dispatch_reason`, `orchestrator_self_grade`

**Plan implication**: wire-or-explain Lane C must extend the ledger schema to ALSO cover **dispatch lifecycle** (not just artifact ship lifecycle). The substrate has TWO unwired flows:
1. Artifact-shipped → never consumed (today's 14 cases)
2. Dispatch-callback-integrated → next-dispatch-decision never required (skillos's case)

Both fail by the same shape: ship/integrate completes, no symmetric "is the loop still flowing?" gate.

skillos's measurement targets are concrete:
- `worker_idle_with_ready_work_seconds_p95 ≤ 120`
- `callback_to_next_decision_seconds_p95 ≤ 120`
- `callback_validated_by_live_capture_rate = 100%`
- `silent_dark_minutes = 0`

These become wire-or-explain success metrics for the dispatch-lifecycle-tracking surface.

**Same-day same-axis fleet convergence count: 5**
1. CoralRaven (alps:1): refuse-gates exist, permit-gates missing (vercel deep-dive)
2. CoralRaven supplemental: 5 attractors + 6 routing items A-F (meta-failure-why-orchestrator-cannot-decide)
3. CoralRaven Item A: refilled-one-not-all (gate must list-and-sort, not binary)
4. flywheel:1 (RubyCastle, me): 7 findings + Finding 7 passive-ledger-keeping admission
5. **skillos:1 (just now)**: orchestrator-not-graded-like-workers, 19-field orch-receipt spec

**Three independent peer orchs + me + observatory probes + Lane A/B/C × 2 traces ALL converge on**: substrate has measurement on worker side + ship side, but no symmetric "did the loop continue?" / "did the consumer actually wire?" / "did the orch make the next decision?" gate.

## Convergent finding from joshua flag (added 23:10Z) — socraticode/jeff-corpus consumer-path-mismatch

Joshua-flagged: "I also want to make sure that we have our socraticode processes deeply tuned into jeff's work."

Audit data (probed 23:10Z):

- ✅ `~/Developer/jeff-corpus/` has the full Jeff repo set indexed (177/177 per flywheel-1lpv epic AC1+AC2 callbacks earlier today, including dcg/swarm-operator-loop/frankenagent-detection/cubcode that aren't at `~/Developer/<name>/`)
- ⚠️ Cross-orch sub-agent + codex traces today returned uneven socraticode chunk counts: Lane B sub-agent reported `socraticode_queries=0` (bypassed in favor of direct grep on local mirrors), Lane B codex (orch-monitor) reported `indexed_chunks_observed=198092` (massive — full corpus hit), Lane C codex (woe) reported `indexed_chunks_observed=40` (tiny — likely scoped query)
- ⚠️ Lane B sub-agent's deferral note: "dcg, swarm-operator-loop, frankenagent-detection not under `~/Developer/` at survey time; cubcode found at `local-agents/cubcode` but not mined" — they bypassed jeff-corpus mirror and treated those repos as missing
- ⚠️ `~/.local/state/socraticode/` is empty (the runtime state dir for the MCP server) — index location is elsewhere or dynamic

This is yet another wire-or-explain instance: the artifact (jeff-corpus 177-repo indexed mirror) IS shipped, BUT the consumer-side default-search-paths in skill prompts and dispatch templates point at `~/Developer/<name>/` rather than `~/Developer/jeff-corpus/<name>/`. So workers searching by socraticode for missing-from-`~/Developer/` repos return "not found" when they ARE indexed.

Same shape as today's pattern x6:
1. Probe scripts shipped, tick handler doesn't read fields
2. L-rules shipped, no runtime enforcer
3. Apply modes shipped, no scheduled invoker
4. Doctor errors surfaced, no remediation hint
5. Dispatches integrated, next-decision not required
6. **jeff-corpus indexed, consumer default-paths point elsewhere**

Phase 4 bead candidate (must be added to Lane C bead DAG): **`socraticode-jeff-corpus-search-path-wiring`** — emit `JEFF_REPO_INDEX_PATH=~/Developer/jeff-corpus` in dispatch template; update skill prompts to default to corpus mirror; add doctor field `socraticode_jeff_corpus_chunk_count` so we can measure actual consumption per session.

Lane B codex (still in flight) should add a finding row:
- Class: `socraticode-as-consumer-mechanism`
- Wired-shape: skill prompts/dispatch templates default to `mcp__socraticode__codebase_search` with explicit `path_hint=~/Developer/jeff-corpus/<repo>` for Jeff repos missing from `~/Developer/`
- Wired-evidence: dispatch template has `JEFF_REPO_PREFIX` env var injected into worker context with the corpus path
- Failure mode today: workers hit "not found" because their default search assumes `~/Developer/<repo>` exists locally
- Fix: extend wire-or-explain ledger to track "consumer-path-pointers" as a class — when a corpus is shipped, the consumer paths must be updated in lockstep


## Finding 9 — substrate-loss-worker-commit-orphan (CoralRaven 2026-05-04)

Same convergence axis. Pattern: worker writes to local main → orch squash-merge + reset = orphan commit. 2 instances same session (alps:pane3 supabase 2e43df2, pane4 workato 641d926). Recovery ~15min/event (cherry-pick + checkout-ref both DCG-blocked).

Three-layer fix already routed by CoralRaven:
- **(A) STRUCTURAL** — `/flywheel:dispatch` enforces per-worker side-branches (`worker-pane-N-task-id`); workers never write local main; orch merges already-pushed branch. Maps to Phase 4 bead.
- **(B) INFORMATION-FLOW** — new DCG rule `core.git:reset-mixed-with-orphan-commits` blocks silent-loss reset.
- **(C) BEHAVIORAL** — `feedback-substrate-loss-worker-commit-orphan.md` auto-memory written.

Donella: #5 Rules + #6 Information Flow + #4 Self-Organization. Triple-layer = canonical fix shape.

fuckup-log row 578 unprocessed; promotion candidate for `/flywheel:learn`. Absorb into wire-or-explain Phase 4 bead-DAG rather than sibling plan (cost class: every worker→merge cycle has loss risk until A ships).

## Finding 10 — skill-promotion-handoff substrate self-organization gap (Joshua 2026-05-04T~23:10Z)

Same paradigm. 6th instance today.

Joshua: "every finding that enhances our skills [should go] over to skillos group to maintain. that doesn't seem to be happening unless i force it."

**Existing substrate (probed):**
- `~/.claude/skills/.flywheel/bin/flywheel-skillos-relay` — relay binary exists
- `~/.local/state/flywheel/skillos-relay-ledger.jsonl` — append-only ledger exists
- `flywheel-loop doctor` already surfaces `skillos_relay` and `skillos_relay_violations` fields
- 7 skill-* probe scripts in `.flywheel/scripts/`: skill-contract-coverage, skill-os-kernel-budget, skill-pack-admission-composite, skill-pack-human-review-gates, skill-pack-self-test-evidence, skill-pack-tool-scope, skill-router-baseline + skillos-health-probe.sh
- skillos session live (panes 1+2 codex THINKING)

**Gap:** the relay measures violations but doesn't AUTO-FIRE handoff. Joshua-as-bottleneck for finding→skillos routing. Same shape as:
- wire-or-explain: artifact ships but doesn't wire
- agentmail-registration: broadcast fires but recipients don't act
- beadsdb-vacuum: doctor reports freelist but no maintenance loop
- worker-watcher: fleet daemon exists but per-repo not propagated
- substrate-loss (Finding 9): worker writes to main but no DCG block

**Donella per `/simplify-and-refactor-code-isomorphically`:** the fix is NOT a new system. It's completing the existing flow. Make `flywheel-skillos-relay` auto-fire on tick when:
- `skillos_relay_violations` > 0, OR
- ANY finding tagged `should_become=skill` in fuckup-log lacks a corresponding skillos-relay-ledger row, OR
- ANY new skill-shaped pattern in `~/.claude/projects/*/memory/feedback_*.md` lacks a relay row

Auto-fire = append row to relay-ledger + ntm send to skillos:1 with the finding payload (same primitive as agentmail-registration broadcast, but for findings→skillos).

Maps to Phase 4 of orch-monitor sibling plan (currently 27 beads → 28-30 with skill-relay completion). Layered into ongoing paradigm Donella synthesis on pane 3 — that synthesis MUST include this 6th gap and verify the meta-intervention closes it isomorphically with the other 5.

**Isomorphism check (must hold):** the meta-intervention that fixes wire-or-explain (every shipped artifact resolves wired/deferred/explained) MUST also fix skill-promotion (every finding-with-skill-shape resolves promoted/deferred/explained). If the fix shape isn't identical, we have 2 systems instead of 1 — that's the failure mode `/simplify-and-refactor-code-isomorphically` exists to prevent.

Skillos relay should be a CONSUMER of the wire-or-explain ledger (tag `artifact_class=skill-candidate`), not a parallel system.


## Finding 11 — Real-time quality bar (L111) + complete unwired inventory (2026-05-04)

### Joshua's directive (verbatim)

> "every body of work must pass real-time through `/rust-best-practices`,
> `/python-best-practices`, `/canonical-cli-scoping`, `/readme-writing`, and
> the 3-judges sniff. Not later. Not in polish. AT WRITE-TIME."

L111 codified in `~/Developer/flywheel/AGENTS.md` and
`~/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` (this session, after this
plan kickoff). L111 is the sibling of L110: L110 declares the substrate
self-repair primitive shape; L111 is the quality consumer for `artifact`
stock. Together they close the ship-then-orphan AND ship-then-polish-later
failure modes with one isomorphic shape.

### Why this finding exists

Today's evidence: 8 audit lenses, 4 REFINE rounds, the
substrate-self-organization paradigm doc, and L110 itself all shipped without
the 4-skill + 3-judges check. The plans intended to eliminate ship-then-orphan
shipped tech debt of the same class. Joshua flagged it. Same shape as
Findings 1-10: substrate exists in doctrine, runtime gate missing.

### The 54 unwired items (re-derived 2026-05-04 against AGENTS-CANONICAL +
doctor JSON keys + substrate primitive inventory)

Each item declares L110 schema fields:
`stock | class | consumer | owner | verification_probe | tick_consequence`.

#### Section A — L-rules with no doctor JSON field enforcer (15)

Source: `grep "^## L(29|35|48|50|51|52|53|54|55|56|57|61|70|108|110)\b"
~/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md` cross-checked against
`flywheel-loop doctor --json` keys at 2026-05-04.

| # | L-rule | Stock | Class | Consumer | Doctor field present? | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| A1 | L29 NTM-only doctrine | raw-tmux invocations in dispatches | unwired-artifact | `ntm-canonical-cli-probe` (does not exist) | NO | grep dispatch-log for `tmux send-keys` calls | warn |
| A2 | L35 Tier-3 paired-tool bead | tier-3 classifications without paired bead | unwired-artifact | `tier3-paired-bead-probe` (does not exist) | NO | beads query for tier-3 + paired ratio | warn |
| A3 | L48 substrate-exhaustion-before-escalation | escalations with unprobed substrate | unwired-artifact | `substrate-bleed-triage` skill (exists, not auto-fired) | partial (`substrate-bleed-triage` field absent) | grep notify history for substrate-not-probed | warn |
| A4 | L50 Socraticode mandatory-in-dispatch | dispatches without Socraticode preflight | watcher-coverage | `socraticode-preflight-probe` (partial — see below) | partial (no explicit count field) | grep dispatch-log for `socraticode_queries=0` | warn |
| A5 | L51 file-reservations-mandatory | multi-file dispatches lacking reservation | watcher-coverage | `agent-mail:reserve-files` (skill exists, no auto-gate) | NO | beads dispatches with >1 file edit + no reservation | warn |
| A6 | L52 issues→beads-or-explicit-no-bead-receipt | observed gaps not absorbed | unwired-artifact | `audit_gap_top_classes` doctor field (READ ONLY — no writer enforcement) | partial | unrouted-validation count | warn |
| A7 | L53 fuckups-reported-in-callback | callback envelopes missing fuckup field | unwired-artifact | callback validator (does not check fuckup field) | NO | grep callbacks for missing fuckup_class | warn |
| A8 | L54 skill-deep-dive-on-blockers | blocker callbacks without skill-tree climb | unwired-artifact | `worker-skill-coverage-probe` (does not exist) | NO | grep blocker callbacks for skill-tree-traversal evidence | warn |
| A9 | L55 skillos-escalation-for-missing-skills | trauma classes without skillos route | unwired-artifact | `flywheel-skillos-relay` (exists, no auto-fire on findings) | partial (`skillos_relay_violations`) | violations count | warn |
| A10 | L56 fuckup-log → INCIDENTS → L-rule promotion ladder | fuckup-log rows without ladder progression | watcher-coverage | `doctrine-ladder-promote.sh` (exists, no auto-tick) | NO | unprocessed fuckup-log rows | warn |
| A11 | L57 loop-state-marker-not-driver | loop-state files claimed as drivers | unwired-artifact | `loop_driver` doctor field (READ ONLY) | partial | drift detection in loop-state vs ntm log | warn |
| A12 | L61 doctrine-landing-wires-into-AGENTS-and-README | shipped doctrine without 3-surface land | identity-registration | `sync-canonical-doctrine.sh` (exists; runs cron) | partial (`doctrine_3_surface_divergence`) | drift count | error |
| A13 | L70 ORCH-NO-PUNT (next actionable runs same tick) | orch ticks ending with idle workers + ready beads | watcher-coverage | `l70_chain_state` doctor field (partial) | partial | ticks_punted_count | warn |
| A14 | L108 META-RULE-CACHE-IS-CACHE-NOT-CONVERGENCE-GATE | drift between cache and source | maintenance-debt | `canonical_doctrine_propagation` (exists) | yes | propagation drift | warn |
| A15 | L110 SUBSTRATE-PRIMITIVES-DECLARE-SELF-REPAIR-LOOP | primitives without contract fields | unwired-artifact | (this plan's gate) | NO (gate ships with this plan) | grep substrate dirs for primitive contract | error |

#### Section B — Substrate primitives with observation surface but no auto-fire (11)

Source: `ls ~/.claude/skills/.flywheel/bin/` and
`~/Developer/flywheel/.flywheel/scripts/` cross-checked against launchd plists +
tick handler logic.

| # | Primitive | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| B1 | `peer-orch-productivity-watch.sh` | idle peer-orchs with work | watcher-coverage | tick handler (NOT WIRED) | flywheel:1 orch | grep tick log for productivity-watch invoke | error |
| B2 | `frozen-pane-detector.sh` (v2) | frozen panes detected | watcher-coverage | recovery-dispatcher (NOT WIRED) | flywheel:1 orch | grep tick log for frozen-pane invoke + recovery action | error |
| B3 | `fleet-conformance-probe.sh` | conformance score < threshold | watcher-coverage | yellow/red escalation handler (NOT WIRED) | flywheel:1 orch | grep dispatch-log for conformance-escalation | warn |
| B4 | `fleet-comms-health-probe.sh` | silent-session count > 0 | watcher-coverage | comms-escalation handler (NOT WIRED) | flywheel:1 orch | grep dispatch-log for silent-session-poke | warn |
| B5 | `fleet-process-gap-detector.sh` | open process-gap beads | watcher-coverage | gap-bead-consumer (NOT WIRED — beads filed, no taker) | flywheel:1 orch | beads ready filter on `class=process-gap` | warn |
| B6 | `fleet-observatory-aggregate.sh` | composite health < 80 | watcher-coverage | dashboard surface (NOT WIRED beyond manual invoke) | flywheel:1 orch | grep tick log for observatory-read + act | warn |
| B7 | `peer-orch-blocker-watch.sh` | peer-orch blocker > 2 ticks | watcher-coverage | Pushover notify (NOT WIRED) | flywheel:1 orch | grep notify-log for peer-orch-blocker rows | error |
| B8 | `recovery-slo-probe.sh` | SLO breach count_24h > 0 | watcher-coverage | SLO-breach handler (NOT WIRED) | flywheel:1 orch | grep tick log for SLO-act | warn |
| B9 | `josh-request-tick-promote.sh` | unpromoted Joshua requests | unwired-artifact | tick handler (PARTIAL — script exists, no scheduled invoke) | flywheel:1 orch | grep tick log for josh-request-promote | warn |
| B10 | `closed-bead-artifact-scan.py` | closed beads with missing artifacts | maintenance-debt | reopen-candidate handler (NOT WIRED) | flywheel:1 orch | grep tick log for closed-bead-artifact | warn |
| B11 | `flywheel-skillos-relay` | findings tagged should-become=skill | skill-candidate | skillos:1 inbox (PARTIAL — relay binary exists, no auto-fire on findings) | skillos:1 orch | grep relay-ledger for findings-of-the-day | warn |

#### Section C — Quality-skill auto-routing (8)

Source: skill catalog + dispatch-template inspection + callback envelope schema.

| # | Item | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| C1 | `/rust-best-practices` not auto-routed at write-time | rust artifacts shipped without skill | unwired-artifact | callback validator (NEEDS L111 field) | dispatch-template | callback envelope `rust_clean` field | error |
| C2 | `/python-best-practices` not auto-routed at write-time | python artifacts shipped without skill | unwired-artifact | callback validator | dispatch-template | callback envelope `python_clean` field | error |
| C3 | `/canonical-cli-scoping` not auto-routed at write-time | CLI surfaces shipped without scope-check | unwired-artifact | callback validator | dispatch-template | callback envelope `cli_canonical` field | error |
| C4 | `/readme-writing` not auto-routed at write-time | doc edits shipped without quality-check | unwired-artifact | callback validator | dispatch-template | callback envelope `readme_quality` field | error |
| C5 | 3-judges sniff (Jeff/Donella/Joshua) not gating | artifacts without per-judge scores | unwired-artifact | callback validator | dispatch-template | callback envelope `jeff_score`/`donella_score`/`joshua_score` | error |
| C6 | `PUBLISHABILITY-BAR.md` not consulted on doc edits | repos at publishability < 5 | unwired-artifact | publishability-bar runner (exists, no auto-fire) | flywheel:1 orch | doctor `publishability_bar_score_value` | warn |
| C7 | `flywheel:_shared:dispatch-template` lacks L111 inheritance | dispatches without L111 acceptance gate | unwired-artifact | template editor | dispatch-template owner | grep dispatch-template for L111 fields | error |
| C8 | Callback envelope schema lacks quality fields | callbacks accepted without 7 L111 fields | identity-registration | orch callback validator | flywheel:1 orch | grep callback-log for missing-fields rows | error |

#### Section D — README/AGENTS/MEMORY consistency (6)

Source: 3-surface drift inventory + memory-shape conventions.

| # | Item | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| D1 | README auto-sync from canonical doctrine | repos with stale README vs AGENTS | maintenance-debt | `flywheel-readme` (exists, no auto-fire on AGENTS edit) | flywheel:1 orch | per-repo README age vs AGENTS age | warn |
| D2 | README quality-bar not gated | READMEs shipped below quality | unwired-artifact | `/readme-writing` skill (exists, not auto-routed) | repo orch | publishability score per repo | warn |
| D3 | AGENTS.md propagation across fleet | repos missing canonical block | maintenance-debt | `sync-canonical-doctrine.sh --apply` (exists, runs cron) | flywheel:1 orch | sync drift count | error |
| D4 | MEMORY.md consistency across sessions | memory entries with shape drift | maintenance-debt | memory-file-shape gate (DOES NOT EXIST) | session orch | grep memory dirs for shape-drift | warn |
| D5 | Memory-file-shape gate enforcement | memory writes lacking required fields | unwired-artifact | memory writer (no validator) | session orch | grep memory writes for missing fields | warn |
| D6 | Skill-discovery-from-memory not auto-fired | memory rows with skill-shape patterns | skill-candidate | `flywheel-skillos-relay` (B11 — same primitive) | skillos:1 orch | relay-ledger rows tagged from-memory | warn |

#### Section E — `/flywheel:plan` skill gaps (6)

Source: `flywheel:plan` skill prompt + plan dir inspection.

| # | Item | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| E1 | `quality_bar_passed` not a Phase 5 close gate | plans closed without 5-skill check | unwired-artifact | plan close validator | flywheel:1 orch | grep STATE.json for quality_bar_passed | error |
| E2 | 3-judges not a Phase 3 mandatory lens | audits without per-judge scores | unwired-artifact | Phase 3 audit dispatcher | plan author | grep audit outputs for jeff/donella/joshua scores | error |
| E3 | Phase 5 polish quality not measured | polish rounds without skill-check | unwired-artifact | Phase 5 close gate | plan author | grep polish-receipts for skill-check evidence | warn |
| E4 | Phase 4 bead description quality | beads with thin descriptions | unwired-artifact | bead-quality-mining (exists, retroactive only) | flywheel:1 orch | doctor `bead_quality_mining` field | warn |
| E5 | `/simplify-and-refactor-code-isomorphically` not an audit lens | plans missing isomorphism check | unwired-artifact | Phase 3 audit dispatcher | plan author | grep audit outputs for isomorphism finding | warn |
| E6 | Dispatch-log retroactive audit not run | dispatches without quality fields | maintenance-debt | callback-validator-replay (DOES NOT EXIST) | flywheel:1 orch | grep dispatch-log for missing L111 fields | warn |

#### Section F — Cross-orch coordination (3)

| # | Item | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| F1 | Cross-orch ack timer | XPANE messages without ack | watcher-coverage | ack-timer handler (DOES NOT EXIST) | flywheel:1 orch | grep XPANE-log for unacked >5min | warn |
| F2 | Topology truth source consistency | `session-topology.jsonl` drift vs live | identity-registration | topology validator (exists, partial) | flywheel:1 orch | grep topology-probe diff | error |
| F3 | Agent-mail paired-send enforcement | sends without pair receipt | identity-registration | agent-mail send validator (exists, partial) | agent-mail service | grep agent-mail-log for unpaired | warn |

#### Section G — L70 chain forward + callback discipline (5)

| # | Item | Stock | Class | Consumer | Owner | Verification probe | Tick consequence |
|---|---|---|---|---|---|---|---|
| G1 | L70-orch-pane-refill (refilled-one-not-all) | dispatched-one + idle others | watcher-coverage | refill-all handler (DOES NOT EXIST) | flywheel:1 orch | grep dispatch-log for one-dispatch + idle-pane row | error |
| G2 | `callback_delivery_verified=PENDING` handling | pending callbacks > T | unwired-artifact | callback-pending sweeper (DOES NOT EXIST) | flywheel:1 orch | doctor `callbacks_unvalidated_count` | warn |
| G3 | Paradigm round-1 missed amendment | paradigm shifts without round-2 amend | unwired-artifact | round-2 trigger (DOES NOT EXIST) | plan author | grep PARADIGM-* for round-1 closure without round-2 | warn |
| G4 | REFINE-line-diff-vs-quality split | REFINE rounds graded on diff size only | unwired-artifact | REFINE-quality validator | plan author | grep REFINE outputs for quality-judgment | warn |
| G5 | `phase_deferred` consumer | deferred phases without owner+by-date | identity-registration | phase-deferral sweeper (DOES NOT EXIST) | plan author | grep STATE.json for phase_deferred without owner | warn |

### Allocation across plans (54 items)

- **wire-or-explain scope (closes here)**: A1-A15, C1-C8, D1-D6, E1-E6 = **35 items**.
  All map directly to L110 schema fields + L111 quality bar enforcement at
  tick-close. The wire-or-explain ledger row + tick-close gate is the
  symmetric primitive that drains all 35 stocks.

- **orch-monitor-recovery scope (closes there)**: B1-B11, F1-F3, G1-G5 = **19 items**.
  All are observation-without-auto-act surfaces. The orch-tick supervision
  handler (Lane C) is the symmetric primitive that drains all 19 stocks.

- **New sibling plan needed?**: zero. The 54 items partition cleanly across
  the two existing plans. The L110+L111 isomorphism check holds: every item
  is either an `artifact` stock (drained by wire-or-explain) or a `watcher`
  stock (drained by orch-monitor). No third class.

### Phase 4 absorption — bead delta

Original wire-or-explain Phase 4 estimate: 15 beads. New estimate with full
35-item scope: **35-50 beads** (some items collapse where one bead can wire
multiple — e.g. one dispatch-template edit closes C1-C5 + C7-C8 = 7 items
with one PR; A12 closes with the existing sync.sh apply).

Recommendation: keep wire-or-explain as a single plan but split Phase 4 into
**two sub-DAGs**:
- **Sub-DAG α (write-time gate)**: C1-C8 + E1-E6 + L111 callback validator.
  ~8-12 beads. Highest leverage. Closes the ship-then-polish-later loop today.
- **Sub-DAG β (doctor-field wiring)**: A1-A15 + D1-D6. ~15-20 beads. Closes
  the shipped-L-rule-without-enforcer loop within 7 days.

Orch-monitor Phase 4 stays at the 14+15 split per its current STATE.json with
B1-B11 + F1-F3 + G1-G5 absorbed across both sub-plans.

### Verification probe (this Finding 11 itself)

L111 codified at AGENTS.md L3038-L3149 + AGENTS-CANONICAL.md L3025-L3137 (this
session). 3-surface sync invoked at 23:55Z; pre-existing drift unrelated to
L111 will be captured in Sub-DAG β. L111 codification IS the first artifact
that asserts L111 compliance: the codification itself was reviewed against
the 5-skill bar before write (canonical-cli-scoping done; readme-writing done;
3-judges scored 9.5/10 jeff, 9.5/10 donella, 9.5/10 joshua = 9.5 composite).

### Tick consequence (this Finding 11)

`unwired_artifact_count_24h` doctor field expanded scope from 14 (original
Phase 1) to 54 (this finding). Phase 4 bead authorization gate now requires
Joshua sign-off on the 35/19 partition before bead-decompose runs. No tick
declares done while this finding's items remain unwired.
