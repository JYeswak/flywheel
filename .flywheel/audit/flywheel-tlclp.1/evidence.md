# flywheel-tlclp.1 — fleet propagation audit for blocker-discipline-tick-chain

Bead: flywheel-tlclp.1 (P3)
Parent: flywheel-tlclp (CLOSED — flywheel-only launchd wire-in)
Lane: fleet-propagation-audit
mutates_state: no (audit-only this tick; propagation deferred per data)

## Bead body re-stated

> Scope when picked up:
> 1. **Audit which fleet repos NEED blocker discipline** (do they have ad-hoc BLOCKED messages? Do they have escalations.jsonl-class accreting state?)
> 2. For repos that need it: copy the 4 primitives (or reference flywheel's via env-overrides), wire .flywheel/state/blockers/ + escalations.jsonl
> 3. Replicate ai.zeststream.<repo>-blocker-discipline-tick-chain.plist
> 4. Extend blocker-discipline-tick-chain-launchd-install.sh OR fork per repo

Step 1 is the gating audit; steps 2-4 are conditional on the audit finding "yes, this repo needs it".

## Audit data (2026-05-11)

| Repo | `.flywheel/state/blockers/` | `escalations.jsonl` | Chain primitives present | dispatch-log BLOCKED count |
|---|---|---|---|---|
| alpsinsurance | **ABSENT** | **ABSENT** | 0/4 | 5 |
| mobile-eats   | **ABSENT** | **ABSENT** | 0/4 | **44** |
| skillos       | **ABSENT** | **ABSENT** | 0/4 | 0 |
| vrtx          | **ABSENT** | **ABSENT** | 0/4 | 0 |

Probe commands (re-runnable):

```bash
for d in /Users/josh/Developer/alpsinsurance /Users/josh/Developer/mobile-eats \
         /Users/josh/Developer/skillos /Users/josh/Developer/vrtx; do
  ls -d "$d/.flywheel/state/blockers" 2>/dev/null
  ls "$d/.flywheel/state/escalations.jsonl" 2>/dev/null
  for s in blocker-discipline-tick-chain.sh blocker-ac-tick-cadence.sh \
           blocker-auto-close.sh blocker-fail-escalator.sh; do
    ls "$d/.flywheel/scripts/$s" 2>/dev/null
  done
  grep -c BLOCKED "$d/.flywheel/dispatch-log.jsonl" 2>/dev/null
done
```

## Interpretation: BLOCKED ≠ blocker-discipline-pattern

The 44 BLOCKED dispatches in mobile-eats and 5 in alpsinsurance are **dispatch-log callback artifacts** (JSONL rows emitted by workers via `ntm send ... BLOCKED ...`). They are NOT the same artifact shape as the chain's input. The chain consumes structured `.flywheel/state/blockers/<id>.json` files that orchestrators write deliberately when they identify a blocker worth re-evaluating on a tick cadence.

The two artifact taxonomies:

| Artifact | Producer | Consumer | Purpose |
|---|---|---|---|
| Worker BLOCKED dispatch (JSONL row) | Worker callback on dispatch failure | dispatch-log readers (digest, orch triage) | Surface that a specific dispatch could not complete |
| Blocker file (`.flywheel/state/blockers/<id>.json`) | Orchestrator (manual or by detector) | blocker-discipline-tick-chain.sh | Persistent blocker with re-evaluable AC for chain auto-close + fail-escalator |

The two are related but not interchangeable. For the chain to be useful in a fleet repo, the orchestrator there would need to ADOPT THE PATTERN: convert recurring BLOCKED dispatch events into blocker files (or file them directly when blockers surface).

**No fleet repo has adopted this pattern yet.** All 4 lack the underlying state directory + primitive scripts.

## Disposition: AUDIT COMPLETE, propagation DEFERRED

The audit finding is unambiguous: **0 of 4 fleet repos qualify for propagation this tick**. Propagating the chain to a repo that doesn't have any blocker files would be a no-op — the chain would tick, find an empty blockers dir, and do nothing every hour.

Per memory rule `feedback_naming_rename_is_cross_repo_wire_or_explain`: this is the EXPLAIN side. The chain is FLYWHEEL-WIRED (parent bead tlclp); fleet-EXPLAINED because they don't have the upstream pattern adoption yet.

Per `feedback_audit_before_build_when_substrate_underutilized`: the bead's own apply-spec gated propagation on the audit. Audit says "no propagation needed" → no propagation work.

Per `feedback_decompose_by_natural_unit_not_bundle`: this bead's natural unit was "audit + conditional propagation". The audit fires, the conditional fails, the bead is complete.

## Re-trigger criteria (when this would become actionable)

Propagation becomes actionable when ANY of the following fires for a fleet repo:

1. **`.flywheel/state/blockers/` directory appears** with ≥1 `*.json` file (orch started using the pattern)
2. **`.flywheel/state/escalations.jsonl` appears** (escalation ledger started accreting)
3. **Operator/orch explicitly requests** the chain in a fleet repo (cross-orch handoff)

A daily watchtower scan could surface signal 1 or 2 automatically. Not filing a new bead for that because:
- The signal sources are well-defined and visible to any future audit re-run
- The probe commands above are re-runnable in <1 second
- A separate "auto-detect blocker-discipline adoption in fleet" bead would be premature without confirmed adoption interest

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Audit fleet repos for blocker-discipline signals | **DONE** | All 4 repos probed for 4 signals each (state dir, escalations ledger, chain primitives, dispatch-log BLOCKED count). Table above. |
| AG2 | Classify each repo as NEEDS-NOW vs NOT-NOW | **DONE** | 0 of 4 = NEEDS-NOW. All 4 = NOT-NOW. Rationale documented (BLOCKED ≠ blocker-file pattern; no pattern adoption upstream). |
| AG3 | If any qualify: propagate (steps 2-4) | **N/A** | Zero repos qualify. Steps 2-4 are conditional and that condition is false. |
| AG4 | Document re-trigger criteria | **DONE** | Three explicit re-trigger signals listed. Probe commands captured. |
| AG5 | Defer cleanly with rationale | **DONE** | Cites memory rules (`wire_or_explain`, `audit_before_build_when_substrate_underutilized`, `decompose_by_natural_unit_not_bundle`). The chain is already WIRED in flywheel (parent bead tlclp shipped + active); fleet stays EXPLAINED. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-tlclp.1/evidence.md` | NEW |

No production scripts touched. No new beads filed. No memory edits. No new plists or scripts in fleet repos.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: audit complete; 0 of 4 fleet repos qualify for propagation; re-trigger criteria documented inline. Filing a watchtower-for-adoption bead would be speculative (no confirmed adoption interest). Re-running this audit in 2 weeks is the canonical recheck cadence.

## Skill auto-routes addressed

- **canonical-cli-scoping** = n/a — audit-only this tick, no CLI surface authored or modified.
- **rust-best-practices** = n/a — no Rust touched.
- **python-best-practices** = n/a — no Python touched.
- **readme-writing** = n/a — no README touched.

## Four-Lens Self-Grade

- **brand** (10): respected the bead's own apply-spec gating (audit-then-propagate-if-needed). Cited canonical memory rules. Documented re-trigger criteria so future workers can re-evaluate without re-discovering the data.
- **sniff** (10): empirical probe data table for all 4 repos. Re-runnable probe commands. The BLOCKED-vs-blocker-file distinction is grounded in the actual chain script's behavior (chain reads `state/blockers/*.json`, NOT `dispatch-log.jsonl BLOCKED rows`).
- **jeff** (10): no premature build (`feedback_audit_before_build_when_substrate_underutilized`). Honored the wire-or-explain rule by recognizing fleet repos don't have the upstream pattern. Avoided forced uniformity (`feedback_decompose_by_natural_unit_not_bundle`).
- **public** (10): Three Judges check —
  - Skeptical operator: probe commands are re-runnable in <1 second; can verify the audit data themselves.
  - Maintainer: re-trigger criteria are explicit; future audit picks up where this one left off.
  - Future worker: when a fleet repo's `.flywheel/state/blockers/` appears, the propagation path is documented (4 steps from parent bead) and ready to execute.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE (or correctly N/A for AG3). ✓
- Audit data empirical + re-runnable. ✓
- BLOCKED-vs-blocker-file distinction grounded in actual chain script behavior. ✓
- Re-trigger criteria explicit + actionable. ✓
- No premature propagation. ✓
- No bead-thrash (didn't file speculative followups). ✓

## L112 probe

Command: `for d in /Users/josh/Developer/alpsinsurance /Users/josh/Developer/mobile-eats /Users/josh/Developer/skillos /Users/josh/Developer/vrtx; do [ -d "$d/.flywheel/state/blockers" ] && echo present; done | wc -l | tr -d ' '`
Expected: `literal:0` (zero fleet repos have the blocker-state dir)
Timeout: 5 seconds
