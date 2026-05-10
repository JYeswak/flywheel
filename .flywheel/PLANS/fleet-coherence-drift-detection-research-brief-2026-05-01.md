---
title: "Fleet-Coherence Drift Detection — Research Brief for Triangulated Planning"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet-Coherence Drift Detection — Research Brief for Triangulated Planning

**Created:** 2026-05-01T15:14Z
**Brief author:** flywheel-p1 (LavenderGlen, opus-4.7)
**Purpose:** Plan-space convergence brief for /planning-workflow. Three independent planners produce architecture recommendations grounded in research and data. Hypothesis-free framing — planners must surface the best option, not validate a preselected one.

---

## Open Question

What is the best architecture for realtime drift-detection and auto-remediation across the flywheel hive — given the drift classes that ALPS exhibited today?

The brief does **not** name a recommended architecture. The planners must research, measure, compare, and recommend.

---

## Triggering Incident (data, not hypothesis)

On 2026-05-01 between roughly 06:00–15:00Z, the alpsinsurance ntm session drifted into a degraded state that was only surfaced when Joshua walked over and looked. The session was not "down" — `ntm health` showed 4 healthy panes — but the orchestration layer was malfunctioning in ways no automated process detected.

### Drift classes observed in ALPS

These are the data the system must catch. Planners may add additional drift classes to this list if their research finds others worth detecting; document each addition with evidence.

1. **Two orchestrator-tick loops on one session.** Pane 0 (codex, registered orch) and pane 1 (cc, registered worker) were both running orchestrator-decision logic. Pane 1 had been running `/flywheel:tick` (an orch command) on a 30-minute `/loop` for ~9 hours and 18 ticks.
2. **Worker pane running orchestrator command (role/command mismatch).** Pane 1 is registered as a worker in `session-topology.jsonl` but executes `/flywheel:tick`, the orchestrator decision function. The correct worker command is `/flywheel:worker-tick` (which doesn't exist yet — bead `josh-1eo8p`).
3. **Topology row stale vs reality.** Topology row says pane 3 = codex; `ntm health` shows pane 3 = cc. (Likely the codex token expired and Joshua relaunched cc on top.) No process detected the mismatch.
4. **Orchestrator with no autonomous tick cadence.** Pane 0 codex did real orchestrator work — diagnosed beads_db leakage, repaired 5 source_repo='.' rows, kicked LaunchAgent — but only when Joshua interacted with it. Codex has no `/loop` equivalent. The orchestrator is reactive, not proactive.
5. **Worker-tick deferring with `sustained_operator_pause` for >N ticks.** Pane 1's tick receipts logged 18 consecutive deferred refills with reason `sustained_operator_pause (~9h, 18 consecutive quiet ticks)`. The detection works; the **escalation** does not — the receipt is written and forgotten.
6. **expected_pane_count ≠ actual pane count.** ALPS topology declares `expected_pane_count=4` but only panes 0–3 are registered. Pane 4 is either dead or never existed. No process detected the gap.
7. **Codex agent token expired silently.** Pane 3 transcript shows a token-refresh failure and a re-login. No event was logged outside the pane scrollback. The pane was effectively offline for an unknown window.
8. **Agent on wrong skill_version.** `tick-skill-version-check.sh` exists per-pane but no aggregate process surfaces "which panes are running tick.md v1 vs v2". Detection per-pane only; no fleet view.

### Substrate already exists for some signals (do not reinvent — research what's there)

| Substrate | Path | Coverage |
|---|---|---|
| Pane liveness | `ntm health` (live), `~/.local/state/flywheel/ntm-fleet-health.jsonl` (60s daemon log) | Detects pane crashes, idle/active. Does NOT detect role/command mismatch, topology staleness, or skill_version drift. |
| Declared topology | `~/.local/state/flywheel/session-topology.jsonl` | Latest-per-session via jq. Read-only by all consumers. |
| Tick receipts | `~/.local/state/flywheel-loop/last_tick_<project>.json` per session | Per-session decision audit. No aggregation. |
| Dispatch flow | `<repo>/.flywheel/dispatch-log.jsonl` per repo | Per-repo. No fleet view. |
| Trauma classes | `~/.local/state/flywheel/fuckup-log.jsonl` | Hand-logged. No real-time emission. |
| Cross-orch comms | fleet-mail-project + L61 ntm-poke pairing | Working today (msg 6–14 verified). |
| Skill-version pin | `tick-skill-version-check.sh` per-skill | Per-pane, no aggregation. |
| Skill-discovery rows | `~/.local/state/flywheel/skill-discoveries.jsonl` | L62 substrate, candidate-skill emission. |
| AGENTS.md doctrine | `~/Developer/flywheel/AGENTS.md` L60–L65 | Declares topology, comms, recovery, but no enforcement. |
| Auto-recovery primitive | `ntm-fleet-health` daemon at `~/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist` | LIVE 60s scan. Restarts stuck panes. Does NOT detect drift classes 1, 2, 3, 4, 5, 6, 7, 8 above. |
| CASS v2 overlay (interface flag from picoz-p1) | `~/Developer/gpu-optimization/mem/migrations/001_overlay.sql` | Has `valid_from` / `valid_to` / `superseded_by` / `confidence` schema. Substrate-relevant to drift class #8. |

---

## Constraints (must be honored by any architecture)

- **Additive to existing substrates.** No rewrites of `ntm-fleet-health`, `session-topology.jsonl`, `tick.md`, etc. Extend or wrap; do not replace.
- **macOS launchd-compatible.** Same deployment surface as `ntm-fleet-health`.
- **L0 cost class for detection.** No LLM calls in the daemon path. LLM work happens downstream (in auto-filed beads dispatched to workers).
- **Detection lag ≤ 60s** for the 8 drift classes (or a planner-justified alternate budget per-class).
- **Self-healing must use NTM + Agent Mail primitives.** Never raw tmux. Dual-channel L61 pairing required for any cross-session message.
- **Doctrine consistency:** doesn't violate L60 (topology declaration), L61 (dual-channel), L62 (skill-discoveries), L63 (recovery rehearsal), L65 (cross-orch via fleet-mail-project).

---

## Success Criteria

- All 8 drift classes detected within 60s (or per-class-justified alternate budget).
- Each detected drift produces either an auto-filed bead OR a `no_bead_reason` row in a queryable substrate. Never silently dropped.
- Affected session's orchestrator receives dual-channel L61 message (fleet-mail + ntm-poke) within the detection window.
- A single `flywheel-loop drift-status` (or equivalent) command shows fleet-wide coherence in <2s.
- Joshua can grep one JSONL to answer "did the brain detect X drift, and what did the brain do about it" — full audit trail.
- Self-healing pathway is documented for each of the 8 classes.

---

## Out of Scope (do not plan these here)

- Fixing today's specific ALPS state (separate execution after the architecture lands).
- Replacing `tick.md` v2 (this layers on top, doesn't replace).
- Implementing `/flywheel:worker-tick` (`josh-1eo8p`) — this architecture *detects* its absence as a drift signal but doesn't build it.
- Fleet-mail server changes (treat the existing surface as fixed).
- ntm or beads_rust upstream changes (those are Jeff's repos; file issues, don't patch).

---

## Architecture Options the Planners MUST Compare

These are starting candidates. Planners may add additional options or eliminate options if research surfaces evidence that justifies it.

- **Option A:** Extend `ntm-fleet-health` daemon to detect all 8 classes. One launchd job, one substrate.
- **Option B:** New sibling daemon (e.g. `fleet-coherence`). Independent failure mode, separate substrate.
- **Option C:** Move detection into `tick.md` v3 as new orchestrator steps. In-band, no new daemon.
- **Option D:** Hybrid — daemon emits raw signals, tick consumes + decides + dispatches.
- **Option E:** Anything the research surfaces (existing tools to adopt, e.g. Jeff's repos, zeststream-infra `watcherctl` patterns, CASS v2 overlay tables).

---

## Required Research Phase (before recommendation)

Each planner must produce evidence in these categories before naming a recommendation. A recommendation without supporting evidence is invalid.

### R1. Prior art audit
- Grep `~/Developer/zeststream-infra` for watcherctl / drift / coherence patterns.
- Grep `~/Developer/picoz`, `~/Developer/zesttube`, `~/Developer/skillos`, `~/Developer/cubcloud` for any existing fleet-coherence or drift-detection code.
- Read Jeff Emanuel's repos (`ntm`, `agent-mail`, `beads_rust`, `dcg`, `cass`) for upstream patterns we should adopt or compose with.
- Examine CASS v2 overlay schema (`~/Developer/gpu-optimization/mem/migrations/001_overlay.sql`) for schema patterns relevant to drift class #8.
- Cite file paths + line numbers, not vibes.

### R2. Substrate inventory (per drift class)
For each of the 8 drift classes, document:
- What substrate already emits part of the signal
- Format, freshness, query latency
- Gap analysis: what's missing to close the detection
- Cite file paths.

### R3. Frequency data (historical)
- Grep `~/.local/state/flywheel/fuckup-log.jsonl` and `<repo>/.flywheel/dispatch-log.jsonl` across all repos for the last 30 days.
- Count occurrences of each drift class (or proxy events).
- Compute mean/median human-detection lag where data exists (when was drift introduced vs when noticed?).
- Report substrate write rates (rows/min for the noisy JSONLs).
- Report ntm + agent-mail primitive round-trip latencies (run actual probes; cite the timings).

### R4. Architecture options compared
For each option (A–E):
- Detection lag for each of 8 drift classes (estimated, with reasoning)
- Cost class (L0/L1/L2 — must justify any non-L0)
- Failure mode if the detector itself dies
- Operational complexity (launchd jobs, JSONL substrates, failure surfaces)
- Composition with existing substrates (additive vs replacement)
- False-positive cost (how do operators silence intentional drift?)
- Self-healing pathway per drift class
- Diff from today (new files, scripts, plists, JSONLs)

### R5. Tiebreaker rubric
Planners must propose the rubric for "best", with rationale. Examples:
- Lowest detection lag (catch fastest)
- Smallest substrate footprint (fewer JSONLs)
- Most accretive to existing patterns
- Simplest to debug when broken
- Weighted combination
- Something else the research surfaces

If two options score within noise on the planner's chosen rubric, say so. Don't force a winner where the data doesn't support one.

---

## Output Contract

Each planner writes to `/tmp/plan_fleet_coherence_drift_paneN.md` (where N is the dispatched pane number) with these sections in order:

1. **Prior-art-found** — citations, file paths, line numbers
2. **Substrate-inventory** — per-class table from R2
3. **Frequency-data** — measurements from R3, with raw command output preserved
4. **Options-compared** — table from R4 with all options scored
5. **Tiebreaker-rubric** — proposed from R5, with rationale
6. **Recommendation** — single architecture choice OR explicit "data insufficient, propose measurement-first phase Z"
7. **Recommendation-rationale** — citing data, not preference
8. **Risks** — failure modes, second-order effects
9. **Open-questions** — what would change the recommendation

Recommendation must cite the data. Vibes-only recommendations will be flagged at convergence.

---

## Convergence Criteria

After all 3 planners deliver:
- **2-of-3 recommend the same architecture AND same (or compatible) tiebreaker rubric** → CONVERGED. Synthesize, then `/jeff-convergence-audit`, then `/beads-workflow`.
- **3-of-3 disagree on architecture OR rubric** → DISPUTED. `/jeff-convergence-audit` runs to find the cross-cutting findings, then Joshua tie-breaks.
- **Any planner says "data is insufficient"** → that's a valid output; we add a measurement phase before deciding.

---

## Coordination

- This brief is shared with picoz-p1 (LavenderGlen ↔ picoz-pane1-orch) via L61 dual-channel. picoz-p1's CASS v2 Lane C synthesis wants the same tiebreaker rubric we converge on, so the chosen rubric flows back to them via fleet-mail + ntm-poke.
- Planners should treat picoz-p1's work as parallel context, not coordinate-with-them. Cross-session work for this plan happens at the synthesis layer (here, in flywheel-p1), not in worker panes.

---

## Inputs (reference docs to load before research)

- `~/Developer/flywheel/AGENTS.md` (L60–L65)
- `~/.claude/commands/flywheel/tick.md` (current tick v2)
- `~/Developer/flywheel/.flywheel/scripts/ntm-fleet-health.sh` (existing daemon pattern)
- `~/.local/state/flywheel/joint-deepdive-2026-05-01/orch-tick-bead-discipline-design.md` (companion design)
- `~/Developer/flywheel/.continue-here.md` (post-compact handoff)
- This brief: `~/Developer/flywheel/.flywheel/plans/fleet-coherence-drift-detection-research-brief-2026-05-01.md`
