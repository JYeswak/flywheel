---
title: flywheel-hj4ip evidence — recovery lane wave 3 (8 P0 binaries under .flywheel/bin/)
type: evidence
created: 2026-05-10
bead: flywheel-hj4ip
parent: flywheel-jloib.2.3 (apply-spec) / flywheel-wzjo9 (recovery decomposition)
chain: doctor-mode-integration / lane-work
---

# flywheel-hj4ip evidence

**Status:** DONE — 8/8 binaries scaffolded; 8/8 lint clean; **104/104 canonical-CLI test assertions PASS**.

## Surfaces (8 P0 binaries under ~/.claude/skills/.flywheel/bin/)

| # | Binary | Lines (before→after) | Lint | Test |
|---|---|---:|:-:|:-:|
| 1 | flywheel-agents-pointer-sweep | 102 → 341 | clean | 13/13 |
| 2 | flywheel-autoloop | 2627 → 2873 | clean (after L4 fixes) | 13/13 |
| 3 | flywheel-check | 147 → 386 | clean | 13/13 |
| 4 | flywheel-codex-snapshot | 84 → 324 | clean (after L5 fix) | 13/13 |
| 5 | flywheel-conductor | 476 → 715 | clean | 13/13 |
| 6 | flywheel-dashboard | 221 → 460 | clean | 13/13 |
| 7 | flywheel-doctrine-sync | 904 → 1144 | clean (after L5+L4+L1 fixes) | 13/13 |
| 8 | flywheel-inject-latest-line | 136 → 375 | clean | 13/13 |

**Totals:** 8/8 scaffold apply_ok, 8/8 lint clean, **104/104 canonical-CLI assertions PASS**.

## Two scaffolder bugs surfaced + workarounds applied

### Bug 1 — SCRIPT path concatenation bug

Generated test file uses `SCRIPT="$ROOT/<absolute-target-path>"`. For
absolute targets like `/Users/josh/.claude/skills/.flywheel/bin/X`,
this produces `$ROOT//Users/...` (double-slash, invalid path).

Workaround applied this tick: `sed -i ""` in-place fix on 8 generated
test files, replacing the buggy `$ROOT/<abs>` form with the literal
absolute path.

### Bug 2 — cmd_doctor/cmd_health/cmd_validate stubs use `[[ ]] && X || Y`

The scaffolder's generated stubs use short-circuit return idioms that
the **paired** canonical-cli-lint flags as L4 violation
(short-circuit-in-helper, error severity). Self-inconsistency: tool
produces code that fails its own paired linter.

Workaround applied this tick: python regex mass-replacement converted
all `[[ X ]] && return N || return M` patterns to
`if [[ X ]]; then return N; else return M; fi` in the 3 affected
binaries (autoloop ×4, doctrine-sync ×3, codex-snapshot ×0).

### Followup bead filed

Both bugs filed as **`flywheel-946sy`** (P2,
`[scaffold-canonical-cli-bugs] absolute-target-path test bug + L4
short-circuit in generated stubs`). Parent: flywheel-ws02m (scaffolder
author). Sister bead: flywheel-aav72 (wave 2) likely hit the same
issues and may need re-validation.

## Acceptance gates

| Gate | Status | Note |
|---|:-:|---|
| 8/8 surfaces canonical-cli 13/13 PASS | ✓ | 104/104 total |
| 8/8 lint clean | ✓ | After 2 lint-bug-class workarounds (filed flywheel-946sy) |
| 8 inventory rows stamped | ✓ | scaffolder logs to `.flywheel/state/scaffold-runs.jsonl` |
| Backward compat preserved | ✓ | Original cmd functionality preserved; only canonical-CLI scaffold added |
| Single batched commit | ✓ | This commit |

## Custom test bridge for autoloop + doctrine-sync

Both binaries already had domain-specific custom tests (602+ lines for
autoloop) that the scaffolder didn't overwrite. Those tests check
domain invariants (e.g., `--help` doesn't create state-dir; specific
flags documented). They remain as pre-existing behavior contracts.

For the canonical-CLI 13/13 coverage, this tick added **sister
scaffolded tests** at `tests/<binary>-canonical-cli-scaffold.sh` (separate
from the domain custom tests). Both 13/13 PASS. Net coverage:
scaffolded tests + domain tests = both invariants validated independently.

## Wall clock

~10-15 min (vs ~3 min for jh5bb wave 1 — extra time spent on the
two scaffolder-bug workarounds).

## Cross-references

- Apply-spec: `.flywheel/audit/flywheel-jloib.2.3/apply-spec.md`
- Sister waves (closed): flywheel-yw63j, flywheel-war3i, flywheel-jh5bb
- Sister wave (in-flight): flywheel-aav72 (likely same scaffolder bugs)
- Followup bead filed: **flywheel-946sy** (scaffolder bugs)
- Tooling chain: flywheel-tiugg (helper lib), flywheel-ws02m (scaffolder v3,
  needs fix per flywheel-946sy), flywheel-etp5n (canonical-cli-lint),
  flywheel-pfjkw (pilot validation)
- Memory cross-refs: `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
- Skill discovery: scaffolder-self-inconsistent-with-paired-linter-class

## Skill discovery

`sd_ids=scaffolder-self-inconsistent-with-paired-linter-class` — when
a code-generation tool ships paired with a linter, the generator must
produce code that lints clean against its own paired linter. flywheel-
ws02m (scaffolder) emits stubs that fail flywheel-etp5n (linter) —
self-inconsistency surfaces as N violations per scaffolded surface.
Sister to today's `canonical-cli-lint-eight-rule-static-analyzer-class`
(etp5n) and `scripted-bulk-fix-with-linter-calibration-class` (at83y).
The fix is at the generator (flywheel-946sy), not at each generated
output.
