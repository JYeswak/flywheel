# flywheel-2xdi.5 Compliance Pack

Task: `flywheel-2xdi.5-2e1823`
Bead: `flywheel-2xdi.5`
Decision: DONE
Compliance score: 880/1000

## Finding

The wired-but-cold report surfaced a real stale-test problem.
`/Users/josh/.claude/skills/.flywheel/tests/test_flywheel_loop_memory_health.sh`
existed in the skill tree but was not committed there. Its fixture also allowed
`flywheel-loop doctor` to call live idle-state / NTM substrate while testing a
memory-health contract, which made the test hang under current doctor wiring.

## Repair

Committed the target test into `/Users/josh/.claude` and made the fixture
self-contained:

- disables idle-state probing via `FLYWHEEL_IDLE_STATE_CONFIG` fixture with
  `{"enabled":false}`
- disables live NTM health with `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1`
- captures the degraded missing-mem doctor exit under `set +e`, matching the
  existing failing-memory branch
- keeps assertions focused on memory-health JSON shape and graceful degradation

External commit:

- `/Users/josh/.claude` commit `07698c8`
  (`test(flywheel): add memory health loop doctor fixture`)

## Evidence

- `br show flywheel-2xdi.5 --json`: bead open before repair.
- `br dep tree flywheel-2xdi.5`: parent `flywheel-2xdi` and grandparent
  `flywheel-wxth` closed.
- Socraticode: 1 query, 10 chunks observed.
- Initial test run: hung inside nested `flywheel-loop doctor` /
  `idle-state-probe.sh --doctor`; process tree was killed before continuing.
- Post-patch syntax:
  `bash -n /Users/josh/.claude/skills/.flywheel/tests/test_flywheel_loop_memory_health.sh`
  passed.
- Post-patch test:
  `timeout 90 /Users/josh/.claude/skills/.flywheel/tests/test_flywheel_loop_memory_health.sh`
  ended with `ALL PASS (flywheel_loop_memory_health)`.
- Dispatch audit:
  `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2xdi.5-2e1823.md`
  passed.
- Validation receipt parser passed for
  `.flywheel/audit/flywheel-2xdi.5/validation-receipt.json`.
- L112 probe:
  `.flywheel/audit/flywheel-2xdi.5/l112-probe.sh` prints `pass`.

## L52

No follow-up bead filed. The stale/cold condition was directly repaired in the
named target test.

## Four-Lens Self-Grade

- brand: 8 - Preserves memory-health coverage as executable substrate.
- sniff: 9 - Fix removes live-probe flake from a fixture-level test.
- jeff: 8 - Does not widen scope beyond the target test and audit pack.
- public: 8 - A future worker can rerun the L112 probe and inspect the external
  commit.
