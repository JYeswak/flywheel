# Journey entry — flywheel-y0ft6

**Bead**: P2 7axmt-followup (sixth of 7 Tier-1).
**Surface**: `.flywheel/scripts/bcv-task-harness.sh` — BCV multi-phase task harness.
**Sisters**: j0xpa (per-target-set on repo), j99xb (per-target-set on sources_file). This bead uses scope = `sha256(sorted target_beads)`.
**Result**: 11/11 in-bead + 71 sister assertions clean; 1000/1000.

## Arc

1. **Read fix-spec section 6**. Hinted at audit row `{idempotency_key, task_id, callback_outcome}`. Inspected surface to validate.
2. **Fix-spec correction**: surface has no per-task-id concept — it processes N beads as a batch. The right scope is the **batch identifier**: `sha256(sorted(target_beads))`. Sister j0xpa template + scope substitution.
3. **Module vars + argparse** — standard shape (both flag forms, missing-value → rc=2 via `die()` helper).
4. **Refusal gate placement**: AFTER `load_targets` (so TARGET_BEADS is populated for sha computation), BEFORE `bootstrap-audit` creates the pass dir (hoqq8 invariant).
5. **`target_beads_sha` computation**: `printf '%s\n' "${TARGET_BEADS[@]}" | sort | shasum -a 256 | awk '{print $1}'`. Sorted set hash means `--beads bd-1,bd-2` and `--beads bd-2,bd-1` produce the same key.
6. **`replay_prior_bcv_run()`**: tolerant-parse via `jq -Rc 'fromjson?'` filters on `(idempotency_key, target_beads_sha)` tuple with status in `{complete, replay}`.
7. **Audit-row wired at 3 terminal `emit_receipt` calls**: validation-failed, banner-present, full-pass. Each terminal path appends BEFORE emit_receipt fires, then the existing stdout receipt is unchanged.
8. **Test design**: full harness requires real beads + br + python3 + skill scripts. Test instead seeds the audit log directly and verifies (a) refusal contract, (b) flag parsing, (c) replay-fires-on-match, (d) per-set-scope isolation, (e) tolerant-parse. Hermetic and fast.

## Discoveries

None new — sister j0xpa template + scope substitution. Pattern matrix mature at 6 applications.

**Process note**: batch-harness surfaces should seed audit log directly in tests rather than running the full pipeline. Faster, more reliable, easier to verify replay-check in isolation.

## 7axmt arc status

After this bead: **6/7 Tier-1 fixed**. Remaining:
- P3: flywheel-wdh08 (jeff-bead-285-divergence-capture)
- L10-lint: flywheel-9dace

Pair-pattern matrix has 6 worked examples across 3 variants. The final P3 surface should map cleanly.

## Behavior change

Callers must pass `--idempotency-key=VALUE` under `--apply`. Recommended date-bucketed key:

```bash
bcv-task-harness.sh --repo "$PWD" --beads bd-123,bd-456 --apply --idempotency-key="bcv-$(date -u +%Y%m%d)" --json
```

Same beads + same UTC day → no-op replay. Different beads OR different day → fresh run.
