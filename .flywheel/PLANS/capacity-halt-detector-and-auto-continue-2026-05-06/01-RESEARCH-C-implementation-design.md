# Phase 1 Lane C - Implementation Design

Plan arc: `capacity-halt-detector-and-auto-continue-recovery`.
Scope: plan-space only; this is not a code patch.

## Source-(a) And Survey Inputs

- Skills: `planning-workflow`, `research-triad`, `codebase-archaeology`, `jeff-convergence-audit`, `donella-meadows-systems-thinking`, `codex-cli-tracker`, `loop-enforcement`, `accretive-cron-orchestration`, `observability-platform`, `socraticode`.
- Evidence rows: `fuckup-log#L1544`, `#L1575`, `#L1579`, `#L1619`, `#L1620`.
- Socraticode survey count: 10.

## SKILL.md Draft

```markdown
---
name: codex-capacity-halt-recovery
description: Detect Codex upstream "selected model is at capacity" halts and recover worker panes with bounded in-place continue before respawn or notification.
---

Use when a Codex pane shows upstream model capacity text and a ready chevron.

Classifier:
- Look at the last 50 lines.
- Require capacity text: `selected model is at capacity` OR `please try a different model`.
- Require ready chevron/prompt evidence.
- Require stable two-frame sample for automated action.
- Classify as `model_at_capacity_halt`.

Recovery:
- Worker panes only.
- First action: `printf 'y\n' | ntm send <session> --pane=<pane> "continue"`.
- Key attempts by `(session,pane,hash_t1,capacity_digest)`.
- Budget: 5 attempts per pane per hour or 3 failed success checks, whichever trips first.
- On success: capacity text disappears, output hash changes, or robot activity moves to THINKING/GENERATING.
- On budget exhaustion: log and notify; do not respawn first.

Do not confuse with:
- auth/quota API errors
- frozen panes
- post-callback reminder/stale spinner
- queued-not-submitted transport failures
- bare chevron prompts
```

## Phase Decomposition

This dispatch closes Phase 1-3 only. Phase 4/5 should run as separate dispatches.

### Phase 4 First Move: Reconcile Existing Code

Parallel code-space work already appears in the dirty tree: `codex-template-stuck-detector.sh` and `worker-auto-respawn-watchdog.sh` declare capacity-halt support, and tests reference capacity fixtures. A later P0 row says the live path failed. Therefore the next code dispatch must start with reconcile, not fresh build:

1. Run classifier against current live-pattern fixtures without `subclass_hint`.
2. Run classifier against a saved live scrollback containing the exact "Selected model is at capacity" string.
3. Run watcher fixture and dry-run paths that invoke the classifier path, not a fixture-only bypass.
4. Prove LaunchAgent/watcher driver is loaded for the flywheel session.
5. Only then patch missing matcher, action, install, or doctor surfaces.

### Landing Location

- Primary classifier: extend/reconcile `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Action router: extend/reconcile `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Coverage surface: extend `.flywheel/scripts/fleet-watcher-coverage-probe.sh` or doctor integration so capacity watcher coverage is visible.
- Do not create a new sibling watcher unless existing classifier/watchdog ownership is proven unsuitable.

## Bead DAG Preview

1. `capacity-halt-production-path-reconcile`: verify/fix live-string classifier path and regression from `fuckup-log#L1620`.
2. `capacity-halt-auto-continue-primitive`: bounded finite-confirmation `ntm send ... "continue"` with per-pane/digest lease.
3. `capacity-halt-success-measurement`: post-send recapture and success criteria: output delta, capacity text disappears, or robot activity transitions.
4. `capacity-halt-cross-session-authorization`: latest topology role check, protected refusal, peer callback/orch liveness proof for peer-session workers.
5. `capacity-halt-burst-budget`: per-pane and fleet burst budgets, serialized sends, no unbounded parallel auto-continue storm.
6. `capacity-halt-doctor-ledger`: JSONL attempt rows plus doctor fields for counts, success percentage, protected refusals, budget exhaustion, and sessions top.
7. `capacity-halt-driver-coverage`: LaunchAgent/install/coverage probe for flywheel and peer sessions, with marker-not-driver proof.

Preview count: 7 beads.

## Test Plan

Golden fixtures:

- Capacity string plus stable chevron classifies `model_at_capacity_halt`.
- `please try a different model` fragment alone with chevron also classifies.
- Bare chevron does not classify capacity.
- Capacity string without stable sample does not auto-apply.
- Fixture with `subclass_hint` removed still passes.

Action tests:

- Dry-run reports `would_auto_continue`, writes no action.
- Apply mode uses finite `printf 'y\n'` confirmation and writes one attempt row.
- Duplicate run with same idempotency key refuses second action.
- Same pane at budget notifies/falls back without respawn.
- Protected role refuses auto-continue.

Live smokes:

- Classifier against captured live scrollback from an actual capacity halt.
- Watchdog dry-run over fixture topology with one capacity worker.
- Watchdog apply in fake `ntm` harness verifying command shape and finite confirmation.
- Launchd `gui/<uid>` driver proof: plist loaded, script contains `ntm` send path where applicable, recent log/doctor row exists.

Doctor/ledger tests:

- Detector doctor exposes recovery success percentage with capacity rows included.
- Watchdog summary exposes `auto_continues_fired`, `would_auto_continues`, `notify_fallbacks_fired`, `protected_refusals`.
- Fleet coverage probe exposes watcher active/loaded state for the capacity recovery driver.

## Acceptance For Future Phase 4/5

- Live-string classifier replay passes without hints.
- No code-space callback can claim DONE until it includes live classifier output for a real capacity string and driver coverage proof.
- Persistent capacity becomes a scoped halt contract, not a global work halt.
