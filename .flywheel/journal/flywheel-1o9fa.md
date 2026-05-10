# Journey entry — flywheel-1o9fa

**Bead**: P1 7axmt-followup (second of 7 Tier-1 fixes).
**Surface**: `.flywheel/scripts/stale-error-auto-ping.sh` — sends `ntm send` pings to stuck panes.
**Sister**: flywheel-8sx9w (first 7axmt P0, shipped `idempotency-key-with-replay-check pair-pattern` discovery).
**Result**: 14/14 in-bead + 165 sister assertions clean; 1000/1000.

## Arc

1. **Read sister 8sx9w fix** and the 7axmt fix-spec section 2. Recipe pre-written by the audit work.
2. **Read target** (117 lines): bash surface with `run_once()` function, argparse loop, candidate-filter via jq.
3. **Decide granularity**: 8sx9w replays the whole invocation if any prior row matches. For per-pane actions, that's wrong — you'd skip every pane on retry. The right granularity is **per-pane**: audit log carries `{idempotency_key, pane}`, replay-check returns the set of pre-pinged panes, surface filters the work-list. This was the key design call.
4. **Module vars**: `IDEMPOTENCY_KEY=""` + `AUDIT_LOG="${STALE_ERROR_AUDIT_LOG:-$HOME/.local/state/flywheel/stale-error-auto-ping-runs.jsonl}"`.
5. **Argparse**: both `--idempotency-key VALUE` and `--idempotency-key=VALUE` forms; missing-value → rc=2 explicit (not bash's `${2:?}` which exits with rc=1).
6. **Refusal gate**: fires after argparse, BEFORE `run_once` is ever called. rc=3 + canonical envelope.
7. **`replay_already_pinged_panes()`**: returns JSON array of pane indices from prior matching audit rows. Uses `jq -Rcs ... fromjson?` (raw + slurp + tolerant) per sister 8sx9w's `ledger-replay-check-with-tolerant-parse` discovery. Survives corrupt rows.
8. **`audit_append()`**: writes one row per ping with `{schema_version, ts, action, idempotency_key, session, pane, ping_text}`.
9. **`run_once()` filter**: computes `eligible_panes = before_candidates - already_pinged` via jq `index() | not` filter. Iterates `eligible_panes` for the actual `ntm send` calls.
10. **Receipt envelope adds 4 fields**: `idempotency_key`, `replay_skipped_panes`, `replay_skipped_count`, `eligible_candidate_count`. Status taxonomy gains `all_replay_skipped` for the "everything pre-pinged" case.
11. **Docs**: usage/examples/info all updated.

## Live verification

- AG1 refusal: `--apply` without key → rc=3 + refusal envelope ✓
- AG3 equals-form: `--idempotency-key=key` parses ✓
- AG2 missing-value: `--idempotency-key` (no arg) → rc=2 ✓ (after fixing `${2:?...}` → explicit `[[ -n "${2:-}" ]] || exit 2`)
- Fixture format pin: candidates_filter wants `.agents[]` shape, not raw `.errors[]` — verified by probing both shapes and selecting the one that produces candidates.
- AG9-13 replay: seeded audit log with prior pings + retried → per-pane filter works; cross-key isolation; tolerant-parse skips corrupt rows; all-skipped status fires when every pane pre-pinged.

## Discovery (1)

**`per-pane-replay-granularity-pattern`** — sister 8sx9w's pair-pattern was whole-invocation replay (atomic operation). For per-target actions (ping pane N, br set bead-id, task harness per task-id), per-target replay is the right granularity:

```
audit log row: {idempotency_key, target}   ← per-action row, not per-invocation
replay-check returns: set of already-acted-on targets
surface action: filter work-list before iteration; replay-skipped targets appear in receipt
status taxonomy: extend with "all_replay_skipped" + per-target counts
```

Future 7axmt fixes for hub-blocker-detect (per-bead `br set`) and bcv-task-harness (per-task-id) likely adopt this granular variant. Whole-run variant from 8sx9w still applies to security-precommit-installer and regenerate-dicklesworthstone-sources (single-batch operations).

## 7axmt arc status

After this bead: **2/7 Tier-1 fixed**. Remaining 5 surfaces + 1 lint-rule bead queued. The two pair-pattern variants now in the pattern catalogue:

| Variant | Whole-run | Per-target |
|---|---|---|
| Sister | 8sx9w (sync-canonical-doctrine) | **1o9fa (this — stale-error-auto-ping)** |
| Reuse | security-precommit-installer (P1), regenerate-dicklesworthstone-sources (P1) | hub-blocker-detect (P2), bcv-task-harness (P2) |
| Audit row | `{idempotency_key, status:ok}` | `{idempotency_key, target}` |
| Replay action | exit 0 early, emit prior receipt | filter work-list, emit per-target skip details |

## Behavior change

Same as 8sx9w: callers must pass `--idempotency-key=VALUE` under `--apply`. Recommended time-bucketed key for launchd schedules: `--idempotency-key="auto-$(date -u +%Y%m%d-%H)"` (hourly bucket replays no-op within the same hour).
