# flywheel-qegt3 Compliance Pack

## Scope

- Added security posture doctor output at `.security`.
- Added PASS/WARN/FAIL/strict FAIL fixture coverage.
- Extended `tests/doctor-validation-signals.sh` to assert security signal metadata.
- Live runtime integration is in `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` and `~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh`.

## Verification

- `bash -n ../../.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh`
- `bash -n ../../.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh`
- `bash -n tests/doctor-security-posture.sh`
- `bash -n tests/doctor-validation-signals.sh`
- `tests/doctor-security-posture.sh`: 6 passed, 0 failed.
- `tests/doctor-validation-signals.sh`: 14 passed, 0 failed.
- `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_DOCTOR_CACHE_DISABLE=1 ../../.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json > /tmp/flywheel-qegt3-doctor.json`
- `jq '.security' /tmp/flywheel-qegt3-doctor.json`: present.
- `jq -e '(.security.settings_deny_rules_present | type) == "boolean"' /tmp/flywheel-qegt3-doctor.json`: pass.
- `jq -e 'all(.security.signals[]; has("producer") and has("measurement") and has("consumer") and has("promotion_path"))' /tmp/flywheel-qegt3-doctor.json`: pass.
- `jq -e '(.security.output_policy.matched_values_emitted == false) and ((.security | tostring | test("CANARY_TEST_") | not))' /tmp/flywheel-qegt3-doctor.json`: pass.
- `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-qegt3-da1613.md`: valid.

## Four-Lens Self-Grade

- brand:9 - Adds a stable security posture surface to the operational doctor without leaking values.
- sniff:9 - Fixture tests cover status classes and metadata requirements.
- jeff:8 - Keeps the implementation narrow; live runtime split is outside this repo's tracked tree.
- public:8 - A skeptical operator, maintainer, and future worker can rerun the evidence from this pack.
