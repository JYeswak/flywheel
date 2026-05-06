# Polish Preflight Quality Gate Implementation

## Orchestration flow diagram

```text
/flywheel:plan close-gate-handler
  -> polish-preflight-quality-gate --check --plan-slug <slug> --json
       -> mission-lock-output-schema-validator contract fixture
       -> dispatch-author-contract-probe contract fixture
       -> close-validator-contract-probe contract fixture
       -> mission-lock-scaffold-validator healthy scaffold fixture
       -> mission-lock-readiness-doctor healthy scaffold + lens fixture
       -> dispatch-self-test-delivery-identity pretest fixture
       -> golden-fixture-replay-runner replay-all
       -> golden-fixture-replay-runner verify-invariants
  -> PASS receipt unlocks terminal close
  -> --apply appends advisory ledger only
```

The orchestrator treats the first failed sub-gate as first fire. PASS requires all
eight sub-gates plus closed audit findings in plan STATE.

## Dependency-on-Wave-1/2/3/4

Wave 1 delivered idempotency replay protection, STATE lens semantics, and the
quality-bar close-gate surface. `--apply` uses the replay guard so repeated
preflight applications append one ledger row.

Wave 2 delivered mission-lock output validation, dispatch author probing, close
receipt validation, and scaffold validation. The preflight gate runs each as a
contract fixture so the terminal check proves the shipped interfaces still work
without rewriting live mission state.

Wave 3 delivered readiness and delivery identity checks. The preflight gate uses
the readiness doctor against a healthy temporary mission/lens fixture and runs
dispatch self-test preflight against a deterministic packet.

Wave 4 #1 delivered the golden replay runner and invariants. The preflight gate
runs both live runner verbs against the seven checked-in fixtures.

## Integration with `/flywheel:plan` close-gate-handler

The close-gate handler should call:

```bash
.flywheel/scripts/polish-preflight-quality-gate.sh --check --plan-slug "$PLAN_SLUG" --json
```

Exit code `0` means the terminal plan arc is eligible to close. Exit code `1`
means a sub-gate fired and `first_fire_reason` names the first failing gate.
Exit code `2` means the target plan is pending or missing.

`--apply` is advisory. It writes the preflight ledger row through
`idempotency-replay-guard.sh` and deliberately does not mutate plan STATE.

## Ledger schema rationale

`polish-preflight-receipt.schema.json` keeps the receipt small: terminal status,
plan slug, per-gate evidence path and latency, first-fire reason, composite
score, closed-audit boolean, timestamp, and gate version. Extra properties are
allowed so `--apply` can report idempotency metadata without forcing a schema
revision.

The receipt is intentionally gate-oriented rather than implementation-oriented;
future close handlers can evaluate the same contract regardless of how the
individual validators evolve.

## Wave 4 #2 closes 13-bead DAG declaration

Wave 4 #2 is the terminal closure bead for
`mission-lock-paradigm-extension-2026-05-06`. With the polish preflight quality
gate shipped and green, the 13-bead DAG is fully closed and the plan arc is
eligible to transition from READY to FULLY-SHIPPED on 2026-05-06.
