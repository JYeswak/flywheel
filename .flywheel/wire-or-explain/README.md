# The Zest Pour

The Zest Pour reads Zest Ledger rows and classifies each shipped artifact by
actual consumer wiring. Its invariant is: a row is `wired` only when mechanical
consumer proof exists; prose-only proof stays visible as weak evidence.

## Quick Start

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-detector.py detect --ledger tests/fixtures/wire-or-explain-detector/ledger.jsonl --relay-ledger tests/fixtures/wire-or-explain-detector/skillos-relay-ledger.jsonl --send-receipts tests/fixtures/wire-or-explain-detector/send-receipts.jsonl --now 2026-05-05T00:00:00Z --execute-probes --json > "$tmp/pour.json"
jq -e '.summary.total == 9 and .summary.unresolved == 4' "$tmp/pour.json"
jq -e '.ranker_input.unresolved | length == 4' "$tmp/pour.json"
```

Expected result: both `jq` probes exit 0. The output includes row-level
classifications, schema-shaped ledger rows, ranker input, and doctor actions.

## What It Measures

The Zest Pour is the detector in the wire-or-explain stock/flow loop:

- Stock: active ledger rows whose consumer proof is not closed.
- Inflow: classifier, ledger writer, worker, or doctrine rows.
- Outflow: `wired`, `not_required`, or consciously `deferred` rows.
- Backlog: `unwired` and `questionably_wired` rows.
- Feedback: `doctor_actions` and `ranker_input.unresolved` route the backlog to
  The Zest Sorter and flywheel doctor surfaces.

## Canonical CLI Matrix

| Verb | Flag | Description | Exit code |
|---|---|---|---|
| global | `--help` | Print argparse help. | 0 |
| global | `--info` | Emit surface name and supported states. | 0 |
| global | `--examples` | Emit minimal example commands. | 0 |
| `detect` | `--ledger PATH` | Read source Zest Ledger JSONL. Required for useful output. | 0, 2 if omitted |
| `detect` | `--relay-ledger PATH` | Read skillos relay rows for skill-candidate closure. | 0 |
| `detect` | `--send-receipts PATH` | Read send receipts that validate relay rows. | 0 |
| `detect` | `--schema-file PATH` | Validate generated B1 rows against a schema if present. | 0 |
| `detect` | `--repo PATH` | Working directory for runnable probes. Defaults to current directory. | 0 |
| `detect` | `--now ISO8601` | Evaluation time for deferral checks. | 0 |
| `detect` | `--execute-probes` | Run runnable consumer probes instead of only recognizing them. | 0 |
| `detect` | `--probe-timeout N` | Per-probe timeout in seconds. Defaults to 5. | 0 |
| `detect` | `--json` | Accepted for consistency; output is JSON either way. | 0 |
| `validate` | same as `detect` | Run detector and tag output as validation. | 0, 2 if ledger omitted |
| `health` | same as `detect` | Return `ok` if unresolved count is zero, else `degraded`. | 0, 2 if ledger omitted |
| `doctor` | same as `detect` | Wrap detector output for doctor consumption. | 0, 2 if ledger omitted |
| `why` | `ROW_ID` plus detect flags | Return one row's classification and `found` boolean. | 0, 2 if ledger omitted |
| `schema` | none | Emit detector output schema summary. | 0 |
| `quickstart` | none | Emit quickstart steps. | 0 |
| `help` | `TOPIC` | Emit topic summary. | 0 |
| `completion` | `bash` or `zsh` | Emit shell completion text. | 0 |
| `audit` | detect flags plus `--limit N --json` | Emit recent row summaries with consumer/probe visibility. | 0, 2 if ledger omitted |
| `repair` | detect flags plus `--dry-run --json` | Emit a route plan for unresolved rows; `--apply` requires `--idempotency-key` and does not mutate ledger rows. | 0, 2, or 4 |

Current boundary: `doctor` and `health` intentionally wrap detection so the
operator view and health view use the same row classifier. `audit` summarizes
recent rows, and `repair` emits routing actions for unresolved stock rather than
editing the ledger directly.

## State Examples

| State | Example condition | Expected output |
|---|---|---|
| `wired` | A row has a runnable probe and `--execute-probes` returns exit 0. | `wire_state=wired`, `reason_code=runnable_consumer_probe_passed` |
| `wired` | A `skill_candidate` row has a matching skillos relay row and send receipt. | `wire_state=wired`, `reason_code=skillos_relay_receipt_found` |
| `deferred` | `deferral_until` is in the future and `deferral_owner` is set. | `wire_state=deferred`, `reason_code=future_deferral` |
| `unwired` | A row has no consumer evidence. | `wire_state=unwired`, `reason_code=no_consumer_evidence` |
| `unwired` | A deferral is overdue. | `wire_state=unwired`, `reason_code=deferral_overdue` |
| `unwired` | Consumer proof points back to the producer without independent proof. | `wire_state=unwired`, `reason_code=circular_self_proof_refused` |
| `questionably_wired` | Evidence is README-only or doctrine-only. | `wire_state=questionably_wired`, `reason_code=readme_or_doctrine_only_reference` |
| `questionably_wired` | A runnable probe exists but was not executed. | `wire_state=questionably_wired`, `reason_code=runnable_probe_not_executed` |
| `not_required` | The source row state or artifact class says no wire is required. | `wire_state=not_required`, `reason_code=wire_not_required` |
| `bypassed` | The source row records explicit bypass. | `wire_state=bypassed`, `reason_code=explicit_bypass` |

Concrete probe:

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-detector.py detect --ledger tests/fixtures/wire-or-explain-detector/ledger.jsonl --relay-ledger tests/fixtures/wire-or-explain-detector/skillos-relay-ledger.jsonl --send-receipts tests/fixtures/wire-or-explain-detector/send-receipts.jsonl --now 2026-05-05T00:00:00Z --execute-probes --json > "$tmp/pour.json"
jq -e '.summary.wired == 2 and .summary.deferred == 1 and .summary.questionably_wired == 1' "$tmp/pour.json"
```

## Failure Modes

| Failure | Output | Recovery |
|---|---|---|
| Missing `--ledger` for detect-like commands | `status=fail`, `reason_code=missing_ledger`, exit 2 | Supply a ledger JSONL path. |
| Ledger path is absent | Empty row set because missing JSONL loads as empty | Treat as bootstrap only; in enforce mode, flywheel doctor should flag missing ledger. |
| Invalid JSONL row | `invalid JSONL` with path and line, process exits | Fix the producer row or rebuild from a trusted ledger source. |
| Runnable probe fails | `wire_state=questionably_wired` or `unwired`, `reason_code=probe_nonzero` or `probe_exec_failed` | Fix the consumer probe or defer with owner and threshold. |
| README-only proof | `questionably_wired` | Add a runnable probe, send receipt, callback receipt, or other mechanical consumer proof. |
| Skill candidate lacks relay | `unwired`, `next_action=send_to_skillos` | Send to skillos and record relay ledger plus send receipt. |
| Schema file missing | `schema_validation_status=deferred_missing_schema` | Restore the schema or pass the correct `--schema-file`. |

## Anti-Patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Count README mentions as `wired`. | Documentation is not a consumer receipt. | Add or execute a mechanical probe. |
| Ignore `questionably_wired` because it is not hard failed. | Weak proof still accumulates operational debt. | Route it through The Zest Sorter and drain it. |
| Run arbitrary probes without timeout. | A stuck probe can stall the detector. | Keep `--probe-timeout` bounded. |
| Treat skill candidates as a separate backlog. | They are part of the same stock and must route to skillos. | Keep them in the ledger and relay to skillos. |
| Let bypass rows disappear after review. | Bypass is a state with an owner and consequence. | Keep the row until a receipt documents closure. |

## Doctor, Health, And Repair Expectations

`doctor` wraps full detection output and should be the operator view for backlog
shape. It must expose unresolved rows, weak proof, schema validation status, and
next actions.

`health` is a single-shot status: `ok` when unresolved count is zero and
`degraded` otherwise. Degraded does not mean the detector is broken; it means
the ledger contains work.

`repair --dry-run --json` returns safe drain proposals for unresolved stock, such
as "send skill candidate to skillos" or "create repair bead for missing consumer
proof." Apply mode requires an idempotency key and still leaves ledger mutation
to the downstream owner.

`flywheel-loop doctor --scope wire-or-explain` consumes this surface by
reporting missing ledgers, unresolved count, overdue count, top actions, and
skill relay state. Halt-on-breach happens there when enforce mode sees missing
ledger, overdue unresolved rows, or undrained skill-candidate stock.

## Halt Behavior

Halt or degrade the tick when:

- A required ledger is missing in enforce mode.
- Any `unwired` row is overdue or has no owner.
- A `questionably_wired` row is the only proof for a ship-critical artifact.
- A `skill_candidate` row lacks a skillos relay receipt past its threshold.
- Schema projection fails for generated ledger rows.

The detector should not silently pass an artifact because a doc says it is wired.
The stock is "rows needing consumer proof"; the outflow is mechanical evidence,
explicit deferral, explicit not-required proof, or a bypass with owner.

## Fleet Rollout

Fleet rollout state lives in `.flywheel/wire-or-explain/fleet-rollout.json`.
Each repo/session entry declares `state`, `trust_domain`, `owning_orch`, and
rollback target. Supported states are `disabled`, `shadow`, `enforce`, and
`deferred`.

`wire-or-explain-close-gate.py rollout-status --json` reports the effective
state. `rollback --target-state shadow|disabled --apply --json` moves the local
entry back without deleting ledger history.

In enforce mode, unresolved rows block only the owning orchestrator. Rows owned
by another session or another trust domain remain visible as warnings so
unrelated ticks do not halt.

Part of the Yuzu Method framework by ZestStream.
