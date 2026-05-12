# Phase 3 AUDIT — Findings register + audit_disposition

**Plan:** `public-share-readiness`
**Phase:** 3 AUDIT
**Round:** 1
**Lenses:** trust-bar / feasibility / completeness (3 of 3 landed)
**Composed:** 2026-05-12T~18:55Z

---

## Aggregate severity table

| Lens | Critical | High | Medium | Low | Total |
|---|---:|---:|---:|---:|---:|
| Trust-bar | 1 | 3 | 5 | 2 | 11 |
| Feasibility | 0 | 3 | 7 | 3 | 13 |
| Completeness | 0 | 4 | 7 | 4 | 15 |
| **TOTAL** | **1** | **10** | **19** | **9** | **39** |

## Lens verdicts

- **Trust-bar:** *Mostly proud-bar-clearable.* Structural skeleton sound; ~20-25% gap concentrated in SMB-trust webpage load + developer-trust README load.
- **Feasibility:** *Shippable with adjustments.* Effort envelope undercounted (~100-140h actual vs 40-60h claimed). 3 small new beads + 2 tactical splits. No re-plan needed.
- **Completeness:** *Complete with material gaps.* 4 HIGH findings map to TRUE-blocker classes — must close before Phase 4 DECOMPOSE.

## TRUE-blocker class findings

Per /flywheel:plan §3 precedence, pause on first-fire class. Multiple findings classified:

### Class 5 (destructive-irreversible-on-shared-state) — FIRST FIRE

**Finding F1+F10 (completeness):** Live-state artifact denylist entirely absent. The plan never disposes of:
- `~/.flywheel/private/state.db` + `-shm` + `-wal` (flywheel runtime SQLite — contains Joshua's full bead history)
- `.beads/issues.jsonl` (canonical bead substrate — names every closed bead with full context)
- `.flywheel/dispatch-log.jsonl` (every dispatch flywheel:1 has issued, with full prompt text)
- `.flywheel/handoffs/` (every cross-orch handoff, including unrelated client work)
- `.flywheel/PLANS/` (this very plan-arc directory)
- `.flywheel/audit/` + `.flywheel/evidence/` + `.flywheel/receipts/` (per-bead substrate from prior work)
- `.flywheel/research/` (research outputs containing client/project specifics)
- `~/.claude/secret-leak-ledger.jsonl` if it ever gets shipped (contains real leak events)

Per secrets-class meta-rule (`feedback_secrets_class_skip_3_strike_gate.md`, 2026-05-12): single-occurrence-irreversible. If any of these ship publicly, Joshua's operational substrate, client identities, and trauma corpus become irreversibly public.

**Class 5 cite:** these files "extend beyond the local repo and cannot be undone" — exactly the irreversible-shared-state class.

### Class 6 (paradigm-conflict-with-active-mission)

**Finding F3 (completeness):** Three HALTED propagator scripts have no disposal policy:
- `.flywheel/scripts/canonical-doctrine-sync.sh` (halted via `chmod -x`)
- `.flywheel/scripts/sync-canonical-doctrine.sh` (halted)
- `.flywheel/scripts/agents-md-fleet-propagator.sh` (halted)

These were halted per L159 N=3 SATURATION trauma (2026-05-12 ~03:36Z). They bypass per-bead OWNED_WRITE_ROOTS by design. If shipped publicly without the class-aware-ownership-gate (still bmbub-pending per L159), adopters install scripts that recreate the exact trauma class L159 was promoted to prevent.

**Class 6 cite:** shipping these scripts contradicts L159 as a load-bearing axiom of the engine's safety substrate.

**Finding F1 (trust-bar):** Self-referential case-study set (v0.2 has only flywheel-on-flywheel). Lane B §4 identified this as the "anonymous SaaS company" anti-pattern. Maps to Class 6 because the active mission is "build trust in Joshua + brand + work"; a self-referential case-study undermines the trust premise. Adopters reading "flywheel built flywheel" perceive marketing-speak, not demonstration.

### Class 4 (legal-or-compliance-decision)

**Finding F5 (completeness) + F4 (feasibility):** H3 case-study consent collection workflow unspecified. H3 (the recommended hypothesis) requires redacted-overlay-as-case-study. The plan:
- Acknowledges the per-surface-consent memory rule (2026-05-11)
- But never specifies: the consent template, the record format, the calendar for collection, the fallback if consent isn't granted in time
- AND F4 (feasibility): even with redaction, implicit class-leak via industry context isn't gated ("A Montana telecom client" still identifies)

**Class 4 cite:** publishing client substrate without explicit consent has legal weight (defamation risk, NDA breach risk, regulatory exposure for HIPAA/PCI-adjacent clients like ALPS/TerraTitle/Blackfoot). Decision belongs to Joshua + counsel, not auto-advance.

## audit_disposition

```
audit_disposition: blocker_class_destructive-irreversible-on-shared-state
audit_blocker_classes: [
  "destructive-irreversible-on-shared-state",   # Class 5; first-fire
  "paradigm-conflict-with-active-mission",      # Class 6
  "legal-or-compliance-decision"                # Class 4
]
audit_blocker_reason: "3 TRUE-blocker-class findings: live-state artifact denylist absent, halted propagator scripts disposal unspecified, H3 case-study consent workflow unspecified"
joshua_decision_pending: true
```

## Proposed remediations (Joshua-ratify or refine)

These are bead-level additions to the DAG that would close each blocker class:

### Class 5 remediation — live-state artifact denylist

**Add B0.5 (P0; S effort; blocks B11 extraction-pipeline-completes):**
- Title: "Live-state artifact denylist — extractor must refuse to copy these paths"
- Acceptance:
  - `scripts/depersonalize.py` reads a checked-in `state/live-state-denylist.yaml`
  - Denylist enumerates: `state.db*`, `*.beads/issues.jsonl`, `dispatch-log.jsonl`, `handoffs/`, `PLANS/`, `audit/`, `evidence/`, `receipts/`, `research/`, `secret-leak-*-ledger.jsonl`, any other identified-overlay path
  - Extractor errors-and-halts if ANY denylist path appears in the extraction target
  - Smoke test: synthetic denylist hit triggers documented error exit code
  - Joshua review: denylist enumeration is complete (manual sign-off; one row in compliance pack)

### Class 6 remediation A — halted propagator disposal

**Add B0.6 (P0; S effort; blocks B11):**
- Title: "Halted propagator scripts: dispose or extract-with-warning"
- Acceptance: ONE of:
  - (a) Three propagators excluded from extraction (don't ship at all)
  - (b) Three propagators shipped with explicit `chmod -x` + README warning + L159 cross-reference
- Joshua decision required: (a) or (b); recorded in compliance pack

### Class 6 remediation B — self-referential case-study

**Refine F1 (trust-bar) into bead-level work:**
- Option A (recommended): Drop `/case-studies` from v0.2 webpage; replace with `/methodology` (shows the system, not claims of outcomes)
- Option B: Recruit ONE external adopter pre-launch (lane B suggested this; F3 trust-bar binds it)
- Option C: Reframe flywheel-on-flywheel as `/methodology/how-we-built-this` (honest meta-application, not "case study")
- **Joshua decision:** A / B / C / hybrid

### Class 4 remediation — H3 consent workflow

**Add B11.5.0 (P0; M effort; blocks B11.5):**
- Title: "H3 case-study consent collection + redaction-class audit"
- Acceptance:
  - Consent template authored (sister to per-surface-consent meta-rule)
  - Per-named-entity consent matrix: for each client name surfacing in the candidate case-study, status ∈ {granted, declined, pending, not-applicable-fully-redacted}
  - Industry-only redaction policy: replaces specific geography ("Montana") with industry-only descriptor ("ISP", "title insurance", "small group insurance")
  - Joshua + counsel sign-off recorded before B15 launch
  - Fallback: if consent matrix has any `declined` or `pending` at T-1-week-before-launch, H3 collapses to alternative (drop case-study; webpage uses `/methodology` instead)

## Non-blocker findings (Phase 4 bead inputs)

The remaining 35 findings (1 critical that maps to Class 6 above + 6 high + 19 medium + 9 low) become severity-mapped Phase 4 beads:

- **F2 trust-bar (high):** README has no quantified differentiator. → bead: add measurable claims block to README spec
- **F3 trust-bar (high):** External-developer README review not bead-bound. → bead: B11.6 README review by 2 external developers, blocks B15
- **F1 feasibility (high):** Effort envelope undercounted. → fix in plan: restate "40-60h" as "40-60h substrate sweep; 100-140h total v0.2 envelope"
- **F3 feasibility (high):** Skillos:1 coordination no SLA. → bead refinement: B16 acceptance adds "skillos ack OR 14-day deadline with zero-skills v0.2 lock"
- Other medium/low findings: standard Phase 4 absorption

## Recommendation

Joshua-decisions required before Phase 4 DECOMPOSE:

1. **Ratify Class 5 remediation** (B0.5 live-state denylist) — likely uncontroversial
2. **Ratify Class 6 remediation A** (halted propagator disposal): (a) exclude / (b) ship-with-warning
3. **Ratify Class 6 remediation B** (case-study positioning): A / B / C / hybrid for self-referential case-study
4. **Ratify Class 4 remediation** (consent workflow + fallback) — likely uncontroversial in shape; calendar may be tight for v0.2

After ratification, Phase 3 audit_disposition flips to `auto_advance` and Phase 4 DECOMPOSE fires with the new beads added.

If any decision is `defer`, Phase 4 fires with all beads except those blocked on Joshua-decision.

## What the audit lenses got right

The audit caught what the rough drafts missed. Phase 3 is doing its job. Specifically:
- **Trust-bar** flagged the case-study self-reference (would have been a quiet self-own at launch)
- **Feasibility** flagged the effort undercounting (would have slipped the calendar)
- **Completeness** flagged the live-state leak risk (would have been catastrophic at launch)

The 4-round Phase 2 convergence didn't surface these — they emerged only when external auditors stress-tested the plan. This is exactly what Phase 3 exists for.
