# L169 — JSM-FIRST-SEARCH-BEFORE-HAND-ROLLING-MANDATORY

---
id: L169
title: Before authoring a new skill or hand-rolling functionality, the orchestrator MUST consult the JSM skill registry first; promote-as-overlay when a JSM skill covers ≥70% of the intended capability
status: long_term
shipped: 2026-05-12
review_due: 2026-11-12
trauma_class: hand-rolled-substrate-when-jsm-already-ships-canonical
promotion: JOSHUA-DIRECTIVE-PROMOTED-IMMEDIATE 2026-05-12T~14:50Z ("we need a mechanism that goes from JSM new skill release → how we are baking it into our systems")
source_doctrine: skillos canonical at .flywheel/doctrine/jsm-ingestion-flywheel.md (5-phase pipeline DETECT → CLASSIFY → ABSORB → PROPAGATE → MEASURE)
parent_l_rule: L78 (JEFF-CORPUS-ACCRETIVE-INGESTION)
sister_l_rules: L63 (JEFF-INTEL-NETWORK-IS-CANONICAL-SUBSTRATE-DEPENDENCY), L64 (JEFF-IS-MENTOR-NOT-JUST-DEPENDENCY)
strategic_frame: ZestStream = Red Hat for the agentic stack scoped to SMBs; Jeff's $20/mo JSM = the kernel; flywheel's value is integration speed + SMB-fit
meta_rule_anchor: feedback_secrets_class_skip_3_strike_gate.md (cross-orch coordination class; promoted via Joshua-directive fast-track)
---

## Rule

Before any orchestrator or worker authors a new skill, scaffolds new tooling, or hand-rolls functionality that might already exist in Jeff's [JSM (Jeffrey's Skill Marketplace)](https://jeffreys-skills.md) catalog, it MUST:

1. **Search JSM first** via `jsm search <capability>` or `jsm show <skill-name>`
2. **Classify any matching JSM skill** per the 4-verdict taxonomy:
   - **REPLACES** — JSM skill fully covers intended capability; adopt directly; retire any hand-rolled equivalent
   - **ENHANCES** — JSM skill covers ≥70% but missing flywheel-specific extensions; adopt as base + author thin overlay
   - **NEW-CAPABILITY** — JSM has no matching skill; proceed with hand-rolled implementation; consider proposing back to JSM
   - **IGNORE-WITH-REASON** — JSM skill exists but explicitly not adopted (with documented rationale; e.g., wrong scope, wrong tradeoffs, license conflict)
3. **Record the classification** in `state/jsm-cross-reference-map.json` (or fleet equivalent) with rationale

## Why

**Cost-of-violation:** rework. Hand-rolling functionality that JSM already ships canonically wastes worker-hours, fragments the substrate (your local hand-roll vs. canonical JSM version), and ages out of the upstream improvement cadence.

**Strategic framing (Joshua-directive 2026-05-12T~14:50Z):** ZestStream's commercial position is "Red Hat for the agentic stack scoped to SMBs." Jeff's $20/mo JSM is the kernel; flywheel's differentiated value is **integration speed + SMB-fit**. Every day flywheel doesn't absorb a JSM release is a day flywheel owes someone else's customer. The JSM Ingestion Flywheel (skillos:1 v0.1 shipped 2026-05-12T16:04Z) operationalizes this rule.

**Why fast-track promotion (skipping standard 3-strike cadence):** Joshua-directive PROMOTE-IMMEDIATE. The strategic positioning depends on this rule being normative across the fleet from day one. Same fast-track pattern as L168 (consumer-repo tenant declaration) — high-leverage paradigm rules can promote on Joshua-directive without N=3 SATURATION.

## The 5-phase pipeline (skillos:1 v0.1, LIVE 2026-05-12T16:04Z)

| Phase | What | Status |
|---|---|---|
| **DETECT** | Daily 03:15 sync from JSM registry → local catalog | Already wired |
| **CLASSIFY** | Daily 04:00 fire; classifier emits 4-verdict JSONL | v0.1 LIVE (Joshua-override of 24h soak) |
| **ABSORB** | Manual for v0.1; auto-absorb in v0.2 | Manual v0.1 |
| **PROPAGATE** | Manual cross-orch announcement; auto in v0.2 | Manual v0.1 |
| **MEASURE** | Heartbeat mission-gate JSON via `scripts/jsm_ingestion_doctor.sh` | LIVE; needs receipt-schema v3 to surface in receipts |

## Sister rule connections

- **L78** JEFF-CORPUS-ACCRETIVE-INGESTION — this L-rule is the operational mechanism for L78's accretive doctrine
- **L63** JEFF-INTEL-NETWORK-IS-CANONICAL-SUBSTRATE-DEPENDENCY — Jeff's substrate is canonical; this rule extends to skill-level dependency
- **L64** JEFF-IS-MENTOR-NOT-JUST-DEPENDENCY — the JSM ingestion flywheel honors Jeff as upstream-of-our-substrate
- **L82** CANONICAL-CLI-SCOPING-MANDATORY — JSM-adopted skills follow this same discipline
- **L168** EVERY-CONSUMER-REPO-MUST-DECLARE-ZS-TENANT-YAML-AT-ROOT — sister fast-track promotion; same Joshua-directive PROMOTE-IMMEDIATE pattern

## How to apply

Before authoring ANY new skill or capability:

```bash
# Step 1: search
jsm search <capability-keyword>

# Step 2: inspect candidates
jsm show <skill-name>

# Step 3: classify (record in cross-reference map)
# verdict ∈ {REPLACES, ENHANCES, NEW-CAPABILITY, IGNORE-WITH-REASON}

# Step 4: act on verdict
# REPLACES → jsm install <skill>; retire hand-roll
# ENHANCES → jsm install + author thin overlay
# NEW-CAPABILITY → proceed with hand-roll; consider jsm publish later
# IGNORE-WITH-REASON → document rationale; proceed with hand-roll
```

## Ownership

- **skillos:1** owns the JSM Ingestion Flywheel pipeline + classifier + cross-reference map
- **flywheel:1** owns this L-rule + fleet coordination + receipt-schema v3 integration
- **mobile-eats:1, alps:1, others** consume the pipeline outputs via daily heartbeat receipt

## Promotion ladder

This L-rule promotes under **Joshua-directive PROMOTE-IMMEDIATE** (2026-05-12T~14:50Z). NOT secrets-class (no irreversibility on incorrect classification — wrong verdicts are recoverable via re-classification). Standard 3-strike cadence does NOT apply because Joshua-directive supersedes.

Empirical receipts:
- skillos:1 v0.1 LIVE 2026-05-12T16:04Z (launchd loaded; pipeline running; 152 classifications emitted; 6 enhances + 10 ignore-with-reason in cross-reference map)
- Joshua-override of 24h soak gate (risk-assessed as conservative; pipeline idempotent + reversible)

## Cross-orch ratification

| Orch | Status |
|---|---|
| skillos:1 | Authored canonical doctrine + v0.1 implementation |
| flywheel:1 | Ratified this packet (2026-05-12T~20:00Z) |
| mobile-eats:1 | Pending; will consume via daily heartbeat receipt after receipt-schema v3 ships |
