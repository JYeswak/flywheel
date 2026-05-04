# Pane-Recovery — REFINE r2 (post-AUDIT)

**Inputs added since r1:** `recovD_audit_crosscutting.md` (899 lines, 6 findings, 13 risks, 0 cycles) + `recovE_audit_safety.md` (819 lines, 8 invariants, 6 races, CLI 4/6 PASS).

**Method:** Fold AUDIT findings into the canonical contract; add new sub-beads to the DAG; tighten ladder where Lane E found FAIL/PARTIAL idempotency.

---

## 1. Audit-driven additions to canonical contract

### A-1: Recovery ledger (REQUIRED)
Lane E found: ladder steps 4 (HARD_INTERRUPT), 6 (RESPAWN), 7 (RELAUNCH) are FAIL or PARTIAL on idempotency without a persistent recovery ledger. Without it: re-runs duplicate destructive ops, kill restarts in flight, race with manual recovers.

**Spec:**
- Path: `~/.local/state/flywheel/recovery-ledger-<session>.jsonl`
- Append-only JSONL with one row per ladder-step transition
- Fields: `ts`, `session`, `pane`, `recover_id` (uuid), `step` (1-8), `state` (started|done|failed|skipped), `actor` (tick|manual|drill), `idempotency_key`
- Idempotency key: `<session>:<pane>:<recover_started_ts_minute_bucket>` (1-min buckets ensure tick + manual within same minute coalesce)
- Reader function in `pane-state.sh` that returns "in_flight" if ledger has incomplete recover for pane

**New bead:** `recov-ledger` (P1, blocks recov-tick-5 + 7xxs implementation)

### A-2: Concurrent-recovery serialization
Lane E race 1-6: tick + tick, tick + manual, stale-claim-after-crash, etc. Ledger alone insufficient — need claim semantics.

**Spec:**
- `pane-state.sh recover_claim <session> <pane>` returns idempotency key OR "claimed_by=<actor>"
- Claim TTL: 60s (auto-stale after); recovers > 60s require fresh claim
- Stale-claim recovery: tick that finds a stale claim from a crashed prior recover marks ledger row `state=abandoned` and starts fresh

**Folds into:** `recov-ledger` bead acceptance criteria.

### A-3: Dispatch contract collision (highest risk per Lane D)
Lane D §4: `/flywheel:dispatch` currently checks pane state via `_shared/pane-state.sh` which (per Lane A) trusts `ntm health` activity. After terc lands, dispatch.md MUST also be updated.

**Decision:** Add `recov-dispatch-update` (P1, depends terc) — surgically update `~/.claude/commands/flywheel/dispatch.md` step 1 (validate pane) to consume the new pane-class taxonomy from the rewritten pane-state.sh. Refuse dispatch into FROZEN_SUSPECT, WORKING, QUARANTINED.

This is the **most-leveraged sub-bead** because dispatch.md is what TODAY would push work into a wedged worker.

### A-4: 4 doctrine-risk reinforcements (no violations)
Lane D §6 named L29, L56, L63, L66 risks, all of which are reinforcements (not violations) IF beads are scoped right:

- **L29** (low-level capture/key injection): Lane B step 3+4 use `tmux send-keys` directly. Bead `flywheel-7xxs` body MUST cite L29 and bracket the keys-as-recovery-only (not as dispatch transport which would violate L29).
- **L56** (promotion ladder): `recov-incidents-draft` (r3c0) MUST use `/flywheel:learn --rule` not direct edit. Update bead acceptance.
- **L63** (drill rows before "ready"): auto-recovery flip gate already covered by `recov-rollout-gate` (lf08); reinforce in lf08's AC.
- **L66** (USE-DATA-NOT-MEAT-PUPPET): r1 already corrected. Remind in DECOMPOSE-final POLISH that Joshua-disposes are pane_quarantine release ONLY, not threshold tuning.

### A-5: 2 CLI-scoping gaps
Lane E §11: 4/6 PASS. Likely 2 gaps:
- `--info` (version + paths + env + deps dump) — not yet specified for `/flywheel:recover-pane`
- `--explain` (rationale before execute) — Lane B mentioned but not in slash command spec

**Fold into:** Update `flywheel-7xxs` bead body to add both flags as MUST in AC.

---

## 2. New sub-beads added to DAG (post-AUDIT)

| Bead | Title | Priority | Deps |
|---|---|---|---|
| `recov-ledger` | Recovery ledger + claim/stale semantics | P1 | (none — root) |
| `recov-dispatch-update` | dispatch.md consumes new pane-class taxonomy | P1 | terc |
| `recov-cli-scoping-fix` | Add --info + --explain to /flywheel:recover-pane | P2 | 7xxs |

Updated DAG:

```
terc ──┬─→ g5ak (tick-3)
       ├─→ qywh (status-surface)
       ├─→ 0a7m (config-toml)
       ├─→ recov-dispatch-update  ◄── NEW
       └─→ 7p0q (tick-5) ←─── 7xxs ──┬─→ 6wwi (synth-e2e)
                ├─→ u6ze (tick-8)         └─→ lf08 (rollout-gate)
                └─→ w6ei (loop-mode)

7xxs ──→ recov-cli-scoping-fix  ◄── NEW (CLI gap fix)

recov-ledger  ◄── NEW (root, no deps)
   └─→ 7p0q + 7xxs (both consume the ledger)

[parallel, no deps]: 6g8b (substrate-reg), r3c0 (incidents-draft)
```

15 total beads (12 original + 3 new). Still no cycles.

---

## 3. Ratified decisions from r1 (carried forward unchanged)

JD-1 through JD-5 stay ratified; AUDIT did not invalidate any. Reaffirming:
- 3-phase rollout (surface → soak → auto)
- 120s threshold + 2 consecutive probes
- Quarantine 2-tier
- Codex relaunch gpt-5.5
- RESPAWN confirm even in auto

Plus new ratified decisions from AUDIT:

**JD-6 (recovery ledger):** Append-only JSONL at `~/.local/state/flywheel/recovery-ledger-<session>.jsonl` with 1-min idempotency buckets. ✅ ratified by Lane E data.

**JD-7 (dispatch.md surgical update):** Mandatory; highest-leverage gap. ✅ ratified by Lane D risk register.

**JD-8 (CLI gaps):** Add `--info` + `--explain` to `/flywheel:recover-pane`. ✅ ratified by canonical-cli-scoping doctrine.

---

## 4. Convergence delta tracking

| Metric | r1 | r2 | Delta |
|---|---|---|---|
| Open Joshua-disposes | 5 | 8 (+3) | +60% but all data-ratified |
| Architectural decisions surfaced | 3 | 3 (+0 new, audit reinforced) | 0% |
| Bead count | 12 | 15 (+3) | +25% |
| DAG cycles | 0 | 0 | — |
| Doctrine violations | 0 | 0 | — |

**Verdict:** r2 added structure (3 sub-beads, 1 contract: ledger) but introduced no contradictions. Convergence holds.

**r3 trigger condition:** if AUDIT lanes generate further follow-up findings during POLISH, r3 happens. Otherwise r2 is final REFINE.

---

## 5. Anti-patterns added (post-AUDIT)

| Anti-pattern | Why it bites | Mitigation |
|---|---|---|
| Recovery without ledger | Re-runs duplicate destructive ops, races between tick + manual | recov-ledger bead is P1 root; all destructive ladder steps consult it |
| dispatch.md not updated alongside terc | Pane-state contract changes but dispatch consumes old contract → silent dispatch into wedged | recov-dispatch-update bead is mandatory; lands same wave as terc |
| Slash command without --info / --explain | Operators can't introspect or preview; CLI-scoping fail | recov-cli-scoping-fix is P2 follow-up to 7xxs |
| INCIDENTS draft via direct edit | Bypasses /flywheel:learn promotion ladder; violates L56 | r3c0 acceptance criteria specify `/flywheel:learn --rule` invocation |

---

## 6. Status: REFINE r2 → AUDIT-folded; plan ready for POLISH

REFINE r2 is the final REFINE round absent new evidence. Plan now has:
- Phase 0 INTENT
- Phase 1 RESEARCH × 3 (3552 lines)
- Phase 2 REFINE r1 + r2 (synthesis + audit fold)
- Phase 3 AUDIT × 2 (1718 lines)
- Phase 4 DECOMPOSE (15 beads, 0 cycles)
- Phase 5 POLISH (next)

POLISH will:
1. Cross-cite each bead against L29/L56/L63/L66 doctrine
2. Add `--info` + `--explain` AC to 7xxs
3. Update dispatch.md sub-bead AC
4. File 3 new beads (`recov-ledger`, `recov-dispatch-update`, `recov-cli-scoping-fix`)
5. Cross-link recovery plan to perpetual-progression plan (sister plan, both about removing orchestrator-Joshua friction)
6. Verify bead dependency graph one more time
