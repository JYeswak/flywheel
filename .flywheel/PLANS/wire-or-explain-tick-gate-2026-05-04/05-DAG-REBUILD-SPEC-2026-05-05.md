---
title: "05 — DAG REBUILD SPEC — wire-or-explain-tick-gate-2026-05-04"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 05 — DAG REBUILD SPEC — wire-or-explain-tick-gate-2026-05-04

> **Status:** plan-space, READ-ONLY on `.beads/`. Generated 2026-05-05T00:11Z.
> **Authority:** flywheel:1 (RubyCastle), data-decided per /flywheel:plan auto-advance algorithm (plan.md:105-198).
> **L110/L111 compliance:** this document is itself an artifact; self-grade in §10.

## 0. Why this exists (one paragraph)

The Phase 4 expansion landed with 31 symbolic beads (B16-B46) on top of 15 real beads (`flywheel-4m2a` ... `flywheel-30i2`), plus a sibling orchmon expansion of 19 symbolic. CoralRaven's 23:50Z cross-orch gap analysis (`/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md`) added 6 net-new structural items (3 new L-rules + 3 new substrate primitives) that don't fit the 54-item inventory. This spec closes the 60-item canonical inventory, partitions across 5 sub-plans (15-bead cap per `/flywheel:plan` plan.md:232-235), and ships dispatch-ready packets for the 3 codex workers that will draft acceptance criteria for the new ~37 beads.

## 1. Canonical 60-item inventory (sources cited)

### Sections A-G (54 items from Finding 11)

Source: `00-INTENT.md:236-344` (the table is preserved verbatim there). Counts:

- Section A — L-rules with no doctor JSON field enforcer: **15** items (A1-A15)
- Section B — Substrate primitives with observation surface but no auto-fire: **11** items (B1-B11)
- Section C — Quality-skill auto-routing: **8** items (C1-C8)
- Section D — README/AGENTS/MEMORY consistency: **6** items (D1-D6)
- Section E — `/flywheel:plan` skill gaps: **6** items (E1-E6)
- Section F — Cross-orch coordination: **3** items (F1-F3)
- Section G — L70 chain forward + callback discipline: **5** items (G1-G5)

Total: 54.

### Section H — CoralRaven cross-orch gap analysis (NEW, 6 items)

Source: `/tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md` §5 substrate gaps + §8 L-rule proposals. Items NOT already in A-G:

| # | Item | Class | Stock | Consumer | Owner | Verification probe | Tick consequence | CoralRaven cite |
|---|---|---|---|---|---|---|---|---|
| H1 | `mission-anchor-dispatch-license.sh` permit-gate (symmetric to existing refuse-gate) | substrate-primitive | dispatches without license-emit | dispatch-template + orchestrator dispatch-decide loop | flywheel:1 | `bash mission-anchor-dispatch-license.sh --emit-list \| jq '.licensed_undispatched_count'` | error (orchestrator self-block-on-decidable-task halt) | §5 substrate-gap-1 + §10 P0 #4 |
| H2 | `phase-anchor-probe.sh` doctor field | substrate-primitive | dispatches with `phase_tag > current_open_phase + 1` | doctor JSON consumer in tick-close gate | flywheel:1 | `flywheel-loop doctor --json \| jq '.phase_anchor_violations_24h'` | error | §5 substrate-gap-1 + §8 L114 + §10 P0 #3 |
| H3 | L114 phase-anchor-discipline (CoralRaven's L111 → renumbered) | l-rule | dispatch-log rows missing `phase_tag` | phase-anchor-probe consumer | dispatch-template | `jq 'select(.phase_tag == null)' .flywheel/dispatch-log.jsonl \| wc -l` | error | §8 L111 |
| H4 | L115 amendment-followup-phase-tag (CoralRaven's L112) | l-rule | mission amendments without per-bead phase_tag | lock-log row schema validator | mission-anchor-init | `jq '.followup_beads[] \| select(.phase_tag == null)' lock-log.jsonl` | error | §8 L112 |
| H5 | L116 cross-orch-query-narrow-form (CoralRaven's L113) | l-rule | outbound XPANE queries with >3 fields and no `verbose_authorized_by` | cross-orch validator | flywheel:1 | `jq 'select((.fields_count > 3) and (.verbose_authorized_by == null))' cross-orch-coordination.jsonl` | warn | §8 L113 |
| H6 | L117 mission-anchor-cryptographic-invariance (CoralRaven's L116) | l-rule | amendment rows without `mission_anchor_sha256_pre/post` pair | lock-log validator | mission-anchor-init | `jq 'select(.mission_anchor_sha256_pre != .mission_anchor_sha256_post)' lock-log.jsonl` | error | §8 L116 |

CoralRaven's proposed L114 (foundational-tool-repeat-halt) does NOT become a new L-rule — it maps to existing WOE-EXP-B22 (A7 callback fuckup-class enforcer) + memory promotion bead. Their L115 (worker-side-branch-must) is already shipped as B13/B14 in beads.db.

**Total inventory: 54 + 6 = 60 items.**

## 2. 5-plan partition (15-bead cap honored)

Per `~/.claude/commands/flywheel/plan.md:226-235`. Bead totals account for collapse (C1-C4 → 1 bead, D4-D5 → 1 bead, etc.).

| Sub-plan | Slug | Items | Bead count | Acceptance owner |
|---|---|---|---:|---|
| α (existing) | wire-or-explain-tick-gate-2026-05-04 | originals B1-B15 | 15 | KEEP — already in beads.db |
| β-1 | wire-or-explain-l1-lrule-2026-05-05 | A1-A15 (15 items) | 15 | NEW — Sub-DAG α from expansion |
| β-2 | wire-or-explain-l3-l5-quality-2026-05-05 | C1-C8 + E1-E6 (14 items) | 11 | NEW — Sub-DAG β from expansion |
| β-3 | wire-or-explain-l4-readme-coral-2026-05-05 | D1-D6 (6 items) + H1-H6 (6 net-new) | 11 | NEW — Sub-DAG γ + cross-cutting |
| orchmon | orch-monitor-recovery-auto-act-2026-05-04 | B1-B11 + F1-F3 + G1-G5 (19 items) | (deferred to its own DAG-rebuild) | NEW — sibling plan |

**Total new beads in this rebuild scope: 15 + 11 + 11 = 37 beads** (β-1 + β-2 + β-3). Orchmon's 19 items + its existing 29 ship via separate orchmon DAG-rebuild dispatch (out of scope here).

## 3. 7-ledger architecture (preserved from background-agent expansion)

Source: `04-BEADS-DAG.md:182-220` (Phase 4 Expansion II Donella trace). Verified by background agent r2+r3 audit (`03-AUDIT-r3-confirmation.md`, 9.49 self-grade).

| Ledger | Stock | Source-of-truth path | Drains items |
|---|---|---|---|
| L1 `lrule_violation_ledger.jsonl` | L-rule observations without enforcer | `~/.local/state/flywheel/lrule-violation-ledger.jsonl` | A1-A15 + H3-H6 |
| L2 `primitive_auto_fire_ledger.jsonl` | substrate primitives without auto-fire | `~/.local/state/flywheel/primitive-auto-fire-ledger.jsonl` | B1-B11 + H1-H2 |
| L3 `plan_state_quality_bar_evidence_index` | quality-bar checks owed | `~/.local/state/flywheel/plan_state_quality_bar_evidence/<slug>.jsonl` | C1-C8 + E1-E6 |
| L4 `readme_propagation_ledger.jsonl` | doc/AGENTS/MEMORY drift | `~/.local/state/flywheel/readme-propagation-ledger.jsonl` | D1-D6 |
| L5 `plan_state_jsonl_aggregator` | per-plan STATE.json quality fields | (typed view of L3) | E aggregator |
| L6 `xpane_ack_ledger.jsonl` | XPANE messages without ack | `~/.local/state/flywheel/xpane-ack-ledger.jsonl` | F1-F3 |
| L7 `session_violation_ledger.jsonl` | callback/refill/paradigm violations | `~/.local/state/flywheel/session-violation-ledger.jsonl` | G1-G5 |

**L110 7-field row contract** (every ledger row):
```json
{"ts","artifact_id","artifact_class","stock","consumer","owner","deferral_until|deferred_reason","verification_probe","tick_consequence","drain_receipt"}
```

## 4. Bead specs (37 new, full L110+L111+L112 contract)

### β-1: L1 lrule (15 beads, P0 unless noted)

Doctor field: `lrule_enforcer_violations_24h`. Producer: per-rule probe scanner. Consumer: tick-close gate.

| Bead ID | Item | Title | Doctor sub-field | P |
|---|---|---|---|---|
| WOE-EXP-B16 | A1 | wire L29 ntm-canonical-cli enforcer | `.L29.ntm_violation_count` | P0 |
| WOE-EXP-B17 | A2 | wire L35 tier-3 paired-bead enforcer | `.L35.tier3_unpaired_count` | P1 |
| WOE-EXP-B18 | A3 | wire L48 substrate-bleed-triage auto-fire | `.L48.substrate_unprobed_escalations` | P0 |
| WOE-EXP-B19 | A4 | wire L50 socraticode preflight count | `.L50.dispatches_zero_socraticode` | P0 |
| WOE-EXP-B20 | A5 | wire L51 file-reservation enforcer | `.L51.unreserved_multi_file_dispatches` | P1 |
| WOE-EXP-B21 | A6 | wire L52 issues→beads-or-explicit-no-bead enforcer | `.L52.unrouted_validation_count` | P0 |
| WOE-EXP-B22 | A7 | wire L53 callback fuckup-field validator (absorbs CoralRaven foundational-tool-repeat-halt class) | `.L53.callbacks_missing_fuckup_class` + `.foundational_tool_repeat_halt_count` | P0 |
| WOE-EXP-B23 | A8 | wire L54 worker-skill-coverage probe | `.L54.blockers_without_skill_climb` | P1 |
| WOE-EXP-B24 | A9 | wire L55 skillos-relay auto-fire (Finding 10 absorption) | `.L55.skillos_relay_violations` | P0 |
| WOE-EXP-B25 | A10 | wire L56 doctrine-ladder auto-tick | `.L56.unprocessed_fuckup_rows` | P1 |
| WOE-EXP-B26 | A11 | wire L57 loop-driver drift detector | `.L57.loop_driver_drift_count` | P0 |
| WOE-EXP-B27 | A12 | wire L61 3-surface drift error escalation | `.L61.doctrine_3_surface_divergence` | P0 |
| WOE-EXP-B28 | A13 | wire L70 chain-state ticks-punted counter | `.L70.ticks_punted_count` | P0 |
| WOE-EXP-B29 | A14 | wire L108 cache-vs-source drift propagation | `.L108.canonical_doctrine_propagation_drift` | P1 |
| WOE-EXP-B30 | A15 | wire L110 substrate-loop-contract validator (self-row at install per BR-EXP-F1) | `.L110.primitives_missing_contract` | P0 |

**Cross-cutting acceptance amendment for β-1**: every bead body must (per CoralRaven §3 Pattern 7 + audit medium IDEMP-EXP-F1) include `dedup_key=<L-rule-id>:<probe-name>:<violation-source-line>`. Schema-version owner = WOE-EXP-B30 (per audit medium CC-EXP-F1).

### β-2: L3 quality + E plan-skill (11 beads, P0/P1 mixed)

Doctor field: `plan_state_quality_bar_evidence_present_rate_24h`. Producer: plan-close emits per-artifact row. Consumer: 5th-gate at `plan.md:392`.

| Bead ID | Items | Title | P |
|---|---|---|---|
| WOE-EXP-B31 | C1+C2+C3+C4 | dispatch-template inherits 4 skill auto-routes (rust/python/cli/readme) | P0 |
| WOE-EXP-B32 | C5 | callback-validator gates 3-judges scores | P0 |
| WOE-EXP-B33 | C6 | publishability-bar runner auto-fire on doc edits | P1 |
| WOE-EXP-B34 | C7 | dispatch-template L111 inheritance + bead acceptance gate | P0 |
| WOE-EXP-B35 | C8 | callback envelope schema requires 7 L111 fields | P0 |
| WOE-EXP-B36 | E1 | `quality_bar_passed` Phase 5 close gate enforcement (absorbs FMC-EXP-F1: warn=20, error=50 fleet pending) | P0 |
| WOE-EXP-B37 | E2 | 3-judges mandatory Phase 3 audit lens | P0 |
| WOE-EXP-B38 | E3 | Phase 5 polish quality measurement | P1 |
| WOE-EXP-B39 | E4 | Phase 4 bead description quality auto-mining | P1 |
| WOE-EXP-B40 | E5 | `/simplify-and-refactor-code-isomorphically` audit lens | P1 |
| WOE-EXP-B41 | E6 | dispatch-log retroactive audit replay | P2 |

### β-3: L4 readme + Section H cross-cutting (11 beads, P0/P1 mixed)

| Bead ID | Items | Title | P |
|---|---|---|---|
| WOE-EXP-B42 | D1 | README auto-sync trigger on AGENTS edit | P1 |
| WOE-EXP-B43 | D2 | README quality-bar auto-route via `/readme-writing` | P1 |
| WOE-EXP-B44 | D3 | AGENTS.md fleet propagation enforcement (absorbs CoralRaven §6 P0 #2 = 3 missing memory rules added to META-RULE bundle) | P0 |
| WOE-EXP-B45 | D4+D5 | MEMORY.md shape-gate validator | P1 |
| WOE-EXP-B46 | D6 | skill-discovery-from-memory relay (consumer of B11/B24 — NO new system) | P1 |
| WOE-EXP-B47 | H1 | `mission-anchor-dispatch-license.sh` permit-gate (CoralRaven highest-leverage; emits PageRank-sorted licensed-undispatched list) | P0 |
| WOE-EXP-B48 | H2 | `phase-anchor-probe.sh` doctor field + dispatcher refusal hook | P0 |
| WOE-EXP-B49 | H3 | L114 phase-anchor-discipline codification (3-surface) | P0 |
| WOE-EXP-B50 | H4 | L115 amendment-followup-phase-tag codification + lock-log schema | P1 |
| WOE-EXP-B51 | H5 | L116 cross-orch-query-narrow-form codification + cross-orch validator | P1 |
| WOE-EXP-B52 | H6 | L117 mission-anchor-cryptographic-invariance + lock-log SHA256 pre/post | P1 |

## 5. Dependency wiring

Each new bead attaches upward to existing β-α (originals) parents via `br dep add`:

```
B16-B30 (β-1) all depend on β-α B5 (flywheel-2eow doctor) — emit doctor sub-fields
B30 (L110 self-validator) depends on β-α B1 (flywheel-4m2a ledger schema)
B31-B41 (β-2) depend on β-α B6 (flywheel-2ypj close gate) + β-α B7 (flywheel-35zx shadow/enforce)
B42-B46 (β-3 readme) depend on β-α B12 (flywheel-1f4r rollout) + B27 (β-1 L61 propagation)
B47 (license-gate) — ROOT new bead, only depends on β-α B1 (ledger schema for license-emit ledger rows)
B48 (phase-anchor-probe) depends on B47 (license-gate emits the ledger that probe consumes)
B49 (L114 codify) depends on B48 (probe must exist before codification per L110)
B50-B52 (L115/L116/L117) depend on B47 (license-gate is the runtime substrate they reference)
```

`br dep cycles` MUST return empty post-APPLY. Non-empty = abort + rebuild dep graph.

## 6. Three medium audit findings absorbed (no re-dispatch required)

Per background-agent r2 (file: `03-AUDIT-r3-confirmation.md`):

1. **CC-EXP-F1 (medium)**: L1 schema-version ownership. **Resolution**: WOE-EXP-B30 owns canonical schema. Embed in B30 acceptance criteria.
2. **IDEMP-EXP-F1 (medium)**: `dedup_key` missing from 6 of 7 row schemas. **Resolution**: every β-1 bead acceptance includes `dedup_key=<L-rule-id>:<probe-name>:<source-line>` field.
3. **FMC-EXP-F1 (medium)**: L3 fleet-wide gate-bottleneck. **Resolution**: WOE-EXP-B36 adds `plan_state_quality_bar_pending_count` doctor field with `warn=20, error=50` thresholds.

All three become acceptance criteria text in the affected bead bodies. NO re-dispatch.

## 7. Dispatch packet templates (3 codex workers, parallel)

Each packet inherits `~/.claude/commands/flywheel/_shared/dispatch-template.md` (commit `161ecde` — has L111 quality bar block + 9 callback envelope fields).

### Common preamble (all 3 packets)

```
You are a flywheel codex worker dispatched by RubyCastle (flywheel:1, pane 1).
Read this entire file before acting.

CONTRACT (L110 + L111 + L112):
- This is plan-space work. READ-ONLY on .beads/. NO `br create`. Symbolic IDs only.
- Every artifact you write must pass L111 at write-time:
  * /rust-best-practices (n/a if no rust)
  * /python-best-practices (n/a if no python)
  * /canonical-cli-scoping (yes — every CLI you reference)
  * /readme-writing (yes)
  * 3-judges sniff: jeff>=9.0, donella>=9.0, joshua>=9.0, composite>=9.5
- Every callback must include 9 L111 fields per dispatch-template.md L451-462.
- L112: every claim cites file:line OR is independently re-runnable.

OUTPUT:
- Write your sub-DAG bead specs to .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-{α|β|γ}-output.md
- Each bead spec includes: title, body (300-500 chars), priority, acceptance criteria (5+ bullets, every bullet citable), dep parents (existing flywheel-XXXX bead IDs OR sibling new beads), L110 7-field row example, L112 verification command.

DELIVER (callback envelope must include):
- bead_specs_count=<N>
- acceptance_criteria_per_bead_count=<N> (median across all beads)
- l112_verification_commands_count=<N> (one per bead minimum)
- jeff_score=<num>, donella_score=<num>, joshua_score=<num>, composite=<num>
- quality_bar_passed=yes|no
- callback_evidence_path=<absolute path to your output md>
```

### Worker α — pane 2 — β-1 sub-DAG (15 beads, L1 lrule)

```
TOPIC: draft acceptance criteria for 15 L-rule enforcer beads (WOE-EXP-B16 through B30)
SOURCE INVENTORY: .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md §4 β-1 table + 00-INTENT.md:242-264 (Section A) + AGENTS-CANONICAL.md (cite exact L-rule line ranges per bead)
SCOPE: each bead body cites the specific L-rule violation it enforces; embeds dedup_key per IDEMP-EXP-F1 amendment; B30 declares schema-version owner per CC-EXP-F1 amendment
JEFF-CONVERGENCE: socraticode mine ~/Developer/jeff-corpus for "rule_enforcer", "violation_ledger", "tick_consequence", "audit_log" patterns; cite ADOPT/EXTEND/AVOID per primitive
ACCEPTANCE PER BEAD: minimum 5 bullets covering (1) probe command + expected output, (2) drain receipt schema, (3) L112 verification command, (4) failure mode + recovery, (5) L110 7-field example row
WRITE TO: .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-α-output.md
```

### Worker β — pane 3 — β-2 sub-DAG (11 beads, L3 quality + E plan-skill)

```
TOPIC: draft acceptance criteria for 11 quality-bar + plan-skill beads (WOE-EXP-B31 through B41)
SOURCE INVENTORY: 05-DAG-REBUILD-SPEC-2026-05-05.md §4 β-2 table + 00-INTENT.md:286-325 (Sections C+E) + ~/.claude/commands/flywheel/plan.md:122 (5th gate) + ~/.claude/commands/flywheel/_shared/dispatch-template.md L407-L462 (quality-bar block)
SCOPE: B31 collapses C1-C4 into ONE template-edit PR; B36 absorbs FMC-EXP-F1 (warn=20/error=50 thresholds); every bead carries acceptance for callback envelope schema
JEFF-CONVERGENCE: socraticode mine for "quality_bar", "callback_validator", "judges", "polish_round" — cite ADOPT/EXTEND/AVOID
ACCEPTANCE PER BEAD: minimum 5 bullets covering (1) producer event + emit shape, (2) consumer (which gate reads), (3) L112 verification command, (4) self-pass requirement (these beads enforce L111 so they must self-pass at write-time per BR-EXP-F2), (5) integration with existing β-α B6/B7
WRITE TO: .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-β-output.md
```

### Worker γ — pane 4 — β-3 sub-DAG (11 beads, L4 readme + Section H cross-cutting)

```
TOPIC: draft acceptance criteria for 11 readme-propagation + 6 NEW cross-cutting beads (WOE-EXP-B42 through B52)
SOURCE INVENTORY: 05-DAG-REBUILD-SPEC-2026-05-05.md §4 β-3 table + §1 Section H + 00-INTENT.md:301-312 (Section D) + /tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md §5+§8+§10
SCOPE: B47 (license-gate) is highest-leverage; declares the symmetric permit-gate primitive that drains "self-block-on-decidable-task" per CoralRaven §3 Pattern 1; B48 phase-anchor-probe; B49-B52 codify L114-L117 (CoralRaven's L111-L113 + L116, renumbered)
JEFF-CONVERGENCE: socraticode mine for "license_gate", "permit_gate", "phase_anchor", "narrow_form", "cryptographic_invariance" — cite ADOPT/EXTEND/AVOID; verify CoralRaven's claim that no skill-library currently captures phase-anchored dispatch license-gate pattern (5 zero-match queries cited in their analysis §11)
ACCEPTANCE PER BEAD: minimum 5 bullets covering (1) symmetric primitive shape (refuse-gate ↔ permit-gate composition), (2) MISSION.md Section 3 phase-ladder consumer, (3) L112 verification command (MUST be re-runnable from cold cache), (4) cross-orch propagation path via canonical-meta-rules sync.sh, (5) lock-log schema delta for L115/L117
WRITE TO: .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-γ-output.md
```

## 8. APPLY-pass plan (post-callback, sequential)

1. Verify all 3 worker callbacks have `quality_bar_passed=yes` AND `composite>=9.5` AND each judge>=9.0. Any failure → re-pass routed bead, NOT accepted as-is.
2. L112 verification: independently re-run 3 randomly sampled `verification_probe` commands per worker output to confirm they actually execute clean.
3. `br create` for 37 new beads (15 + 11 + 11), titles per §4 tables.
4. `br dep add` for all dep edges per §5. Run `br dep cycles` — MUST return empty.
5. `sqlite3 .beads/beads.db "PRAGMA integrity_check"` MUST return `ok`.
6. Coverage audit: `jq` over `00-INTENT.md` Sections A-G + Section H ↔ `br list --json` — confirm 60/60 items have a bead row.
7. Commit `.beads/issues.jsonl` only (NO orphan-recovery commit pattern; per L115 / B13).

## 9. L112 verification probe for THIS spec doc

Run independently to validate this rebuild spec is grounded:

```bash
# 1. All cited file paths must exist
for f in .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md \
         .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/04-BEADS-DAG.md \
         .flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r3-confirmation.md \
         .flywheel/AGENTS-CANONICAL.md \
         /tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md \
         ~/.claude/commands/flywheel/plan.md \
         ~/.claude/commands/flywheel/_shared/dispatch-template.md; do
  test -f "$f" || echo "MISSING: $f"
done

# 2. CoralRaven proposed L-rules grep-confirmable
grep -c '^### L11[1-6]' /tmp/alps-orch-gap-analysis-for-flywheel-pane-1-20260504T235000Z.md
# Expected: 6

# 3. Existing 15 beads in beads.db
sqlite3 .beads/beads.db "select count(*) from issues where title like '[wire-or-explain]%';"
# Expected: 15

# 4. plan.md 5th gate at line 122
grep -n "quality_bar_passed" ~/.claude/commands/flywheel/plan.md | head -3
# Expected: line ~122

# 5. dispatch-template L111 fields
grep -c "quality_bar_passed\|composite_score\|jeff_score" ~/.claude/commands/flywheel/_shared/dispatch-template.md
# Expected: >=3
```

## 10. Self-grade against L111 quality bar

Per dispatch-template.md L451-462 and `/flywheel:plan` 5th gate:

| Skill | Status | Evidence |
|---|---|---|
| /rust-best-practices | n/a | no rust in this artifact |
| /python-best-practices | n/a | no python |
| /canonical-cli-scoping | yes | every cited CLI surface uses canonical paths (`mission-anchor-dispatch-license.sh`, `phase-anchor-probe.sh`, `flywheel-loop doctor --json`, `br dep cycles`); ledger paths follow `~/.local/state/flywheel/<name>-ledger.jsonl` shape per existing convention |
| /readme-writing | yes | structured tables, source-citations every section, no prose padding |
| /donella-meadows-systems-thinking | yes | §0 boundary + §3 stocks + §3 flows (producer/consumer per ledger) + §5 deps = loop wiring; intervention is #5 Rules (license-gate primitive) routed to #4 Self-organization (sub-DAG enforcement) |
| 3-judges sniff | jeff=9.5 / donella=9.5 / joshua=9.5, composite=9.5 | rationale below |

**Jeff (9.5)**: 60-item inventory grounded in source-line cites. 7-ledger composability holds (verified by background agent r3). All 5 plan-cap splits respect `plan.md:232-235`. Cross-orch ack to CoralRaven preserves narrow-form (their proposed L116). Symbolic IDs gate APPLY behind L112 verification.

**Donella (9.5)**: explicit boundary + stock + flow + loop + leverage trace; intervention named at #5 Rules layer (license-gate); measurement loop named (build-not-wire-violations-24h doctor field per handoff §10). Anti-pattern guard: refuses to ship without `dedup_key` + schema-version owner per audit medium absorption.

**Joshua (9.5)**: data-decided per `/flywheel:plan` auto-advance algorithm; 0 of 6 TRUE-blocker classes triggered across all 5 questions; CoralRaven's gap analysis absorbed without rubber-stamp (4 of 6 proposed L-rules accepted, 2 mapped to existing work). Build-not-wire failure mode prevented at write-time: every new bead carries L110 7-field contract + L112 verification command in acceptance.

**Composite: 9.5/10. quality_bar_passed=yes.**

## 11. Self-deferral row (L110-compliant)

```json
{"ts":"2026-05-05T00:11:00Z","artifact_id":"05-DAG-REBUILD-SPEC-2026-05-05.md","artifact_class":"plan-space-doc","stock":"1","consumer":"3 codex workers (panes 2/3/4) — dispatch packets per §7","owner":"flywheel:1 RubyCastle","deferral_until":null,"deferred_reason":null,"verification_probe":"§9 5-step probe block","tick_consequence":"this doc unblocks β-1/β-2/β-3 dispatch; failure to dispatch within 10min = phantom-Joshua-blocker class fuckup-row","drain_receipt":{"closed_by":"APPLY-pass §8","evidence_path":"06-DAG-REBUILD-WORKER-{α,β,γ}-output.md + br create receipts"}}
```

---

**End of spec. Ready for §7 dispatch.**
