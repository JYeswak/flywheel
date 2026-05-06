# The Zest Ledger

The Zest Ledger is the append-only source of truth for wire-or-explain rows. Its
invariant is: every durable observation has an owner, consumer or deferral,
verification probe, tick consequence, sequence number, previous hash, and
checksum.

The schema name is `flywheel.wire-or-explain.v1`. The row contract lives at
`.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json`.

## L110 Primitive Wording

The Zest Ledger is the wire-or-explain source of truth: every durable
observation/finding/artifact must declare its stock, class, consumer or explicit
deferral, owner, action ledger, verification probe, and tick/status consequence.

## Quick Start

```bash
tmp="$(mktemp -d)"
bash .flywheel/scripts/wire-or-explain-ledger-writer.sh --row tests/fixtures/wire-or-explain-ledger/valid-wired.json --ledger "$tmp/zest-ledger.jsonl" --json > "$tmp/append.json"
bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --ledger "$tmp/zest-ledger.jsonl" --json > "$tmp/verify.json"
jq -e '.status == "appended" and .sequence_num == 1' "$tmp/append.json"
jq -e '.status == "pass" and .tampered_count == 0' "$tmp/verify.json"
```

Expected result: both `jq` probes exit 0. The writer appends one canonical JSONL
row and the verifier proves the hash chain is intact.

## Row Shape

The schema requires more than 30 fields. The load-bearing fields are:

| Field | Why it matters |
|---|---|
| `identity_key` | Stable duplicate-detection key. Duplicate writes return a duplicate receipt instead of creating a second active row. |
| `state` | Current wire status: `wired`, `deferred`, `unwired`, `questionably_wired`, `not_required`, or `bypassed`. |
| `artifact_class` | Routes the row as `finding`, `dispatch_packet`, `bead`, `callback`, `worker_branch`, `skill_candidate`, `ledger_rebuild`, or `other`. |
| `owner` | Accountable operator, orchestrator, pane, or substrate owner. |
| `consumer` | Mechanical drain path, skillos route, bead owner, or explicit `NONE` with deferral fields. |
| `verification_probe` | Command or probe that proves the row closed. |
| `tick_status_consequence` | The doctor/status effect when the row remains active. |
| `action_ledger` | Durable JSONL path where action and receipt history lives. |
| `prev_hash` and `checksum` | Tamper-evident hash chain fields. |

The full field list is in the schema. Operators should link to the schema for
complete validation rules instead of copying schema definitions into dispatches.

## Writer And Verifier Pair

The ledger has two paired executable surfaces:

- `wire-or-explain-ledger-writer.sh`: appends one row, fills sequence/hash
  fields, validates against the schema when `jsonschema` is available, and
  returns a receipt.
- `wire-or-explain-chain-verifier.sh`: replays the ledger, recomputes checksums,
  checks `prev_hash`, checks sequence order, and reports tampered row numbers
  without printing row payloads.

The writer is the only current mutating surface. The verifier is read-only.

## Canonical CLI Matrix

| Verb | Flag | Description | Exit code |
|---|---|---|---|
| writer default / `append` | `--row PATH` | Required row JSON to append. | 0, usage error on missing row |
| writer default / `append` | `--ledger PATH` | Target JSONL ledger. Defaults to `$WIRE_OR_EXPLAIN_LEDGER` or the user state path. | 0 |
| writer default / `append` | `--json` | Emit JSON receipt. Current writer emits JSON receipts by default. | 0 |
| writer global | `--no-color --no-emoji --width N` | Accepted output controls for deterministic logs and non-TTY capture. | 0 |
| writer global | `--help` | Print usage. | 0 |
| writer global | `--info` | Emit name, human name, schema name/version, and default ledger. | 0 |
| writer global | `--examples` | Emit examples for append and verify. | 0 |
| writer `quickstart` | `--json` | Emit quickstart payload. | 0 |
| writer `schema` | none | Print the schema file. | 0 |
| writer `validate` | `--row PATH --ledger PATH --json` | Validate schema availability, optional row shape, and chain verifier status. | 0 or 1 |
| writer `audit` | `--ledger PATH --limit N --json` | Emit recent redacted ledger row summaries. | 0 |
| writer `why` | `IDENTITY_OR_SEQUENCE --ledger PATH --json` | Explain one row by identity key or sequence number without payload dump. | 0 or 1 |
| writer `doctor` | `--ledger PATH --json` | If ledger is absent, pass with row count 0; otherwise delegate to verifier. | 0 or 1 |
| writer `health` | `--ledger PATH --json` | Same current behavior as doctor. | 0 or 1 |
| writer `repair` | `--scope ledger --dry-run --json` | Plan safe ledger/lock repairs; `--apply` requires `--idempotency-key`. | 0, 1, 2, or 4 |
| writer `completion` | `bash` | Emit bash completion text. | 0 |
| writer `completion` | `zsh` | Emit zsh completion text. | 0 |
| verifier default | `--ledger PATH` | Verify a ledger JSONL. | 0 on pass, 1 on tamper |
| verifier default | `--json` | Emit JSON result. Current verifier emits JSON either way. | 0 or 1 |
| verifier global | `--help` | Print usage. | 0 |
| verifier global | `--no-color --no-emoji --width N` | Accepted output controls for deterministic logs and non-TTY capture. | 0 |
| verifier `doctor` / `health` / `validate` | `--ledger PATH --json` | Reuse chain verification as the diagnostic, health, or validation probe. | 0 or 1 |
| verifier `audit` | `--ledger PATH --limit N --json` | Emit recent redacted chain row summaries plus invalid row state. | 0 |
| verifier `why` | `IDENTITY_OR_SEQUENCE --ledger PATH --json` | Explain checksum status for one row by identity key or sequence number. | 0 or 1 |
| verifier `repair` | `--scope chain --dry-run --json` | Plan chain repair; tamper repair is blocked for manual rebuild review. | 0, 1, 2, or 4 |
| verifier `schema` / `quickstart` / `help` | `--json` | Emit chain verifier schema, quickstart, or topic help payloads. | 0 |
| verifier `completion` | `bash` or `zsh` | Emit shell completion text. | 0 |

Current boundary: writer and verifier both expose the canonical inspect,
validate, audit, why, repair, schema, quickstart, and completion surfaces. Repair
is deliberately bounded: safe directory preparation can be applied with an
idempotency key, but tampered row repair is reported for manual rebuild review
rather than rewritten in place.

## State Examples

| State | Fixture | Expected meaning |
|---|---|---|
| `wired` | `tests/fixtures/wire-or-explain-ledger/valid-wired.json` | Consumer proof exists; tick may close when verifier passes. |
| `deferred` | `tests/fixtures/wire-or-explain-ledger/valid-deferred.json` | Consumer is not active yet; `deferral_owner` and `deferral_until` explain the delay. |
| `unwired` | `tests/fixtures/wire-or-explain-ledger/valid-unwired.json` | Artifact has no current consumer or closure proof; tick must not close parent work. |
| `questionably_wired` | `tests/fixtures/wire-or-explain-ledger/valid-questionably-wired.json` | Weak proof exists but needs a stronger probe. |
| `not_required` | `tests/fixtures/wire-or-explain-ledger/valid-not-required.json` | No consumer is required and the row records why. |
| `bypassed` | `tests/fixtures/wire-or-explain-ledger/valid-bypassed.json` | A guard bypass was observed and must remain reviewable. |
| `unwired` skill candidate | `tests/fixtures/wire-or-explain-ledger/valid-skill-candidate.json` | Feedback/fuckup finding should route to skillos as `artifact_class=skill_candidate`. |

Concrete state probe:

```bash
tmp="$(mktemp -d)"
bash .flywheel/scripts/wire-or-explain-ledger-writer.sh --row tests/fixtures/wire-or-explain-ledger/valid-deferred.json --ledger "$tmp/zest-ledger.jsonl" --json > "$tmp/deferred.json"
jq -e '.status == "appended" and .ledger_written == true' "$tmp/deferred.json"
bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --ledger "$tmp/zest-ledger.jsonl" --json > "$tmp/verify.json"
```

## Idempotency Contract

The writer computes or preserves `identity_key`. If an active row with the same
identity already exists, the writer returns:

- `status=duplicate`
- `ledger_written=false`
- `duplicate_of_sequence_num`
- `duplicate_of_checksum`

It must not append a second active row for the same identity. That duplicate
receipt is the correct idempotency result.

## Tamper Detection Contract

The verifier reports hash-chain breaches without leaking row payloads. It emits:

- `status=pass` or `fail`
- `row_count`
- `tampered_count`
- `tampered_rows` with line, sequence number, expected/actual checksum,
  expected/actual previous hash, expected/actual sequence number, and reason

Payload fields are intentionally omitted. A tamper report should tell the
operator where the chain broke, not expose the evidence body.

## Failure Modes

| Failure | Output | Recovery |
|---|---|---|
| Missing `--row` on append | `status=usage_error` | Supply a fixture or row JSON path. |
| Row fails schema validation | Python/jsonschema validation error | Fix the producer row against `.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json`. |
| `jsonschema` unavailable | Validation is skipped in writer internals | Run tests in the repo environment and install the dependency for strict validation. |
| Duplicate identity | `status=duplicate`, `ledger_written=false` | Use the existing row; do not force a second active row. |
| Invalid JSONL line | Verifier marks `reason=invalid_json`, exits 1 | Restore from trusted ledger source or repair the line with audit trail. |
| Broken sequence | Verifier marks `reason=sequence_num`, exits 1 | Rebuild or repair ledger under an explicit repair bead. |
| Broken hash chain | Verifier marks `reason=prev_hash` or `checksum`, exits 1 | Treat the ledger as tampered until rebuilt from trusted receipts. |
| Repair without `--dry-run` | `status=usage_error` | Preview first; no current writer repair applies mutations. |

## Anti-Patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Edit ledger rows by hand. | Manual edits break checksum and `prev_hash`. | Append a new receipt row or rebuild under a repair bead. |
| Create a second active row after a duplicate receipt. | It inflates stock and hides the original owner. | Drain the existing row or mark it inactive through a future repair path. |
| Put raw secrets in payload or metadata. | The ledger is durable and widely consumed. | Store redacted summaries, hashes, or paths to protected stores. |
| Treat the schema description as the operator README. | Operators need commands, states, failure modes, and halt behavior. | Use this README as the entrypoint and link to the schema for full rules. |
| Ignore `skill_candidate` rows. | Feedback/fuckup findings are stock that should route to skillos. | Keep `artifact_class=skill_candidate` and verify skillos relay receipts. |

## Doctor, Health, And Repair Expectations

`writer doctor --json` and `writer health --json` currently delegate to the
chain verifier when the ledger exists. An absent ledger passes with row count 0,
which is acceptable in bootstrap mode but should be escalated by higher-level
doctor enforce mode when the system expects rows.

`writer repair --dry-run --json` and `chain-verifier repair --dry-run --json`
are bounded repair planners. Mutating mode requires `--apply` plus an
idempotency key, applies only safe directory preparation, and leaves row repair
or chain rebuild work to an explicit repair bead with audit trail.

The chain verifier is the hash-chain operator CLI for this surface. Use it for
doctor, health, validate, audit, why, repair planning, schema, quickstart, help,
and shell completion around ledger integrity.

`flywheel-loop doctor --scope wire-or-explain` uses this ledger as the source
stock. Halt-on-breach is triggered by missing expected ledger stock, unresolved
rows past threshold, or hash-chain/tamper failures.

## Halt Behavior

Halt or degrade when:

- Required B1 fields are absent.
- A row state has no owner, consumer, deferral, or verification probe.
- Duplicate identity would create a second active row.
- Verifier reports invalid JSON, sequence mismatch, previous hash mismatch, or
  checksum mismatch.
- `skill_candidate` stock has no skillos relay path or receipt.

The ledger exists to prevent ship-then-orphan drift. The stock is "durable
observations needing a drain"; the outflow is a verified consumer receipt,
explicit deferral, explicit not-required proof, or a reviewed bypass.

Part of the Yuzu Method framework by ZestStream.
