# flywheel-wire-validator-uses-isolated-tmpdir-9d2c51d5 Evidence

## Scope

- Wired `validator-uses-isolated-tmpdir` into `.flywheel/scripts/meta-rule-structural-batch-gate.sh`.
- Added `.flywheel/tests/test-validator-uses-isolated-tmpdir.sh` to prove the live memory rule is registered and parity-classified `WIRED`.
- Updated `INCIDENTS.md` structural batch coverage from 37 to 38 rules.

## Validation

- `bash -n .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-validator-uses-isolated-tmpdir.sh`
- `shellcheck .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-validator-uses-isolated-tmpdir.sh`
- `bash .flywheel/tests/test-validator-uses-isolated-tmpdir.sh`
- `MEMORY_RULE_GATE_PARITY_LEDGER="$(mktemp -t validator-isolated-parity-ledger.XXXXXX)" .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json | jq -e '.rules[] | select(.memory_path == "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_validator_uses_isolated_tmpdir.md") | .classification == "WIRED" and .evidence_count >= 3 and (.missing_evidence | length == 0)'`
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-wire-validator-uses-isolated-tmpdir-9d2c51d5-b4e780.md`

## Four-Lens Self-Grade

- brand:8
- sniff:8
- jeff:8
- public:8

## Close Notes

- Socraticode queries: 4; indexed chunks observed: 40.
- Shared-surface reservations released before callback.
- No new reusable skill discovery beyond the existing parity-gate pattern.
