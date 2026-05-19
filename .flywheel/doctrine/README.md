---
title: Flywheel doctrine catalog
type: readme
created: 2026-05-10
updated: 2026-05-11
auto_generated: true
bead: flywheel-s8tdd
update_bead: flywheel-kk08x
parent: filesystem-as-rag
inventory_as_of: 2026-05-11
total_doctrines: 90
canonical_doctrines: 81
cross_reference_stubs: 9
last_added: cross-repo-write-path-discipline (flywheel-16b53.3 P0 trauma-mitigation-C)
---

# `.flywheel/doctrine/`

Canonical doctrine documents for the flywheel substrate. Each doc is
authoritative for its named topic and is the single source of truth
for downstream artifacts (skills, scripts, beads).

## Naming convention

`<topic-kebab>.md` — one doctrine per file, named for the topic.
Frontmatter required (per `filesystem-as-rag.md` Rule 2).

## Catalog

The catalog is materialized by `ls -1 .flywheel/doctrine/*.md` —
this README is intentionally not exhaustive so it doesn't drift.
For the live list:

```bash
ls -1 .flywheel/doctrine/*.md
```

Notable load-bearing doctrines (as of 2026-05-10):

- `filesystem-as-rag.md` — at-rest discoverability discipline (this dir's parent)
- `dispatch-author-skill-routing-contract.md` — orch dispatch path
- `skill-autoresearch-tooling-preference-class.md` — skill-target routing

## Inventory snapshot (2026-05-11)

- Total doctrine files: **89**
- Canonical (flywheel-authored or fleet-promoted): **80**
- Cross-reference stubs (skillos-canonical pointer, `type: doctrine-cross-reference-stub`): **9**

Live counts:

```bash
# Total
ls -1 .flywheel/doctrine/*.md | wc -l

# Stubs only
for f in .flywheel/doctrine/*.md; do
  head -10 "$f" | grep -q "type: doctrine-cross-reference-stub" && echo "$f"
done | wc -l

# Canonical only (= total minus stubs)
```

## Recent additions (2026-05-11 wave)

6 new canonical doctrines shipped in the v38e1 cohort + cluster-promotion arc:

| File | Source bead | Class |
|------|-------------|-------|
| `closure-evidence-contract-version-anchor.md` | flywheel-v38e1.1 | cross-orch closure-evidence discipline |
| `closure-evidence-public-lens-anchor-discipline.md` | flywheel-v38e1.2 | cross-orch closure-evidence discipline |
| `inbox-discipline-missed-during-deep-burndown-motion.md` | flywheel-v38e1.3 | cross-orch bilateral protocol (0th probe) |
| `outbox-discipline-cross-orch-ship-notification.md` | flywheel-v38e1.4 | cross-orch bilateral protocol (outgoing) |
| `option-e-cross-orch-fuckup-log-fold-up.md` | flywheel-nk0r0 | mechanization-axis META-pattern |
| `single-axis-reframe-of-multi-axis-data-trauma-class.md` | flywheel-0mw8v | META-EXTRACTION-DRIFT trauma class |

9 cross-reference stubs to skillos-canonical META-doctrines (`type: doctrine-cross-reference-stub`):

| File | Skillos canonical authority |
|------|----------------------------|
| `additive-v0.0.2-expansion-after-v0.0.1-under-extraction.md` | skillos:1 |
| `cross-language-audit-as-cousin-scout.md` | skillos:1 |
| `depth-axis-mismatch.md` | skillos:1 |
| `dispatch-assumes-fresh-extraction-but-package-preexists.md` | skillos:1 |
| `dispatch-expectation-vs-audit-verdict-divergence.md` | skillos:1 |
| `dispatch-premise-mismatch.md` | skillos:1 |
| `meta-aggregation-family.md` (v0.3) | skillos:1 (mobile-eats:1 authored, skillos canonical-locator) |
| `source-project-aggregation-from-n-repos.md` | skillos:1 |
| `substrate-layer-shape-mismatch.md` | skillos:1 |

Stubs follow `cross-repo-consumer-vs-mutator-boundary.md` discipline: read-only consumer pattern at flywheel side; canonical body lives at skillos canonical-locator path. Verify byte-equality via `sha256` anchor in the stub frontmatter when ratifying.

## Lifecycle

- **active** — currently load-bearing
- **archived** / **superseded** — kept in tree for history; new work
  uses the named successor (named in frontmatter `superseded_by:`)

Per `filesystem-as-rag.md` Rule 7 (No Junk Drawers), superseded
doctrines stay in this directory with `status: superseded` rather than
being moved to `_archive/`.

## Authoring a new doctrine

1. Author the body
2. Add frontmatter via `.flywheel/scripts/scaffold-doc-frontmatter.sh`
3. Lint with `.flywheel/scripts/file-rag-discipline-lint.sh`
4. Commit with reference bead in trailer

## Cross-references

- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
- Doctrine source rule: `.flywheel/doctrine/filesystem-as-rag.md`
- AGENTS.md (canonical operational doctrine): `../../AGENTS.md`
- AGENTS.md (repo-local snapshot): `../AGENTS.md`
- Cross-orch discipline: `cross-repo-consumer-vs-mutator-boundary.md`, `substrate-boundary-three-class-taxonomy.md`


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
