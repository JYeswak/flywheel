# flywheel-vso8.1 evidence

task_id=219bb9e8
bead=flywheel-vso8.1

## DID

- AG1 audit gap closed mechanically: `flywheel-loop doctor --json` now exposes `storage_override.auto_clear_signal`.
- Receipt rows also preserve `storage_override.rows[].auto_clear_signal`, so active receipt evidence remains inspectable.
- Regression coverage added to `tests/storage-override.sh` as `doctor_exposes_auto_clear_signal`.

## DIDNT

- none

## GAPS

- `flywheel-c5zi`: while validating this surface, found storage override schema drift. The schema declares `rollback_guard` as a string, while current receipt fixtures write it as an object and tests do not validate generated receipts against the schema.

## Validation

```text
bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop
tests/storage-override.sh

PASS flywheel_loop_syntax
PASS schema_declares_storage_override_v1
PASS valid_receipt_lowers_low_storage_gate
PASS doctor_exposes_auto_clear_signal
PASS expired_receipt_fails_closed
PASS missing_applies_to_fails_closed
PASS receipt_above_threshold_auto_reverts
PASS storage_cleared_event_written
PASS cli_flag_storage_min_free_pct
PASS env_var_storage_min_free_pct

Summary: 10 passed, 0 failed
```

Live doctor probe:

```text
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json \
  | jq -e '.storage_override.auto_clear_signal == "STORAGE-CLEARED"'

true
```

Graph:

```text
br dep cycles
✓ No dependency cycles detected.
```

## Three-Q

- VALIDATED: storage override test and live doctor JSON proof pass.
- DOCUMENTED: evidence captured here; existing AGENTS/README already describe storage override receipts.
- SURFACED: new schema validation gap filed as `flywheel-c5zi`.

## Four-Lens Rework - flywheel-joh7

### Public Lens Self-Grade - Three Judges Publishability

Would-they-fork-and-star verdict: PASS for the scoped `flywheel-vso8.1` artifact. The evidence is not a standalone product page; it is a closeout receipt for one audit-gap child. On that scope, it gives a serious builder enough proof to trust the change: the doctor JSON field is named, the test command is reproducible, the dependent schema drift is preserved as `flywheel-c5zi`, and the closeout states what was validated, documented, and surfaced.

| facet_id | facet | verdict | evidence |
|---|---|---|---|
| F1 | README front-door | YES | Existing storage-override behavior is already described in repo docs; this child evidence points to `flywheel-loop doctor --json` and the `storage_override.auto_clear_signal` field instead of requiring oral context. |
| F2 | Doctrine clarity | YES | Storage override receipts are governed by L79 and the parent `flywheel-vso8`; this receipt keeps the doctrine link concrete through `storage-override/v1` and the `STORAGE-CLEARED` signal. |
| F3 | Doctor/health/repair triad | YES | Doctor visibility is the shipped surface: `flywheel-loop doctor --json` exposes `storage_override.auto_clear_signal`, while `flywheel-c5zi` preserves the schema follow-up instead of hiding repair work. |
| F4 | Executable tests | YES | `tests/storage-override.sh` includes `doctor_exposes_auto_clear_signal`; the evidence records 10 passed, 0 failed and the live `jq` probe. |
| F5 | Idempotent install + uninstall | YES | The child does not add an installer; it validates an existing `storage-override/v1` receipt path that already expires, fails closed, and auto-clears through `STORAGE-CLEARED`. |
| F6 | Code aesthetic | YES | The public artifact is small and local: one doctor field, one receipt row field, one regression name, and one gap bead for schema drift. |
| F7 | Demo-ability | YES | A reviewer can demo the value with one command: `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq -e '.storage_override.auto_clear_signal == "STORAGE-CLEARED"'`. |

Three Judges:

- Jeffrey: PASS. Mutation-adjacent storage override behavior has a schema marker, doctor JSON proof, fixture-backed regression, fail-closed receipt handling, and a named follow-up for rollback schema drift.
- Donella: PASS. The artifact improves the feedback loop: the storage override no longer lives only as a receipt fact; the doctor exposes the auto-clear signal where operators and daily gates can see the stock returning to the base threshold.
- Joshua: PASS. A 25-year operations manager would recognize the operator-experience pattern: temporary overrides must tell the next shift exactly when they clear. This has company-building leverage and turnover resilience because a later operator can inspect the doctor field and the `flywheel-c5zi` gap instead of relying on the original worker's memory.

Public voice gate: EXEMPT internal receipt. ZestStream voice score: not applicable. Banned words count: 0. Ungrounded claims count: 0. Scorecard log: this section.

Four-Lens Self-Grade: brand voice PASS; Joshua sniff PASS; Jeff doctrine PASS; public publishability PASS for Three Judges and all seven facets.

Result: the receipt now names the publishability bar and explains why the scoped storage-override child is public-grade evidence without pretending the schema follow-up is closed.
