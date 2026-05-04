# Perpetual Progression Doctrine — Intent

**Plan ID:** perpetual-progression-2026-05-02
**Started:** 2026-05-02T03:05Z
**Owner:** flywheel orchestrator
**Trigger:** Joshua's directive: "an accretive way to keep our projects moving — only truly stopping once mission is an absolute success or there is a major blocker." Backed by arxiv research.
**Companion fuckup class:** `orchestrator-asked-instead-of-decided` (logged 2026-05-02 ~03:00Z; NOT yet promoted to INCIDENTS — promotion deferred until this plan converges so the Forever-Rule has literature backing per Joshua's "arxiv research" directive)

## One-line goal

A doctrine + substrate + skill combination that makes flywheel projects **monotonically progress** toward declared mission targets, halting if-and-only-if (a) mission is provably HIT or (b) a hard blocker is detected, with literature-grounded thresholds for each halt class.

## Why this matters (the trauma being prevented)

Today's session produced 2 instances of a single trauma class:
1. Pre-CASS-V2: orchestrator paused after fleet-idle research, asking Joshua what to do — Joshua said "i'm the meat puppet you are the orchestrator"
2. Mid-pane-recovery REFINE: orchestrator surfaced 5 "Joshua-disposes" with all-recommended-yes from data convergence; Joshua said "data not meat puppet"

Both are **the same failure shape**: orchestrator with sufficient data to decide, paused for human approval anyway. This is a structural defect in how the flywheel handles non-trivial decision points. We have:
- **L66** USE-DATA-NOT-MEAT-PUPPET (canonical rule, exists)
- **`feedback_orchestrator_must_dispatch.md`** (memory, exists, hardened twice today)
- **`/flywheel:learn`** (skill, exists, didn't fire)

…and yet the trauma recurred mid-same-session. That means rules + memory + skills **alone** are insufficient. We need a structural shift: progression-by-default with explicit halt classes.

## Mission of this plan

Produce a doctrine + skill + integration changes that make the flywheel system **default-progress, default-not-halt**, with these properties:

1. **Halt classes are enumerable + finite** — the system knows exactly when to stop, not "when uncertain."
2. **Decision-point handling is data-driven** — when N research lanes converge with all-recommended-yes, that's a ratification, not a question.
3. **Mission completion is detectable** — an automated test can answer "are we done?" not just human gut-check.
4. **Major blockers are detectable** — distinct from "this is hard" or "Joshua might prefer different."
5. **The doctrine has literature backing** — autonomy theory, agentic AI, dual-process decision theory. Forever-Rules need external grounding to outlive their authors (per `/flywheel:learn` skill's own anti-pattern note).

## Halt classes (taxonomy v0, to refine)

| Class | Detection signal | Action | Authority |
|---|---|---|---|
| **MISSION_SUCCESS** | All declared mission criteria pass + sustained-validation gate green for N consecutive probes | Halt with celebration; archive plan; surface to Joshua for new mission anchor | data-driven |
| **HARD_BLOCKER** | Substrate down (autoloop dead, all worker panes ERROR, beads.db corrupt, GitHub auth broken with no fallback) | Halt with diagnostic dump; refuse new dispatch; surface to Joshua | data-driven |
| **L48_BINARY_MOD** | Action requires mutating: source code outside .flywheel/, plists, system services, paid-API config, irreversible git ops | Halt for Joshua sign-off only | doctrine (canonical) |
| **MONEY_PATH_INTEGRITY** | Action touches billing, payments, customer data | Halt for Joshua sign-off | doctrine (canonical) |
| **AMBIGUOUS_TIE** | Research/data lanes return contradictory verdicts (>40% disagreement after 2 refine rounds) | Halt for Joshua tie-break | data-driven, needs threshold |
| **NOVEL_DOMAIN** | Action enters domain with no prior INCIDENTS or memory entries AND no existing skill | Halt for Joshua scope check OR auto-research-then-proceed | data-driven, needs threshold |

Anything NOT in this list is **DEFAULT_PROGRESS** — orchestrator decides + dispatches, no asking.

## What "asking" looks like vs what "deciding" looks like

| ❌ Anti-pattern (asking) | ✅ Doctrine (deciding) |
|---|---|
| "Want me to do A or B?" | "Doing A because data says X. If wrong, red-pen and I'll switch to B." |
| "Should I dispatch this bead?" | "Dispatching to pane 3, callback by ETA." |
| "Joshua-disposes: approve all 5?" | "5 decisions ratified by data convergence; proceeding. Red-pen any retroactively." |
| "Ready when you are" | "Phase X complete; phase Y starting" + dispatch |
| "Awaiting your call" | "Data converges to call C; executing call C" |

Allowed pauses: 6 halt classes above. Everything else: keep moving.

## User workflows

### W1 — Mission target reached
- **Persona:** orchestrator at end of long campaign
- **Trigger:** All MISSION criteria pass + sustained-validation gate green for N=5 probes across distinct repos/sessions
- **Steps:**
  1. Auto-detector emits `MISSION_SUCCESS` decision in tick
  2. /flywheel:status surfaces 🎉 MISSION_HIT row
  3. Plan workspace archived to `.flywheel/missions/` with success receipt
  4. Joshua surfaced ONCE: "ready for next mission anchor?"
  5. Until Joshua sets new mission: orchestrator runs DOCTRINE_HUNT (existing) but doesn't dispatch new mission-scope work
- **Outcome:** Halt is celebratory, not deflating. Mission outcome captured durably.

### W2 — Hard blocker hit
- **Persona:** orchestrator mid-progression
- **Trigger:** All 4 worker panes ERROR, OR autoloop dead, OR beads.db corrupt
- **Steps:**
  1. Detector classifies HARD_BLOCKER + names which substrate is down
  2. Tick refuses new dispatches; preserves all in-flight state
  3. /flywheel:status surfaces 🚨 HARD_BLOCKER with substrate identity + recommended fix
  4. Joshua disposes: hand-fix or approve auto-recovery
- **Outcome:** Halt is precise; Joshua knows EXACTLY what's broken.

### W3 — Default progression (the 99% case)
- **Persona:** orchestrator at any tick
- **Trigger:** Idle workers + ready beads + no halt class triggered
- **Steps:**
  1. Tick reads pane state (`ntm activity` per recent doctrine)
  2. Selects highest-PageRank ready bead
  3. Dispatches without asking
  4. Logs decision to dispatch-log; logs reasoning to tick receipt
  5. Continues to next tick
- **Outcome:** Joshua sees movement, not pauses. Mission progresses tick-by-tick.

### W4 — Ambiguous-tie escalation
- **Persona:** orchestrator after 2 refine rounds
- **Trigger:** Research lanes return >40% contradictory verdicts on same decision
- **Steps:**
  1. Detector classifies AMBIGUOUS_TIE
  2. Orchestrator drafts 2-option summary (each option with cost-of-wrong)
  3. Surfaces to Joshua with deadline ("if no answer by next tick, picks option A on data-best-guess")
  4. If Joshua answers: proceeds with chosen option
  5. If Joshua silent past deadline: proceeds with option A, logs `auto_tiebreak` decision
- **Outcome:** Even genuine ties don't halt forever. Joshua's silence = consent to default.

## Non-goals (explicitly out of scope)

- Removing Joshua from doctrine sign-off (L48 binary mods stay Joshua's domain)
- Removing Joshua from money-path approvals (compliance + cost reasons)
- Replacing `/flywheel:learn` (this builds ON it, doesn't replace)
- Building a new orchestrator binary — this is doctrine + skill update + integration
- Replicating arxiv research IN-detail; we cite papers, we don't reproduce them

## Constraints

- **Backward compatible:** existing flywheel projects keep working; they opt INTO perpetual-progression mode via config
- **Cost class L0-L1:** detection is shell + ntm + beads queries (L0); halt-class determination has tiny LLM step (L1)
- **Literature-grounded:** at least 5 arxiv/peer-reviewed citations for the Forever-Rule, mapped to specific decisions
- **Substrate-registry registered:** new perpetual-progression detector registers BEFORE activation per orchestrator-substrate-blindness doctrine
- **Composes with /flywheel:learn:** the trauma class `orchestrator-asked-instead-of-decided` becomes the zeroth example INCIDENTS entry promoted via /flywheel:learn after this plan converges

## Success criteria (measurable)

| # | Criterion | Measurement |
|---|---|---|
| 1 | All 6 halt classes have detector specs + thresholds | Spec doc shows: detection rule, threshold value, action on trigger, escalation path |
| 2 | At least 5 arxiv citations grounding the doctrine | Each Forever-Rule clause links to ≥1 paper |
| 3 | DEFAULT_PROGRESS replaces DEFAULT_PAUSE in tick decision matrix | Tick Step 5 priority list updated; existing decisions reclassified |
| 4 | `/flywheel:learn` skill updated with halt-class taxonomy | Skill markdown amends "asking vs deciding" anti-pattern table |
| 5 | Companion bead graph filed (mirrors pane-recovery DAG approach) | ≥10 beads, no cycles, dep edges to terc/7xxs/etc as appropriate |
| 6 | INCIDENTS.md `orchestrator-asked-instead-of-decided` Forever-Rule promoted | Entry written via /flywheel:learn --rule with ≥1 cost citation + 5 arxiv citations |
| 7 | Mission-success detector spec written | Sustained-validation pattern from CASS v2 generalized; works for any /flywheel:plan-style mission |

## Anchored references (existing substrate to build on)

- **CASS v2 mission target HIT** — exemplar of mission-success detector with sustained-validation gate (memory: `project_cass_v2_mission_target_hit_2026_05_02.md`)
- **`accretive-cron-orchestration` skill** — existing accretive doctrine, may be the canonical home for new rule
- **`accretive-file-write` skill** — companion accretive pattern
- **`feedback_flywheel_never_idles.md`** — operational form of the rule, needs literature grounding
- **`feedback_orchestrator_must_dispatch.md`** — current rule statement, hardened twice today
- **L66 USE-DATA-NOT-MEAT-PUPPET** — canonical rule, doctrine layer
- **`mission-anchor-drift-sub-mission-promotion`** — INCIDENTS entry just shipped (CASS v2), prevents mission scope creep
- **Pane-recovery DAG** — sister plan converging in parallel; both about removing orchestrator-Joshua friction
- **`stop-slop` skill** — similar trauma class (orchestrator does too much vs too little)

## Phase plan

| Phase | Output | Status |
|---|---|---|
| 0 — INTENT | This doc | ✅ shipped |
| 1 — RESEARCH (3 lanes) | A: arxiv lit review, B: substrate inventory, C: halt-class taxonomy | ⏳ next |
| 2 — REFINE r1+r2 | Cross-lane convergence, ratify halt-class thresholds | pending |
| 3 — AUDIT | Cross-cutting (doesn't break existing rules), safety (halt classes don't deadlock the system) | pending |
| 4 — DECOMPOSE | Bead graph: doctrine entry, skill updates, detector implementations, /flywheel:learn integration | pending |
| 5 — POLISH | 6+ rounds | pending |
| 6 — PROMOTE via /flywheel:learn | The Forever-Rule lands, with arxiv citations, into the right INCIDENTS file | terminal |
