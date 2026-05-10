# Journey entry — flywheel-7axmt

**Bead**: P2 fleet audit (m12ji-followup)
**Sister**: flywheel-m12ji (mutation-gate-ordering audit, 970/1000, 0 violations)
**Bug class**: surfaces with `--apply` but no `--idempotency-key` gate (different from m12ji's "gate-after-side-effect" invariant)
**Scope**: 82 candidates carried over from m12ji's `no-key-candidates.txt`
**Result**: 7 Tier-1 violations identified + per-violation fix-specs + 8 follow-up beads filed

## Arc

1. **Read m12ji methodology** — sister audit established scanner + spot-check approach. 82 no-key candidates explicitly punted to a future audit (this bead).
2. **Copy candidate list** from m12ji audit dir; verify all 82 files still exist.
3. **Build scanner v1** mirroring m12ji's regex-heuristic shape but adapted for the no-key bug class. 4 verdicts: APPLY_IS_READ_ONLY, APPLY_IS_IDEMPOTENT, APPLY_HAS_OTHER_GATE, APPLY_NEEDS_KEY.
4. **Run v1 + spot-check** — 38 IDEMPOTENT + 23 READ_ONLY + 20 NEEDS_KEY + 1 OTHER_GATE. Spot-checked 10 candidates manually.
5. **Spot-check findings**:
   - `agents-md-shard-extract.sh` flagged NEEDS_KEY but uses `write_if_changed` (idempotent)
   - `ntm-serve-eventstream-bridge.sh` flagged NEEDS_KEY but explicitly refuses --apply with rc=3
   - `validate-callback-before-close.sh` flagged NEEDS_KEY but apply-path uses "create or reuse" semantics
6. **Scanner v2 refinement** — added idempotent hints for `write_if_changed`, `idempotent:`, `backup-before-write`, `.bak`. Re-ran: 39 IDEMPOTENT + 23 READ_ONLY + 19 NEEDS_KEY + 1 OTHER_GATE.
7. **Manual triage per-NEEDS_KEY surface** — inspected each of the 19 individually. Found 12 false positives + 7 genuine Tier-1 candidates.
   - 3 reclassified READ_ONLY: ntm-serve-eventstream-bridge (rc=3 refusal), validate-callback-before-close (rare apply path with reuse semantics), validation-e2e-smoke (smoke test, no real mutation)
   - 9 reclassified IDEMPOTENT: dispatch-log-fitness-invariant (mktemp+os.replace), jeff-shadow-socraticode (write_readonly_marker), polish-preflight-quality-gate (apply_receipt), fleet-conformance-probe (write_json+atomic), fleet-coherence-launchd (plist pure-function), sync-four-lens-validator (write-if-changed via diff), daily-jeff-ingest (idempotent under same input), jeff-daily-corpus-diff (output to canonical path), peer-orch-blocker-watch (downstream tool gates)
8. **7 Tier-1 confirmations** with mutation-kind documented:
   - **P0**: sync-canonical-doctrine.sh (cross-fleet doctrine sync, largest blast radius)
   - **P1**: stale-error-auto-ping (ntm send), security-precommit-installer (git commit/push), regenerate-dicklesworthstone-sources (destructive regen)
   - **P2**: hub-blocker-detect (br set), bcv-task-harness (task execution)
   - **P3**: jeff-bead-285-divergence-capture (low-frequency capture)
9. **Per-violation fix-specs** at `fix-specs.md` with concrete recipe: parser snippet + gate snippet + audit-trail wire snippet + verification commands.
10. **File 8 follow-up beads** (7 Tier-1 + 1 L10-lint-rule orch-action).

## Final verdict counts

```
APPLY_IS_IDEMPOTENT     = 48  (39 scanner + 9 triage-reclassified)
APPLY_IS_READ_ONLY      = 26  (23 scanner + 3 triage-reclassified)
APPLY_HAS_OTHER_GATE    =  1
APPLY_NEEDS_KEY genuine =  7  Tier-1 (P0: 1, P1: 3, P2: 2, P3: 1)
                       ────
                         82
```

## Comparison to m12ji

| Axis | m12ji | 7axmt |
|---|---|---|
| Bug class | gate fires AFTER side-effect | no gate at all |
| Audit scope | 95 has-key surfaces | 82 no-key surfaces |
| Violations | 0 (after hoqq8 fix landed) | **7 Tier-1** |
| Methodology | scanner + spot-check | scanner + spot-check + per-violation triage |
| Output | report (passing) | report + fix-specs + 8 follow-up beads |

The non-zero violations here reflect the bug class being genuinely present in the fleet — these surfaces predate the helper-lib's `cli_refuse_apply_without_idem_key` and never picked up the canonical pattern. 7axmt identifies which surfaces should backfill it.

## Discoveries

1. **heuristic-scanner-then-manual-triage pattern** — for fuzzy bug classes where function names can encapsulate idempotency (write_if_changed, write_readonly_marker, apply_receipt), a 2-pass scanner + manual triage catches both directions of misclassification. Sister m12ji used spot-check; 7axmt extended to per-violation triage because Tier-1 count > 0.

2. **apply-flag-taxonomy 4-way classification** — for "does this surface need a gate?" audits, the 4 verdicts (READ_ONLY / IDEMPOTENT / OTHER_GATE / NEEDS_KEY) cleanly partition the space. Reusable for future gate-class audits.

## Follow-up beads filed

```
flywheel-8sx9w  P0  sync-canonical-doctrine.sh
flywheel-1o9fa  P1  stale-error-auto-ping.sh
flywheel-j0xpa  P1  security-precommit-installer.sh
flywheel-j99xb  P1  regenerate-dicklesworthstone-sources.sh
flywheel-mfy7u  P2  hub-blocker-detect.sh
flywheel-y0ft6  P2  bcv-task-harness.sh
flywheel-wdh08  P3  jeff-bead-285-divergence-capture.sh
flywheel-9dace  P2  L10 canonical-cli-lint rule (orch-action)
```
