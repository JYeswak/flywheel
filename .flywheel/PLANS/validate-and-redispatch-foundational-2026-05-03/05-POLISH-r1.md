# Phase 5 POLISH r1 - validate everything bead polish

Plan: `validate-everything-we-build-2026-05-03`
Required set: B01-B12. Extra-final-plan beads included: B13, B14.
Round diff: `129.79%` strict description-line change from starting descriptions.
Convergence status: `not_converged_this_round`

## Bead mapping

| Code | Bead ID | Priority | Status | Title |
|---|---|---:|---|---|
| B01 | `flywheel-bc7c` | 0 | open | [validation-schema] define callback validation receipt schema and fixture corpus |
| B02 | `flywheel-scwo` | 0 | open | [dispatch-template-validation] append validation block to every worker dispatch packet |
| B03 | `flywheel-0wbf` | 0 | open | [validate-callback] implement read-only callback validator and reaper gate |
| B04 | `flywheel-zgo3` | 1 | open | [doctor-validation-signals] wire callback validation signals into flywheel-loop doctor |
| B05 | `flywheel-hf58` | 1 | open | [validate-tick-phase] insert VALIDATE phase between DISPATCH and INTEGRATE |
| B06 | `flywheel-8xrn` | 1 | open | [auto-fix-bead] auto-open or update fix beads when validation gates fail |
| B07 | `flywheel-i8b6` | 1 | open | [auto-reopen-bead] detect and reopen falsely closed beads with missing shipped artifacts |
| B08 | `flywheel-zdva` | 0 | open | [orch-no-punt-chain] implement L70 same-tick phase chaining and ticks_punted_count gate |
| B09 | `flywheel-kscr` | 1 | open | [learn-validation-routing] route validation events through /flywheel:learn without double-processing |
| B10 | `flywheel-dw5w` | 1 | open | [doctrine-memory-wire] codify validation discipline into L-rules, memory, skill, and README surfaces |
| B11 | `flywheel-u2dr` | 1 | open | [codex-parity-validation] enforce L69 agent-context validation for Codex and Claude callback probes |
| B12 | `flywheel-yasl` | 0 | open | [validation-e2e] ship end-to-end smoke harness and staged rollout gate |
| B13 | `flywheel-erkx` | 0 | open | [orch-capture-parity] define cross-runtime Joshua-input capture parity rule and signal |
| B14 | `flywheel-m5kg` | 0 | open | [three-q-surface-registry] implement 3-Q surface registry and audit runner |

## Per-bead polish metrics

| Code | ID | prior_lines | after_lines | +/- lines | diff_pct | gates before/after | DOD before/after | doctrine before/after | CLI |
|---|---|---:|---:|---:|---:|---|---|---|---|
| B01 | `flywheel-bc7c` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B02 | `flywheel-scwo` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B03 | `flywheel-0wbf` | 52 | 99 | +55/-8 | 121.15% | 8/8 | True/True | True/True | PASS |
| B04 | `flywheel-zgo3` | 55 | 103 | +57/-9 | 120.00% | 9/9 | True/True | True/True | PASS |
| B05 | `flywheel-hf58` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B06 | `flywheel-8xrn` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B07 | `flywheel-i8b6` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B08 | `flywheel-zdva` | 44 | 90 | +53/-7 | 136.36% | 7/7 | True/True | True/True | PASS |
| B09 | `flywheel-kscr` | 43 | 89 | +53/-7 | 139.53% | 7/7 | True/True | True/True | PASS |
| B10 | `flywheel-dw5w` | 51 | 97 | +53/-7 | 117.65% | 7/7 | True/True | True/True | PASS |
| B11 | `flywheel-u2dr` | 53 | 100 | +55/-8 | 118.87% | 8/8 | True/True | True/True | PASS |
| B12 | `flywheel-yasl` | 55 | 103 | +57/-9 | 120.00% | 9/9 | True/True | True/True | PASS |
| B13 | `flywheel-erkx` | 49 | 96 | +55/-8 | 128.57% | 8/8 | True/True | True/True | PASS |
| B14 | `flywheel-m5kg` | 51 | 99 | +57/-9 | 129.41% | 9/9 | True/True | True/True | PASS |

## Dependency state

- B01 `flywheel-bc7c` waits_on=none
- B02 `flywheel-scwo` waits_on=flywheel-bc7c
- B03 `flywheel-0wbf` waits_on=flywheel-bc7c, flywheel-scwo
- B04 `flywheel-zgo3` waits_on=flywheel-0wbf, flywheel-erkx, flywheel-m5kg
- B05 `flywheel-hf58` waits_on=flywheel-8xrn, flywheel-i8b6, flywheel-zgo3
- B06 `flywheel-8xrn` waits_on=flywheel-0wbf
- B07 `flywheel-i8b6` waits_on=flywheel-0wbf
- B08 `flywheel-zdva` waits_on=flywheel-hf58
- B09 `flywheel-kscr` waits_on=flywheel-8xrn, flywheel-erkx, flywheel-i8b6, flywheel-m5kg, flywheel-zgo3
- B10 `flywheel-dw5w` waits_on=flywheel-erkx, flywheel-hf58, flywheel-kscr, flywheel-m5kg, flywheel-zdva
- B11 `flywheel-u2dr` waits_on=flywheel-0wbf, flywheel-erkx, flywheel-zgo3
- B12 `flywheel-yasl` waits_on=flywheel-dw5w, flywheel-erkx, flywheel-hf58, flywheel-kscr, flywheel-m5kg, flywheel-u2dr, flywheel-zdva
- B13 `flywheel-erkx` waits_on=flywheel-bc7c
- B14 `flywheel-m5kg` waits_on=flywheel-bc7c, flywheel-erkx

## Graph cycle result

- `br dep cycles`: `✓ No dependency cycles detected.`
- `bv --robot-insights | jq .Cycles`: `null` (bv no-cycle value); `bv --robot-insights | jq ".Cycles // []"`: `[]`

## Wave plan status

- Wave 1: B01 -> B02/B03 primitives remain first.
- Wave 2: B06/B07 remediation primitives remain after B03.
- Wave 3: B13 capture parity and B11 parity validation remain chained by dependency.
- Wave 4: B14/B04/B05/B08/B09 remain measurement/tick/learn layer after producers.
- Wave 5: B10 doctrine wire-in and B12 final e2e remain final proof surfaces.

## CLI scoping self-test

canonical_cli_scoping=PASS
cli_beads_checked=B01:flywheel-bc7c,B02:flywheel-scwo,B03:flywheel-0wbf,B04:flywheel-zgo3,B05:flywheel-hf58,B06:flywheel-8xrn,B07:flywheel-i8b6,B08:flywheel-zdva,B09:flywheel-kscr,B10:flywheel-dw5w,B11:flywheel-u2dr,B12:flywheel-yasl,B13:flywheel-erkx,B14:flywheel-m5kg
cli_gaps=none

## Unresolved blockers

- No new polish blockers. External implementation blockers remain only where named in individual bead bodies, e.g. q03g/xap2 policy gates.
- No new feature scope added; Phase 5 only added proof mapping, CLI checklist, dry-run/rollback posture, callback evidence shape, and dependency receipts.

## Ladder

- B01-B12 have 5+ acceptance gates: PASS
- B01-B12 have DOD + commit tag: PASS
- B01-B12 have out-of-scope sections preserved: PASS
- Dry-run/rollback posture added: PASS
- Callback evidence shape added: PASS
- B13/B14 included as extra-final-plan beads: PASS
