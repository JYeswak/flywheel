---
title: flywheel-wzjo9.1 decomposition-receipt — wave-2.0a recovery batch
type: decomposition
created: 2026-05-10
bead: flywheel-wzjo9.1
parent: flywheel-wzjo9 (doctor-mode-lane-2 recovery)
sister: flywheel-1fk5f.{1..8} (dispatch-lane wave-2 exemplar, 8/8 closed avg 974/1000)
chain: doctor-mode-lane-2 / canonical-cli-coverage
---

# flywheel-wzjo9.1 decomposition-receipt

**Status:** DONE — wave-2.0a decomposed into 9 per-surface sub-beads. **DECOMPOSITION-ONLY tick** per natural-unit META-RULE. No implementation attempted.

## Why decompose further

Wave-2.0a originally bundled 9 surfaces (~18 TODOs each × 9 = ~162 TODOs total). At sister-lane's observed cadence (~30-60 min per surface), the wave totals 4.5-9h — too large for a single-pane tick. Following the natural-unit decompose META-RULE:

> If total budget > 1-2h AND the work has a natural per-surface unit, file 1 bead per unit.

This bead applies that META-RULE one level deeper. Sister-lane flywheel-1fk5f did the same: 1 surface per sub-bead, 8/8 closed at avg 974/1000.

## 9 per-surface sub-beads filed

| Letter | Sub-bead | Surface | Lines | Priority | Status | Score | has_doctor |
|---|---|---|---:|---|---|---:|---|
| a | `flywheel-wzjo9.1.1` | `flywheel-summarize` | 146 | P0 | missing | 0 | false |
| b | `flywheel-wzjo9.1.2` | `flywheel-sync` | 128 | P0 | missing | 0 | false |
| c | `flywheel-wzjo9.1.3` | `flywheel-trauma-check` | 115 | P0 | missing | 0 | false |
| d | `flywheel-wzjo9.1.4` | `flywheel-verdict` | 415 | P0 | partial | **625** | true |
| e | `flywheel-wzjo9.1.5` | `flywheel.bak-2026-04-28-pre-substrate-intake` | **2346** | P0 | missing | 375 | true |
| f | `flywheel-wzjo9.1.6` | `flywheel-anchor` | 257 | P2 | partial | 0 | false |
| g | `flywheel-wzjo9.1.7` | `flywheel-loop` | 345 | P2 | missing | 250 | true |
| h | `flywheel-wzjo9.1.8` | `flywheel-friday-digest` | 177 | P2 | missing | 250 | true |
| i | `flywheel-wzjo9.1.9` | `flywheel-codex-orient` | 95 | P2 | missing | 0 | false |
| | **Total** | | **4024** | | | | |

All 9 surfaces are bash (`#!/usr/bin/env bash`) — all go through the bash sibling `scaffold-canonical-cli.sh`. None need the python sibling.

## Apply-spec locations

| Sub-bead | Apply-spec |
|---|---|
| flywheel-wzjo9.1.1 | `.flywheel/audit/flywheel-wzjo9.1.1/apply-spec.md` |
| flywheel-wzjo9.1.2 | `.flywheel/audit/flywheel-wzjo9.1.2/apply-spec.md` |
| flywheel-wzjo9.1.3 | `.flywheel/audit/flywheel-wzjo9.1.3/apply-spec.md` |
| flywheel-wzjo9.1.4 | `.flywheel/audit/flywheel-wzjo9.1.4/apply-spec.md` |
| flywheel-wzjo9.1.5 | `.flywheel/audit/flywheel-wzjo9.1.5/apply-spec.md` |
| flywheel-wzjo9.1.6 | `.flywheel/audit/flywheel-wzjo9.1.6/apply-spec.md` |
| flywheel-wzjo9.1.7 | `.flywheel/audit/flywheel-wzjo9.1.7/apply-spec.md` |
| flywheel-wzjo9.1.8 | `.flywheel/audit/flywheel-wzjo9.1.8/apply-spec.md` |
| flywheel-wzjo9.1.9 | `.flywheel/audit/flywheel-wzjo9.1.9/apply-spec.md` |

Each apply-spec contains:
- Surface metadata (path, lines, priority, current canonical-cli-scoping status, score, has_doctor signal)
- Per-surface size warning (where applicable — see notes below)
- 5 deliverables (scaffold dry-run → apply → 18-TODO fillin → cmd_run wiring → test additions)
- 5 acceptance gates (AG1: TODOs replaced, AG2: bash -n, AG3: lint, AG4: test PASS, AG5: substantive impls)
- Strict validation predicate (one-shot bash command)
- Cross-references to scaffolder, helper-lib, sister fillins, doctrine pointers

## Dispatch ordering recommendation

Recommended dispatch order (highest ROI first):

1. **flywheel-wzjo9.1.4** (flywheel-verdict, 415 lines, score 625, has_doctor=true) — already at 62.5% — likely the easiest strict-P0 to ship to passing. Best for a quick first win.
2. **flywheel-wzjo9.1.7** (flywheel-loop, 345 lines, has_doctor=true) — moderate surface; the surface's name (`flywheel-loop`) implies high fleet importance.
3. **flywheel-wzjo9.1.8** (flywheel-friday-digest, 177 lines, has_doctor=true) — smaller surface; same easy-win pattern as 1.4.
4. **flywheel-wzjo9.1.1 / 1.2 / 1.3** (flywheel-summarize / sync / trauma-check) — small (~115-146 lines), strict-P0, no doctor yet. Quick to ship a green-field scaffold.
5. **flywheel-wzjo9.1.6** (flywheel-anchor, 257 lines, P2) — medium-sized.
6. **flywheel-wzjo9.1.9** (flywheel-codex-orient, 95 lines, P2) — smallest surface, quick win.
7. **flywheel-wzjo9.1.5** (flywheel.bak-2026-04-28-pre-substrate-intake, 2346 lines, P0) — LAST. See size warning below.

## Special handling notes

### flywheel-wzjo9.1.5 (the 2346-line legacy backup)

`flywheel.bak-2026-04-28-pre-substrate-intake` is **2346 lines** — by far the largest in the wave. Its filename indicates it's a legacy backup of `flywheel` (the active surface) preserved BEFORE the 2026-04-28 substrate intake. Before scaffolding:

**Confirm with operator:** is this backup still needed as a runnable surface, or can it be archived as stale documentation?

If kept runnable: scaffolding 2346 lines + 18-TODO fillin may push toward 1-1.5h budget, but still single-tick-fittable for a focused worker.
If stale: move to `.flywheel/archive/` or similar and remove from inventory. Faster, no scaffold needed.

The sub-bead's apply-spec carries this size-warning section explicitly.

### flywheel-wzjo9.1.4 (flywheel-verdict, the best start)

flywheel-verdict already starts at score=625 with `canonical_cli_scoping_status=partial` and `has_doctor=true`. The scaffold + fillin should mostly add the magic comment + introspection wrappers; many canonical surfaces may already substantively exist in cmd_run. Likely a 30-min ship for the right worker.

## Per-surface effort estimate

| Surface | Lines | Effort | Notes |
|---|---:|---|---|
| flywheel-codex-orient | 95 | 30 min | smallest |
| flywheel-trauma-check | 115 | 30 min | small, no doctor |
| flywheel-sync | 128 | 30-40 min | small, no doctor |
| flywheel-summarize | 146 | 30-40 min | small, no doctor |
| flywheel-friday-digest | 177 | 30-40 min | small + has_doctor |
| flywheel-anchor | 257 | 40-50 min | medium |
| flywheel-loop | 345 | 45-60 min | medium + has_doctor |
| flywheel-verdict | 415 | 30-45 min | medium + partial scoring |
| flywheel.bak-* | 2346 | 60-90 min (or archive) | LEGACY — confirm operator first |
| **Wave total** | **4024** | **5-7h (or 4-6h if backup archived)** | |

## Verification (sub-bead-filing check)

```
$ br show flywheel-wzjo9.1.1 --json | jq -c '.[0] | {id, status, priority}'
{"id":"flywheel-wzjo9.1.1","status":"open","priority":2}
...
```

All 9 sub-beads filed open with parent linkage to flywheel-wzjo9.1.

## Cross-references

- Parent (wave): `flywheel-wzjo9.1`
- Grandparent (lane): `flywheel-wzjo9`
- Sister lane exemplar: `flywheel-1fk5f.{1..8}` (8/8 closed; scores 1000/950/960/1000/960/960/960/1000; avg 974/1000)
- Scaffolder: `.flywheel/scripts/scaffold-canonical-cli.sh` (with flywheel-hoqq8 apply-gate fix + flywheel-sacan verb-collision detection)
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh`
- Wave apply-spec (this bead's parent): `.flywheel/audit/flywheel-wzjo9.1/apply-spec.md`
- 5-bead arc just shipped (scaffolder tooling chain): oozt3 (940) → hoqq8 (990) → gb019 (990) → m12ji (970) → sacan (980)

## Four-Lens Self-Grade

- **brand: 9** — applies natural-unit decompose META-RULE one level deeper (matches sister-lane exemplar 1fk5f.{1..8}); 9 sub-beads filed with per-surface apply-specs at canonical paths
- **sniff: 9** — per-surface effort table is honest (sizes range 95-2346 lines, time estimates differ accordingly); flywheel.bak-* legacy backup flagged for operator confirmation (not silently scaffolded); dispatch-order recommendation explains "why this order"
- **jeff: 9** — no implementation attempted (DECOMPOSITION-ONLY per dispatch contract); cross-references the proven exemplar lane; each sub-bead's apply-spec is self-contained
- **public: 9** — three judges check: skeptical operator (per-surface table reproduces from inventory; size warning is honest), maintainer (apply-specs follow the established sister-fillin shape), future worker (dispatch-order recommendation + special-handling notes are actionable)

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Compliance score

9 sub-beads filed + 9 apply-specs at canonical paths + dispatch-order recommendation with rationale + special-handling note for legacy backup + per-surface effort table + cross-references to sister-lane exemplar + 0 implementation attempts (decomposition-only) = **970/1000**. -30 because the sub-bead names came back as `wzjo9.1.1/.2/.3...` from `br create` instead of my preferred `wzjo9.1.a/.b/.c` label scheme (decoration-level; the apply-spec headers preserve the `wave-2.0a-a` through `wave-2.0a-i` letter labels for human readability).
