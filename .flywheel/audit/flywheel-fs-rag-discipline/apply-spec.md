---
title: Filesystem-as-RAG discipline (doctrine + linter + scaffolder)
type: apply-spec
created: 2026-05-10
bead: flywheel-fs-rag-discipline
chain: doctor-mode-integration
---

# Filesystem-as-RAG discipline

Joshua signoff 2026-05-10: "treat our filesystems like a RAG in and of itself
— every repo we touch needs to be built & organized as if we were presenting
it to the world." Drives concrete structural discipline + mechanical
enforcement.

## Doctrinal claim

The filesystem IS the RAG substrate. Agents (and humans) discover content by
browsing directories, reading frontmatter, scanning section headers, and
following anchor markers. If the filesystem is disorderly, retrieval
degrades — independent of the LLM's capabilities or the embedding model's
quality.

This is the structural complement to the canonical-cli-helpers chain:
- canonical-cli-helpers + lint = the **runtime** introspection contract
- filesystem-as-RAG = the **at-rest** introspection contract

Research backing:
- Anthropic Contextual Retrieval (2024) — chunk-level prepending of context
  improves retrieval by 49-67%. Extending the principle to entire docs:
  prepend metadata (frontmatter) + structural anchors so each chunk arrives
  with self-explanatory context.
- ReaderLM-v2 (Jina AI, arxiv 2503.01151) — Markdown is the canonical
  destination format; structural discipline within Markdown gets ~80% of
  HTML's hierarchy benefit at ~30% of the token cost.
- See `.flywheel/audit/flywheel-fs-rag-discipline/research-citations.md`
  (filed by this bead).

## Scope

### AG1: doctrine doc

Ship `.flywheel/doctrine/filesystem-as-rag.md` (~150-200 lines) covering:

1. **Universal Discoverability** — agents discover by browsing; structure
   must be self-explanatory without external context.
2. **YAML Frontmatter Rule** — every meaningful `.md` carries
   `title`, `type`, `created`, optional `tags` / `bead` / `parent` /
   `expires`. Machine-readable, RAG-indexable.
3. **Section Anchors Rule** — docs >200 lines have `## H2` anchors at least
   every ~80 lines for RAG retrieval; long sections add
   `<!-- AGENT-ANCHOR: <id> -->` markers.
4. **Local README Rule** — every meaningful dir
   (`audit/<bead>/`, `doctrine/`, `PLANS/<plan-slug>/`, `reports/`,
   `evidence/`) has a `README.md` explaining purpose + naming convention +
   exemplar links.
5. **Public Voice Rule** — write as if a stranger reads it: no
   pronoun-only references, no in-jokes, no `we`/`our` ambiguity. Name
   beads, files, dates explicitly.
6. **Dated Artifacts Rule** — temporal artifacts use `YYYY-MM-DD`
   (or ISO) in filename AND frontmatter `created` field.
7. **No Junk Drawers Rule** — no `_archive/`, `WIP_*`, `_old_*`, or
   `.bak.*` committed. Use git history. Use frontmatter
   `status: archived` if a doc must stay in tree but is superseded.
8. **Mechanical Validation Rule** — every rule above is lint-checkable;
   doctrine has linter as its dual.
9. **Cross-repo propagation** — doctrine ships in flywheel first;
   propagation to alps, mobile-eats, skillos, vrtx files as followup
   beads.

### AG2: linter

Ship `.flywheel/scripts/file-rag-discipline-lint.sh` checking:

| Rule | Check | Severity |
|---|---|---|
| F1 | `.md` files have YAML frontmatter (or are explicitly exempt: README.md at repo root, INCIDENTS.md, AGENTS.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE.md) | error |
| F2 | Every dir under `.flywheel/audit/`, `.flywheel/PLANS/`, `.flywheel/doctrine/` has README.md OR a canonical content file (apply-spec.md, evidence.md, STATE.json) | warn |
| F3 | Markdown docs >200 lines have ≥1 `## H2` anchor per ~80-line section | warn |
| F4 | No `.bak.*` or `*.bak.*` files committed (allow in `.gitignore` paths only) | error |
| F5 | Filenames are kebab-case for docs (no spaces, no `_` except in test fixtures + receipts) | warn |
| F6 | Dated filenames use `YYYY-MM-DD` ISO format consistently | warn |
| F7 | `apply-spec.md` files have canonical structure (`## Goal`, `## Scope`, `## Boundary`, `## Acceptance gate` or `## Success criteria` H2 sections) | warn |
| F8 | Long docs (>500 lines) have a TOC or section index near the top | info |

Output:
```bash
file-rag-discipline-lint.sh <path>                # one file/dir
file-rag-discipline-lint.sh --scan-all            # whole repo
file-rag-discipline-lint.sh --scan-all --json     # baseline output
file-rag-discipline-lint.sh <path> --rule F1,F4   # filter rules
file-rag-discipline-lint.sh --backfill-frontmatter <path>   # auto-fix F1
```

Schema: `file-rag-discipline-lint/v1`. Exit 0 clean, 1 violations, 2 errors.

### AG3: frontmatter scaffolder

Ship `.flywheel/scripts/scaffold-doc-frontmatter.sh` that:

- Takes a `.md` file (or a dir, with `--recursive`)
- If file already has frontmatter: skip (idempotent)
- Otherwise: infer `title` from H1 (or filename), `type` from path
  (audit-spec / doctrine / plan / report / handoff / evidence / general),
  `created` from git first-commit-date or file mtime, `bead` from path
  pattern (`flywheel-<id>` matches)
- Emit unified diff (`--dry-run` default) or apply (`--apply --idempotency-key KEY`)
- Generate audit row to
  `.flywheel/state/scaffold-doc-frontmatter-runs.jsonl`

### AG4: pre-commit hook

Ship `.flywheel/hooks/file-rag-discipline-pre-commit.sh` that:
- Runs `file-rag-discipline-lint.sh` on every staged `.md` file
- Refuses commit if F1, F4 violations (errors)
- Warns on F2/F3/F5/F6/F7 (allows commit)
- `--no-verify` override available

### AG5: regression test

Ship `tests/file-rag-discipline-lint.sh` exercising:
- Each of 8 rules with positive + negative fixtures
- `--scan-all --json` produces canonical envelope
- `--backfill-frontmatter` applies F1 fix idempotently
- Pre-commit hook refuses staged file with frontmatter missing,
  allows with frontmatter present

### AG6: baseline scan

After linter ships, run `file-rag-discipline-lint.sh --scan-all --json` and
write `.flywheel/audit/flywheel-fs-rag-discipline/baseline.json`. Reports
expected: hundreds of violations across hundreds of `.md` files. This is
the input to AG7 (backfill).

### AG7: backfill high-leverage dirs

Run `scaffold-doc-frontmatter.sh --recursive --apply --idempotency-key fs-rag-backfill-2026-05-10`
on:
- `.flywheel/doctrine/` (canonical doctrine — high-leverage)
- `.flywheel/PLANS/` (plan artifacts — high-leverage)
- `.flywheel/audit/<recent-30-day-beads>/` (active audit dirs)

Skip:
- `.flywheel/reports/daily-*.md` (auto-generated, separate doctrine)
- `.flywheel/handoffs/` (already mostly compliant)
- `.flywheel/evidence/` (per-bead, varied shapes)

### AG8: README.md scaffolds

Generate `README.md` for the high-leverage parent dirs that lack them:
- `.flywheel/doctrine/README.md` (catalog of all doctrine docs)
- `.flywheel/audit/README.md` (audit dir convention + pointer to bead lookup)
- `.flywheel/PLANS/README.md` (plan dir lifecycle + STATE.json schema)
- `.flywheel/scripts/README.md` (already exists? if not, scaffold)
- `.flywheel/lib/README.md` (already exists? if not, scaffold)

### AG9: receipt

Write `.flywheel/audit/flywheel-fs-rag-discipline/evidence.md` with:
- Doctrine doc + linter + scaffolder + hook + test artifact paths
- Baseline scan summary (total .md scanned, violations by rule)
- Backfill summary (frontmatters added, dirs touched)
- README.md scaffolds shipped
- Pre-commit hook install verification

## Boundary

- ALL changes are reversible via git revert.
- Doctrine doc + linter + scaffolder + hook are NEW files (no existing
  file rewrites except the 4-5 README.md scaffolds, which are auto-generated
  with frontmatter `auto_generated: true`).
- Backfill adds frontmatter ONLY (no body content changes); idempotency-key
  required for any frontmatter add; ALL backfilled files get
  `frontmatter_source: scaffold-doc-frontmatter` for traceability.
- ZERO changes to scripts, beads, or runtime substrate.
- Does NOT touch sister repos (alps, mobile-eats, skillos, vrtx) —
  cross-repo propagation is a SEPARATE followup bead.

## Acceptance gate

- `bash -n` clean on all 4 new shell scripts (linter, scaffolder, hook, test)
- `bash tests/file-rag-discipline-lint.sh` reports all-pass on rule fixtures
- Linter runs clean on doctrine doc itself + its own audit dir
- Backfill is byte-identical-on-second-run (idempotency proven)
- README.md scaffolds emit valid frontmatter + actually catalog the dir
- Baseline.json captured before backfill (visible improvement on re-scan)
- Pre-commit hook denies a staged file with missing frontmatter
  (positive test fixture)

## Estimated effort

~3-4 hours. Composition:
- Doctrine doc: ~30 min (research-backed, structured prose)
- Linter (8 rules): ~60 min (parallel pattern with canonical-cli-lint)
- Scaffolder: ~30 min (frontmatter parser + writer)
- Pre-commit hook: ~15 min (thin wrapper)
- Test fixtures: ~30 min
- Baseline scan + backfill + README scaffolds: ~30 min
- Receipt + commit chain: ~30 min

## Cross-orch implications

After this lands in flywheel:
- File followup beads for cross-repo propagation: `alps`, `mobile-eats`,
  `skillos`, `vrtx`, `picoz`, `zesttube`. Each is a per-repo small lift
  (~1h: copy linter + scaffolder, run baseline, backfill).
- Notify skillos:1 (NIGHTHAWK) — they may want to align their TS-side
  doc discipline with the same rules. Their `--format toon` work in
  cli-kit hints they're already philosophically aligned.

## Dependencies

- None (independent from canonical-cli tooling chain).
- Can run in parallel with bead 2.x lane work.
