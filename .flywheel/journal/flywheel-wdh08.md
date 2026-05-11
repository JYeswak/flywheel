# Journey entry — flywheel-wdh08

**Bead**: P3 7axmt-followup — **seventh and final** of 7 Tier-1.
**Surface**: `.flywheel/scripts/jeff-bead-285-divergence-capture.sh` — forensic capture tool for Jeff Emanuel's beads_rust upstream issue #285.
**Sister**: j0xpa per-target template, scope substituted to `bead_id`.
**Result**: 11/11 in-bead + 82 sister assertions clean; 1000/1000.

## Arc

1. **Read sister templates**. Pattern catalogue mature at this point; pick the right variant by inspection.
2. **Surface inspection**: takes `<bead-id>` as positional arg, runs `br close <bead-id>` with RUST_LOG trace, captures pre/post `br doctor` snapshots into `$CAPTURE_ROOT/$TS-$BEAD_ID/`. Single-bead-per-invocation surface → per-target variant, scope=`bead_id`.
3. **Standard sister j0xpa template applied**: module vars + argparse + gate + replay helpers + audit-append + receipt fields + docs. Audit row: `{idempotency_key, bead_id, capture_dir, manifest, close_exit_code, pre_status, post_status, divergence_observed, ts}`.
4. **Gate placement**: AFTER dry-run early-return, BEFORE `mkdir -p "$CAPTURE_DIR"` (capture-dir creation is the first side-effect — hoqq8 invariant).
5. **Tests**: hermetic via seeded audit log. No real `br close` invocation needed — replay-check semantics verified directly from the audit log.

## Discoveries

None new — sister template + scope substitution. Pair-pattern matrix complete and stable at 3 variants with 7 worked applications.

## 7axmt arc completion

**This bead closes the 7axmt-followup arc.** All 7 Tier-1 surface fixes shipped in one session:

| # | Bead | Surface | Variant | Scope |
|---|---|---|---|---|
| 1 | 8sx9w | sync-canonical-doctrine.sh | Whole-run global | — |
| 2 | 1o9fa | stale-error-auto-ping.sh | Per-target | pane |
| 3 | j0xpa | security-precommit-installer.sh | Per-target-set | repo |
| 4 | j99xb | regenerate-dicklesworthstone-sources.sh | Per-target-set | sources_file |
| 5 | mfy7u | hub-blocker-detect.sh | Per-target | bead_id |
| 6 | y0ft6 | bcv-task-harness.sh | Per-target-set | target_beads_sha |
| 7 | **wdh08 (this)** | jeff-bead-285-divergence-capture.sh | Per-target | bead_id |

93 regression assertions, 0 fail. 5 skill discoveries (all consumed and stable). 1 fix-spec correction filed.

## Pair-pattern matrix (final stable form)

```
                         ┌────────────────────────────────┐
                         │ Does the surface refuse --apply │
                         │ without --idempotency-key?      │
                         └──────────────┬─────────────────┘
                                        │ rc=3 + canonical refusal
                                        ▼
                  ┌──────────────────────────────────────────┐
                  │ How many independently-actionable targets │
                  │ does ONE invocation operate on?           │
                  └────────────┬──────────────┬──────────────┘
                       1 atomic │              │ N independent
                                ▼              ▼
                ┌──────────────────┐   ┌──────────────────────┐
                │ Whole-run global │   │ Surface caller passes │
                │ (single scope)   │   │ a target identifier   │
                └────────┬─────────┘   │ in flags?             │
                         │             └──────┬───────┬───────┘
                         │                    │ yes   │ no
                         ▼                    ▼       ▼
              {key} replay-check  Per-target-set      Per-target
                  exit 0 early     {key, scope-id}    {key, target}
                                  exit 0 if match     filter work-list
              ◄───────────── 8sx9w sister
                                                     ◄── 1o9fa, mfy7u,
                            j0xpa, j99xb, y0ft6 ───►     wdh08
```

## Remaining 7axmt deliverable

flywheel-9dace (L10 canonical-cli-lint rule, orch-action recommendation): NOT a surface fix. A lint enhancement to detect future surfaces adding `--apply` without `--idempotency-key`. When shipped, it will prevent regression into the bug class fleet-wide.

The patterns are now mature enough that the lint rule can detect violations by:
1. Surface has `--apply` parser
2. Surface mutates non-tmp/non-idempotent state (git commit, ntm send, br update, file write to stable path)
3. Surface lacks `--idempotency-key` parser

With exemption for explicit refusal (`apply_not_supported`, `--apply == --check`) or `# IDEMPOTENT-BY-CONSTRUCTION:` marker comments.

## Behavior change rollup

All 7 surfaces now require `--idempotency-key` under `--apply`. Recommended buckets by cadence:
- **Hourly cadence**: `--idempotency-key="hourly-$(date -u +%Y%m%d-%H)"`
- **Daily cadence**: `--idempotency-key="daily-$(date -u +%Y%m%d)"`
- **Per-commit cadence**: `--idempotency-key="$(git rev-parse HEAD)"`
- **Named rollout**: `--idempotency-key="rollout-$NAME"`
- **Single capture event**: `--idempotency-key="capture-$NAME-$(date -u +%Y%m%d)"`

CI/automation/launchd configs that invoke these surfaces with `--apply` need to be updated.
