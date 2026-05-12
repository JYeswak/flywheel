# flywheel-wire-orch-wake-event-driven-not-time-ba-91af94c2-66ebc3 Evidence

Task: `flywheel-wire-orch-wake-event-driven-not-time-ba-91af94c2`

## Acceptance

- AG1: PASS. `.flywheel/scripts/meta-rule-structural-batch-gate.sh` now registers `orch-wake-event-driven-not-time-based`; detector hook evidence resolves through `/Users/josh/.claude/settings.json`.
- AG2: PASS. `.flywheel/tests/test-orch-wake-event-driven-not-time-based.sh` verifies the rule is registered and classified `WIRED`.
- AG3: PASS. `memory-rule-gate-parity-detector.sh` no longer reports `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md` as zero structural evidence.

## Socraticode Survey

- socraticode_queries=3
- indexed_chunks_observed=30
- Findings: existing `tests/test_loop_dynamic_mode_arms_monitor.sh` already validates the event-driven Monitor contract; this task needed memory-rule parity wiring through the existing consolidated batch gate, settings hook evidence, test stub, and INCIDENTS evidence.

## Files Changed

- `.flywheel/scripts/meta-rule-structural-batch-gate.sh`
- `.flywheel/tests/test-orch-wake-event-driven-not-time-based.sh`
- `INCIDENTS.md`
- `.beads/issues.jsonl` via `br close`

## Verification

Commands run:

```bash
bash -n .flywheel/scripts/meta-rule-structural-batch-gate.sh
bash -n .flywheel/tests/test-orch-wake-event-driven-not-time-based.sh
shellcheck .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-orch-wake-event-driven-not-time-based.sh
bash .flywheel/tests/test-orch-wake-event-driven-not-time-based.sh
bash tests/test_loop_dynamic_mode_arms_monitor.sh
MEMORY_RULE_GATE_PARITY_LEDGER=/tmp/parity-after.jsonl .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json | jq -e '.rules[] | select(.memory_path == "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_wake_event_driven_not_time_based.md") | .classification == "WIRED" and .evidence_count == 4 and (.missing_evidence | length == 0)'
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-wire-orch-wake-event-driven-not-time-ba-91af94c2-66ebc3.md
```

Result markers:

```text
PASS orch-wake-event-driven-not-time-based registered and parity-classified WIRED
PASS: loop dynamic mode Monitor contract fixture
l112_marker=orch_wake_rule_wired
l112_marker=detector_evidence_count_4
```

Detector target row after patch:

```json
{"rule_id":"orch-wake-event-driven-not-time-based","classification":"WIRED","evidence_count":4,"missing_evidence":[]}
```

## Four-Lens Self-Grade

- brand:9
- sniff:9
- jeff:9
- public:9

Three Judges check: skeptical operator gets a live detector row, maintainer gets the established batch-gate pattern plus existing Monitor fixture coverage, and future worker gets a named regression test.

## Receipts

- tmp_dir_released=true
- files_reserved=.flywheel/scripts/meta-rule-structural-batch-gate.sh,.flywheel/tests/test-orch-wake-event-driven-not-time-based.sh,INCIDENTS.md,.beads/issues.jsonl,.flywheel/receipts/flywheel-wire-orch-wake-event-driven-not-time-ba-91af94c2-66ebc3-evidence.md
- beads_updated=flywheel-wire-orch-wake-event-driven-not-time-ba-91af94c2:closed
- beads_filed=none
- fuckups_logged=none
- skill_discoveries=0
- agents_md_updated=no
- readme_updated=no
- no_touch_reason=structural-gate-and-incidents-only-no-agent-doctrine-or-readme-change-required
