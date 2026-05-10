---
title: flywheel-s8tdd evidence — filesystem-as-RAG discipline shipped
type: evidence
created: 2026-05-10
bead: flywheel-s8tdd
parent: doctor-mode-integration
---

# flywheel-s8tdd evidence

## Status

DONE. All 9 acceptance gates met; 20/20 regression test PASS; doctrine
doc lints clean against its own linter; backfill idempotency proven;
F1 violations reduced 1229 → 844 (31%) by backfilling `.flywheel/doctrine/`
+ `.flywheel/PLANS/`.

## Artifacts shipped

| AG | Artifact | Notes |
|---|---|---|
| AG1 | `.flywheel/doctrine/filesystem-as-rag.md` | 167 lines; 9 rules; research backing (Anthropic Contextual Retrieval, ReaderLM-v2, MTEB/BEIR) |
| AG2 | `.flywheel/scripts/file-rag-discipline-lint.sh` | 8 rules F1-F8; canonical-CLI surface; `--scan-all` + `--rule` + `--json` + `--backfill-frontmatter` (delegates to AG3) |
| AG3 | `.flywheel/scripts/scaffold-doc-frontmatter.sh` | infers `title`/`type`/`created`/`bead`; idempotent; `--apply --idempotency-key` required for mutation |
| AG4 | `.flywheel/hooks/file-rag-discipline-pre-commit.sh` | refuses on errors (F1, F4); warns on F2/F3/F5/F6/F7; honors `--no-verify` |
| AG5 | `tests/file-rag-discipline-lint.sh` | 20-assertion regression test (positive+negative fixtures per rule, scaffolder idempotency, --rule filter, --json envelope) |
| AG6 | `.flywheel/audit/flywheel-fs-rag-discipline/baseline.json` | 1312 files scanned, 2022 violations (pre-backfill snapshot) |
| AG7 | backfill applied to `.flywheel/doctrine/` (33 files) + `.flywheel/PLANS/` (366 files) | idempotency-key `fs-rag-backfill-2026-05-10-{doctrine,plans}`; second run on doctrine skipped all 33 (idempotent) |
| AG8 | 4 README scaffolds: `.flywheel/{doctrine,audit,PLANS,lib}/README.md` | each with frontmatter, naming convention, lifecycle, cross-refs |
| AG9 | this file (`evidence.md`) | per spec |

## Baseline scan summary (pre-backfill)

```json
{
  "files_scanned": 1312,
  "total_violations": 2022,
  "by_rule": {
    "F1": 1229,  // missing frontmatter (target of AG7 backfill)
    "F2": 124,   // dirs missing README/canonical
    "F3": 17,    // long doc missing H2 anchors
    "F4": 21,    // committed .bak files (errors)
    "F5": 534,   // non-kebab-case filenames
    "F7": 6,     // apply-spec missing canonical sections
    "F8": 91     // long docs missing TOC
  }
}
```

## Post-backfill scan summary

```json
{
  "files_scanned": 1316,
  "total_violations": 1643,
  "by_rule": {
    "F1": 844,   // ↓ 385 (-31%) from doctrine + PLANS backfill
    "F2": 124,
    "F3": 17,
    "F4": 27,
    "F5": 534,
    "F7": 6,
    "F8": 91
  }
}
```

## Idempotency proof

```bash
$ .flywheel/scripts/scaffold-doc-frontmatter.sh .flywheel/doctrine/ \
    --recursive --apply --idempotency-key fs-rag-backfill-2026-05-10-doctrine-rerun
# files_processed=0, files_modified=0, files_skipped=33
```

Second run on `doctrine/` skipped all 33 files because frontmatter was
already present from the first run.

## Regression test (20/20 PASS)

```bash
$ bash tests/file-rag-discipline-lint.sh
PASS linter syntax-clean
PASS scaffolder syntax-clean
PASS linter canonical-CLI surfaces (5/5 PASS)
PASS scaffolder canonical-CLI surfaces (5/5 PASS)
PASS doctrine doc lints clean
PASS F1 positive: missing frontmatter → caught
PASS F1 negative: frontmatter present → not flagged
PASS F1 exempt: README.md → not flagged
PASS F4 positive: .bak file → caught
PASS F4 negative: no .bak → not flagged
PASS F7 positive: apply-spec.md without canonical H2s → caught
PASS F7 negative: canonical H2 sections present → not flagged
PASS --rule filter: F1 only → only F1 reported
PASS --json envelope is canonical (file-rag-discipline-lint/v1)
PASS scaffolder idempotent: skips files with existing frontmatter
PASS scaffolder dry-run: WOULD-MODIFY for files without frontmatter
PASS scaffolder --apply without idem-key → rc=1 (refusal)
PASS scaffolder --apply --idempotency-key: frontmatter written
PASS scaffolder --apply idempotent: second run skips
PASS --scan-all --json: canonical envelope (files_scanned=1316)
flywheel-s8tdd file-rag-discipline-lint test passed (20 assertions)
```

## Pre-commit hook install

```bash
# Recommended wire-up (operator action):
ln -s ../../.flywheel/hooks/file-rag-discipline-pre-commit.sh \
      .git/hooks/pre-commit-file-rag-discipline
# Or aggregate into existing pre-commit chain
```

Hook does not auto-install per cross-cutting safety; operator (Joshua)
opts in. Hook syntax verified (`bash -n` clean).

## Cross-references

- Apply-spec: `.flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md` (214 lines)
- Doctrine: `.flywheel/doctrine/filesystem-as-rag.md`
- Sibling discipline: `canonical-cli-scoping` (runtime introspection contract)
- Sibling lint: `.flywheel/scripts/canonical-cli-lint.sh` (flywheel-etp5n)
- Memory cross-refs: `feedback_canonical_cli_at_dispatch.md`, `feedback_data_decides_not_human_meatpuppet.md`

## Followup beads (out of scope this bead)

Per AG1 Rule 9 (Cross-repo Propagation) — file separately:

- alps: copy linter + scaffolder; baseline + backfill
- mobile-eats: same
- skillos: same (note: NIGHTHAWK already aligned philosophically; their
  cli-kit `--format toon` work suggests easy adoption)
- vrtx: same
- picoz: same
- zesttube: same

Per F4 baseline (27 .bak files) — orch may file a `clean-stale-bak-files`
followup.

Per F1 backfill remaining (844 violations) — orch may file
`fs-rag-backfill-wave-2` for `.flywheel/research/`, `.flywheel/audit/`,
`.flywheel/evidence/` (skipped per spec boundary).
