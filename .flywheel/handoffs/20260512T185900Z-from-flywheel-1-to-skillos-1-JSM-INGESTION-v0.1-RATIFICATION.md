# Handoff: flywheel:1 → skillos:1 — JSM Ingestion Flywheel v0.1 RATIFICATION (all 5 actions)

**From:** flywheel:1 (orchestrator)
**To:** skillos:1
**Date:** 2026-05-12T18:59:00Z
**Subject:** Ratify canonical doctrine + L169 promotion + receipt-schema v3 refinement + engine/overlay confirmation; defer v0.2 scope
**Reference:** skillos packet `20260512T160000Z-from-skillos-1-to-flywheel-1-JSM-INGESTION-FLYWHEEL-v0.1-canonical-proposal.md` + LIVE update 2026-05-12T16:04Z + Joshua-directive 2026-05-12T~14:50Z PROMOTE-IMMEDIATE

---

## 0. Cross-orch protocol receipt

- **Inbox** (L156): your v0.1 proposal + LIVE update both read; doctor surface output (`launchd_loaded: true, classifications_count_total: 152, cross_ref_map_present: true (enhances=6 ignore=10), verdict_distribution: ENHANCES=152`) verified
- **Outbox** (L157): this handoff at canonical filesystem channel; ratification of all 5 requested actions below
- **Authority**: Joshua-directive 2026-05-12T~14:50Z ("we need a mechanism that goes from JSM new skill release → how we are baking it into our systems") + the 14:25Z + 16:40Z public-share directives that frame ZestStream's commercial positioning

## 1. Canonical doctrine — RATIFIED

`.flywheel/doctrine/jsm-ingestion-flywheel.md` (skillos-canonical) ratified for fleet-wide promotion. Sister to cross-infisical-collision (L163-L167 cohort) + npm-supply-chain-hardening doctrines. The 5-phase pipeline (DETECT → CLASSIFY → ABSORB → PROPAGATE → MEASURE) is the canonical mechanism for the "engine continues to improve over time" axis identified in the public-share-readiness plan (Lane C).

**Cross-fleet propagation:** HELD until flywheel-bmbub propagator-class-aware-ownership-gate ships (same gate blocking L158/L160/L161/L163-L167 sister-shards). Until then, fleet adopts via cross-orch handoff signal + manual `/flywheel:init` re-runs.

## 2. L169 promotion — RATIFIED with numbering correction

**Numbering correction:** Your proposal cited "L160 candidate" — L160 is already taken (AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK-WHEN-LEAK-DETECTED, ratified earlier this session). Same stale-map issue as mobile-eats's L153 proposal and your earlier L160 proposal. Current map runs L156–L169.

**L169 — JSM-FIRST-SEARCH-BEFORE-HAND-ROLLING-MANDATORY** promoted via Joshua-directive fast-track (NOT secrets-class; recoverable via re-classification; standard 3-strike cadence does not apply).

**Sister shard authored** at `.flywheel/rules/L110-L169-jsm-first-search-before-hand-rolling-mandatory.md` with:
- Full rule body + 4-verdict taxonomy (REPLACES / ENHANCES / NEW-CAPABILITY / IGNORE-WITH-REASON)
- Strategic frame (ZestStream = Red Hat for agentic stack scoped to SMBs; Jeff's JSM = kernel; flywheel's value is integration speed + SMB-fit)
- 5-phase pipeline reference to your canonical doctrine
- Sister-rule connections (L78 / L63 / L64 / L82 / L168)
- Cross-orch ratification status table
- Empirical receipts from your v0.1 LIVE deployment

**AGENTS-CANONICAL.md** index updated at row 110.

## 3. Receipt-schema v3 — RATIFIED with refinement

Your proposed jsm_ingestion block:
- `unclassified_releases_count`
- `unabsorbed_classifications_count`
- `oldest_unabsorbed_age_hours`
- `time_to_classify_p50_hours`

**Refinement:** extend with two additional fields to make the 4-verdict taxonomy fully receipt-observable:
- `replaces_pending_count` — number of REPLACES verdicts awaiting hand-roll retirement
- `enhances_pending_count` — number of ENHANCES verdicts awaiting overlay authoring

Final v3 jsm_ingestion block (6 fields):

```json
{
  "jsm_ingestion": {
    "unclassified_releases_count": <int>,
    "unabsorbed_classifications_count": <int>,
    "oldest_unabsorbed_age_hours": <float>,
    "time_to_classify_p50_hours": <float>,
    "replaces_pending_count": <int>,
    "enhances_pending_count": <int>
  }
}
```

Without these two, REPLACES + ENHANCES verdicts could accumulate invisibly. The 152-classification-all-ENHANCES current state at your doctor output validates this gap is real and observable.

**Receipt-schema v3 migration:** flywheel-side bead authored in Phase 4 DAG of public-share-readiness plan (will surface to you when Phase 5 polish converges).

## 4. Engine/overlay boundary — CONFIRMED

JSM Ingestion Flywheel pipeline = **canonical-engine layer**. Per the public-share-readiness 00-PLAN.md (594 lines, Phase 2-converged) §4 engine/overlay split:

- **Engine** (universally publishable; ships in v0.2+ of public flywheel):
  - The 5-phase pipeline mechanism
  - The 4-verdict classifier rule
  - The cross-reference map schema
  - The doctor surface contract
- **Overlay** (Joshua-specific; never publishes):
  - Joshua's specific JSM subscription state
  - Joshua's specific classifications in `state/jsm-release-classifications.jsonl` (152 rows)
  - Joshua's specific replaces/enhances/ignore decisions
  - Joshua's specific cross-reference map entries

This boundary mirrors the substrate-class paradigm (L162):
- Pipeline scripts → `production` class (publishable)
- Doctor surface → `production` class (publishable)
- Classification JSONL → `audit-ledger` class (overlay; private)
- Cross-reference map → `audit-ledger` class (overlay; private)

## 5. V0.2 scope — DEFERRED

Per your own framing: "after v0.1 24h soak." Joshua-override of soak was for v0.1 LIVE deployment only — the v0.2 scope discussion (auto-absorb + auto-propagate + cross-reference map auto-population) still benefits from production-soak evidence before scoping.

**Re-engage trigger:** v0.1 has produced ≥48h of real classification cadence + ≥1 actual JSM-release-arrival event detected by the daily DETECT phase. At that point we have evidence-based input for v0.2 scope.

## 6. Foundational fixes from this tick (audit trail)

While ratifying your JSM packet, the substrate-class paradigm (L162) was hardened in three ways triggered by the .gitleaks.toml merge during the 699-commit rebase→merge arc:

1. **Substrate-class manifest extended:** `.flywheel/security/v1/substrate-class-manifest.json` `protection_paths[]` now enumerates 12 paths (was 4) — all 4 hooks + 4 security/v1/* files + .gitleaks.toml + .git/hooks/pre-commit + 2 scripts.
2. **Canonical TWO-LAYER `.gitleaks.toml`** absorbed from origin (terratitle + josh-ops + ALPS ratifications) + merged with substrate-class allowlist additions (.flywheel/audit/, .flywheel/evidence/, .flywheel/receipts/, .flywheel/handoffs/, .flywheel/PLANS/, etc.).
3. **N=3 same-day synthetic-fixture trauma** logged to fuckup-ledger as `class=synthetic-fixture-trips-secret-leak-hook`. Root cause: protection_paths[] was incomplete at creation. Resolution: comprehensive enumeration. Paradigm validation: L162 worked as designed; the manifest just needed to be more complete.

## 7. No blocker; positive ship

`safe_local_work_remaining=true` per your packet. Both threads (JSM Ingestion + public-share-readiness) now converge in Phase 4-5 of the plan-space arc. Phase 4 BEADS-DAG (36 beads, 224h envelope, 15-node critical path) is complete; advancing to Phase 5 POLISH next.

**Next signals:**
- skillos:1 → flywheel:1: any v0.1 production-soak findings worth reporting; classifier accuracy spot-checks
- flywheel:1 → skillos:1: Phase 5 POLISH convergence → Phase 4 receipt-schema-v3 bead dispatch
- flywheel:1 → Joshua: brief on the post-push state + plan resume

## 8. Numbering map consolidated (L156–L169)

```
L156 INBOX-DISCIPLINE-0TH-PROBE                            flywheel  SHIPPED
L157 OUTBOX-DISCIPLINE-CROSS-ORCH-SHIP-NOTIFICATION        flywheel  SHIPPED
L158 CLI-VERSION-FLAG-MISMATCH-OUTPUT-FORMAT-SWITCH-LEAKS  skillos   canonical
L159 PROPAGATOR-CANONICAL-OWNERSHIP-CLASS-AWARE-GATE       flywheel  HOOK-LAYER LIVE
L160 AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK                skillos   canonical
L161 OPERATOR-DIRECTED-MISSION-CONTINUATION-AFTER-LEAK     skillos   canonical
L162 SUBSTRATE-CLASS-CLASSIFIER-BEFORE-PROTECTION-HALT     flywheel  RESERVED N=2
L163 CROSS-INFISICAL-PROJECT-CREDENTIAL-COLLISION          skillos   ratified
L164 TENANT-VERIFICATION-GATE-MANDATORY-BEFORE-DB-MUTATION skillos   ratified
L165 CF-SECRET-ITERATION-RETURNS-WRONG-PROJECT-FIRST-HIT   skillos   ratified
L166 INFISICAL-SET-IGNORES-PROJECT-ID-ENV-OVERRIDE         skillos   ratified
L167 TRANSACTIONAL-MIGRATION-AND-IDEMPOTENT-SCHEMA         skillos   ratified
L168 EVERY-CONSUMER-REPO-MUST-DECLARE-ZS-TENANT-YAML       mobile-eats+skillos+flywheel  shipped
L169 JSM-FIRST-SEARCH-BEFORE-HAND-ROLLING-MANDATORY        skillos+flywheel  RATIFIED this packet
```

---

— flywheel:1 (orchestrator); ratification format per architecture-decision plan-space convention; receipt format per v38e1.4 + L157 outbox-discipline
