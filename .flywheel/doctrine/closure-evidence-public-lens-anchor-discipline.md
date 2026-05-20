---
title: "Closure Evidence Public-Lens Anchor Discipline (four-lens self-grade must reference Donella/Meadows/Jeff/Three-Judges)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Closure Evidence Public-Lens Anchor Discipline

Version: `closure-evidence-public-lens-anchor-discipline/v1`
Owner: workers + orchestrators authoring closure evidence files
Status: canonical, shipped 2026-05-11
Source bead: flywheel-v38e1.2 (P1 doctrine promotion)
Source incident: skillos-fuckup-log 2026-05-11T14:50Z — skillos-beug.1 closure BLOCKED with `lens_public_fail=no_bar_self_grade`
Sister doctrine: flywheel-v38e1.1 (closure-evidence-missing-contract-version, 12:12Z)

## ★ ORIENT

When authoring closure evidence files for `Shape B SHIPPED_BUT_STUB_BLIND` (or
any worker-tick close), the file MUST contain at least ONE of these
**public-lens anchor tokens**:

- `three judges`
- `publishability`
- `brand voice`
- `donella` (Donella Meadows — leverage points)
- `jeff` (Jeff doctrine references)
- `meadows`
- `four-lens` / `four lens`

`validate-callback-before-close.sh:301-303` enforces this via:

```bash
if ! grep -qiE '(three judges|publishability|brand voice|donella|jeff|meadows|four-lens|four lens)' "$EVIDENCE_ABS"; then
  lens_fail public "no_bar_self_grade"
fi
```

A closure attempt missing all 8 tokens fails with
`lens_public_fail=no_bar_self_grade` — the bead remains OPEN until the
evidence is revised.

## ✦ MOTIVATE

Why this discipline exists: 2026-05-11T14:50Z trauma — **skillos-beug.1
closure attempt BLOCKED**. Worker shipped what they believed was complete
evidence but failed validate-callback-before-close.sh public-lens gate.
Root cause: closure evidence had no "Publishability bar self-grade" section
referencing any Three Judges / Donella / Meadows / Jeff systems-thinking
anchor.

The public-lens isn't a stylistic preference. It's a **forcing function**
that closure evidence be scrutinized for downstream impact (per Donella's
12 leverage points + Jeff Emanuel's brand-voice discipline + the Three
Judges check: skeptical operator, maintainer, future worker). Evidence
that fails to ground itself in these anchors is **shipped-but-stub-blind**
— surface metrics may pass while substrate decay accelerates.

**Resolution:** skillos-beug.1 closure SUCCEEDED after Donella/Meadows
anchor added.

## ◐ MENTAL-MODEL

```
Worker authoring closure evidence:

  ┌─────────────────────────────────────────────────┐
  │  Closure evidence file content                   │
  │                                                  │
  │  ## Acceptance gates  ✓                          │
  │  ## L52 bead receipt  ✓                          │
  │  ## Files touched     ✓                          │
  │  ## Four-Lens Self-Grade  ← MUST contain ≥1 of:  │
  │     - "three judges" (Three Judges check)        │
  │     - "publishability" (Publishability Bar)      │
  │     - "brand voice"                              │
  │     - "donella" / "meadows" (leverage points)    │
  │     - "jeff" (Jeff doctrine)                     │
  │     - "four-lens" / "four lens"                  │
  │                                                  │
  │  brand:N sniff:N jeff:N public:N  ✓              │
  └─────────────────────────────────────────────────┘
                          │
                          ▼
       validate-callback-before-close.sh:301
                          │
                ┌─────────┴────────┐
                ▼                  ▼
        contains token?       no match?
                │                  │
                ▼                  ▼
          lens_public_pass    lens_public_fail=no_bar_self_grade
                                   → bead stays OPEN
```

## ⬡ EXEMPLIFY

### Canonical: Four-Lens section with Three Judges check (preferred)

```markdown
## Four-Lens Self-Grade

- **brand** (10): [...]
- **sniff** (10): [...]
- **jeff** (10): [...]
- **public** (10): Three Judges check —
  - Skeptical operator: [...]
  - Maintainer: [...]
  - Future worker: [...]

four_lens=brand:10,sniff:10,jeff:10,public:10
```

This format triggers `three judges` + `jeff` + `four-lens` matches simultaneously.

### Minimal: single-anchor reference

```markdown
## Publishability Bar Self-Grade

Per Donella Meadows leverage-point analysis (point #5: rules of the system),
this fix changes the corpus property rather than the per-script proxy.
```

Single token (`donella` + `meadows` + `publishability`) → passes.

### What WON'T pass

```markdown
## Four-Lens Self-Grade

- **brand** (10): clean.
- **sniff** (10): tested.
- **jeff** (10): scoped.
- **public** (10): operator-validated.

four_lens=brand:10,sniff:10,jeff:10,public:10
```

The bare `four_lens=...` machine-readable line matches `four-lens` (NB:
matches the hyphenated form via `four-lens` token), but worker should
include EXPLICIT Three Judges narrative for genuine substrate grounding,
not just to satisfy the lint.

## ⚠ WARN — Anti-patterns

- **DO NOT** ship closure evidence without any public-lens anchor — closure
  will BLOCK with `lens_public_fail=no_bar_self_grade`.
- **DO NOT** game the regex with a hidden HTML comment containing the
  tokens but no genuine grounding — evidence is human-audited by orchs;
  passing the lint while failing the substance is detected on later review
  (Donella's "shifting the goal" anti-pattern).
- **DO NOT** rely on machine-readable `four_lens=...` line alone — author
  the narrative Three Judges check too. The bare line passes the lint but
  defeats the forcing function.
- **DO NOT** wait for the validator block to author the section. The
  Publishability Bar Self-Grade should be a natural product of closing
  out the work, not a retrofit after the lint fires.

## ⇄ CROSS-LINK

### Sister doctrine (this session's wave)

- `.flywheel/doctrine/closure-evidence-contract-version-discipline.md` (flywheel-v38e1.1, sister rule from 12:12Z fuckup-log) — closure evidence MUST also cite the `schema_version` / `contract_version` of any artifact it ships
- (forthcoming) closure-evidence-inbox-discipline (flywheel-v38e1.3, 17:00Z)
- (forthcoming) closure-evidence-outbox-discipline (flywheel-v38e1.4, 22:30Z)

### Validator source

- `~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:301-303` — load-bearing enforcement of this discipline

### Sister recipes

- `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (pmg3c) — recipe used to author this doc
- `.flywheel/doctrine/operator-library-recipe.md` (vbk3h) — operator pipeline (★ ORIENT → ✦ MOTIVATE → ◐ MENTAL-MODEL → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK) used to structure this doc

### Trauma anchor

- skillos-beug.1 closure attempt 2026-05-11T14:50Z BLOCKED with
  `lens_public_fail=no_bar_self_grade`; closure succeeded after
  Donella/Meadows anchor added

### Related substrate

- `feedback_publishability_bar_three_judges.md` (Joshua memory: "every flywheel-touched repo passes 'would Jeff/Donella/Josh sign off'")

## Conformance (proof contract)

This doctrine is considered live when ALL of these hold:

1. ✓ Doctrine doc exists at `.flywheel/doctrine/closure-evidence-public-lens-anchor-discipline.md`
2. ✓ At least one public-lens anchor token from the 8-token set appears in the doc (proves self-application)
3. ✓ Validator source path cited explicitly (line:range)
4. ✓ Sister doctrine cross-linked (flywheel-v38e1.1 + forthcoming .3/.4)
5. ✓ Trauma anchor cited (skillos-beug.1 14:50Z)

## Below-trauma-class tracking

| Instance | Date | Discipline-bypass cost | Outcome |
|---|---|---|---|
| 1 | 2026-05-11T14:50Z | skillos-beug.1 closure BLOCKED (`lens_public_fail=no_bar_self_grade`) | closure_succeeded after Donella/Meadows anchor added |
| (future) | — | — | open: monitor for N≥2 instances to warrant validator tightening (e.g., require explicit `## Publishability Bar Self-Grade` section header, not just token presence) |

## Combines-with rules

This rule **combines with** the contract-version-anchor rule from the
12:12Z fuckup-log entry (flywheel-v38e1.1). Both rules together establish
a 2-axis closure evidence quality bar:

| Axis | Rule | Token enforcement |
|---|---|---|
| public-lens | THIS rule | ≥1 of {three judges, publishability, brand voice, donella, jeff, meadows, four-lens, four lens} |
| contract-version | v38e1.1 sister rule | `schema_version` / `contract_version` cite for shipped artifacts |

Future Shape B `SHIPPED_BUT_STUB_BLIND` closures must pass BOTH axes.

## Sub-pattern (per forward-link-doctrine-doc-recipe)

This is a **1:1 forward-link** instance: single fuckup-log entry documents
single discipline (validator-enforced public-lens anchor). Combines-with
sister rule from same session's fuckup-log harvest (v38e1.1).

## Cross-references

- Source bead: flywheel-v38e1.2 (P1)
- Parent bead: flywheel-v38e1 (P1 wave of 4 fuckup-log → doctrine promotions)
- Source fuckup entry: `~/.local/state/flywheel/fuckup-log.jsonl` row matching `class:closure-evidence-missing-public-lens-anchor` ts=2026-05-11T14:50:00Z
- Validator load-bearing point: `~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:301-303`
- Sister recipes: `forward-link-doctrine-doc-recipe.md` (pmg3c), `operator-library-recipe.md` (vbk3h)

## Publishability Bar Self-Grade

This doctrine doc demonstrates Three Judges grounding via:
- **Skeptical operator:** all 8 anchor tokens enumerated; validator regex quoted verbatim from source
- **Maintainer:** combines-with table shows 2-axis closure quality bar; sister doctrine forthcoming for outbox/inbox disciplines
- **Future worker:** below-trauma-class tracking captures N=1 + promotion threshold

Per Donella Meadows leverage point #5 (rules of the system): this doctrine
codifies a quality-gate RULE that shapes the closure-evidence-authoring
behavior across the fleet. Per Jeff Emanuel's brand-voice discipline: bare
machine-readable `four_lens=` lines are insufficient — narrative Three
Judges check is the canonical form. Per the publishability bar three-judges
memory: "every flywheel-touched repo passes 'would Jeff/Donella/Josh sign
off'" — this doctrine operationalizes that judgment as a validator gate.

four_lens=brand:10,sniff:10,jeff:10,public:10


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
