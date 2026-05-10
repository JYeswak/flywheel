---
title: flywheel-jh5bb evidence — recovery lane wave 1 (8 P0 surfaces)
type: evidence
created: 2026-05-10
bead: flywheel-jh5bb
parent: flywheel-jloib.2.1 (apply-spec) / flywheel-wzjo9 (decomposition)
chain: doctor-mode-integration / lane-work
---

# flywheel-jh5bb evidence

**Status:** DONE — 8/8 surfaces shipped; 8/8 lint clean; 104/104 canonical-CLI test assertions PASS.

## Surfaces

| # | Surface | Scaffold | Lint | CLI test |
|---|---|:-:|:-:|:-:|
| 1 | `cross-skill-dependency-probe.sh` | apply_ok | clean | 13/13 |
| 2 | `flywheel-recovery.sh` | apply_ok | clean | 13/13 |
| 3 | `handoff-skill-to-skillos.sh` | apply_ok | clean | 13/13 |
| 4 | `recovery-doctor-probe.sh` | apply_ok | clean | 13/13 |
| 5 | `recovery-escape-then-reprompt.sh` | apply_ok | clean (after L4 fix) | 13/13 |
| 6 | `recovery-restore-harness.sh` | apply_ok | clean | 13/13 |
| 7 | `skill-bandit-measurement-probe.sh` | apply_ok | clean | 13/13 |
| 8 | `skill-enhance-jsm-discipline.sh` | apply_ok | clean | 13/13 |

**Totals:** 8/8 scaffold apply_ok, 8/8 lint clean, **104/104 canonical-CLI test PASS**.

## Method

Same as dispatch waves 1+2 (yw63j, war3i):

```bash
for t in <8 surfaces>; do
  .flywheel/scripts/scaffold-canonical-cli.sh ".flywheel/scripts/$t" \
    --apply --idempotency-key "${t%.sh}-jloib.2.1-2026-05-10" --json
done
```

## L4 calibration on recovery-escape-then-reprompt.sh

The scaffolder upgrade preserved a pre-existing `[[ ]] && X || Y` short-
circuit pattern in the `run()` function (line 270). Per F4 lint rule
(short-circuit-in-helper, error severity), this is a real violation —
fixed by converting to `if/then/else` with explicit `return 0`. Body
content semantics unchanged; rc-flow now explicit.

Before:
```bash
[[ "$JSON" -eq 1 ]] && printf '%s\n' "$row" || jq -r ... <<<"$row"
```
After:
```bash
if [[ "$JSON" -eq 1 ]]; then
  printf '%s\n' "$row"
else
  jq -r ... <<<"$row"
fi
return 0
```

## Acceptance gates (apply-spec)

| Gate | Status |
|---|:-:|
| 8/8 surfaces canonical-cli 13/13 PASS | ✓ (104/104 total) |
| 8/8 lint clean | ✓ |
| 8 inventory rows stamped | ✓ (scaffolder logs to `.flywheel/state/scaffold-runs.jsonl`) |
| Backward compat preserved | ✓ (only header/CLI scaffolding added; existing logic untouched except L4 fix) |
| Single batched commit | ✓ |

## Wall clock

~5 min (scaffold bulk + L4 hand-fix + verification).

## Cross-references

- Apply-spec: `.flywheel/audit/flywheel-jloib.2.1/apply-spec.md`
- Sister waves (closed): `flywheel-yw63j` (wave 1 — 8 dispatch surfaces),
  `flywheel-war3i` (wave 2 — 8 dispatch surfaces)
- Tooling chain: `flywheel-tiugg` (helper lib), `flywheel-ws02m` (scaffolder v3),
  `flywheel-etp5n` (canonical-cli-lint), `flywheel-pfjkw` (pilot validation)
- Linter (calibrated for L2 + L1 in etp5n; reused unchanged here):
  `.flywheel/scripts/canonical-cli-lint.sh`
