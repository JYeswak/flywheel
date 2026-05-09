# flywheel-keji Evidence — fix br list shape in library ingestion test

Task: `flywheel-keji-2d55d6`
Bead: `flywheel-keji` (P2 OPEN → CLOSED this turn)
Title: [jeff-corpus-test] fix br list shape in library ingestion test
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Repo: `/Users/josh/Developer/flywheel`
Source: validation of `flywheel-1lpv` 2026-05-04 — `jq: Cannot index array with string "issues"` on AG6.

## What changed

`tests/jeff-corpus-library-ingestion.sh` only. No production script edits.

1. AG6 jq expression made shape-tolerant:
   ```
   [(if type == "object" then .issues else . end)[] | select(...) ] | length >= 5
   ```
   Tolerates both legacy `{issues: [...]}` and current br 0.2.5 top-level array.
2. New `derived_beads_shape_fixture_check()` writes two synthetic
   inputs (5 matching rows in each shape) and asserts the same jq
   expression against both. Wired into `main()` immediately after
   `derived_beads_check`.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG-1 — tolerate top-level array AND legacy object-with-issues | DID | `tests/jeff-corpus-library-ingestion.sh:81-90` |
| AG-2 — fixture both shapes | DID | `tests/jeff-corpus-library-ingestion.sh:92-116`; `after-test-output-merged.txt` shows `PASS AG6-fixture array shape` and `PASS AG6-fixture object-with-issues shape` |
| AG-3 — passes or fails only on real corpus gate | DID | `after-test-output-merged.txt` SUMMARY: `pass=9 fail=1`; the one FAIL is AG6 main on the real `br list` data (only 1 jeff-corpus-derived P0/P1 bead exists, need ≥5) — that is a real corpus shortfall, NOT a shape bug |
| AG-4 — no production script behavior changes | DID | `git diff` touches `tests/jeff-corpus-library-ingestion.sh` only; `flywheel-loop`, `loop-integrity-signals.sh`, etc. unchanged |
| AG-5 — callback cites before/after test output | DID | this evidence pack at `.flywheel/audit/flywheel-keji/`; merged stderr+stdout captures preserved |

did=5/5 didnt=none gaps=none.

## Files changed

- `tests/jeff-corpus-library-ingestion.sh` — shape-tolerant AG6 jq + new
  fixture function + main wiring.
- `.flywheel/audit/flywheel-keji/evidence.md` — this report.
- `.flywheel/audit/flywheel-keji/before-test-output-merged.txt` — pre-edit
  test output (stderr merged), 7 PASS + 1 FAIL on AG6 (jq shape error).
- `.flywheel/audit/flywheel-keji/after-test-output-merged.txt` — post-edit
  test output, 9 PASS + 1 FAIL where the only FAIL is AG6 main on real
  corpus shortfall (both fixture shapes PASS).

Pathspec staging only.

## Before / After receipts

### BEFORE (pre-edit, file from stash)

```
PASS AG1 verified repo state covers 177 repos
PASS AG3 persistent progress supports resume-after-interrupt
PASS AG5 ten per-query learning artifacts exist
PASS AG5 learning artifacts carry required sections
PASS AG9 fixture query artifacts present
FAIL AG6 five P0/P1 jeff-corpus-derived beads exist
PASS AG8 jeff-intel state and learnings canonical paths exist
PASS AG7 doctor exposes jeff_corpus_indexed_count
SUMMARY pass=7 fail=1
```

### AFTER (post-edit)

```
PASS AG1 verified repo state covers 177 repos
PASS AG3 persistent progress supports resume-after-interrupt
PASS AG5 ten per-query learning artifacts exist
PASS AG5 learning artifacts carry required sections
PASS AG9 fixture query artifacts present
FAIL AG6 five P0/P1 jeff-corpus-derived beads exist
PASS AG6-fixture array shape (5 matching beads)
PASS AG6-fixture object-with-issues shape (5 matching beads)
PASS AG8 jeff-intel state and learnings canonical paths exist
PASS AG7 doctor exposes jeff_corpus_indexed_count
SUMMARY pass=9 fail=1
```

Net: +2 PASS gates (the two fixtures). The AG6 FAIL changes meaning —
before it was a *shape* failure (`jq: Cannot index array with string
"issues"`); after it is a *corpus* failure (only 1 jeff-corpus-derived
P0/P1 bead exists; the test discriminates correctly between the two
classes via the fixtures).

## Verification commands (re-runnable)

```bash
# Run merged
bash /Users/josh/Developer/flywheel/tests/jeff-corpus-library-ingestion.sh > /tmp/wt-keji/now.txt 2>&1
# Both fixture shapes must PASS
grep -q "PASS AG6-fixture array shape" /tmp/wt-keji/now.txt \
  && grep -q "PASS AG6-fixture object-with-issues shape" /tmp/wt-keji/now.txt \
  && echo ok || echo missing
```

Expected: literal `ok`.

## L112 probe (worker callback)

```bash
grep -q "PASS AG6-fixture array shape (5 matching beads)" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-keji/after-test-output-merged.txt \
  && grep -q "PASS AG6-fixture object-with-issues shape (5 matching beads)" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-keji/after-test-output-merged.txt \
  && echo ok || echo missing
```

Expected: literal `ok`.

## Boundary

- No production script touched (no `flywheel-loop`, no `loop-integrity-signals.sh`, no `gap-hunt-probe.sh`, no skill mutation).
- AG6 main still fails on real corpus (only 1 P0/P1 jeff-corpus-derived bead). That gap is corpus content, owned by the broader `flywheel-1lpv` arc — out of scope for this rework which is purely a test-shape fix.
- No upstream Jeffrey patch. Test-local change only.
- No `git restore` on working tree; no `mv` of sensitive paths; no DCG-blocked operations.

## Skill auto-routes

- `canonical-cli-scoping`: n/a — no CLI authored, only jq tolerance in a test.
- `rust-best-practices`: n/a.
- `python-best-practices`: n/a.
- `readme-writing`: n/a — audit-doc style.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=test_shape_fix_only_no_canonical_surface_or_doctrine_mutated`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes acceptance gates 1-5 verbatim (shape tolerance,
  fixture coverage, real-corpus discrimination, production unchanged,
  before/after captures cited).
- **Sniff: 9** — fixture proves the jq is correct on both shapes; the
  remaining FAIL is honestly attributed to corpus content, not test
  bug. The test now discriminates between shape and corpus failures.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; no upstream
  patch; pin (`br 0.2.5`) named explicitly; small surface (test only);
  problem-statement framing for the corpus shortfall (call out, route
  to flywheel-1lpv arc, don't auto-file).
- **Public: 9** — Three Judges check passes:
  - operator: re-run command in <1s; PASS/FAIL deterministic on jq tolerance;
  - maintainer: future br shape changes break only AG6-fixture asserts cleanly, with grep-friendly labels;
  - future worker: bar named so subsequent reworks of test-shape gates use the same fixture pattern.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8;
bar = Three Judges + Jeffrey Emanuel publishability + Donella Meadows
leverage).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-keji
no_bead_reason=test_shape_rework_complete_corpus_shortfall_already_owned_by_flywheel-1lpv_arc`.

## Mission fitness

`mission_fitness=infrastructure` — fixes a substrate test-shape
assumption that was blocking honest signal from the
`jeff-corpus-library-ingestion` validator. Restores discriminating
power between shape and corpus failures so the broader flywheel-1lpv
arc gets accurate green/red on AG6.
