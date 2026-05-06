# Phase 1 Synthesis — wire-or-explain-tick-gate-2026-05-04

**Generated:** 2026-05-04T23:15Z
**Skill:** /jeff-convergence-audit Phase 1 broad-sweep convergence
**Status:** Phase 1 CONVERGED, ready for Phase 2 deep-dives

## Source matrix

Six independent research traces produced concurrently:

| Lane | Source 1 (sub-agent) | Source 2 (codex worker) |
|---|---|---|
| A — taxonomy | ✅ 955-line classification, 16 classes, 0/6/8 wired/partial/unwired (loose definition) | ✅ 17 classes, 2/12/0 wired/partial/unwired (strict definition); agreement=high |
| B — ecosystem | ✅ 12 mechanisms, dispatch-log gap finding, gate_mode={shadow,warn,enforce} | ✅ 10 mechanisms, 8 Jeff adopted, 198,092 chunks observed; agreement=high |
| C — design | ✅ 530 lines, 11 doctor fields, 7 failure modes, 15-bead DAG | ✅ 12 doctor fields, 5 failure modes, 14 dogfood, 12-bead DAG; agreement=high |

Plus 3 cross-orch independent traces (CoralRaven alps:1, skillos:1, joshua-flag socraticode/jeff-corpus) and the sibling orch-monitor plan (lanes A/B/C).

**Total: 6 in-plan sources + 3 cross-orch sources + 1 sibling-plan cross-link = 10 independent traces all converging on the same paradigm.** This is unusually strong audit convergence (typical /jeff-convergence-audit converges on 2-3).

## Convergent findings (HIGH confidence — appears in 4+ sources)

### F1: substrate has measurement, not action

| Source | Specific evidence |
|---|---|
| Lane A sub-agent | 0/14 today-shipped artifacts have action wiring; doctor fields emit but no consumer reads |
| Lane A codex | 12/17 today-shipped at "partial" — measurement only, no action gate |
| Lane B sub-agent | "rich consumer-side machinery and ZERO ship-side ledger; dispatch-log.jsonl 1,205 rows but no `event:'artifact_shipped'`" |
| Lane B codex | 10 mechanisms audited, missing artifact_shipped row class |
| sibling orch-monitor Lane A | 13/13 failure classes have gate gap, 8/8 have ledger gap |
| skillos:1 | "substrate measures worker compliance more completely than orchestrator supervision" |

**Synthesis:** the substrate's measurement spine is mature. The action spine (consume → act → record → close) is missing or asymmetric.

### F2: refuse-gates exist, permit-gates missing

| Source | Specific evidence |
|---|---|
| CoralRaven vercel deep-dive | `mission-anchor-dispatch-preflight.sh` refuses on unfilled MISSION; no symmetric `mission-anchor-dispatch-license.sh` |
| CoralRaven meta-failure | 5 attractors all pull toward Joshua-gate when locked-envelope license is missing |
| Lane C sub-agent | gate-truth-separation skill cited: "stop rules are mature, go rules are doctrine-only" |
| Lane C codex | architecture proposes symmetric ledger with explicit `wired_into=` AND `deferred_until=` resolution |
| skillos:1 | dispatch-callback PASS doesn't trigger next-decision requirement |

**Synthesis:** Asymmetry between stop-rules (refuse-gates, runtime-enforced) and go-rules (permit-gates, doctrine-only). The wire-or-explain gate IS the missing symmetric permit-side substrate.

### F3: the canonical reference shape exists in ONE place

| Source | Specific evidence |
|---|---|
| Lane A sub-agent (2nd pass) | "`~/.flywheel/canonical-meta-rules/sync.sh` has full transit (probe → doctor → tick handler line 917 invokes `--apply --json`)" |
| Lane A codex | L102 + L108 are the only L-rules wired end-to-end (META-RULE sync runs in tick at flywheel-loop-tick:912-952) |
| Lane B sub-agent | sync.sh is the only mechanism with full discoverability (`--check` exposes state) |
| Lane B codex | sync.sh + flywheel-loop-tick line 917 = the proven wired-shape for the entire ecosystem |

**Synthesis:** We don't need to invent "wired" — we have a working example. Every other artifact today should be measured against the sync.sh shape. Lane C's dogfood plan codifies this as the reference.

### F4: the gate must list-and-sort, not binary yes/no

| Source | Specific evidence |
|---|---|
| CoralRaven Item A enhancement | "mission-anchor-dispatch-license.sh should emit FULL list of licensed-but-undispatched tasks per session sorted by PageRank, not just answer 'is THIS task licensed'" |
| CoralRaven refilled-one-not-all | dispatched ONE thing, left 2 idle; gap is at dispatch-decide-time scope |
| Lane C sub-agent | doctor fields include `wire_or_explain_top_unwired_class`, not just count |
| Lane C codex | 12 doctor fields include `unwired_artifact_top_5_oldest` and `unwired_artifact_top_5_highest_downstream_cost` |

**Synthesis:** Output must be ranked list at every check. Add `wire-priority-ranker` primitive to bead DAG.

### F5: "shadow → warn → enforce" 3-stage rollout

| Source | Specific evidence |
|---|---|
| Lane B sub-agent | "3-stage `gate_mode={shadow,warn,enforce}` keyed in loop.json with auto-promote thresholds" |
| Lane C sub-agent | 7-day shadow-mode default; flip criteria = 5-criterion check including monotonic decreasing unwired_24h + Joshua sign-off; auto-rollback on >3 tick-fails/24h |
| Lane C codex | shadow_mode_specced=yes with explicit ramp |
| External pattern survey | k8s rollout state machine = template |

**Synthesis:** All 4 design sources agree on phased rollout. No source dissents.

## Convergent findings (MEDIUM confidence — appears in 2-3 sources)

### F6: orchestrator-not-graded-like-workers (skillos finding)

skillos:1 raised it; sibling orch-monitor Lane C absorbed it into Finding 7 (passive-ledger-keeping); Lane C codex includes `orchestrator_self_grade` in 19-field receipt schema. **Not yet in Lane A/B but logically belongs.**

**Action:** Phase 2 deep dive should ratify whether the wire-or-explain ledger covers orch-grade rows directly OR a sibling ledger handles it.

### F7: doctor probe surfaces problem without remediation hint

CoralRaven beads_db_health VACUUM finding; Lane A codex anti-pattern #4 (apply-mode-without-trigger); skillos no_silent_darkness probe.

**Action:** Phase 2 deep dive should spec a doctor-probe schema enhancement: every `errors[]` row carries a `remediation_hint` field.

### F8: jeff-corpus consumer-path-mismatch (joshua-flagged)

Lane B sub-agent bypassed socraticode (queries=0); Lane C codex got 40 chunks; Lane B codex got 198,092 — proves it CAN find when prompted right. The artifact (jeff-corpus 177-repo mirror) IS shipped but consumer default-paths point at `~/Developer/<name>/`.

**Action:** Phase 4 bead `socraticode-jeff-corpus-search-path-wiring` (already in DAG candidates).

## Disagreements (require Phase 2 resolution)

### D1: bead DAG count — 12 vs 15

Lane C sub-agent: 15 beads. Lane C codex: 12 beads.

**Resolution needed:** which 3 sub-agent beads does codex consider out-of-scope? Phase 2 should reconcile.

### D2: today-wired count — 0 vs 1 vs 2

Lane A sub-agent (loose): 0 wired, 6 partial, 8 unwired.
Lane A sub-agent (2nd pass): 1 fully wired (sync.sh).
Lane A codex (strict): 2 wired (L102, L108), 12 partial, 0 unwired.

**Resolution needed:** Phase 2 spec must define the precise "wired" criterion the gate uses. Lane C codex/sub-agent agree on schema fields but the threshold is not yet pinned.

### D3: failure-mode count — 5 vs 7

Lane C sub-agent: 7 modes (incl. bootstrap recursion + cross-repo ships). Lane C codex: 5 modes.

**Resolution needed:** Phase 2 should ratify the full failure-mode set; bootstrap recursion is the load-bearing one (gate must be able to ship ITSELF without orphaning).

## Cross-orch fleet pattern (this is the system Joshua is building)

5 same-day same-axis convergence events:

1. CoralRaven (alps:1) vercel deep-dive (refuse vs permit asymmetry)
2. CoralRaven supplemental (5 attractors + 6 routing items A-F)
3. CoralRaven Item A (refilled-one-not-all → list-and-sort gate output)
4. flywheel:1 (RubyCastle, me) Finding 7 passive-ledger-keeping admission
5. skillos:1 orchestrator-not-graded-like-workers (19-field receipt schema)
6. CoralRaven supabase wrong-target (canonical_url shape-passes-fails-at-deploy — same gate-truth shape)

**Plus**: Vercel actually shipped under `mission_license=P3-frontend-deploy-vercel` on alps:4 — first dispatch-log row of the corrected pattern, executing in real-time during this audit.

This is the desired-state fleet behavior: peer-orchs detect failures, broadcast structural findings, the meta-orch absorbs into the active plan. The auto-act loop is partially manifested at the human-coordinated layer; the wire-or-explain gate substrates it for the machine-coordinated layer.

## Phase 2 deep dive scope (next step)

Per `/jeff-convergence-audit` Phase 2 protocol, deep dives target the high-finding nodes. Proposed lanes:

- **Deep-dive 1: gate-truth precise definition.** Resolve D2 today-wired-count disagreement. Specify the EXACT detection algorithm + threshold. Output: deterministic classifier function + test fixtures with known-wired/unwired/deferred examples.
- **Deep-dive 2: bootstrap recursion + override.** Resolve F8 (gate must wire itself without orphaning) + override mechanism. Output: bootstrap-row spec + override-flag audit trail spec.
- **Deep-dive 3: shadow → enforce promotion criteria.** Resolve F5 ramp specifics. 5-criterion check, auto-rollback, Joshua sign-off contract. Output: state-machine diagram + rollback runbook.
- **Deep-dive 4: cross-orch ledger scope.** Resolve F6 orch-grade ledger scope. Single fleet ledger vs per-orch ledgers + aggregation. Output: ledger-topology decision + cross-session join key.
- **Deep-dive 5: dispatch-lifecycle integration with skillos 19-field receipt.** Reconcile F6 finding with Lane C ledger schema. Output: extended ledger schema with `dispatch_id`, `worker_pane`, `idle_after_callback_seconds`, `next_dispatch_decision`, `orchestrator_self_grade`.

After deep dives, Phase 3 = full UBS spec, Phase 4 = cross-cutting verification, Phase 5 = convergence confirmation.

## Joshua decision points (Phase 1 → Phase 2 transition)

**Joshua-disposes pause point per `/flywheel:plan` skill contract:**

1. Approve Phase 2 scope (5 deep-dive lanes above)?
2. Confirm the 3 disagreements (D1-D3) are appropriately scoped to deep-dive lanes vs Phase 4 bead-decompose?
3. Approve absorbing the 3 substrate findings (F6, F7, F8) into wire-or-explain plan vs spawning sibling plans?
4. Confirm dispatch mode for Phase 2: codex workers + sub-agents in parallel (proven model) OR fewer-deeper lanes?

This synthesis is READY. No source edits made. No bead-decompose performed. All artifacts read-only research outputs in `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/`.

## Files this synthesis cites

- `01-RESEARCH-A.md` (sub-agent, 955 lines)
- `01-RESEARCH-A-codex.md` (codex pane 2, 26K)
- `01-RESEARCH-B.md` (sub-agent, 310 lines)
- `01-RESEARCH-B-codex.md` (codex pane 3)
- `01-RESEARCH-C.md` (sub-agent, 530 lines)
- `01-RESEARCH-C-codex.md` (codex pane 4)
- `00-INTENT.md` (this plan)
- `../orch-monitor-recovery-auto-act-2026-05-04/01-RESEARCH-{A,B,C}.md` (sibling plan)
- `/Users/josh/Developer/alpsinsurance/.flywheel/reports/2026-05-04-vercel-blocker-deep-dive.md`
- `/Users/josh/Developer/alpsinsurance/.flywheel/reports/2026-05-04-meta-failure-why-orchestrator-cannot-decide.md`
- `~/.local/state/flywheel/cross-orch-coordination.jsonl` (skillos:1 + alps:1 supplementals)
