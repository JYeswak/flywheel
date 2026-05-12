# flywheel-wire-dispatch-to-lib-not-bin-for-split-ac3cbeaf-6a6ead Evidence

Task: `flywheel-wire-dispatch-to-lib-not-bin-for-split-ac3cbeaf`

## Acceptance

- AG1: PASS. `.flywheel/scripts/meta-rule-structural-batch-gate.sh` now registers `dispatch-to-lib-not-bin-for-split-modules`; detector hook evidence resolves through `/Users/josh/.claude/settings.json`.
- AG2: PASS. `.flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh` verifies the rule is registered and classified `WIRED`.
- AG3: PASS. `memory-rule-gate-parity-detector.sh` no longer reports `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dispatch_to_lib_not_bin_for_split_modules.md` as zero structural evidence.

## Socraticode Survey

- socraticode_queries=3
- indexed_chunks_observed=30
- Findings: existing parity detector, consolidated batch gate, test-stub pattern, settings reference, and INCIDENTS evidence pattern were already present. The correct fix was to extend that substrate, not create a bespoke gate.

## Files Changed

- `.flywheel/scripts/meta-rule-structural-batch-gate.sh`
- `.flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh`
- `INCIDENTS.md`
- `.beads/issues.jsonl` via `br close`

## Verification

Commands run:

```bash
bash -n .flywheel/scripts/meta-rule-structural-batch-gate.sh
bash -n .flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh
shellcheck .flywheel/scripts/meta-rule-structural-batch-gate.sh .flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh
bash .flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh
MEMORY_RULE_GATE_PARITY_LEDGER=/tmp/parity-after.jsonl .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json | jq -e '.rules[] | select(.memory_path == "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dispatch_to_lib_not_bin_for_split_modules.md") | .classification == "WIRED" and .evidence_count == 4 and (.missing_evidence | length == 0)'
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-wire-dispatch-to-lib-not-bin-for-split-ac3cbeaf-6a6ead.md
```

Result markers:

```text
PASS dispatch-to-lib-not-bin-for-split-modules registered and parity-classified WIRED
l112_marker=dispatch_to_lib_rule_wired
l112_marker=detector_evidence_count_4
```

Detector target row after patch:

```json
{"rule_id":"dispatch-to-lib-not-bin-for-split-modules","classification":"WIRED","evidence_count":4,"missing_evidence":[]}
```

## Four-Lens Self-Grade

- brand:9
- sniff:9
- jeff:9
- public:9

Three Judges check: skeptical operator gets a live detector row, maintainer gets the established batch-gate pattern, and future worker gets a named regression test.

## Receipts

- tmp_dir_released=true
- files_reserved=.flywheel/scripts/meta-rule-structural-batch-gate.sh,.flywheel/tests/test-dispatch-to-lib-not-bin-for-split-modules.sh,INCIDENTS.md,.beads/issues.jsonl,.flywheel/receipts/flywheel-wire-dispatch-to-lib-not-bin-for-split-ac3cbeaf-6a6ead-evidence.md
- beads_updated=flywheel-wire-dispatch-to-lib-not-bin-for-split-ac3cbeaf:closed
- beads_filed=none
- fuckups_logged=dcg-redirect-truncate-blocked
- skill_discoveries=0
- agents_md_updated=no
- readme_updated=no
- no_touch_reason=structural-gate-and-incidents-only-no-agent-doctrine-or-readme-change-required
