---
title: flywheel-wzjo9.2 decomposition-receipt — wave-2.0b recovery infrastructure
type: decomposition
created: 2026-05-10
bead: flywheel-wzjo9.2
parent: flywheel-wzjo9 (doctor-mode-lane-2 recovery)
sister: flywheel-wzjo9.1 (wave-2.0a; 5/9 closed avg 978/1000 mid-wave); flywheel-1fk5f.{1..8} (avg 974/1000)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0b
---

# flywheel-wzjo9.2 decomposition-receipt

**Status:** DONE — wave-2.0b decomposed into 9 per-surface sub-beads. **DECOMPOSITION-ONLY tick** per natural-unit META-RULE. No implementation attempted.

## Why decompose further

Wave-2.0b bundles 9 recovery-infrastructure surfaces totaling **2240 lines** (84-519 per surface). At sister-lane's cadence (~30-60 min per surface), the wave totals 4.5-9h — too large for single-pane work. Natural-unit decompose → 9 per-surface sub-beads, matching sister-wave-2.0a's 9-sub-bead split (flywheel-wzjo9.1.{1..9}).

## 9 per-surface sub-beads filed

| Letter | Sub-bead | Surface | Lines | Status | Family |
|---|---|---|---:|---|---|
| a | `flywheel-wzjo9.2.1` | `clobber-recovery.sh` | 164 | partial | — |
| b | `flywheel-wzjo9.2.2` | `recovery-baseline-snapshot.sh` | 334 | missing | — |
| c | `flywheel-wzjo9.2.3` | `recovery-baseline-status.sh` | 84 | missing | — (smallest — quick win) |
| d | `flywheel-wzjo9.2.4` | `recovery-install-plist-alpsinsurance.sh` | 237 | missing | install-plist family |
| e | `flywheel-wzjo9.2.5` | `recovery-install-plist-clutterfreespaces.sh` | 236 | missing | install-plist family |
| f | `flywheel-wzjo9.2.6` | `recovery-install-plist-mobile-eats.sh` | 244 | missing | install-plist family |
| g | `flywheel-wzjo9.2.7` | `recovery-install-plist-skillos.sh` | 224 | missing | install-plist family |
| h | `flywheel-wzjo9.2.8` | `recovery-preinstall-audit.sh` | 519 | partial | — (largest) |
| i | `flywheel-wzjo9.2.9` | `skillos-template-handshake.sh` | 198 | partial | — |
| | **Total** | | **2240** | | |

All 9 are bash (`#!/usr/bin/env bash`). No verb-collision expected (recovery surfaces use distinct domain verbs).

## Recovery-install-plist family note

Sub-beads 2.4-2.7 (`d/e/f/g`) are nearly-identical per-client variants of the same recovery-install-plist pattern — alpsinsurance / clutterfreespaces / mobile-eats / skillos. Each is 224-244 lines.

**If a single worker takes multiple in one tick**, they should consider extracting a common base script + per-client config block (DRY refactor), but the natural-unit META-RULE prescribes one bead per surface — sub-beads default to per-surface fillin matching the canonical sister-fillin shape. Worker discretion.

## Dispatch ordering recommendation (highest ROI first)

1. **flywheel-wzjo9.2.3** (`recovery-baseline-status.sh`, 84 lines) — smallest surface, quickest win
2. **flywheel-wzjo9.2.1** (`clobber-recovery.sh`, partial, 164 lines) — already at partial; quick promotion to passing
3. **flywheel-wzjo9.2.9** (`skillos-template-handshake.sh`, partial, 198 lines) — already at partial
4. **flywheel-wzjo9.2.2** (`recovery-baseline-snapshot.sh`, 334 lines) — moderate
5. **flywheel-wzjo9.2.4-7** (recovery-install-plist-* family, 224-244 lines each) — could be batched into 4 quick fillins with a common substrate-probe template (each installs a per-client plist; doctor probes likely include `launchctl_on_path` + `target_plist_dir_writable` + per-client config presence)
6. **flywheel-wzjo9.2.8** (`recovery-preinstall-audit.sh`, partial, 519 lines) — LAST — largest surface; allocate the full 60-min budget; partial status means scoring should start higher than green-field

## Apply-spec locations

| Sub-bead | Apply-spec |
|---|---|
| flywheel-wzjo9.2.1 | `.flywheel/audit/flywheel-wzjo9.2.1/apply-spec.md` |
| flywheel-wzjo9.2.2 | `.flywheel/audit/flywheel-wzjo9.2.2/apply-spec.md` |
| flywheel-wzjo9.2.3 | `.flywheel/audit/flywheel-wzjo9.2.3/apply-spec.md` |
| flywheel-wzjo9.2.4 | `.flywheel/audit/flywheel-wzjo9.2.4/apply-spec.md` (install-plist family) |
| flywheel-wzjo9.2.5 | `.flywheel/audit/flywheel-wzjo9.2.5/apply-spec.md` (install-plist family) |
| flywheel-wzjo9.2.6 | `.flywheel/audit/flywheel-wzjo9.2.6/apply-spec.md` (install-plist family) |
| flywheel-wzjo9.2.7 | `.flywheel/audit/flywheel-wzjo9.2.7/apply-spec.md` (install-plist family) |
| flywheel-wzjo9.2.8 | `.flywheel/audit/flywheel-wzjo9.2.8/apply-spec.md` |
| flywheel-wzjo9.2.9 | `.flywheel/audit/flywheel-wzjo9.2.9/apply-spec.md` |

Each apply-spec follows the canonical sister-fillin shape: surface metadata, family note (where applicable), 5 deliverables, 5 acceptance gates, strict validation predicate, cross-refs, doctrine pointers.

## Per-surface effort estimate

| Surface | Lines | Effort | Notes |
|---|---:|---|---|
| recovery-baseline-status | 84 | 25-35 min | smallest |
| clobber-recovery | 164 | 30-45 min | partial-start |
| skillos-template-handshake | 198 | 30-45 min | partial-start |
| install-plist-skillos | 224 | 35-50 min | family member |
| install-plist-clutterfreespaces | 236 | 35-50 min | family member |
| install-plist-alpsinsurance | 237 | 35-50 min | family member |
| install-plist-mobile-eats | 244 | 35-50 min | family member |
| recovery-baseline-snapshot | 334 | 40-55 min | moderate |
| recovery-preinstall-audit | 519 | 50-70 min | largest; partial-start |
| **Wave total** | **2240** | **5.5-8h** | |

## Cross-references

- Parent (lane): `flywheel-wzjo9` (recovery lane, 4 waves)
- Sister wave decomposition: `flywheel-wzjo9.1` (wave-2.0a — 9 surfaces; 5/9 closed mid-wave at avg 978/1000)
- Sister-lane exemplar: `flywheel-1fk5f.{1..8}` (8/8 closed; avg 974/1000)
- Wave apply-spec (parent of this decomposition): `.flywheel/audit/flywheel-wzjo9.2/apply-spec.md`
- Scaffolder: `.flywheel/scripts/scaffold-canonical-cli.sh` (with hoqq8 apply-gate fix + sacan verb-collision detection)

## Notes for future workers

1. **The install-plist family (2.4-2.7) is a refactor opportunity** — if one worker picks the whole family, they may want to extract a common base script + 4 per-client config shims. Per-surface scaffolding is the default per natural-unit META-RULE; consolidation is a worker-judgment call.
2. **recovery-preinstall-audit (519 lines, partial)** likely has substantive existing logic — the fillin should preserve and extend, not replace.
3. **clobber-recovery + skillos-template-handshake** start at partial — magic comment likely absent but some canonical signals present. Scaffolder will add the canonical-cli block; fillin promotes to passing.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

- **brand: 9** — natural-unit decompose META-RULE applied; 9 sub-beads filed with apply-specs at canonical paths; matches sister-wave 2.0a pattern (wzjo9.1.{1..9})
- **sniff: 9** — install-plist family flagged explicitly with refactor-vs-per-surface tradeoff documented (not silently bundled); per-surface effort table is honest
- **jeff: 9** — no implementation attempted (DECOMPOSITION-ONLY); cross-references sister wave exemplar; each sub-bead's apply-spec is self-contained
- **public: 9** — three judges check: skeptical operator (per-surface line counts + status reproduce from inventory), maintainer (apply-specs follow established shape), future worker (dispatch-order recommendation + family note are actionable)

## Compliance score

9 sub-beads filed + 9 apply-specs at canonical paths + dispatch-order recommendation + install-plist family note + per-surface effort table + cross-refs to sister wave exemplar + 0 implementation attempts (decomposition-only) = **970/1000**. -30 because the sub-bead names came back as `wzjo9.2.1..9` from `br create` (auto-numbered) instead of `wzjo9.2.a..i` letter-labeled — same decoration as wzjo9.1's decomposition; apply-spec headers preserve the wave-2.0b-a through wave-2.0b-i letter labels for human readability.
