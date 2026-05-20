---
title: "Operator Library Recipe (cognitive-operator auto-injection for doc-authoring beads)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Operator Library Recipe

Version: `operator-library-recipe/v1`
Owner: orchestrator + workers handling doc-authoring beads (`[doctrine]`, `[skill-md]`, `[skill-promotion]`, `[client-doc-*]`, `[readme]`)
Status: canonical, shipped 2026-05-11
Source bead: flywheel-vbk3h (P2 operator-library-auto-route)
Operator library source: `~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md`

## TL;DR

When the orchestrator dispatches a doc-authoring bead (title prefix
matches `[doctrine]` / `[gap-memory-without-cross-link]` / `[skill-md]` /
`[skill-promotion]` / `[client-doc-*]` / `[readme]`), the dispatch packet
is auto-augmented with an `## OPERATOR LIBRARY RECIPE BLOCK` containing
a per-class **cognitive-operator pipeline** synthesized from the
`documentation-website-for-software-project` skill's OPERATOR-LIBRARY.md.

Workers no longer need to re-derive the operator sequence (★ ORIENT → ✦ MOTIVATE → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK → ⌘ REDUCE) per bead — it appears in the dispatch packet.

This recipe is sister to:
- `forward-link-doctrine-doc-recipe.md` (flywheel-pmg3c, N=4 memory wire-in)
- `cluster-maintainer-pattern.md` (flywheel-r9pri, N=3 skill-wide doc fix)
- `test-receiver-wire-in-recipe.md` (flywheel-eq9wv, N=3 per-script test wire-in)

The four together form the **substrate-self-improvement family** for doc-authoring + script-receiver hygiene.

## The 11 cognitive operators (from OPERATOR-LIBRARY.md)

| Tag | Operator | One-line definition |
|---|---|---|
| ★ | **ORIENT** | First 3 paragraphs: what/who/where; reader lands without needing breadcrumbs |
| ✦ | **MOTIVATE** | Why does this exist? what problem solved? |
| ◐ | **MENTAL-MODEL** | Diagram/sketch/table showing relationships |
| ⬡ | **EXEMPLIFY** | Copy-pasteable runnable example |
| ⚠ | **WARN** | Anti-patterns / pitfalls / gotchas |
| ✧ | **TIP** | Non-obvious insight |
| ⇄ | **CROSS-LINK** | Links to related surfaces |
| ⤵ | **DECOMPOSE** | Break complex idea into parts |
| ⊕ | **SYNTHESIZE** | Merge fragments into coherent whole |
| ⊙ | **DE-SLOP** | Remove fluff, tighten prose |
| ⌘ | **REDUCE** | Cut by 30%+ |

For full per-operator prompt modules + Polish Bar exit criteria, see
the source library at
`~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md`.

## Per-class operator pipelines

### `[doctrine]` / `[gap-memory-without-cross-link]`
**Pipeline:** ★ ORIENT → ✦ MOTIVATE → ◐ MENTAL-MODEL → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK

Why this pipeline: doctrine docs anchor doctrine for future workers.
They need orientation (what/who), motivation (why pay this cost),
mental model (how this relates to sister doctrine), copy-paste
exemplification, anti-pattern warnings, and explicit cross-links to
the source memory + bead-id + sister doctrine.

### `[skill-md]` / `[skill-promotion]`
**Pipeline:** ★ ORIENT → ✦ MOTIVATE → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK → ⌘ REDUCE

Why this pipeline: SKILL.md activation context is precious. Drop the
mental-model section (skills already have references/) but enforce
the REDUCE operator: ≤500 lines, move detail to references/.

### `[client-doc-*]`
**Pipeline:** ★ ORIENT → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK

Why this pipeline: client-facing doc — drop internal-team motivation
(client doesn't need our trauma class history); focus on
orientation + copy-paste + warnings + cross-links. Cross-links must
be one-way (internal source-of-truth pointers not exposed to client).

### `[readme]`
**Pipeline:** ★ ORIENT → ✦ MOTIVATE → ⬡ EXEMPLIFY → ⌘ REDUCE

Why this pipeline: README is the first surface a stranger sees; needs
orientation + motivation + Quick Start exemplification. REDUCE
enforces ≤5 core commands in Quick Start.

## How it's wired

```
build-dispatch-packet.sh
  ├─ inject-skill-auto-routes.sh
  ├─ inject-l-rule-hints.sh
  ├─ inject-forward-link-recipe.sh  ← sister (pmg3c)
  └─ inject-operator-library-recipe.sh  ← THIS (vbk3h)
```

The injector reads the dispatch body, detects title-class via regex,
selects the per-class pipeline, and inserts an `## OPERATOR LIBRARY
RECIPE BLOCK` before `## METADATA` (preserving the canonical
block-ordering invariant per build-dispatch-packet.sh).

When the bead title doesn't match any of the 4 supported classes, the
injector passes through unchanged (no false-positive injection).

## Anti-patterns

- **Do NOT inject for `[bug]` / `[task]` / `[gap-wired-but-cold]` /
  `[gap-probe-without-receiver]`** — these are code/script-class beads;
  the operator library is for doc-authoring.
- **Do NOT replace the recipe block contents** in the dispatch packet
  on a per-bead basis. Edit this doctrine doc + injector script;
  re-dispatch picks up new shape on next packet build.
- **Do NOT add operators beyond the 11 in OPERATOR-LIBRARY.md** without
  updating the source skill first. The library is intentionally small.
- **Do NOT bundle operators across pipelines** (e.g., adding ◐ MENTAL-MODEL
  to `[readme]` pipeline). Each pipeline is curated for its title class.

## Conformance (proof contract)

For this doctrine to be considered live:

1. ✓ `.flywheel/scripts/inject-operator-library-recipe.sh` exists + executable + canonical-cli triad (`--info`, `--schema`, `--examples`, `--doctor`, `--help`)
2. ✓ `.flywheel/scripts/build-dispatch-packet.sh` invokes the injector after inject-forward-link-recipe.sh
3. ✓ `--doctor` returns exit 0 (doctrine_doc=present + builder_wired=wired + source_operator_library=present)
4. ✓ Fixture test passes: doctrine-class body → contains `OPERATOR LIBRARY RECIPE BLOCK`; non-matching body → pass through unchanged
5. ✓ Regression test at `.flywheel/tests/test-inject-operator-library-recipe.sh`

## Substrate-self-improvement family (4 recipes converging)

| Recipe | Source bead | N | Class |
|---|---|---|---|
| cluster-maintainer-pattern | r9pri | 3 | skill-wide doc-completeness |
| forward-link-doctrine-doc-recipe | pmg3c | 4 | memory-without-cross-link |
| test-receiver-wire-in-recipe | eq9wv | 3 | per-script test receiver |
| **operator-library-recipe** | **vbk3h** | **N=1 (this dispatch)** | **doc-authoring cognitive operators** |

The first 3 trigger on probe-class beads (auto-filed by gap-hunt-probe).
This 4th recipe operates a level UP — it shapes the WORKER PROMPT for
doc-authoring beads regardless of their class trigger, ensuring
consistent operator-disciplined output.

## Cross-references

- Source bead: flywheel-vbk3h (P2 operator-library-auto-route, shipped 2026-05-11)
- Sister auto-injector: flywheel-pmg3c (inject-forward-link-recipe.sh)
- Sister recipe docs: cluster-maintainer-pattern.md, forward-link-doctrine-doc-recipe.md, test-receiver-wire-in-recipe.md
- Operator library source: `~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md`
- Build-dispatch-packet integration: `.flywheel/scripts/build-dispatch-packet.sh:937` (sister inject point)
- Polish Bar (Operator triggers): docs-website skill SKILL.md §"the-polish-bar-non-negotiable"


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
