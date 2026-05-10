# Journey entry — flywheel-mfy7u

**Bead**: P2 7axmt-followup (fifth of 7 Tier-1).
**Surface**: `.flywheel/scripts/hub-blocker-detect.sh` — detects beads blocking >N parents, promotes to P0 + labels in apply mode.
**Sister**: 1o9fa (per-pane variant). This bead applies the per-target template with scope=`bead_id`.
**Result**: 13/13 in-bead + 161 sister assertions clean; 1000/1000.

## Arc

1. **Read sister 1o9fa**. Per-pane pattern: filter work-list by replay-skip set, mark filtered items in receipt. Same approach with `pane` → `bead_id`.
2. **Module vars** + argparse + refusal gate — standard shape from sister j0xpa.
3. **`replay_already_promoted_bead_ids()`** — tolerant-parse via `jq -Rcs ... fromjson?` returns JSON array. Read once before the per-bead loop into a bash associative array for O(1) lookup.
4. **Per-bead loop fork**: `if APPLY=1 && bead_id in skip-set → replay_skipped=true + counter+=1`; `elif APPLY=1 → existing br update/label/fuckup flow + audit-row append`.
5. **Top-level payload** gains `idempotency_key`, `audit_log`, `replay_skipped_count`, `replay_skipped_bead_ids`.
6. **Test fixture** uses stubbed BR_BIN that captures br update calls into a side-log so the regression can verify the gate fires at the SIDE-EFFECT layer (not just the receipt-shape layer).
7. **Surface design quirk** discovered: surface exits 1 on RED signal regardless of `--apply` mode (it's a detector). Test wraps apply-path invocations with `|| true` and asserts on receipt content. Documented in test header.
8. **`.beads/` workspace required**: surface refuses to run if `$REPO/.beads/` doesn't exist. Test fixture creates it before any invocation.
9. **AG7 verifies the side-effect gate**: BR_BIN stub log shows br update called 3 times across BOTH the first apply (3 promotions) AND the second apply (3 replay-skipped) — total still 3, proving replay-skip prevented the actual side effect.

## Sister flake fix

Sister j99xb test regression: AG9 failed (expected 3 applied rows, got 2). Root cause: surface embeds `--now` timestamp in rendered content; when sister tests run close-in-time, both invocations land in the same wall-clock second, content is byte-identical, cmp-s short-circuits → `status=no_change` instead of `status=applied`. Test was passing only by luck of running across second boundaries.

Fixed in this bead's commit (no separate bead):
- AG9: count non-replay rows (`applied` OR `no_change`) — both are "real run happened, not a replay"
- AG12: pin `--now=$PINNED_NOW` for both writes that should produce byte-identical content

Latent flake pattern: tests asserting against accreting audit logs need to either (a) pin timestamp fixtures, or (b) count by status-class rather than exact status enum.

## Discoveries

None new (pattern + scope substitution from sister 1o9fa). One process note in evidence about flake-resistant test fixtures.

## 7axmt arc status

After this bead: **5/7 Tier-1 fixed**. Remaining 2 surfaces + 1 lint-rule. Pair-pattern matrix:

| Variant | Sisters | Remaining candidates |
|---|---|---|
| Whole-run global | 8sx9w | (none) |
| Per-target | 1o9fa (per-pane), **mfy7u (per-bead)** | flywheel-y0ft6 (bcv-task-harness, per-task-id) |
| Whole-run scoped per-target | j0xpa (per-repo), j99xb (per-sources-file) | flywheel-wdh08 (jeff-bead-285-divergence-capture, per-divergence-id) |
| L10-lint-rule | — | flywheel-9dace |

Matrix is mature: 5 applications across 4 surfaces. Remaining surfaces match cleanly.

## Behavior change

Callers must pass `--idempotency-key=VALUE` under `--apply`. Recommended hourly bucket for orchestrator-driven cadence:

```bash
hub-blocker-detect.sh --apply --idempotency-key="hourly-$(date -u +%Y%m%d-%H)" --json
```

Within the same UTC hour, re-runs no-op via per-bead replay (don't double-escalate hub blockers if the orchestrator re-fires within the hour).
