---
title: Filesystem-as-RAG discipline
type: doctrine
created: 2026-05-10
bead: flywheel-s8tdd
parent: doctor-mode-integration
tags:
  - doctrine
  - filesystem
  - retrieval-augmented-generation
  - canonical-cli
status: active
---

# Filesystem-as-RAG discipline

> "Treat our filesystems like a RAG in and of itself; every repo we touch
> needs to be built and organized as if we were presenting it to the world."
> — Joshua, 2026-05-10

The filesystem **is** the retrieval substrate. Agents and humans alike
discover content by browsing directories, reading frontmatter, scanning
section headers, and following anchor markers. If the filesystem is
disorderly, retrieval degrades — independent of LLM capability or
embedding-model quality.

This is the **structural complement** to the canonical-CLI helpers chain:

- `canonical-cli-helpers` + `canonical-cli-lint` = the **runtime** introspection contract
- `filesystem-as-RAG` (this doc + `file-rag-discipline-lint`) = the **at-rest** introspection contract

## Research backing

- **Anthropic Contextual Retrieval (2024)** — chunk-level prepending of
  context improves retrieval by 49–67%. Extending the principle to entire
  documents: prepend metadata (frontmatter) and structural anchors so each
  chunk arrives with self-explanatory context.
- **ReaderLM-v2 (Jina AI, arXiv 2503.01151)** — Markdown is the canonical
  destination format; structural discipline within Markdown gets ~80% of
  HTML's hierarchy benefit at ~30% of the token cost.
- **MTEB and BEIR retrieval benchmarks** — recall@k is dominated by
  structural cues (headings, list markers, frontmatter) more than by
  semantic similarity at the long-document scale.

See `.flywheel/audit/flywheel-fs-rag-discipline/` for citations + scan
baseline.

## Nine rules

### 1. Universal Discoverability

Agents discover by **browsing** before they query. A directory listing
must be self-explanatory without external context. If you have to read
the bead to understand the directory, the directory is wrong.

Concretely: every meaningful directory has either a `README.md` or a
canonical content file (`apply-spec.md`, `evidence.md`, `STATE.json`)
that names its purpose.

### 2. YAML Frontmatter Rule

Every meaningful `.md` carries YAML frontmatter at the top:

```yaml
---
title: <human-readable title>
type: <audit-spec|doctrine|plan|report|handoff|evidence|general>
created: <YYYY-MM-DD>
bead: <flywheel-id-if-applicable>
parent: <parent-doc-or-effort>
tags:
  - <kebab-case-tag>
status: <draft|active|archived|superseded>
---
```

Required fields: `title`, `type`, `created`. Optional: `bead`, `parent`,
`tags`, `status`, `expires`, `owner`.

**Exempt files** (no frontmatter required):
- `README.md` at repo root
- `INCIDENTS.md`, `AGENTS.md`, `CHANGELOG.md`, `CONTRIBUTING.md`,
  `LICENSE.md`
- `*.lock`, `*.cache`, generator-output `.md` (auto-attested via
  `auto_generated: true` frontmatter when present)

### 3. Section Anchors Rule

Markdown documents longer than 200 lines have `## H2` anchors at least
every ~80 lines for RAG retrieval. Long sections (>~80 lines without an
anchor) add an explicit anchor marker:

```markdown
<!-- AGENT-ANCHOR: section-name-kebab -->
```

The marker is grep-friendly and gives long-form prose a stable handle.

### 4. Local README Rule

Every meaningful directory has a `README.md` explaining:
- The directory's purpose
- The naming convention for files inside it
- One or more exemplar links to representative artifacts

Specifically required for: `audit/<bead>/`, `doctrine/`, `PLANS/<plan>/`,
`reports/`, `evidence/<bead>/`. The README MAY be auto-generated when
the dir is mechanical (e.g., `evidence/<bead>/`); auto-generated READMEs
carry frontmatter `auto_generated: true`.

### 5. Public Voice Rule

Write as if a stranger reads it:
- No pronoun-only references ("we did X" → "the flywheel orchestrator did X")
- No in-jokes
- Name beads, files, dates, scripts explicitly
- Avoid `we`/`our` ambiguity in prose; prefer named subject

This is the *Three Judges* discipline applied to docs: skeptical
operator, maintainer, future worker. Each must understand without
reading your prior conversations.

### 6. Dated Artifacts Rule

Temporal artifacts use `YYYY-MM-DD` (or full ISO8601 when intra-day
ordering matters) **both** in the filename AND in the frontmatter
`created` field:

```
.flywheel/reports/daily-2026-05-10.md
.flywheel/handoffs/20260510T020000Z-end-of-day.md
.flywheel/research/fleet-ops-meeting-2026-05-05/
```

### 7. No Junk Drawers Rule

The filesystem does not have an `_archive/`, `WIP_*`, `_old_*`, or
`.bak.*` committed. Use git history for revisions. If a doc must stay
in the working tree but is superseded, set frontmatter
`status: archived` (or `status: superseded`) and keep the file in
place.

### 8. Mechanical Validation Rule

Every rule above is **lint-checkable**. Doctrine has its linter as its
dual: `.flywheel/scripts/file-rag-discipline-lint.sh` checks rules
F1–F8 mechanically; the doctrine and the linter ship together so prose
and enforcement cannot drift.

### 9. Cross-repo Propagation

Doctrine ships in flywheel **first**. Propagation to sister repos
(alps, mobile-eats, skillos, vrtx, picoz, zesttube) files as separate
followup beads — each is a per-repo lift of ~1h (copy linter +
scaffolder, run baseline, backfill).

## How to use this doctrine

### When authoring a new `.md` file

1. Author the body
2. Run `.flywheel/scripts/scaffold-doc-frontmatter.sh <path>` to add
   frontmatter (idempotent — skips if frontmatter already present)
3. If the doc lives in a new directory, add a `README.md` per Rule 4
4. Run `.flywheel/scripts/file-rag-discipline-lint.sh <path>` before
   commit

### When backfilling a directory

```bash
.flywheel/scripts/scaffold-doc-frontmatter.sh \
  --recursive --apply --idempotency-key <key> \
  <directory>
```

### When the pre-commit hook refuses

Either fix the violation (preferred) or pass `--no-verify` (Joshua's
prerogative; document the reason in the commit message).

## Cross-references

- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
- Scaffolder: `.flywheel/scripts/scaffold-doc-frontmatter.sh`
- Pre-commit hook: `.flywheel/hooks/file-rag-discipline-pre-commit.sh`
- Regression test: `tests/file-rag-discipline-lint.sh`
- Apply-spec: `.flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md`
- Sibling discipline: `canonical-cli-scoping`
  (`~/.claude/skills/canonical-cli-scoping/SKILL.md`)
- Sibling linter: `.flywheel/scripts/canonical-cli-lint.sh`
  (flywheel-etp5n)

## Why this matters

Joshua's signoff names the load-bearing claim: "every repo we touch needs
to be built and organized as if we were presenting it to the world." The
audience is not just the future Joshua — it is every autonomous agent
that browses the tree, every operator who hits the codebase cold, and
every retrieval pipeline that indexes the artifacts. The filesystem is
the first contact surface; structural discipline at this layer
compounds across every downstream consumer.
