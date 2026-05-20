# Joint Codesign Packet — Codex /goal-mode Runtime Enforcement

**To:** Joshua
**From:** skillos:1 + flywheel:1 (joint signatures)
**ts:** 2026-05-20T00:20Z
**ratification gate:** single Joshua-approval covers all components below
**block:** both skillos + flywheel codex panes stalled pending T1 ratification

---

## TL;DR

Your rule 2026-05-20T00:05Z: codex workers must enter /goal mode AND accumulate runtime in pane — dispatch-time prefix alone is insufficient. Current czwpu enforcement (commit 3985ff59 skillos / 7f244a2f flywheel) only checks SYNTAX (prefix character match). Your rule requires SEMANTICS (mode actually entered + runtime visible).

This packet proposes a **4-layer enforcement** + **5 canonical trauma classes** + **8-state pane-work-signal taxonomy** + **ownership split** + **T1+96h+1wk timeline**. Single ratification covers all.

---

## 1. The Rule (Joshua-direct quote)

> "codex workers now ONLY get disptached using /goal <task> format - if they aren't racking up on their goal, persueing goal in their pane, its done wrong - this is a new requirement - let skillos know and figure out how to ensrue that this new rule is baked across our ecosystems."

---

## 2. The Gap

Current enforcement (Layer 1 — czwpu hook, LIVE):

```
PreToolUse Bash → matches ntm send --pane=N codex
  → first line of --file/--text starts with /goal ?
    PASS or BLOCK
```

Insufficient because: a prefix-correct dispatch CAN land into a codex pane that immediately enters `Goal paused (/goal resume)` state or never enters Goal-box state at all. Layer 1 = syntax check; your rule = semantic check.

**Evidence:**
- flywheel post-azvz9 close: pane showed `Goal paused (/goal resume)` despite prefix-correct dispatch
- skillos post-callback ghost-hang series 22:15Z + 22:48Z + 22:55Z (closed as skillos-fqtw4): background-terminal-wait state with no Goal-box accumulator

---

## 3. 4-Layer Enforcement Design

| Layer | Enforces | Status | Owner |
|---|---|---|---|
| 1. Dispatch-time prefix | `/goal ` on first line | ✓ LIVE (czwpu hook) | flywheel:1 (no change) |
| 2. Mode-entry verification | within 30s post-dispatch, pane shows `Goal in progress` | NEW | flywheel:1 (polling probe) |
| 3. Mode-persistence monitoring | every 60s while in-flight, pane stays in Goal-in-progress + runtime accumulating | NEW | flywheel:1 (polling probe) |
| 4. Mode-exit alarm | callback received only if pane transitioned through Goal-in-progress | NEW | flywheel:1 (polling probe) |

Layer 1 stays unchanged. Layers 2-4 are NEW polling-probe primitive integrated into `/flywheel:dispatch`.

---

## 4. 5 Trauma Classes (canonical taxonomy)

| # | Class | Trigger | Remediation |
|---|---|---|---|
| 1 | `codex-goal-entry-failed` | Layer 2 detects no Goal-in-progress within 30s post-dispatch | re-poke, then respawn if 2 failures |
| 2 | `codex-goal-abandoned` | Layer 3 detects mode-regression (Goal paused / idle-chat) without callback | operator-resume or respawn |
| 3 | `codex-goal-mode-bypassed` | Layer 4 detects callback received but pane never showed Goal-in-progress | flag as Joshua-rule violation; bead with evidence |
| 4 | `codex-goal-resume-stuck` | Goal paused for >120s without auto-resume | empty submit-poke; respawn on 2 fails |
| 5 | `codex-goal-mode-flapping` | ≥3 entry↔pause transitions within one dispatch | prompt-structure refactor (indicates bad prompt, not bad codex) |

Canonical home: `.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md` on skillos with flywheel canonical-doctrine sync.

---

## 5. 8-State pane-work-signal Taxonomy (v0.2)

| State | Detection text regex / pattern | Layer-monitor behavior |
|---|---|---|
| `goal-in-progress` | `Worked for ([0-9]+m [0-9]+s)` AND no `Goal paused` AND visible Goal box | Layer 3 PASS |
| `goal-paused` | `Goal paused (/goal resume)` literal | Layer 3 FAIL after 120s → fires class 4 |
| `goal-completing` | callback-fire → Goal-box-clear (transient 2-5s) | Layer 2/3 SUPPRESS (false-fire trap) |
| `goal-completed` | `Goal completed` literal | terminal-state, transitions to Layer 4 |
| `idle-chat` | prompt-only, no Goal box, no Working line | Layer 2 FAIL → fires class 1; or class 3 if callback already received |
| `working-non-goal` | `Working ([0-9]+s • esc to interrupt)` AND no Goal box | Layer 3 FAIL → fires class 3 (RED FLAG — Joshua-rule violation) |
| `error-state` | codex error/exception text + no Goal box | distinct handler; not Layer-2/3 fire |
| `respawn-residue` | <15s post-respawn window | SUPPRESS all classifiers (stale scrollback class per existing memory) |

Spec home: `.flywheel/specs/pane-work-signal-taxonomy-v0.2.md` on skillos. Reference shell impl ships alongside.

---

## 6. Ownership Split

| Component | Owner | Lane |
|---|---|---|
| pane-work-signal taxonomy v0.2 spec + reference impl | **skillos:1** | canonical-detector |
| 5 trauma class canonical taxonomy doctrine | **skillos:1** | canonical-doctrine |
| Polling probe primitive (Layer 2/3/4) | **flywheel:1** | dispatch-surface |
| `/flywheel:dispatch` integration | **flywheel:1** | dispatch-surface |
| Fleet propagation across 8 orchs | **skillos:1** then **flywheel:1** dogfood | canonical-locator |
| `codex-goal-mode-discipline.md` doctrine | **skillos:1** | canonical-doctrine |
| Bypass / override hatch (env var + audit ledger) | **flywheel:1** authors + **skillos:1** canonicalizes | typical pattern |

---

## 7. Timeline (T1 = your ratification timestamp)

| Phase | Owner | Deliverable | Window |
|---|---|---|---|
| T1+0..T1+24h | skillos | pane-work-signal v0.2 spec + reference impl | 24h |
| T1+0..T1+24h | skillos | 5 trauma class canonical taxonomy doctrine | 24h |
| T1+0..T1+24h | flywheel | polling probe primitive + `/flywheel:dispatch` integration | 24h |
| T1+24h..T1+48h | flywheel | dogfood on flywheel session — 3 dispatch types (deep-work + quick-fix + multi-bead-sprint) | 48h |
| T1+48h..T1+72h | skillos | fleet propagation to 8 orchs | 72h |
| T1+72h..T1+96h | flywheel | dogfood validation across propagated fleet; file any class-divergence findings | 96h |
| T1+96h+ | joint | promote `codex-goal-mode-discipline.md` to MP-NN candidate at next mp-authoring-cadence window | 1wk+ |

---

## 8. Halt Coordination During Ratification Window

**flywheel + skillos codex panes:** STALLED for new dispatches until T1. Current in-flight dispatches finish naturally (skillos pane 2 jsm-recovery-tier6-cache + pane 3 disk-cleanup-halt-lift-1 — both /goal-prefixed + Goal-in-progress confirmed).

**Other 6 orchs (mobile-eats, picoz, clutterfreespaces, alps, vrtx, terratitle/marty):**

Joint recommendation: **option (b) — per-orch dispatch-throttle with explicit Joshua-permitted exemption.**

- 6 orchs continue dispatching but throttle to low-risk work (single-bead, no multi-pane coordination)
- ANY goal-mode failure observed during ratification window MUST be logged to `~/.local/state/flywheel/codex-goal-mode-ratification-evidence.jsonl` for L160-class evidence corpus
- Post-T1, fleet-wide propagation locks all 8 orchs to Layer 2/3/4 enforcement

Rationale: option (a) fleet-wide halt freezes 6 orchs for ≥24h of paper-only work which is excessive blast-radius given the rule is well-defined and the 4-layer design is paper-ready. Option (b) preserves throughput while building the evidence corpus.

---

## 9. What This Does NOT Change

- Layer 1 czwpu hook stays as-is (no contract surface change)
- Claude / CC pane dispatches unaffected (rule is codex-specific)
- Existing dispatches that already passed Layer 1 + completed callback are NOT retroactively audited
- Bypass override hatch (`CODEX_GOAL_FORMAT_BYPASS=<reason>`) extended to also bypass Layer 2-4 with same audit-ledger requirement (single hatch, not separate per layer)

---

## 10. Implementation Specs Already Drafted (paper-only, pre-ratification)

For your visibility — these are the flywheel-side implementation artifacts the polling probe will be built from. **Reading them is OPTIONAL for ratification** (they elaborate the Section 3-4 design; no new contract surface):

- `.flywheel/specs/codex-goal-mode-monitor-probe.md` — Layer 2/3/4 probe primitive spec (flags, layer semantics, trauma envelope JSON, /flywheel:dispatch integration, 4 open implementation Qs)
- `.flywheel/specs/codex-goal-mode-bypass-design.md` — bypass hatch design (4 bypass classes, audit ledger schema, anti-abuse properties, 4 open implementation Qs)

Implementation Qs in those specs are resolved during T1+0..T1+24h work, not blocking ratification.

---

## 11. Ratification Request

Single Joshua-approval covers:

- ✓ 4-layer enforcement design
- ✓ 5 trauma classes (canonical names + triggers)
- ✓ 8-state pane-work-signal taxonomy (state names + detection patterns)
- ✓ Ownership split (skillos vs flywheel components)
- ✓ T1+96h+1wk timeline
- ✓ Option (b) halt coordination during ratification window
- ✓ Bypass override hatch extension

**To approve:** reply with "RATIFY codex-goal-mode-4layer T1=<your timestamp>" or equivalent.

**To modify:** flag specific section(s); both orchs hold ratification until revised packet returned.

---

**Signatures:**

- ✓ **skillos:1** — author + canonical-doctrine lane — signed 2026-05-20T00:18Z
- ✓ **flywheel:1** — reviewer + dispatch-surface lane — signed 2026-05-20T00:20Z

Both signatures recorded. Joint Joshua-direct submission via flywheel:1 active chat at 2026-05-20T00:20Z.
