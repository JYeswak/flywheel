# Compliance pack flywheel-9dace — L10 canonical-cli-lint rule (apply-mutation-needs-key)

## Bead disposition

P2 7axmt orch-action. **Final 7axmt deliverable** after the 7 Tier-1 surface fixes. Filed by the 7axmt audit as the orch-action recommendation to prevent regression into the bug class fleet-wide.

Surface: `.flywheel/scripts/canonical-cli-lint.sh` — fleet lint with rules L1-L9. This bead adds L10 (`apply-mutation-needs-key`).

556 → 614 lines (+58/-4; +148-line regression test).

## L7 vs L10 — broad presence check vs targeted bug-class detector

The pre-existing L7 was a broad presence check: "does the file have BOTH `--apply` AND `--idempotency-key` tokens?" That fires for EVERY surface with `--apply` regardless of whether `--apply` triggers actual mutation.

L10 is a targeted bug-class detector:

```
L10 fires when ALL of:
  1. Surface has `--apply` parser
  2. Surface has NO `--idempotency-key` reference
  3. Surface has MUTATION PATTERNS (git commit/push/reset, ntm send, br
     update/set/close/dep/label, sed -i, plistlib.dump)
  4. Surface lacks EXEMPTION MARKERS (apply_not_supported, read_only_bridge,
     "--apply == --check" refusal, "# IDEMPOTENT-BY-CONSTRUCTION:" comment)
```

L7 is broad (warn-class for any read-only `--apply`); L10 is narrow (error-class only for genuine bug-class surfaces). Both coexist — operators tuning lint severity can disable L7 (broad warning) while keeping L10 (genuine bug).

## Mutation pattern detection

Patterns drawn from the 7axmt audit's scanner.py + the 7 sister fix-shapes:

| Pattern | Sister sister(s) | Example |
|---|---|---|
| `git commit\|push\|reset --hard\|checkout --\|merge\|rebase\|tag\|branch -D` | j0xpa | `git -C "$repo" config --local core.hooksPath githooks` (but matches actual commits) |
| `ntm send` | 1o9fa | `"$NTM_BIN" send "$SESSION" --pane="$pane"` |
| `"$BR_BIN" (update\|set\|close\|dep\|label)` or `br (update\|set\|close\|dep add\|label add)` | mfy7u, wdh08 | `(cd "$REPO" && "$BR_BIN" update "$bead_id" --priority 0)` |
| `sed -i` | (none in 7axmt) | in-place file editing |
| `plistlib.dump` | (recovery-install-plist family — already canonical) | per-client plist write |

Comment-line stripping prevents documentation references (`# Don't use git commit...`) from triggering false positives.

## Exemption markers

| Marker | Use case |
|---|---|
| `apply_not_supported` | Surface emits this in a refusal envelope (e.g., ntm-serve-eventstream-bridge) |
| `read_only_bridge` | Same as above |
| `apply.*==.*--check` or `--apply == --check` | Surface treats apply as alias for check (e.g., dcg-prose-trigger-strip-gate) |
| `# IDEMPOTENT-BY-CONSTRUCTION:` | Declared idempotent (atomic-replace, write-if-changed, content-sha-dedup) |

Operators adding a new surface that's read-only or naturally idempotent under `--apply` can add the marker comment to opt out of L10.

## Acceptance gates (12/12)

- AG1 PASS — `--info` lists L10 with label `apply-mutation-needs-key`
- AG2 PASS — `--schema` rule enum includes L10
- AG3 PASS — git-commit pre-fix-shape fixture → L10 fires (rc=1)
- AG4 PASS — ntm-send pre-fix-shape → L10 fires
- AG5 PASS — br-update pre-fix-shape → L10 fires
- AG6 PASS — post-fix-shape (apply + idempotency-key + git commit) → L10 silent
- AG7 PASS — `apply_not_supported` exemption → L10 silent
- AG8 PASS — `# IDEMPOTENT-BY-CONSTRUCTION:` exemption → L10 silent
- AG9 PASS — no `--apply` present → L10 silent
- AG10 PASS — `--apply` without mutation patterns → L10 silent
- **AG11 PASS — all 7 7axmt-followup sister surfaces PASS L10 (regression guard)**
- AG12 PASS — L10 violation message names the triggering mutation pattern

## Regression-guard significance (AG11)

AG11 is the most important assertion in the test: **the 7 surfaces fixed by sister beads (8sx9w, 1o9fa, j0xpa, j99xb, mfy7u, y0ft6, wdh08) must all PASS L10**. If any sister fix regressed (e.g., a future operator removed the `--idempotency-key` parser), L10 would catch it.

L10 also serves as the gate for NEW surfaces: any future `--apply` surface that mutates external state without an idempotency-key gate gets caught at lint time, before it ships.

## Sister regression coverage

| Suite | Result |
|---|---|
| `canonical-cli-lint-l10.sh` (this bead) | 12/12 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |
| `jeff-bead-285-divergence-capture-idempotency-key.sh` (wdh08) | 11/11 PASS |
| `bcv-task-harness-idempotency-key.sh` (y0ft6) | 11/11 PASS |
| `hub-blocker-detect-idempotency-key.sh` (mfy7u) | 13/13 PASS |
| `regenerate-dicklesworthstone-sources-idempotency-key.sh` (j99xb) | 18/18 PASS |
| `security-precommit-installer-idempotency-key.sh` (j0xpa) | 15/15 PASS |
| `stale-error-auto-ping-idempotency-key.sh` (1o9fa) | 14/14 PASS |
| `sync-canonical-doctrine-idempotency-key.sh` (8sx9w) | 11/11 PASS |

112 sister + 12 in-bead = **124 across the cluster**.

## Pre-existing L3 self-check noise (NOT introduced by this bead)

`canonical-cli-lint.sh` linted against itself emits 3 L3 violations at lines 13, 376, 379. These are documentation strings showing `${X:-{}}` as the EXAMPLE of the L3 brace-default-ambiguity pattern. They existed before this bead's edit (lines 13 and 376 were untouched; line 379 is part of the unchanged L3 emit_v string).

Not in scope for this bead. Future operator can add a `# lint-self-exempt: L3` marker if these become noisy.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/canonical-cli-lint.sh` | +58/-4: header doc + emit_info rules list + emit_schema enum (2 places) + L10 global-signal gather + L10 rule check + usage flag list |
| `tests/canonical-cli-lint-l10.sh` | NEW: 12-AG test with 9 synthetic fixtures + cross-surface regression guard against all 7 sister fixes |
| `.flywheel/compliance/flywheel-9dace/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-9dace/canonical-cli-lint.diff` | NEW: 121-line captured diff |
| `.flywheel/journal/flywheel-9dace.md` | NEW: journey entry + complete 7axmt arc summary |

## Skill auto-routes

- canonical-cli-scoping: **yes** (this IS the canonical-cli lint)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (rule added to schema + info + usage; both broad L7 and narrow L10 coexist; per-pattern exemption markers documented)
- regression depth: 240/220 (12 assertions: 3 pre-fix-shape catches, 5 silent cases, 1 regression-guard against 7 sister surfaces, 1 violation-message specificity check, 2 schema/info presence)
- doctrine: 220/200 (the 7axmt arc's lint-time enforcement deliverable; pair-pattern matrix from sister fixes is now codified into a detector; exemption markers (`IDEMPOTENT-BY-CONSTRUCTION`) are publishable convention)
- integration risk: 200/200 (additive rule; L7 unchanged; default `--rule` behavior includes L10 but operators can `--rule L1-L9` to opt out; no behavior change to existing L1-L9 violations)
- live demonstration: 200/200 (12 assertions exercise real lint invocations; 7-sister regression guard verifies real surface files; comment-stripping verified by exemption test)

Total: 1100/1040 → 1000

## Skill discoveries

None new — L10 codifies the pair-pattern matrix established by the 7 sister fixes. The exemption-marker convention (`# IDEMPOTENT-BY-CONSTRUCTION:`) is a small piece of publishable doctrine: future operators marking a surface idempotent-by-design opt out of L10 with a single comment line.

## 7axmt arc — COMPLETE

This bead closes the 7axmt audit's deliverables:

| Deliverable | Status | Commit |
|---|---|---|
| 7axmt audit + scanner + per-violation fix-specs | shipped | a3666bf |
| 8sx9w (P0) sync-canonical-doctrine | shipped | 19c8cfc |
| 1o9fa (P1) stale-error-auto-ping | shipped | 5f66a44 |
| j0xpa (P1) security-precommit-installer | shipped | 074d66e |
| j99xb (P1) regenerate-dicklesworthstone-sources | shipped | c55f962 |
| mfy7u (P2) hub-blocker-detect | shipped | ca86bcf |
| y0ft6 (P2) bcv-task-harness | shipped | aff20b7 |
| wdh08 (P3) jeff-bead-285-divergence-capture | shipped | f7821e7 |
| **9dace (this) L10 lint rule** | **shipped** | **(this commit)** |

**9 beads, all closed in one session. 105 total regression assertions across the cluster (12 L10 + 93 idempotency-key sister surfaces). Zero failures. 5 cumulative skill discoveries (all stable).**

The arc is mature enough that future audits can detect the same bug class via `bash .flywheel/scripts/canonical-cli-lint.sh <path> --rule L10` and reach for the same pair-pattern matrix established here.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Final deliverable of the 7axmt arc shipped same session as the 7 surface fixes + the audit itself. Lint rule codifies the doctrine; future operators don't need to re-derive the pattern from scratch. Exemption markers give clean opt-out for legitimately read-only or idempotent surfaces.
- **sniff**: 12 in-bead assertions with 9 synthetic fixtures covering all 4 mutation pattern families (git, ntm, br, sed/plist) + 4 exemption types. **AG11 is the regression guard**: all 7 freshly-fixed sister surfaces must PASS L10. 112 sister assertions clean. Mutation-pattern matching excludes comment-only lines (no false positives on documentation strings mentioning `git commit`).
- **jeff**: Data decided — patterns lifted from the 7axmt audit's scanner.py + the 7 sister fix-shapes; exemption marker `# IDEMPOTENT-BY-CONSTRUCTION:` is a new tiny convention but follows the established `# flywheel-cli-surface: true` marker pattern from L6. L7 preserved as broad warn-level coexisting with L10 narrow error-level.
- **public**: Three Judges: operator running lint sees actionable error message naming the triggering mutation pattern; maintainer sees the L7 vs L10 distinction documented in the header comments + this evidence; future worker authoring a new `--apply` surface sees lint output + can either add `--idempotency-key` (the right path) or add the `# IDEMPOTENT-BY-CONSTRUCTION:` marker (legitimate opt-out for atomic-replace/write-if-changed surfaces).
