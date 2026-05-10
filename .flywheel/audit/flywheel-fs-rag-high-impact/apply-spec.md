---
title: fs-rag high-impact violation fixes (F8 + F3 + F7 on retrieval-critical docs)
type: apply-spec
created: 2026-05-10
bead: flywheel-fs-rag-high-impact
parent: flywheel-s8tdd (closed)
chain: doctor-mode-integration / fs-rag-discipline
leverage_points:
  - "#3 system goals (optimize for retrieval quality, not parameter counts)"
---

# fs-rag high-impact violation fixes

Joshua signoff 2026-05-10 (Meadows-lens reframe): the violation count
optimization target was wrong. F1 (frontmatter, 844) is high-volume
parameter tuning. F8/F3/F7 are LOW-volume but HIGH-per-doc impact on
the docs most likely to surface in agent retrieval.

This bead fixes the few-but-critical violations and skips the
high-volume-low-impact ones.

## Goal

Retrieval-quality optimization on the load-bearing long docs in
flywheel. Fix violations that actually degrade RAG navigation (long
docs without TOCs, long docs without section anchors, apply-specs
missing canonical structure) — not violations that affect metadata only.

## Scope

### AG1: identify retrieval-critical docs

Run `file-rag-discipline-lint.sh --scan-all --rule F8,F3,F7 --json` and
filter to:

- F8 violations on docs in `.flywheel/{doctrine,PLANS,audit,reports}/`
  with >500 lines (the long docs that suffer from no-TOC retrieval)
- F3 violations on docs >200 lines without section anchors
- F7 violations on apply-spec.md files

Skip F8/F3 violations on:
- `.flywheel/runtime/` (auto-generated state)
- `.flywheel/state/` (machine-only artifacts)
- `tests/` (test fixtures don't need TOCs)
- Anything with frontmatter `auto_generated: true`

Expect ~30-50 high-impact docs total.

### AG2: fix per-doc

For each F8 violation:
- Add a TOC at top, after frontmatter
- TOC includes all H2 + selected H3 anchors
- Format: bullet list with markdown anchor links

For each F3 violation:
- Identify natural section boundaries (~80-line chunks)
- Add `## H2` headers if missing
- For very long sub-sections, add `<!-- AGENT-ANCHOR: <slug> -->`
  markers for retrieval hints

For each F7 violation (apply-spec.md):
- Reorder/insert canonical H2 sections: `## Goal`, `## Scope`,
  `## Boundary`, `## Acceptance gate` (or `## Success criteria`)
- DO NOT change the body content; just structure the headers

### AG3: regression — re-lint

After fixes:
- `file-rag-discipline-lint.sh --scan-all --rule F8,F3,F7 --json` should
  show <5 remaining violations on retrieval-critical docs
- The `pilot-lessons.md`, `inventory.jsonl`, and other audit artifacts
  must REGENERATE-IDENTICALLY after fix (no content corruption)

### AG4: F4 cleanup (.bak.* committed)

The 21 F4 violations are likely committed `.bak.<timestamp>` artifacts
from old auto-rotations. Audit each:
- If superseded by a newer `.bak.*`: delete via `git rm`
- If only one bak exists: delete (the actual file is canonical;
  bak is git-redundant)

Add `*.bak.*` to `.gitignore` if not already present, so future bak
files don't get committed.

### AG5: F7 audit-spec backfill (6 violations)

The 6 F7 violations are apply-spec.md files missing canonical structure.
Identify them via `--rule F7 --json`. Backfill the missing H2 sections
without changing body content.

### AG6: receipt

Write `.flywheel/audit/flywheel-fs-rag-high-impact/evidence.md`:
- Per-rule before/after violation counts
- List of docs touched (with diffs)
- Re-lint verification (F8/F3/F7 violations <5 each)
- F4 cleanup log
- Any docs intentionally left as violations (with `frontmatter
  exempt_reason: ...`)

## Boundary

- DO NOT touch F1 (wave-2 frontmatter backfill — high-volume, low-impact;
  the pre-commit hook prevents new ones; existing ones erode naturally
  as files get touched)
- DO NOT touch F5 (filename kebab-case — cosmetic; rename-cost > value)
- DO NOT touch F2 (missing dir READMEs — covered by AG8 of s8tdd
  partially; remainder is sibling-repo work)
- DO NOT change body content of any doc beyond inserting TOCs/headers
- All changes reversible via git revert

## Acceptance gate

- F8/F3/F7 violations on retrieval-critical docs: <5 remaining each
- F4 violations: 0 (or all justified via .gitignore exemption)
- 30-50 docs touched (estimated; actual TBD)
- Re-lint --scan-all confirms reduction
- No body-content corruption (audit dataset comparable to baseline)
- Evidence.md documents what changed + why each touched doc was selected

## Estimated effort

~1-1.5 hours:
- AG1 (identify): 10 min (filter command)
- AG2 (per-doc fix): 5-10 min × ~30 docs ≈ 30-60 min
- AG3 (re-lint): 5 min
- AG4 (F4 cleanup): 15 min
- AG5 (F7 backfill): 15 min
- AG6 (receipt): 15 min

## Dependencies

- s8tdd (fs-rag-discipline base ship) — CLOSED. Linter + scaffolder ready.
- No other blockers; runs parallel with fs-rag-portable bead.
