# Perpetual-Progression — REFINE r2 (post-AUDIT)

**Inputs since r1:** `perpD_audit_crosscutting.md` (845 lines, 6 findings, 18 risks, 5 collisions, 0 cycles) + `perpE_audit_safety.md` (617 lines, 24 invariants, 4 deadlocks, 4 drift mitigations, 6 findings).

**Method:** Fold AUDIT findings into bead graph; cross-link with sister plan; surface counter-trauma class as new shared substrate; finalize bead DAG for DECOMPOSE.

---

## 1. AUDIT-driven additions

### A-1: Counter-trauma class (`orchestrator-decided-when-should-have-asked`)
Lane E §5 surfaced the symmetric anti-pattern: over-correction. Forever-Rule says "default to dispatch" but if orchestrator NEVER asks Joshua, it eventually crosses an L48 boundary. Lane E proposes confidence-threshold escape:

**Spec:**
- Per-tick decision class has `authority` field: `data` (orchestrator decides) | `doctrine` (Joshua-asks always) | `hybrid` (data with confidence floor)
- `data` class with confidence < 0.6 → re-classify as AMBIGUOUS_TIE (deadline-halt)
- `doctrine` class always halts (L48, MONEY_PATH)
- `hybrid` class: data unless confidence < 0.6, then deadline-halt

**New bead:** `perp-counter-trauma-confidence-floor` (P1) — implements confidence threshold + re-classification logic

### A-2: Deadlock mitigations (4 named in Lane E)
1. **AMBIGUOUS_TIE on every tick:** mitigation = default-best-guess on timeout already in Lane C; reinforce: cap at 3 consecutive AMBIGUOUS_TIEs → escalate to NOVEL_DOMAIN auto-research
2. **NOVEL_DOMAIN recursion:** mitigation = depth-limit on auto-research (max 1 round); if novel-after-research → Joshua-halt
3. **HARD_BLOCKER cycle:** if unblock requires QUARANTINED worker pane → automatic upgrade to "session HARD_BLOCKER" (no new dispatches anywhere in session); Joshua-only escape
4. **MISSION_SUCCESS false-positive:** mitigation = sustained-validation gate K=6 across L=2 distinct sessions (already in Lane C); add: re-evaluate mission criteria on every tick post-HIT for 24h before celebrate-and-archive

**New bead:** `perp-deadlock-mitigations` (P1) — implements 4 specific mitigations as part of detector logic

### A-3: Doctrine-drift mitigation (Lane E §3)
Risk: future authors create L68/L69 with conflicting "pause" semantics, fragmenting halt classes.

**Spec:**
- L67's frontmatter must include `halt-classes-version: 1` field
- New halt class additions require fuckup-log → INCIDENTS → L-rule promotion ladder (CANNOT be freelance edit)
- L67 explicitly says "halt-class set is closed-form; extension requires promotion ladder"

**Folds into:** `perp-canonical-l67` bead acceptance criteria.

### A-4: 5 sister-plan collisions (from Lane D §6)
Lane D enumerates 5 specific collision points with pane-recovery plan:

| Collision | Resolution |
|---|---|
| C1: substrate-registry namespace | Both plans append to same JSONL; namespace by `owner` field (`pane-recovery-detector` vs `perpetual-progression-detector`) |
| C2: INCIDENTS.md edit collision | Sequence: pane-recovery's r3c0 lands FIRST (frozen-pane class, narrower scope); then perpetual's `perp-incidents-orchestrator-asked` (wider scope, may cite r3c0) |
| C3: AGENTS.md L-rule numbering | L48 + L66 exist; L67 reserved for perpetual-progression; pane-recovery doesn't add canonical L-rules (its INCIDENTS entries stay component-level) |
| C4: tick.md Step 5 priority | pane-recovery inserts RECOVER_PANE; perpetual inserts MISSION_SUCCESS, HARD_BLOCKER, AMBIGUOUS_TIE, NOVEL_DOMAIN. Combined ordering published in this REFINE |
| C5: pane-state.sh consumer signature | pane-recovery's contract changes pane class taxonomy; perpetual's detectors consume it. Compose works: perpetual READS pane class from pane-state.sh, doesn't CHANGE it |

**Combined Tick Step 5 priority (final):**
```
MISSION_SUCCESS (terminal halt, perpetual)
HARD_BLOCKER (halt, perpetual)
[L48_BINARY_MOD, MONEY_PATH] (Joshua-disposes)
SUBSTRATE_WARN
FLEET_REPAIR
LEARN_REVIEW
RECOVER_PANE (pane-recovery)
AMBIGUOUS_TIE (deadline-halt, perpetual)
NOVEL_DOMAIN (research-then-progress, perpetual)
DISPATCH_BEAD
DOCTRINE_HUNT
CROSS_REPO_SYNTH
IDLE_CLEAN (forbidden in doctrine tier)
```
13 priorities; both plans coordinate without contradiction.

### A-5: AMBIGUOUS_TIE offline-Joshua risk (Lane D §10)
Risk: Joshua offline for hours; 1-tick deadline expires; orchestrator picks data-best-guess for several decisions in a row; drift accumulates.

**Mitigation:**
- After 3 consecutive `auto_tiebreak` decisions in a session, escalate next AMBIGUOUS_TIE to HARD_BLOCKER (refuses progress, surfaces all 3 prior decisions for batch Joshua review on return)
- This caps drift at 3 decisions, not unbounded

**Folds into:** `perp-detector-ambiguous-tie` bead AC.

---

## 2. Bead DAG (final, post-AUDIT)

Adding 2 new beads from AUDIT:
- `perp-counter-trauma-confidence-floor` (P1, depends `perp-detector-ambiguous-tie`)
- `perp-deadlock-mitigations` (P1, depends 4 detectors + `perp-counter-trauma-confidence-floor`)

Updated bead list (14 total, was 12):

| Bead | Title | P | Deps |
|---|---|---|---|
| 1 | `perp-canonical-l67` | P0 | (root) |
| 2 | `perp-incidents-orchestrator-asked` | P1 | r3c0 (pane-recovery; sequence C2) |
| 3 | `perp-detector-mission-success` | P1 | l67 |
| 4 | `perp-detector-hard-blocker` | P1 | l67 |
| 5 | `perp-detector-ambiguous-tie` | P1 | l67 |
| 6 | `perp-detector-novel-domain` | P1 | l67 |
| 7 | `perp-counter-trauma-confidence-floor` | P1 | detector-ambiguous-tie |
| 8 | `perp-deadlock-mitigations` | P1 | detectors 3-6 + counter-trauma |
| 9 | `perp-tick-priority-update` | P1 | detectors 3-6 + counter-trauma |
| 10 | `perp-status-surface` | P2 | tick-priority-update |
| 11 | `perp-config-toml` | P2 | l67 |
| 12 | `perp-substrate-reg` | P2 | l67 |
| 13 | `perp-skill-update-flywheel-learn` | P2 | l67 + incidents |
| 14 | `perp-cross-link-recovery-plan` | P2 | (parallel; no deps) |

DAG: 0 cycles. Root: `perp-canonical-l67`. Parallel root: `perp-cross-link-recovery-plan`.

---

## 3. Carrying-forward ratified decisions from r1 (unchanged, post-AUDIT-validated)

D-RATIFIED-1 through D-RATIFIED-9 from r1 stay ratified; AUDIT did NOT invalidate any. Cross-cite each by AUDIT Lane:

| Decision | r1 | Lane D verdict | Lane E verdict |
|---|---|---|---|
| 6-class taxonomy | ratified | ratified (consistency table §5) | ratified (24 invariants checked) |
| Forever-Rule one-liner | ratified | ratified (§7 promotion audit) | ratified (bibliography integrity §8) |
| Tick Step 5 priority | ratified | ratified post-merge with pane-recovery (C4) | n/a |
| AMBIGUOUS_TIE deadline + 0.4 Hamming | ratified | n/a | extended (§5 confidence floor 0.6) |
| NOVEL_DOMAIN auto-research | ratified | ratified | ratified with depth-limit (deadlock #2) |
| Mission-success M=N, K=6, L=2 | ratified | ratified | extended (24h re-evaluate guard) |
| HARD_BLOCKER 2-of-4 | ratified | ratified | extended (cycle mitigation #3) |
| Forever-Rule → L67 | ratified | ratified (L67 confirmed unused) | extended (drift mitigation §3) |
| L-rule format | ratified | ratified | ratified |

**Net new ratifications from AUDIT (not r1):**
- D-RATIFIED-10: counter-trauma confidence-floor 0.6 (Lane E §5)
- D-RATIFIED-11: 4 deadlock mitigations (Lane E §2)
- D-RATIFIED-12: doctrine-drift via halt-classes-version=1 frontmatter (Lane E §3)
- D-RATIFIED-13: 5 sister-plan collision resolutions (Lane D §6, table above)
- D-RATIFIED-14: AMBIGUOUS_TIE 3-consecutive-cap → HARD_BLOCKER escalation (Lane D §10)

All 14 ratifications are data-driven. NO Joshua-blanket-asks.

---

## 4. Convergence delta tracking

| Metric | r1 | r2 | Delta |
|---|---|---|---|
| Open Joshua-disposes | 0 | 0 | 0 |
| Ratified decisions | 9 | 14 (+5) | AUDIT contributed; reinforcing not contradicting |
| Bead count | 12 | 14 (+2) | AUDIT-driven mitigations as separate beads |
| DAG cycles | 0 | 0 | — |
| Doctrine violations | 0 | 0 | — |
| Sister-plan collisions resolved | 0 | 5 | shared substrate now coordinated |

**Verdict:** r2 is final REFINE. AUDIT was reinforcing, not refuting. Convergence holds.

---

## 5. Compose with sister plan (FINAL spec)

Both plans run a coordinated wave during DECOMPOSE → execution:

### Wave 1 (foundation, parallel):
- pane-recovery: `flywheel-terc` (detector switch) + `flywheel-8xea` (recovery ledger)
- perpetual: `perp-canonical-l67` (Forever-Rule lands as canonical L-rule)
- Both: substrate-registry registrations (namespace by `owner`)

### Wave 2 (consumers, after Wave 1):
- pane-recovery: `flywheel-7xxs` + `flywheel-g5ak` (tick-3) + `flywheel-9t3l` (dispatch-update)
- perpetual: 4 detectors + counter-trauma + deadlock-mitigations

### Wave 3 (integration, after Wave 2):
- pane-recovery: `flywheel-7p0q` (tick-5) + `flywheel-u6ze` (tick-8 quarantine)
- perpetual: `perp-tick-priority-update` (insert all 6 halt classes into ordering)

### Wave 4 (surface + polish):
- pane-recovery: `flywheel-qywh` (status-surface)
- perpetual: `perp-status-surface` + `perp-skill-update-flywheel-learn`
- Both: INCIDENTS entries land sequenced (r3c0 first, then perp-incidents-orchestrator-asked, with cross-cites)

### Wave 5 (verification + soak):
- pane-recovery: `flywheel-6wwi` (synthetic E2E) + `flywheel-lf08` (rollout-gate)
- perpetual: post-soak monitoring of fp_rate on AMBIGUOUS_TIE / NOVEL_DOMAIN

This 5-wave structure prevents collision and lets both plans land cleanly.

---

## 6. Status: REFINE r2 → DECOMPOSE next; bead filing this turn

Phase plan progress:
- ✅ Phase 0 INTENT
- ✅ Phase 1 RESEARCH × 3 (1900 lines)
- ✅ Phase 2 REFINE r1 (9 ratified) + r2 (this doc; 14 ratified, 2 new beads, 5 sister collisions resolved)
- ✅ Phase 3 AUDIT × 2 (1462 lines)
- ⏳ Phase 4 DECOMPOSE — file 14 beads with explicit DAG
- Phase 5 POLISH — cross-cite each bead; finalize wave structure
- Phase 6 PROMOTE via /flywheel:learn → L67 + INCIDENTS entries

Next action: file 14 perpetual beads in br with explicit deps (DECOMPOSE phase).
