# Journey entry — flywheel-j99xb

**Bead**: P1 7axmt-followup (fourth of 7 Tier-1).
**Surface**: `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` — regenerates sources.txt from `gh repo list Dicklesworthstone`.
**Sister**: j0xpa (established per-scope variant on `repo`); this bead generalizes to scope=`sources_file`.
**Result**: 18/18 in-bead + 169 sister assertions clean; 1000/1000.

## Arc

1. **Read sister j0xpa**. Matrix has 3 variants now. Pick the right one.
2. **Inspect surface** (213 lines, no canonical-cli scaffold). Mutation:
   - `MODE=apply && CHANGED=true`: write timestamped backup, `mv` rendered to sources file
   - `MODE=apply && CHANGED=false` (content-identical via `cmp -s`): no-op (already idempotent!)
3. **Variant decision**: one sources-file per invocation, overridable via `--sources-file` flag. Direct fit for j0xpa's pattern with scope identifier = `sources_file` instead of `repo`. Confirms the pattern generalizes.
4. **Module vars** + argparse (uses existing `die()` helper for `--idempotency-key` missing-value → rc=2, matching the surface's existing style).
5. **Refusal gate** + `replay_prior_regen` helper + `audit_append_regen` helper — same shape as sister j0xpa.
6. **Status enum**: extended to include `no_change` (cmp-s short-circuit). Replay-check accepts `applied|replay|no_change` so that re-rendered-but-unchanged invocations also serve as replay anchors.
7. **Audit row** carries `{ts, status, sources_file, idempotency_key, backup_path, content_sha256, active_repo_count}`. Content sha pins the rendered output for incident forensics.
8. **Receipt envelope** adds `idempotency_key` + `audit_log` fields.
9. **Live verification** with 2-sources-file fixture: refusal, gate, replay, per-target scope isolation, tolerant-parse — all work.

## Discoveries

None new — the per-scope variant generalizes cleanly from j0xpa's `(key, repo)` to `(key, sources_file)`. Same code shape, different scope-identifier field name. Pair-pattern matrix is mature enough to pick variants without filing new doctrine.

## 7axmt arc status

After this bead: **4/7 Tier-1 fixed**. Remaining 3 surface fixes + 1 lint-rule. Pair-pattern matrix has 3 variants; remaining surfaces map directly:

| Variant | Sister | Remaining |
|---|---|---|
| Whole-run global | 8sx9w | (none) |
| Per-target | 1o9fa | flywheel-mfy7u (hub-blocker-detect, per-bead), flywheel-y0ft6 (bcv-task-harness, per-task-id) |
| Whole-run scoped per-target | j0xpa, **j99xb** | flywheel-wdh08 (jeff-bead-285-divergence-capture, per-divergence-id) |

## Behavior change

Callers must pass `--idempotency-key=VALUE` under `--apply`. The documented daily runner (per surface's own usage doc: "invoke this script before daily-jeff-ingest.sh in the existing Jeff ingest launchd/cron path") should use a date-based key:

```bash
regenerate-dicklesworthstone-sources.sh --apply --idempotency-key="daily-$(date -u +%Y%m%d)" --json
```

Daily bucket: within the same UTC day, re-runs no-op via replay. Drift across UTC midnight applies a fresh row (correct semantics — each day is a new run).
