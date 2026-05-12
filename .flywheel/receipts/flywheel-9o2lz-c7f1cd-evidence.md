# flywheel-9o2lz-c7f1cd evidence

## Changed

- Added `.flywheel/scripts/bcv-task-harness.sh`.
- Added `tests/bcv-task-harness.sh`.
- Filed follow-up `flywheel-9s6df` for the upstream BCV `inventory-beads.sh` macOS `xargs -d` portability gap observed during fixture execution.

## Harness behavior

- Bootstraps a BCV pass through the skill bootstrap script.
- Runs Phase 1 inventory through the skill script when available, with a scoped target-bead fallback for macOS/BSD `xargs`.
- Runs Phase 2 `extract-spec.py` and Phase 3 `gather-evidence.sh`.
- Emits Phase 4 Task-tool prompt files under `task-prompts/phase4/`.
- Waits for non-stub `compliance.json` packs where `executor` is not `stub-wrapper` or `single-bead-stub`.
- Runs Phase 5 `theater-scan.sh` and `anomaly-scan.sh`.
- Emits Phase 6 Task-tool prompt files under `task-prompts/phase6/`.
- Waits for non-stub `test_depth.json` packs where `auditor` is not `stub-wrapper` or `single-bead-stub`.
- Validates each bead pack via `validate-evidence.py`.
- Runs `synthesize.py`, `score-bead.py`, and `master-report.py`.
- Fails the run if the master report contains `DETERMINISTIC-ONLY PASS`.

## Verification

Passed:

```text
bash -n .flywheel/scripts/bcv-task-harness.sh
bash -n tests/bcv-task-harness.sh
.flywheel/scripts/bcv-task-harness.sh --info --json | jq -e '.version == "bcv-task-harness/v1"' >/dev/null
.flywheel/scripts/bcv-task-harness.sh --repo "$PWD" --beads flywheel-9o2lz --json | jq -e '.status == "dry_run" and (.target_beads | length == 1)' >/dev/null
shellcheck .flywheel/scripts/bcv-task-harness.sh tests/bcv-task-harness.sh
bash tests/bcv-task-harness.sh
```

Fixture result:

```text
bcv-task-harness fixture passed
```

The fixture creates two closed beads in a temp repo, runs the harness in `--apply` mode, writes non-stub Phase 4/6 packs only after prompt files appear, and asserts:

- `non_stub_compliance_count == 2`
- `non_stub_test_depth_count == 2`
- `validation_passed == true`
- `deterministic_banner_present == false`
- two Phase 4 prompts and two Phase 6 prompts were emitted
- the final report has no `DETERMINISTIC-ONLY PASS` banner

## Socraticode

- `socraticode_queries=3`
- `indexed_chunks_observed=30`

## Notes

The upstream skill `inventory-beads.sh` currently fails on macOS because BSD `xargs` does not support `-d`. The harness records that as a warning and uses a scoped target-bead inventory fallback so real Phase 4/6 orchestration remains usable.
