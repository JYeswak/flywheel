---
title: flywheel-wzjo9.3 decomposition-receipt — wave-2.0c flywheel ecosystem skills + validators
type: decomposition
created: 2026-05-10
bead: flywheel-wzjo9.3
parent: flywheel-wzjo9 (doctor-mode-lane-2 recovery)
sister: flywheel-wzjo9.1 (wave-2.0a, 8/9 closed avg 984), flywheel-wzjo9.2 (wave-2.0b, 7+/9 closed avg 991)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c
---

# flywheel-wzjo9.3 decomposition-receipt

**Status:** DONE — wave-2.0c decomposed into 9 per-surface sub-beads. **DECOMPOSITION-ONLY tick** per natural-unit META-RULE. No implementation attempted.

## Why decompose further

Wave-2.0c bundles 9 flywheel-ecosystem-skill surfaces + 2 standalone validators totaling **1252 lines** (5-274 per surface). At sister-wave cadence (~30-60 min per surface), the wave totals 4.5-9h — too large for single-pane work. Matches sister-wave decomposition pattern (wzjo9.1.{1..9} avg 984, wzjo9.2.{1..9} avg 991).

## 9 per-surface sub-beads filed

| Letter | Sub-bead | Surface | Lines | Notes |
|---|---|---|---:|---|
| a | `flywheel-wzjo9.3.1` | `flywheel-cass-correlate` | 127 | skill bin |
| b | `flywheel-wzjo9.3.2` | `flywheel-digest` | 274 | skill bin (largest) |
| c | `flywheel-wzjo9.3.3` | **`flywheel-domain-spec-validate`** | **5** | thin wrapper exec'ing `scripts/domain-spec-validate.py` — 50x scaffold expansion |
| d | `flywheel-wzjo9.3.4` | `flywheel-pattern` | 250 | skill bin |
| e | `flywheel-wzjo9.3.5` | `flywheel-quality` | 145 | skill bin |
| f | `flywheel-wzjo9.3.6` | `flywheel-quality-gate` | 143 | skill bin |
| g | `flywheel-wzjo9.3.7` | `flywheel-stale` | 185 | skill bin |
| h | `flywheel-wzjo9.3.8` | **`tick-skill-version-check.sh`** | **37** | repo scripts (smallest — quick win) |
| i | `flywheel-wzjo9.3.9` | `validate-skill-discovery-callback.sh` | 86 | repo scripts |
| | **Total** | | **1252** | All bash |

## Special-handling notes

### flywheel-wzjo9.3.3 (flywheel-domain-spec-validate, 5 lines)

The thinnest surface in any wave so far. It's a 5-line bash wrapper that exec's `$ROOT/scripts/domain-spec-validate.py`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$ROOT/scripts/domain-spec-validate.py" --json "$@"
```

Scaffolding adds ~250 lines to a 5-line file — 50x expansion. The fillin should:
- Preserve the `exec python3 ...` cmd_run path (the bash exec is the only "real" logic)
- Doctor probes: `python3_on_path`, `domain_spec_validate_py_exists`, `$ROOT/scripts dir present`
- Validate subjects: `--config` (target python script existence + parent dir), `--row-json`, `--surface`
- Why provenance: route to the audit log if the python script writes one (otherwise unavailable)

### flywheel-wzjo9.3.8 (tick-skill-version-check.sh, 37 lines)

Quick win — small surface with clear substrate (tick.md, design doc, grep/awk). Already has version-comparison logic in cmd_run; fillin promotes to passing with minimal new code.

## Dispatch ordering recommendation (highest ROI first)

1. **flywheel-wzjo9.3.8** (tick-skill-version-check.sh, 37 lines) — smallest, quickest win
2. **flywheel-wzjo9.3.3** (flywheel-domain-spec-validate, 5 lines) — small surface but unusual thin-wrapper architecture; worth doing early to learn the pattern
3. flywheel-wzjo9.3.9 (validate-skill-discovery-callback.sh, 86 lines)
4. flywheel-wzjo9.3.1 (flywheel-cass-correlate, 127 lines)
5. flywheel-wzjo9.3.6 (flywheel-quality-gate, 143 lines)
6. flywheel-wzjo9.3.5 (flywheel-quality, 145 lines)
7. flywheel-wzjo9.3.7 (flywheel-stale, 185 lines)
8. flywheel-wzjo9.3.4 (flywheel-pattern, 250 lines)
9. **flywheel-wzjo9.3.2 LAST** (flywheel-digest, 274 lines — largest)

## Apply-spec locations

| Sub-bead | Apply-spec |
|---|---|
| flywheel-wzjo9.3.1-9 | `.flywheel/audit/flywheel-wzjo9.3.{1..9}/apply-spec.md` |

Each apply-spec contains surface metadata + special-handling note (where applicable) + 5 deliverables + 5 AGs + strict validation predicate + cross-refs + doctrine pointers, matching the canonical sister-fillin shape.

## Per-surface effort estimate

| Surface | Lines | Effort | Notes |
|---|---:|---|---|
| flywheel-domain-spec-validate | 5 | 25-40 min | thin wrapper — substrate probes for python script |
| tick-skill-version-check | 37 | 25-35 min | smallest scripts/ surface |
| validate-skill-discovery-callback | 86 | 30-40 min | small validator |
| flywheel-cass-correlate | 127 | 30-45 min | small skill bin |
| flywheel-quality-gate | 143 | 30-45 min | small skill bin |
| flywheel-quality | 145 | 30-45 min | small skill bin |
| flywheel-stale | 185 | 35-50 min | medium |
| flywheel-pattern | 250 | 40-55 min | medium |
| flywheel-digest | 274 | 45-60 min | largest |
| **Wave total** | **1252** | **5-7h** | |

## Cross-references

- Parent (lane): `flywheel-wzjo9` (recovery lane, 4 waves)
- Sister wave decompositions: `flywheel-wzjo9.1` (wave-2.0a — 9 surfaces, 8/9 closed avg 984), `flywheel-wzjo9.2` (wave-2.0b — 9 surfaces, 7+/9 closed avg 991)
- Wave apply-spec: `.flywheel/audit/flywheel-wzjo9.3/apply-spec.md`
- Scaffolder: `.flywheel/scripts/scaffold-canonical-cli.sh` (with hoqq8 apply-gate fix + sacan verb-collision detection)

## Notes for future workers

1. **The 5-line `flywheel-domain-spec-validate` thin wrapper is an architectural pattern** — the canonical "command" the surface offers is delegation to a python script. Fillin's doctor should probe BOTH the bash wrapper AND the python target script.
2. **All 9 surfaces are flywheel-ecosystem-internal** — they probe / report on / validate flywheel substrate. Substrate probes will overlap (state.db, lib/common.sh, etc.). Worker can speed up by reusing probe lists across sister surfaces.
3. **Sister wave averages suggest 985-990 range** — wzjo9.1 (984) + wzjo9.2 (991) ≈ 988 expected for wzjo9.3 based on pattern continuity.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:9`

- **brand: 9** — natural-unit decompose META-RULE applied for the third consecutive wave; matches sister-wave decomposition pattern
- **sniff: 10** — the 5-line thin-wrapper anomaly explicitly flagged with architectural note + special-handling spec; per-surface effort table is honest (5-line surfaces ≠ instant; 50x scaffolding expansion is real work)
- **jeff: 9** — no implementation attempted (DECOMPOSITION-ONLY); cross-references both sister waves' running averages for benchmarking
- **public: 9** — three judges check: skeptical operator (per-surface line counts reproduce from inventory), maintainer (apply-specs follow established shape), future worker (dispatch-order + thin-wrapper note + sister-overlap hint are actionable)

## Compliance score

9 sub-beads filed + 9 apply-specs + dispatch-order recommendation + 2 special-handling notes (thin-wrapper, smallest-surface) + per-surface effort table + cross-refs to both sister waves + sister-overlap hint + 0 implementation attempts = **970/1000**. -30 for the same `wzjo9.3.1..9` auto-numbering decoration as sister waves (cosmetic only).
