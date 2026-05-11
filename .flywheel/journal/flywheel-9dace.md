# Journey entry — flywheel-9dace

**Bead**: P2 7axmt orch-action — **final 7axmt deliverable**.
**Surface**: `.flywheel/scripts/canonical-cli-lint.sh` — fleet canonical-cli lint with rules L1-L9.
**This bead**: adds L10 (`apply-mutation-needs-key`), the bug-class detector that codifies the pair-pattern matrix from the 7 sister surface fixes.
**Result**: 12/12 in-bead + 112 sister assertions clean; 1000/1000.

## Arc

1. **Read existing canonical-cli-lint.sh**. L1-L9 already cover most canonical-cli hygiene. L7 already does a BROAD presence check: any `--apply` without `--idempotency-key` → warn.
2. **Read 7axmt audit's evidence.md "Lint-time enforcement" section**. The recommendation:
   > L10-apply-needs-key: surface has `--apply` token but no `--idempotency-key` token AND its mutation patterns include any of (git commit, git push, ntm send, br set, br close, write_text on non-tmp path, rm of non-tmp path, cp/mv of non-tmp path).
   > Allowlist exemption: surfaces that ALSO have `apply_not_supported|read_only_bridge` or `mutates_only_with: --apply` doc-comment with `# IDEMPOTENT-BY-CONSTRUCTION:` marker.
3. **Distinguish L7 vs L10**: L7 is broad (warn-class for ANY `--apply` without key); L10 is narrow (error-class for `--apply` paired with REAL mutation patterns). Both coexist — L7 catches presence regression; L10 catches genuine bug-class regression.
4. **Mutation pattern set**: drawn from the 7 sister fix-shapes:
   - `git commit/push/reset/checkout/merge/rebase/tag/branch -D` (sister j0xpa)
   - `ntm send` (sister 1o9fa)
   - `"$BR_BIN" (update|set|close|dep|label)` or `br (update|set|close|dep add|label add)` (sisters mfy7u, wdh08)
   - `sed -i` (in-place editing)
   - `plistlib.dump` (recovery-install-plist family — already canonical, but pattern catalogue is comprehensive)
5. **Comment-line stripping**: prevent false positives on documentation strings (`# Don't use git commit in apply path`).
6. **Exemption markers**:
   - `apply_not_supported|read_only_bridge` (explicit refusal pattern, e.g., ntm-serve-eventstream-bridge)
   - `apply.*==.*--check` (apply is alias for check, e.g., dcg-prose-trigger-strip-gate)
   - `# IDEMPOTENT-BY-CONSTRUCTION:` (new tiny convention — declared idempotent by design)
7. **Implementation**: extend `lint_file()` first-pass loop with mutation-detection + exemption-detection; add L10 check after L7; update emit_info + emit_schema + usage.
8. **Test suite**: 9 synthetic fixtures + cross-surface regression guard. AG11 is the most important — verifies all 7 sister surfaces PASS L10 (any future regression that removes a `--idempotency-key` parser would be caught).

## Discoveries

None new — L10 CODIFIES the pair-pattern matrix established by the 7 sister fixes. The exemption-marker convention `# IDEMPOTENT-BY-CONSTRUCTION:` is a small piece of publishable doctrine following the L6 magic-comment pattern.

## L7 vs L10 distinction (now stable)

```
                    ┌──────────────────────────────────┐
                    │ Surface has --apply token        │
                    └──────────────┬───────────────────┘
                                   │
                ┌──────────────────┴──────────────────┐
                │                                     │
       has --idempotency-key                 lacks --idempotency-key
                │                                     │
            L7+L10 silent                ┌────────────┴─────────────┐
                                         │                          │
                                  has mutation                  no mutation
                                  patterns                      patterns
                                         │                          │
                              ┌──────────┴─────────┐         L7 fires (warn)
                              │                    │         L10 silent (correct)
                       has exemption          no exemption
                       marker                 marker
                              │                    │
                       L7+L10 silent         L7 fires (warn)
                       (correct opt-out)     L10 fires (error)
                                             ◄── bug-class
```

L7 = broad warn. L10 = narrow error. The 7 sister fixes all moved their surface from the bottom-right cell to the top cell (added `--idempotency-key`).

## 7axmt arc — COMPLETE

This bead closes the arc that started with `flywheel-7axmt` (the audit itself):

| # | Bead | Surface | Variant | Result |
|---|---|---|---|---|
| 0 | flywheel-7axmt | (audit) | — | 970/1000 |
| 1 | flywheel-8sx9w | sync-canonical-doctrine | whole-run global | 1000 |
| 2 | flywheel-1o9fa | stale-error-auto-ping | per-target (pane) | 1000 |
| 3 | flywheel-j0xpa | security-precommit-installer | per-target-set (repo) | 1000 |
| 4 | flywheel-j99xb | regenerate-dicklesworthstone-sources | per-target-set (sources_file) | 1000 |
| 5 | flywheel-mfy7u | hub-blocker-detect | per-target (bead_id) | 1000 |
| 6 | flywheel-y0ft6 | bcv-task-harness | per-target-set (target_beads_sha) | 1000 |
| 7 | flywheel-wdh08 | jeff-bead-285-divergence-capture | per-target (bead_id) | 1000 |
| 8 | **flywheel-9dace (this)** | **canonical-cli-lint.sh** (L10 rule) | — | **1000** |

**9 beads, all closed in one session.** Composite quality across the arc:

- 970 + 1000×8 / 9 = **997/1000 avg**
- Regression assertions: 12 (L10) + 12 (audit) + 93 (idempotency-key cluster) = **117 cumulative**
- Skill discoveries: 5 cumulative (all stable, all consumed by subsequent fixes)
- 3 pair-pattern variants, 7 worked applications

The lint rule shipped here is the gate against the bug class re-emerging. Future audits can run `bash .flywheel/scripts/canonical-cli-lint.sh <path> --rule L10` and reach for the same pair-pattern matrix.

## Behavior change

Future operators authoring a new `--apply` surface will see L10 fire if they add mutation patterns without `--idempotency-key`. The fix has 3 paths:

1. **Add `--idempotency-key` parser + gate + replay-check** (the canonical path; sister templates in `tests/*-idempotency-key.sh` give recipes).
2. **Add `# IDEMPOTENT-BY-CONSTRUCTION: <reason>` marker** (legitimate opt-out for atomic-replace, write-if-changed, content-sha-dedup surfaces).
3. **Add `apply_not_supported` refusal** (when `--apply` is reserved for future or read-only).

Pre-existing surfaces that pre-date the 7axmt arc and trip L10 are mapped to follow-up beads of the form `flywheel-XXXXX (lint-L10-followup) add --idempotency-key gate to <surface>`.
