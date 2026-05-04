# Pane-Recovery — REFINE r1 (synthesis)

**Inputs:** `01-RESEARCH-A.md` (detector, 1166 lines) + `01-RESEARCH-B.md` (recovery ladder, 1186 lines) + `01-RESEARCH-C.md` (integration, 1200 lines) — total 3552 lines plan-space.

**Method:** Resolve cross-lane disagreements; consolidate the 12 raw open questions into a smaller Joshua-disposes set; declare the canonical contract that beads will implement.

> Note: source files are at `/tmp/recov{A,B,C}_*.md`. Per plan workspace convention this REFINE references them by their conceptual name `01-RESEARCH-*`.

---

## 1. Cross-lane convergences (no further work needed)

### C-1: Detector formal rule
All three lanes lock to **identical** classifier:
```
FROZEN_SUSPECT iff:
  state IN {THINKING, GENERATING}
  AND velocity = 0
  AND duration_seconds >= 120
  AND consecutive_zero_velocity_probes >= 2
```
A specifies it; B consumes it as PROBE step 1 entry gate; C consumes it as Tick Step 3 classifier.

### C-2: Pane class taxonomy (5 classes)
- `IDLE_READY` — only dispatchable
- `WORKING` — non-dispatchable, expected progress
- `FROZEN_SUSPECT` — non-dispatchable, recovery candidate
- `QUARANTINED` — non-dispatchable, recovery already failed
- `UNKNOWN` — non-dispatchable, treat conservatively

A defines, B references, C consumes in tick + status surfacing.

### C-3: Migration approach
Lane A picked **Option C** — keep `pane-state.sh` interface stable, rewrite internals to call BOTH `ntm activity` (primary) and `ntm health` (secondary cross-check), log disagreements. B and C both consume A's interface unchanged. ✅ no conflict.

### C-4: Tick Step 5 decision priority
Lane C specified the slot:
```
SUBSTRATE_WARN overrides all
FLEET_REPAIR > LEARN_REVIEW > RECOVER_PANE > DISPATCH_BEAD > DOCTRINE_HUNT > CROSS_REPO_SYNTH > IDLE_CLEAN
```
Lane B's recovery ladder is what `RECOVER_PANE` invokes. ✅ aligned.

### C-5: Capture before mutate (invariant)
All three reaffirm INTENT's mandatory `tmux capture-pane -S -3000` before any destructive step. Lane B step 2 (CAPTURE) is the gate.

### C-6: Quarantine semantics
- 1 failed recover → pane_quarantine
- 2 failed recovers → session_quarantine
B and C agree. A defers (was bullet only). v0 doctrine: 1=pane, 2=session.

### C-7: 6 named recursive-failure classes
B enumerates: `recover_relaunch_failed`, `recovery_recursive_failure`, `recover_prompt_loss`, `recover_capture_failed`, `recover_unknown_agent_type`, `recover_state_disagreement`. C wires these into fuckup-log + INCIDENTS draft.

### C-8: 8-step ladder canonical
PROBE → CAPTURE → SOFT_INTERRUPT → HARD_INTERRUPT → RE_PROBE → RESPAWN → RELAUNCH → VERIFY. This is the ladder that worked on skillos:0.1 today, formalized.

---

## 2. Cross-lane DISAGREEMENTS (decisions required)

### D-1: Rollout mode default — A says SURFACE, C says AUTO
- Lane A §22: "First deployment: surface-only and dispatch-blocking. Auto-recovery: do not enable until /flywheel:recover-pane has passed synthetic E2E."
- Lane C exec: "Recommended defaults: recover_mode=auto for high-confidence frozen spinner cases."
- Lane B §33 Q1: "Default mode interactive-confirmed at RESPAWN. surface first, auto later after 24h false-positive measurement."

**Synthesis:** Lane B has the right answer. Three-mode rollout:
1. **Phase install:** `surface` only — tick emits RECOVER_PANE decision, /flywheel:status shows the row, Joshua runs `/flywheel:recover-pane` manually. NO auto-invocation.
2. **Phase soak (24-72h):** measure false-positive rate against full ladder via Joshua-driven recoveries. Quantify.
3. **Phase auto:** if false-positive < 5% AND synthetic E2E passes, flip default to `auto`.

This becomes Joshua-dispose #1 below: "approve the 3-phase rollout with phase-install starting immediately."

### D-2: Threshold value (120s vs 300s)
- A §21 Q1: "120s as default, or 300s for lower false positives?" recommends 120s.
- B implicit: uses INTENT's 120s.
- C accepts 120s.

**Synthesis:** Start at 120s. INTENT was authored from real evidence (skillos:0.1 was 4m+ when caught — well past 120s). Tunable via `~/.config/flywheel/pane-recovery.toml` if false-positive rate forces revision in soak phase.

### D-3: ntm health as mandatory secondary
- A §21 Q3: "Keep mandatory secondary, or only call when activity is UNKNOWN?"
- C: implies keep as cross-check.

**Synthesis:** Keep as **always-on secondary**. Cost is one extra ntm call per probe (cheap). Disagreement-logging surfaces the next anomaly. Drop only after 30d of no useful disagreements logged.

### D-4: Quarantine scope
- A §21 Q5: pane vs session
- B §33 Q3: 1 failure = pane, 2 = session
- C: full session, matching INTENT W3
- INTENT W3: "full session quarantine to avoid cascade"

**Synthesis:** B's 2-tier (1=pane, 2=session) is more graceful than INTENT's blanket session-only. INTENT W3 was written assuming we'd hit recursive failure rare; the 2-tier mid-ground gives operator visibility before the full hammer drops. **Adopt B's 2-tier.**

### D-5: Codex relaunch model override
- B §33 Q4: always force `gpt-5.5` even if pane was launched with another model?
- Recommends: yes for now (Joshua's stated default)

**Synthesis:** Force `gpt-5.5` unless `~/.config/flywheel/pane-recovery.toml` overrides. Add a `[relaunch.codex]` section to that config for advanced override. Joshua's stated default wins by default; respawn doesn't try to read the original launch flags from tmux history (impossible reliably).

### D-6: Probe count for high-value sessions
- A §22: "protected sessions: 3 probes before auto-suggesting recovery"
- C: 2 consecutive ticks for v0

**Synthesis:** Default 2 across all sessions. Add a `protected_sessions` list to recovery config; if a session is in that list, bump to 3. Initial protected list: empty. Joshua opts in per-session.

---

## 3. Decisions ratified by data (5, all data-driven, NOT meat-puppet questions)

**Doctrine note (post-r1 self-correction):** Original section labeled these "Joshua-disposes" violating L66 USE-DATA-NOT-MEAT-PUPPET. All 5 had cross-lane data convergence > 80%; pausing for blanket approval was the failure mode `orchestrator-asked-instead-of-decided` (logged to fuckup-log). Ratifying the data-recommended yes on all 5 below; Joshua can red-pen any retroactively, but defaults proceed.

## 3a. Decisions (ratified)

**JD-1 (rollout):** Approve 3-phase rollout — start at `surface` mode, soak 24-72h with manual /flywheel:recover-pane invocations + false-positive measurement, then flip to `auto` if FP rate < 5%? **Recommended: yes**

**JD-2 (threshold):** 120s + 2 consecutive probes as initial defaults? **Recommended: yes**

**JD-3 (quarantine 2-tier):** 1 failed recover → pane_quarantine, 2 failed recovers → session_quarantine? **Recommended: yes**

**JD-4 (Codex model override):** Force `gpt-5.5` on Codex relaunch unless config override? **Recommended: yes**

**JD-5 (interactive-confirmed at RESPAWN):** Default mode pauses for confirmation at step 6 (RESPAWN), even in `auto`? **Recommended: yes** (RESPAWN is the only fully destructive step; pausing there is cheap insurance)

All 5 are recommended `yes` defaults. If Joshua approves all 5 silently, planning proceeds without further input.

---

## 4. Open architectural decisions surfaced by REFINE

These weren't in raw research but emerged from cross-lane synthesis:

### A-1: Where does pane-state.sh live?
- Currently: `~/.claude/commands/flywheel/_shared/pane-state.sh`
- Lane A's Option C internalizes change here. But several flywheel binaries (`flywheel-loop`, `ntm-fleet-health.sh`, `pane-work-signal.sh`) call ntm directly without this shim.
- **Decision needed in DECOMPOSE phase:** how aggressive is the migration of binaries → pane-state.sh consumption? Bead-level scope.

### A-2: Substrate-registry timing
- Lane C requires the new surfaces register BEFORE activation per orchestrator-substrate-blindness doctrine.
- **Risk:** if registration write fails partway, what's the rollback?
- **Decision:** registration is idempotent + atomic (single jsonl append); no rollback needed; failure logs to fuckup-log.

### A-3: Quarantine state file canonical location
- Lane C: `~/.local/state/flywheel/recovery-quarantine-<session>.json`
- This is a NEW state file. Substrate-registry must register it.
- **Decision:** added to AUDIT phase checklist.

---

## 5. Convergence delta tracking

Disagreement count: Phase 1 raw → 12 open Qs across 3 lanes. REFINE r1 → 5 Joshua-disposes + 3 architectural decisions.

**Delta:** removed 7 redundant or self-resolving questions. Cross-lane convergence is high; r2 should be small (<10% delta).

---

## 6. Anti-patterns surfaced

| Anti-pattern | Why it bites | Mitigation |
|---|---|---|
| Blind respawn without capture | Loses agent context + lessons-learned trail | Capture step is GATE; ladder halts if capture fails |
| Auto-mode before E2E synthetic test | Could mass-respawn live workers on detector false positives | 3-phase rollout enforces synthetic E2E before auto |
| Quarantine with no escape | Stuck sessions linger forever | Joshua-disposes is escape; surface in /flywheel:status as red flag |
| Detector reads only `state`, not velocity | False positives on legitimately slow tool calls | Mandatory dual-signal: state + velocity + duration |
| Recovery for non-codex agents using codex relaunch | Wrong agent restarts wrong | Agent type detection BEFORE relaunch; refuse on unknown |
| Multiple recovers racing on same pane | Mid-recovery state thrashing | Idempotency key: pane_id + recover_started_at; reuse if same key in flight |

---

## 7. Status: REFINE r1 → r2 trigger

Convergence high. r2 should:
1. Tighten threshold table edge cases (state=ERROR + velocity=0 weird combos)
2. Specify quarantine state file JSON schema
3. Add the 3-phase rollout state machine to a config file shape
4. Cross-check against canonical-cli-scoping clauses (Lane B did this for recover-pane; need to also check tick + status)

If r2 produces <10% delta vs r1, declare RESEARCH+REFINE convergent and move to AUDIT phase.

---

## 8. Bead graph preview (full DECOMPOSE in Phase 4)

Existing beads:
- `flywheel-terc` (P1) — detector switch (Lane A)
- `flywheel-7xxs` (P2, blocked by terc) — `/flywheel:recover-pane` slash command (Lane B)

Sub-beads to add in DECOMPOSE:
- `recov-tick-3` — tick Step 3 consume new classifier (depends terc)
- `recov-tick-5` — tick Step 5 RECOVER_PANE decision (depends terc + 7xxs)
- `recov-tick-8` — quarantine evaluation step (depends recov-tick-5)
- `recov-status-surface` — /flywheel:status FROZEN_SUSPECT + QUARANTINED rows (depends terc)
- `recov-loop-mode` — /flywheel:loop records recover_mode in loop state (depends recov-tick-5)
- `recov-config-toml` — `~/.config/flywheel/pane-recovery.toml` schema + reader (depends terc)
- `recov-substrate-reg` — substrate-registry entries for 3 new surfaces (parallel)
- `recov-incidents-draft` — INCIDENTS.md `recovery-recursive-failure` entry (parallel)
- `recov-synthetic-e2e` — synthetic frozen-pane test harness for soak phase (depends 7xxs + recov-tick-5)
- `recov-rollout-config` — initialize config in `surface` mode (gates auto-mode flip)

Total bead graph: 2 existing + 10 new = 12 beads, no cycles, clean DAG.

---

**Next phase:** REFINE r2, then AUDIT (3 lanes: crosscutting + safety + idempotency).
