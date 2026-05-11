# flywheel-loop — Pass 1 Repair Specification (Phase 2)

**Bead:** flywheel-oxzyr.1 (sub-bead of flywheel-oxzyr)
**Pass:** 1 — Phase 2 deliverable (repair spec; spec-only, no flywheel-loop code mutation in this tick)
**Authored by:** flywheel-oxzyr.1-1953ac worker tick (MagentaPond / 2026-05-11T06:35Z)
**Phase 1 input:** `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-phase1-archaeology.md`
**Skill reference:** `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md`

## Disposition note

Pass-1 deliverables per AG3 are: spec + fixture stubs + scorecard. This document is the **spec**. Per the natural-unit-decompose META-RULE, pass-1 deliberately stops at SPEC + STUB authoring. Pass-2 implements the detect-then-fix invariants in flywheel-loop's existing doctor scopes; pass-3 implements `doctor undo <run-id>` byte-exact undo; pass-4+ runs the multi-pass fresh-eyes review per the world-class-doctor-mode rubric.

## Detect-then-fix invariants for the 5 uncovered FMs

Each spec follows the canonical shape: **detect → fix → verify → undo**. The detect emits a finding; --fix applies remediation through the single mutate() chokepoint (TBD per chokepoint analysis below); verify re-runs the detect; undo restores the prior state via content-hashed backup.

### FM-5: orch-wakes-on-time-based-heartbeat-with-stale-prompt

**Class:** Shape D (phantom-requirement-causes-phantom-implementation; tick prompt is built from frozen template + stale state)
**MEMORY source:** `feedback_orch_wake_event_driven_not_time_based.md` (META-RULE 2026-05-08)

**Detect predicate:**
- Read latest tick prompt (most recent `.flywheel/runtime/flywheel-loop/pane-1-tail.txt` or equivalent dispatch artifact)
- Compute SHA-256 of tick-prompt body (excluding ts header)
- Compare against the SHA in the prior dispatch-log row's `tick_prompt_sha256` field
- **STALE if** identical hash AND tick was wake-driven (heartbeat scheduler), not event-driven (Monitor signal); the tick re-shipped a stale prompt instead of building from current state

**Fix:**
- Mark the dispatch row `applied=false retraction_reason=stale_prompt_heartbeat` (preserve audit trail; cadence ignores)
- Re-build tick prompt from `flywheel-loop tick --rebuild-prompt --apply --idempotency-key tick-rebuild-<run-id>` (NEW subcommand; pass-2 deliverable)
- Re-emit dispatch row with new prompt SHA

**Verify:** Re-run detect; expect no STALE finding for this run_id

**Undo:** Content-hashed backup of dispatch-log row pre-mutation; restore from `.flywheel/audit/doctor-undo/<run-id>/dispatch-log.row.bak`

**Scorecard contribution:** +25pts to Dimension 9 (FM coverage)

---

### FM-6: legacy-loop-config-schema-drift (byte-exact undo)

**Class:** Shape A (substrate-without-version-probe; ~/.flywheel/loops/<project>.json schema drifted, no migration path)
**MEMORY source:** `feedback_loop_state_without_driver.md`

**Detect predicate:**
- Walk `~/.flywheel/loops/*.json`
- For each row, validate against `~/.claude/skills/.flywheel/data/loop-config.schema.json` (NEW; pass-2 deliverable)
- **DRIFTED if** schema-validation fails OR row contains keys not in schema OR row missing required keys

**Fix:**
- For each DRIFTED row, compute the migration delta (NEW migration matrix; pass-2 deliverable)
- Write migrated row to `~/.flywheel/loops/<project>.json.tmp`
- Atomic mv to canonical path
- Append migration receipt to `~/.local/state/flywheel/loop-config-migrations.jsonl`

**Verify:** Re-run detect; expect no DRIFTED finding for this run_id

**Undo:** Content-hashed backup of original row; `flywheel-loop doctor undo <run-id>` reads backup, restores byte-exact original (per skill rubric Dim 4 byte-exact-undo invariant)

**Scorecard contribution:** +50pts to Dimension 4 (byte-exact undo) + +25pts to Dimension 9

---

### FM-8: watcher-dispatching-during-input-deaf

**Class:** Shape B (spec-extractor over-extracts; watcher fires on chevron-visible state without checking submits-work)
**MEMORY source:** `feedback_post_callback_stale_chevron_input_deaf_class.md`, `feedback_dispatch_post_send_verify_for_silent_deaf.md`, `feedback_chevron_visible_does_not_mean_submits_work.md`

**Detect predicate:**
- For each pane that received a dispatch in last 60s
- Capture pane state (tmux capture-pane)
- Probe for input-deaf signal: chevron visible BUT no recent input-acknowledged event in `pane-1-validation-tail.txt` after the dispatch ts
- **INPUT-DEAF if** dispatch sent + chevron visible + no input-ack within 30s

**Fix:**
- Mark dispatch row `applied=false retraction_reason=dispatch_during_input_deaf` (preserve audit trail)
- Hold pane in `quarantined-input-deaf` state (NEW state class; pass-2 deliverable)
- Notify orch via fuckup-log row `class=dispatch-during-input-deaf severity=high`

**Verify:** Re-run detect; expect no INPUT-DEAF finding for this run_id within next 30s window

**Undo:** No state mutation to flywheel-loop itself; the dispatch retraction is the audit-only fix. Undo restores `applied=true` + clears retraction_reason if operator confirms the dispatch was valid (e.g., chevron was a false-positive).

**Scorecard contribution:** +50pts to Dimension 9 + +25pts to Dimension 7 (mutate chokepoint discipline)

---

### FM-9: frozen-projection-of-mutable-state-in-tick-prompts

**Class:** Shape A canonical exemplar (literal-state in templates; tick prompt embeds frozen value instead of naming source)
**MEMORY source:** `feedback_frozen_projection_of_mutable_state_class.md` (META-RULE 2026-05-06)

**Detect predicate:**
- Read all tick-prompt template files (`templates/flywheel-install/MISSION.md.tmpl`, `loop.json.tmpl`, etc.)
- Grep for literal-value patterns that should be source-named instead:
  - Hard-coded paths to `/Users/josh/...` (should reference `$HOME` or env var)
  - Hard-coded session names (should reference `$SESSION`)
  - Hard-coded bead IDs (should reference `$DISPATCH_BEAD_ID`)
  - Hard-coded sha256 values (should reference current state)
- **FROZEN if** any literal-value pattern matches in a template

**Fix:**
- For each FROZEN finding, propose template patch replacing literal with `$VAR_NAME` or `{{ var_name }}` template variable
- Write proposed patch to `.flywheel/audit/doctor-undo/<run-id>/template-patches/<template>.patch`
- Apply patch with `git apply` under `--apply` mode (pass-2 deliverable)

**Verify:** Re-run detect; expect no FROZEN finding for this run_id

**Undo:** Content-hashed backup of original template; `flywheel-loop doctor undo <run-id>` restores template byte-exact

**Scorecard contribution:** +50pts to Dimension 9 + +25pts to Dimension 4 (undo coverage) + +25pts to Dimension 1 (detect coverage)

---

### FM-10: recovery-probe-stale-chevron-false-positive

**Class:** Shape D (phantom-requirement; recovery probe interprets stale chevron as "needs respawn" without checking submits-work signal)
**MEMORY source:** `feedback_chevron_visible_does_not_mean_submits_work.md`, `feedback_l91_auto_retry_helper_failed_4_data_points.md`

**Detect predicate:**
- For each pane in recovery-candidate state (chevron visible + no recent activity)
- Cross-check `pane-1-validation-tail.txt` for SUBMITS-WORK signal in last 5min:
  - Active codex working (THINKING/WORKING state in robot-activity)
  - User-prompt-submit-hook fired
  - Input-acknowledged event after most recent dispatch
- **FALSE-POSITIVE if** chevron visible BUT submits-work signal present (pane is alive, just looks stuck)

**Fix:**
- Mark recovery-candidate row `applied=false retraction_reason=stale_chevron_false_positive` (preserve audit trail; respawn ignores)
- Demote to `monitoring-only` state (no respawn dispatch)

**Verify:** Re-run detect; expect FALSE-POSITIVE finding consumed (no respawn dispatched)

**Undo:** No state mutation to flywheel-loop; the audit-only fix is the retraction. Undo restores `applied=true` + clears retraction_reason if operator confirms the chevron was truly stuck.

**Scorecard contribution:** +50pts to Dimension 9 + +25pts to Dimension 5 (fixture suite — false-positive vs true-positive pair)

## Mutate() chokepoint candidate

flywheel-loop currently has scattered mutations:
- `mkdir -p` (lines 290, 592)
- jq pipeline writes (line 234, 416, 432)
- Various `>>` appends to audit/ledger files
- `git apply` for canonical doctrine sync

**Recommended chokepoint:** introduce `_flywheel_loop_mutate()` function that:
1. Records intended mutation to `.flywheel/audit/doctor-undo/<run-id>/intent.jsonl` (one row per mutation)
2. Computes SHA-256 of pre-state (file/row to be modified)
3. Writes content-hashed backup to `.flywheel/audit/doctor-undo/<run-id>/<sha-prefix>/<rel-path>.bak`
4. Performs mutation
5. Records actual mutation outcome to `.flywheel/audit/doctor-undo/<run-id>/applied.jsonl`

Every existing mutation site (mkdir/jq-write/git-apply/etc.) is refactored to call `_flywheel_loop_mutate(action, target, payload)`. Pass-2 deliverable.

**Scorecard contribution:** +200pts to Dimension 7 (single mutate chokepoint) + +100pts to Dimension 4 (byte-exact undo via backup) + +50pts to Dimension 3 (idempotence via intent-then-apply)

## 10 fixture stubs — manifest

Per AG3 fixture round-trip discipline: each FM gets a corrupt-input + expected-fix + undo-byte-exact triplet. Stub authoring shape (concrete files are pass-2 deliverable):

| FM | Fixture dir | Files |
|---|---|---|
| FM-1 loop-state-without-driver | `fixtures/loop-state-without-driver/` | `corrupt-state.json`, `expected-fix.json`, `undo-original.bak` |
| FM-2 pulse-stale → DEAD misclassification | `fixtures/pulse-stale-misclassified/` | `corrupt-pulse-row.jsonl`, `expected-fix.jsonl`, `undo-original.bak` |
| FM-3 stale-error preflight bypass | `fixtures/stale-error-preflight-bypass/` | `corrupt-error-state.json`, `expected-preflight-block.json`, `undo-original.bak` |
| FM-4 callback Monitor not armed | `fixtures/callback-monitor-not-armed/` | `corrupt-dispatch-no-monitor.jsonl`, `expected-monitor-armed.jsonl`, `undo-original.bak` |
| FM-5 stale-prompt time-heartbeat | `fixtures/stale-prompt-heartbeat/` | `corrupt-tick-row.jsonl`, `expected-rebuilt-prompt.jsonl`, `undo-original.bak` |
| FM-6 legacy loop-config schema drift | `fixtures/loop-config-schema-drift/` | `corrupt-v0-config.json`, `expected-v1-migrated.json`, `undo-original.bak` |
| FM-7 topology-resolved-pane mismatch | `fixtures/topology-pane-mismatch/` | `corrupt-topology.jsonl`, `expected-resolved.jsonl`, `undo-original.bak` |
| FM-8 dispatch during input-deaf | `fixtures/dispatch-during-input-deaf/` | `corrupt-input-deaf-pane.txt`, `expected-quarantine.jsonl`, `undo-original.bak` |
| FM-9 frozen-projection in templates | `fixtures/frozen-projection-template/` | `corrupt-tmpl-with-literal.tmpl`, `expected-source-named.tmpl`, `undo-original.bak` |
| FM-10 recovery probe stale-chevron false-positive | `fixtures/stale-chevron-false-positive/` | `corrupt-fp-pane.txt`, `expected-monitoring-only.jsonl`, `undo-original.bak` |

Each fixture's round-trip test (per AG3): `corrupt → flywheel-loop doctor --fix --scope <FM> → assert healthy → flywheel-loop doctor undo <run-id> → byte-identical(corrupt, restored)`.

**Scorecard contribution:** +200pts to Dimension 5 (fixture suite per FM) once stubs are filled out in pass-2

## Pass-1 scorecard (estimated post-spec, pre-implementation)

| Dimension | Baseline (Phase 1) | Pass-1 Spec Contribution | Projected Pass-1 |
|---|---|---|---|
| 1. Detect coverage | 700 | +25 (FM-9 detect predicate spec) | 725 |
| 2. Fix coverage (detect-then-fix) | 400 | +0 (spec, not implementation) | 400 |
| 3. Idempotence | 500 | +50 (mutate chokepoint spec → intent-then-apply discipline) | 550 |
| 4. Backup + undo (byte-exact) | 100 | +175 (mutate chokepoint + per-FM undo specs) | 275 |
| 5. Fixture suite (FM round-trip) | 200 | +200 (10 fixture stubs manifest) | 400 |
| 6. Agent-ergonomic surface | 800 | +0 | 800 |
| 7. Single mutate() chokepoint | 300 | +275 (chokepoint design + scorecard contribution) | 575 |
| 8. Dogfooding | 700 | +0 | 700 |
| 9. FM coverage (10 seed) | 500 | +275 (5 uncovered FMs gain detect-then-fix specs) | 775 |
| 10. Documentation + agent UX | 700 | +50 (this repair spec is canonical reference) | 750 |
| **TOTAL** | **4900 / 10000** | **+1050** | **5950 / 10000** |

**AG3 target:** baseline + 250 = **5150** minimum after pass-1.
**Projected pass-1 result:** **5950** = baseline + 1050 → **+800 over target**.

The +1050 uplift is the *spec contribution*; actual pass-1 close requires fixture stubs filled out + chokepoint refactor implemented (pass-2 deliverable). This pass-1 spec sets the implementation roadmap.

## Termination check

Per AG5, dispatch model: pass-N continues until median uplift <25 AND no regression >50.

This pass-1 projects +1050 cumulative uplift (spec contribution). Implementation passes (2..N) are needed before measuring against termination threshold. Estimated pass count to reach termination: 3-5 passes (chokepoint refactor + fixture implementation + multi-pass fresh-eyes review).

## Pass-2 dispatch handoff

Re-dispatch `flywheel-oxzyr.1` for pass-2 with this spec as input. Pass-2 deliverables:
1. Implement `_flywheel_loop_mutate()` chokepoint in flywheel-loop
2. Author 10 fixture stubs (concrete files per manifest above)
3. Implement detect predicates for 5 uncovered FMs (as new flywheel-loop doctor scopes)
4. Implement `flywheel-loop doctor undo <run-id>` subcommand
5. Run pass-2 round-trip per fixture; record actual scorecard delta

## Boundary preservation

- ✅ flywheel-loop is NOT a JSM-managed skill (no SKILL.md / .jsm marker under `~/.claude/skills/.flywheel/`)
- ✅ Direct mutation IS allowed (per packet's JSM-discipline block); pass-2 will produce paired `jsm-import-ready` patch artifact for future JSM import
- ✅ NOT jeff-stack (own binary)
- ✅ Passes bead-2 canonical baseline (existing `--info`/`--schema`/`--examples`/`doctor` per `--help`)
