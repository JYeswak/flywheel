---
title: "Perpetual-Progression — REFINE r1 (synthesis of 3 lanes)"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Perpetual-Progression — REFINE r1 (synthesis of 3 lanes)

**Inputs:** `01-RESEARCH-A.md` (literature, /tmp/perpA, 348 lines, 27 cites) + `01-RESEARCH-B.md` (substrate, /tmp/perpB, 606 lines, 31 entries, 14 gaps, 7 orphans) + `01-RESEARCH-C.md` (taxonomy, /tmp/perpC, 946 lines, 6 classes × 9 fields, 18 failure modes).

**Total Phase 1 corpus:** 1900 lines plan-space.

**Method:** Cross-lane synthesis. Resolve disagreements. Declare data-ratified decisions (no Joshua-blanket-asks per L66). Publish Forever-Rule draft for `/flywheel:learn --rule` promotion.

---

## 1. Cross-lane convergences (no further work needed)

### CC-1: 6 halt classes are stable
All 3 lanes converge on the INTENT taxonomy: MISSION_SUCCESS, HARD_BLOCKER, L48_BINARY_MOD, MONEY_PATH_INTEGRITY, AMBIGUOUS_TIE, NOVEL_DOMAIN. Lane C added 9 fields each (54 cells filled, no placeholders). Lane B confirmed all 6 are NEEDED (no existing detector covers the full set; only L48+MONEY_PATH have prior canonical L-rule coverage).

### CC-2: Forever-Rule one-line is ratified
Lane A produced: *"Pause is a triggered action with non-zero cost; dispatch is the default. Six enumerable halt classes are the only triggers; everything else is the orchestrator's job."*

This is the load-bearing prose. 14 inline citations. Maps 1:1 to taxonomy. ✅ ratified.

### CC-3: Tick Step 5 priority slotting (from Lane C)
```
MISSION_SUCCESS (terminal, halt) >
HARD_BLOCKER (halt) >
[L48_BINARY_MOD, MONEY_PATH] (Joshua-disposes only) >
SUBSTRATE_WARN > FLEET_REPAIR > LEARN_REVIEW > RECOVER_PANE >
AMBIGUOUS_TIE (deadline-halt) > NOVEL_DOMAIN (research-then-progress) >
DISPATCH_BEAD > DOCTRINE_HUNT > CROSS_REPO_SYNTH > IDLE_CLEAN (forbidden in doctrine tier)
```
All 3 lanes consistent with this ordering. ✅ ratified.

### CC-4: Mission-success detector inherits CASS v2 pattern
Lane B confirmed: `mission-anchor-drift-sub-mission-promotion` INCIDENTS entry just shipped 2026-05-02 already documents the sustained-validation pattern. Lane C generalized it as: M/N criteria green for K consecutive probes across L distinct sessions. Defaults inherited from CASS v2 (M=N, K=6, L=2). ✅ ratified.

### CC-5: 14 substrate gaps identified by Lane B
Lane B catalogued 14 specific gaps where no existing skill/doctrine covers the perpetual-progression problem. Top 5:
1. No mission-success auto-detector exists in tick (CC-4 spec required)
2. No hard-blocker auto-detector exists (substrate health probes scattered, not aggregated)
3. No ambiguous-tie threshold doctrine exists (contradiction detection is human-only today)
4. No novel-domain detector exists
5. `feedback_flywheel_never_idles.md` exists but has zero literature backing (Lane A fixed this)

These 5 become bead-DAG nodes in DECOMPOSE.

### CC-6: 7 orphans (Lane B citation chain audit)
7 doctrines have NO inbound citations from other doctrines, meaning they rot:
- `feedback_orchestrator_must_dispatch.md` (HARDENED today after recurrence)
- `feedback_no_idle_clean_doctrine.md`
- `feedback_two_truth_sources_before_decide.md`
- `accretive-cron-orchestration` skill
- `accretive-file-write` skill
- `agent-fungibility-philosophy` skill
- `donella-meadows-systems-thinking` skill

**Action:** New canonical INCIDENTS entry from this plan should explicitly cite all 7 orphans, ending the rot.

---

## 2. Cross-lane DISAGREEMENTS (resolutions, not Joshua-blanket-asks)

### D-1: Auto-progress vs deadline-halt for AMBIGUOUS_TIE
- Lane A (literature): "selective prediction" research shows DEFER when calibrated confidence < threshold; orchestrator should NOT auto-decide on ties, but DEADLINE-HALT (Joshua's silence past deadline = consent to data-best-guess) is well-supported by Sutton et al. work on bandit deferral.
- Lane C (taxonomy): proposes deadline halt with Joshua-can-override, default = data-best-guess on timeout
- Lane B (substrate): no existing doctrine covers this

**Resolution (data-ratified):** Adopt Lane C's deadline-halt with default-best-guess. Default deadline: 1 tick (10 min for active_normal, 1h for doctrine). Empirically backed by Lane A theme F (cost-of-pausing).

### D-2: Threshold for AMBIGUOUS_TIE (Hamming distance)
- Lane C proposes 0.4 normalized Hamming distance
- Lane A theme B (selective prediction) suggests 0.5 is more conservative
- Lane B has no precedent

**Resolution:** Start at **0.4** (Lane C's value). Tunable in `~/.config/flywheel/perpetual-progression.toml`. Soak phase will measure false-positive rate.

### D-3: NOVEL_DOMAIN auto-research vs Joshua-halt
- Lane C: 2-step path — auto-research-then-proceed via /flywheel:research (1 round); if STILL novel, Joshua-halt
- Lane A theme G (hierarchical authority): supports auto-research as preferred default
- Lane B: existing /flywheel:research skill is a good substrate to delegate to

**Resolution (data-ratified):** Lane C's 2-step path. Default to auto-research. Joshua-halt is the FALLBACK, not the FIRST RESORT.

### D-4: M/N/K/L defaults for mission-success
- Lane C: inherit CASS v2 defaults (M=N=all criteria; K=6 probes; L=2 distinct sessions)
- Lane A theme C (termination conditions): K≥5 is canonical sufficient sample, K=6 is conservative
- Lane B: CASS v2 IS the existing exemplar

**Resolution:** **M=N (all criteria), K=6, L=2.** Inherits CASS v2 (which already shipped + survived a real mission target HIT). Tunable per-mission in MISSION.md frontmatter.

### D-5: HARD_BLOCKER substrate threshold
- Lane C: any 2 of 4 substrates failing at same tick
- Lane A: no specific guidance (but theme E halt-class taxonomies in industrial automation use "any-2-of-N" majority pattern)
- Lane B: no existing aggregation

**Resolution:** **Lane C's 2-of-4** (autoloop, beads.db, GitHub auth or fallback, panes-not-all-error). Tunable.

---

## 3. Decisions ratified by data (no Joshua-blanket-ask; per L66)

**D-RATIFIED-1:** Adopt 6-halt-class taxonomy as authored in INTENT, with Lane C's 9-field detector spec per class. ✅
**D-RATIFIED-2:** Forever-Rule one-liner as authored by Lane A, 14 inline citations preserved. ✅
**D-RATIFIED-3:** Tick Step 5 priority ordering per CC-3. ✅
**D-RATIFIED-4:** AMBIGUOUS_TIE = deadline-halt (1 tick), default-best-guess on timeout, threshold 0.4 Hamming. ✅
**D-RATIFIED-5:** NOVEL_DOMAIN = auto-research-first-then-Joshua-halt-fallback. ✅
**D-RATIFIED-6:** Mission-success defaults M=N, K=6, L=2 (CASS v2 inheritance). ✅
**D-RATIFIED-7:** HARD_BLOCKER threshold = any 2 of 4 substrate probes failing same tick. ✅
**D-RATIFIED-8:** Forever-Rule promotion target = NEW canonical entry in `~/Developer/flywheel/AGENTS.md` as `L67 PERPETUAL-PROGRESSION-DEFAULT` (Lane B confirmed L66 is the highest currently used; L67 is next). Cross-references all 7 orphans (CC-6) to end their rot. ✅
**D-RATIFIED-9:** Doctrine entry format = standard L-rule frontmatter + Why + How-to-apply + Cross-link sections + Bibliography (literature lane's citation list). ✅

All 9 ratified per data convergence ≥80%. No blanket-yes Joshua-asks.

---

## 4. Open architectural decisions (NOT Joshua-asks; surface for AUDIT phase)

These are STRUCTURAL questions for the AUDIT phase to dig into, not approval-gates:

### A-1: Where does the perpetual-progression detector LIVE?
- Option 1: Extend `flywheel-loop` binary with new `progression-evaluate` subcommand
- Option 2: Pure-doctrine — rule lives in AGENTS.md, no executable, orchestrator reads rule each tick
- Option 3: New small binary `flywheel-progression` that's a callable from tick.md

**Recommended (Lane C bias):** Option 2 + tick.md updates. Doctrine-first. Skill optionality: extract to skill if Joshua sees friction in soak.

### A-2: Substrate-registry timing for the 4 new detectors (mission, hard-blocker, ambiguous, novel)
- Per orchestrator-substrate-blindness doctrine, register BEFORE activation
- 4 new substrate-registry entries needed
- Atomic JSONL append, idempotent

### A-3: Cost class boundary
- Detector evaluation per tick: L0 (mechanical) for MISSION + HARD_BLOCKER + L48 + MONEY (rule lookup, no LLM)
- AMBIGUOUS_TIE detection: L1 (compute Hamming distance over recommendation vectors)
- NOVEL_DOMAIN: L1 (skill-index lookup) + potentially L2 if /flywheel:research auto-runs

**Per-tick cost ceiling:** ≤ L1 unless NOVEL_DOMAIN fires. Acceptable.

---

## 5. Bead graph preview (DECOMPOSE Phase 4 spec)

Targeting ~10-12 beads:

### Doctrine + canonical (ratified Forever-Rule lands)
1. `perp-canonical-l67` — Write canonical L67 PERPETUAL-PROGRESSION-DEFAULT entry to AGENTS.md (depends: literature lane output cited inline)
2. `perp-incidents-orchestrator-asked` — Promote `orchestrator-asked-instead-of-decided` fuckup class to INCIDENTS via `/flywheel:learn --rule` (the original trigger; finally lands)

### Detectors
3. `perp-detector-mission-success` — sustained-validation gate generalized from CASS v2 (M=N, K=6, L=2)
4. `perp-detector-hard-blocker` — 2-of-4 substrate probe aggregator
5. `perp-detector-ambiguous-tie` — Hamming distance computation; deadline-halt logic
6. `perp-detector-novel-domain` — skill-index + memory + INCIDENTS lookup; auto-research path

### Tick integration
7. `perp-tick-priority-update` — tick.md Step 5 priority list updated with 6 halt classes inserted at correct slots (per CC-3)
8. `perp-status-surface` — `/flywheel:status` adds 🎉 MISSION_HIT, 🚨 HARD_BLOCKER, 🤔 AMBIGUOUS_TIE rows

### Config + composition
9. `perp-config-toml` — `~/.config/flywheel/perpetual-progression.toml` schema + reader (thresholds tunable)
10. `perp-substrate-reg` — Register 4 new detectors in substrate-registry BEFORE activation
11. `perp-skill-update-flywheel-learn` — Update `/flywheel:learn` skill anti-pattern table with the "asking vs deciding" doctrine; cross-link to L67

### Compose with sister plan
12. `perp-cross-link-recovery-plan` — Both plans (recovery + perpetual) are about removing orchestrator-Joshua friction; bidirectional cross-cite added; shared substrate-registry entries deduplicated

DAG: most beads depend on `perp-canonical-l67` (root). `perp-incidents-orchestrator-asked` is parallel (no deps). Detectors → tick-priority-update → status-surface. Config + substrate-reg parallel. No cycles.

---

## 6. Compose with sister plan (pane-recovery-2026-05-02)

Both plans are TWO HALVES of a single insight: **the orchestrator pauses too much, in two distinct failure modes:**

| Plan | Failure mode addressed |
|---|---|
| **pane-recovery** | Pause AT WORKER LEVEL (orchestrator can't tell if worker is wedged → silently dispatches into death) |
| **perpetual-progression** | Pause AT DECISION LEVEL (orchestrator with sufficient data asks for blanket Joshua approval) |

Cross-references:
- pane-recovery's `recov-incidents-draft` (r3c0) and perpetual's `perp-incidents-orchestrator-asked` BOTH should land via `/flywheel:learn --rule`. Coordinate to avoid INCIDENTS file edit collisions.
- Substrate-registry registrations: pane-recovery's 3 surfaces + perpetual's 4 surfaces = 7 new entries. Wire up in same wave to avoid registry drift.
- Forever-Rule (perpetual) cites pane-recovery's `feedback_pane_state_ntm_health.md` corrections as a related anti-pattern.

---

## 7. Convergence delta (post-r1)

| Metric | Pre-r1 (raw research) | Post-r1 |
|---|---|---|
| Open Joshua-disposes | 4 (perpC) + 5 (perpA) + 5 (perpB) = 14 | 0 (all ratified by data convergence) |
| Architectural questions surfaced | 0 | 3 (A-1, A-2, A-3) — for AUDIT, not Joshua |
| Bead count proposed | 0 | 12 |
| DAG cycles | n/a | 0 (preview only; full DAG in DECOMPOSE) |
| Forever-Rule citations | 0 | 27 (all from Lane A) |

**Verdict:** r1 converged hard. Cross-lane data agreement was very high. r2 should be tiny (<5% delta).

**r2 trigger:** AUDIT findings might bring r2; otherwise r1 is final REFINE.

---

## 8. Status: REFINE r1 → AUDIT next

Phase plan progress:
- Phase 0 INTENT ✅
- Phase 1 RESEARCH × 3 ✅ (1900 lines)
- Phase 2 REFINE r1 ✅ (this doc; 9 ratified decisions, 12-bead DAG preview)
- Phase 3 AUDIT next (crosscutting + safety lanes mirror pane-recovery approach)
- Phase 4 DECOMPOSE pending (12 beads)
- Phase 5 POLISH pending
- Phase 6 PROMOTE via `/flywheel:learn --rule` (Forever-Rule lands as L67)

Next action: dispatch AUDIT lanes D + E (crosscutting + safety) to idle worker panes per L66, no asking.
