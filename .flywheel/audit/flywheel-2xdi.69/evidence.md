# flywheel-2xdi.69 — bead-without-followup false-positive: phantom-bead test-pollution

Bead: flywheel-2xdi.69 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: gap-detector-quality
mutates_state: yes (one suppression block added to bead_followup_false_positive_reason + regression test)

## Probed per META-RULE 2xdi.54

flywheel-0u9ch close_reason (from `.beads/issues.jsonl`):

```
phantom bead — test-pollution artifact from callback-receipt-validator-canonical-cli.sh
line 40 invoking validator → real opener → live .beads/ write; isolated test with
CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true; future runs 0-delta; commit 828b671
```

This is **explicitly a phantom bead** — a test invoking the real bead-opener produced a live `.beads/` row by accident. The close note documents (a) the source of pollution (callback-receipt-validator-canonical-cli.sh:40), (b) the isolation fix (CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true), (c) the verification (future runs 0-delta), (d) the fix commit (828b671).

Phantom beads NEVER represent real doctrine/canonical/promotion work — they're test artifacts. Citing them in INCIDENTS.md would be incorrect.

## Why the probe flagged it (false-positive root cause)

`probe_bead_without_followup` at line 1337 matches `\b(doctrine|canonical|promote|promotion)\b` in bead text. flywheel-0u9ch's close_reason contains `canonical-cli` (part of `callback-receipt-validator-canonical-cli.sh`) — that triggers the `canonical` keyword match. The probe then checks if the bead is cited in INCIDENTS.md; it's not; flags as gap.

The `bead_followup_false_positive_reason()` function at line 1277 has narrow-suppression precedents for known false-positive shapes (plan-space-cross-link-design, mkdir-lock-fallback-plan, external-issue-reply-draft, recover-pane-command-spec, upstream-issue-draft-or-comment-decision). But phantom-bead-test-pollution was not yet a recognized class.

## Fix

Added one suppression block to `bead_followup_false_positive_reason`:

```python
(
    # 2026-05-11 (flywheel-2xdi.69): phantom beads are test-pollution
    # artifacts (a test invoking the real bead-opener writes a live
    # .beads/ row; the close note documents the pollution + isolates
    # the test). They never represent real doctrine/canonical/promotion
    # work and have nothing to cite in INCIDENTS.md.
    "phantom-bead-test-pollution",
    [
        "phantom bead",
        "test-pollution",
    ],
),
```

The suppression uses `all(needle in text for needle in needles)` (precedent from other suppressions). Both needles must match for the suppression to fire — prevents over-matching (e.g., a bead mentioning "phantom" alone or "test-pollution" alone in different context).

This class-fix benefits all future phantom-bead artifacts. Currently 1 instance (flywheel-0u9ch); future test-pollution incidents producing phantom beads will be auto-suppressed.

## Live verification

```bash
# Pre-fix
$ jq -r '[.gaps_by_class["bead-without-followup"][]?.id | select(contains("0u9ch"))] | length' /tmp/gh-pre.json
1

# Post-fix
$ jq -r '[.gaps_by_class["bead-without-followup"][]?.id | select(contains("0u9ch"))] | length' /tmp/gh-post.json
0
```

## Acceptance gates

Auto-filed by gap-hunt-probe. Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the bead's actual nature | **DONE** | flywheel-0u9ch's close_reason explicitly identifies it as "phantom bead — test-pollution artifact". NOT real doctrine/canonical/promotion work. |
| AG2 | Classify root cause | **DONE** | False-positive: `canonical-cli` substring in close note (from script name `callback-receipt-validator-canonical-cli.sh`) matched the probe's `canonical` keyword. Phantom bead shape not in existing suppression list. |
| AG3 | Apply class-fix | **DONE** | Added `phantom-bead-test-pollution` suppression with both-needles match (`phantom bead` + `test-pollution`). Live probe verified named target dropped 1→0. |
| AG4 | Zero regression on baseline + prior fixes | **DONE** | gap-hunt-probe-canonical-cli.sh 30/30, on-demand-allowlist 6/6, suppression-smoke 7/7 = 43/43. Prior 2xdi.37 suppression (flywheel-0h0b upstream-issue-draft) preserved (T5 asserts). |
| AG5 | Regression test for the new behavior | **DONE** | tests/gap-hunt-probe-phantom-bead-suppression.sh — 6/6 PASS. T1-T2 structural (suppression key + both needles present), T3 named target dropped, T4 envelope shape, T5 prior fix preserved, T6 all-needles match logic preserved. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | +14 lines (one suppression block + comment) |
| `tests/gap-hunt-probe-phantom-bead-suppression.sh` | NEW (75 lines, 6 assertions) |
| `.flywheel/audit/flywheel-2xdi.69/evidence.md` | NEW |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: class-fix benefits all future phantom-bead artifacts; existing 1 instance resolved.

## Skill auto-routes addressed

- **canonical-cli-scoping** = n/a — internal suppression list extension.
- **rust-best-practices** = n/a — no Rust.
- **python-best-practices** = YES — fix is in Python heredoc inside gap-hunt-probe.sh. (1) Function signature unchanged; (2) No new deps; (3) Regression test exercises the suppression; (4) Tests use TMPDIR; (5) file-length unaffected.
- **readme-writing** = n/a — no README touched.

## Four-Lens Self-Grade

- **brand** (10): used the canonical suppression mechanism (`bead_followup_false_positive_reason`); format mirrors 5 existing suppression blocks; cited the bead ID + date in inline comment. Honored META-RULE 2xdi.54 (probed close_reason before implementing).
- **sniff** (10): empirical pre/post probe verification (1→0); regression test asserts both structural (suppression present) and behavioral (named target suppressed); T5 explicitly asserts prior 2xdi.37 fix preserved.
- **jeff** (10): didn't over-match — both-needles requirement (`phantom bead` AND `test-pollution`) prevents false-suppression. Didn't extend probe corpus a 7th time today (this is a SUPPRESSION addition, not a corpus extension — different mechanism).
- **public** (10): Three Judges check —
  - Skeptical operator: pre/post outputs are deterministic; both-needles match is verifiable.
  - Maintainer: suppression follows 5-entry precedent pattern; inline comment cites bead + date + example.
  - Future worker: when next test-pollution incident produces a phantom bead, it auto-suppresses without needing a probe-trip + bead-thrash.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical pre/post (1→0 in bead-without-followup). ✓
- 43/43 baseline tests PASS unchanged. ✓
- Prior 2xdi.37 suppression preserved (T5). ✓
- Class-fix benefits future phantom-bead artifacts. ✓
- Both-needles match prevents over-matching (T6). ✓

## L112 probe

Command: `bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-phantom-bead-suppression.sh 2>&1 | grep -c '^PASS'`
Expected: `literal:6`
Timeout: 60 seconds
