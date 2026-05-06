# The Zest Press

The Zest Press turns a shipped artifact event into a deterministic Zest Ledger
row candidate. Its invariant is: identical non-secret evidence maps to one
stable row identity, and secret-looking evidence is refused before serialization.

## Quick Start

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-classifier.py classify --event tests/fixtures/wire-or-explain-classifier/script.json --json > "$tmp/press.json"
jq -e '.status == "pass" and .row.artifact_class == "finding"' "$tmp/press.json"
jq -e '.row.payload.evidence_root_hash | startswith("sha256:")' "$tmp/press.json"
```

Expected result: both `jq` probes exit 0. The output contains a candidate row,
not a ledger mutation, unless `--apply` is supplied.

## What It Presses

The press receives event JSON from worker, doctrine, dispatch, reset-guard,
Jeff-corpus, CLI, and skill-candidate surfaces. It emits a B1-shaped row with:

- `identity_key`: stable SHA-256 identity over event class, target, refs, and
  evidence root.
- `artifact_class`: ledger class such as `finding`, `dispatch_packet`,
  `worker_branch`, or `skill_candidate`.
- `state`: normally `unwired`; `not_required` when the input proves no wire is
  required.
- `consumer`: the current drain path or explicit no-wire receipt owner.
- `verification_probe`: the mechanical probe a downstream consumer must satisfy.
- `tick_status_consequence`: how the row affects the current tick.
- `payload.evidence_root_hash`: a hash of the evidence payload, never a secret
  dump.

## Canonical CLI Matrix

| Verb | Flag | Description | Exit code |
|---|---|---|---|
| global | `--help` | Print argparse help for the current command. | 0 |
| global | `--info` | Emit surface name, version, and command list. | 0 |
| global | `--examples` | Emit a minimal example command list. | 0 |
| global | `--json` | Emit JSON for global info/examples and command output. | 0 |
| `classify` | `--event PATH` | Required input event JSON. | 0 on pass, 1 on refusal |
| `classify` | `--schema PATH` | Ledger schema used for row validation. Defaults to `.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json`. | 0 or 1 |
| `classify` | `--ledger PATH` | Target ledger for `--apply`. Defaults to the user flywheel ledger path. | 0 or 1 |
| `classify` | `--apply` | Append idempotently instead of only printing the candidate row. | 0 or 1 |
| `classify` | `--json` | Emit machine-readable classification or refusal. | 0 or 1 |
| `doctor` | `--json` | Report schema availability, required B1 row fields, and secret refusal pattern coverage. | 0 or 1 |
| `health` | `--json` | Return single-shot `healthy` or `degraded` status for schema and field visibility. | 0 or 1 |
| `repair` | `--dry-run --json` | Plan safe schema/ledger-parent repair; `--apply` requires `--idempotency-key`. | 0, 1, or 4 |
| `validate` | `--event PATH --json` | Probe schema visibility and optionally classify one event into a schema row. | 0 or 1 |
| `audit` | `--ledger PATH --limit N --json` | Emit recent redacted ledger row summaries for classifier provenance. | 0 or 1 |
| `why` | `IDENTITY_KEY --ledger PATH --json` | Explain one ledger row by identity key or sequence number. | 0 or 1 |
| `schema` | `--json` | Report schema status and required B1 fields. | 0 |
| `quickstart` | `--json` | Emit quickstart payload. | 0 |
| `help` | `TOPIC --json` | Emit topic payload for operator help. | 0 |
| `completion` | `bash` | Print bash completion text. | 0 |
| `completion` | `zsh` | Print zsh completion text. | 0 |

Current boundary: these commands are scoped operator probes, not a second
classifier. `validate --event` proves one event can become a B1-shaped row;
`audit` and `why` read ledger provenance; `repair` only plans safe environment
preparation unless an idempotency-keyed apply is explicitly requested.

## State Examples

| Input class | Example fixture | Output state | Expected output |
|---|---|---|---|
| Script or normal shipped artifact | `tests/fixtures/wire-or-explain-classifier/script.json` | `unwired` | `status=pass`, `row.artifact_class=finding`, `row.consumer=wire-or-explain-detector` |
| Doctrine or L-rule artifact | `tests/fixtures/wire-or-explain-classifier/l_rule.json` | `unwired` | `row.consumer=doctrine-3-surface-divergence-probe` |
| Dispatch template | `tests/fixtures/wire-or-explain-classifier/dispatch_template.json` | `unwired` | `row.artifact_class=dispatch_packet`, `row.consumer=dispatch-and-log` |
| Worker branch artifact | `tests/fixtures/wire-or-explain-classifier/worker_branch.json` | `unwired` | `row.artifact_class=worker_branch`, `branch_ref` retained |
| Reset-guard artifact | `tests/fixtures/wire-or-explain-classifier/reset_guard.json` | `unwired` | `reset_intent_hash` retained or derived |
| Skill-shaped finding | `tests/fixtures/wire-or-explain-classifier/skill_candidate.json` | `unwired` | `row.artifact_class=skill_candidate`, `consumer=skillos:skill-candidate-relay` |
| Explicit no-wire event | `tests/fixtures/wire-or-explain-classifier/no_wire_required.json` | `not_required` | `predicate=no_wire_required`, `blocking_scope=none` |
| Secret-looking evidence | `tests/fixtures/wire-or-explain-classifier/secret_evidence.json` | refused | `status=refused`, `reason_code=secret_looking_evidence` |
| Duplicate apply | run `classify --apply` twice with the same event and ledger | duplicate | `status=duplicate`, `appended=false` |

Concrete probe:

```bash
tmp="$(mktemp -d)"
.flywheel/scripts/wire-or-explain-classifier.py classify --event tests/fixtures/wire-or-explain-classifier/no_wire_required.json --json > "$tmp/not-required.json"
jq -e '.row.state == "not_required" and .row.blocking_scope == "none"' "$tmp/not-required.json"
```

## Failure Modes

| Failure | Output | Recovery |
|---|---|---|
| Event file is not a JSON object | `reason_code=event_not_object`, exit 1 | Fix the event producer to write a JSON object, then rerun `classify`. |
| Secret-looking evidence is present | `status=refused`, `reason_code=secret_looking_evidence`, exit 1 | Remove or hash the secret value at the event source. The press reports classes and paths only. |
| Worker branch lacks identity proof | `reason_code=worker_branch_identity_proof_missing`, exit 1 | Include `branch_ref` and `identity_proof` in the event. |
| `jsonschema` is missing | `schema_validation.reason_code=jsonschema_missing` | Install the Python dependency or run in the repo environment that has it. |
| Schema file is missing | `schema_status=deferred_pending_F03` or `schema_file_missing` | Restore `.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json`. |
| Duplicate active row | `status=duplicate`, `appended=false` | Treat the existing row as the source of truth; do not create a second active row. |

## Anti-Patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Paste raw evidence with tokens, bearer headers, or API keys. | The press refuses secret-shaped evidence and must not become a secret ledger. | Store a hash, path, or redacted summary. |
| Treat `status=pass` as proof that the artifact is wired. | The press only creates a candidate row. Wiring is proved by The Zest Pour. | Run the detector and ranker after appending. |
| Append duplicate event identities to force progress. | Duplicate active rows inflate backlog and break stock accounting. | Use the duplicate receipt and drain the existing row. |
| Override `consumer` to a human when a mechanical consumer exists. | It converts an automatable drain into an escalation. | Name the script, doctor probe, skillos route, or owner surface. |
| Hide missing schema validation because the row shape "looks right." | The B1 schema is the operator contract. | Fix schema availability or keep the row blocked. |

## Doctor, Health, And Repair Expectations

`doctor --json` proves that the press can name the required B1 fields, see the
canonical schema, and keep secret refusal patterns visible. Use
`validate --event` for an explicit fixture classification probe before append
workflows.

`health --json` should be single-shot and non-mutating. If schema visibility or
secret refusal breaks, health is degraded because the press can no longer
produce safe ledger candidates.

`repair --dry-run --json` must remain preview-only until a concrete safe repair
exists. Any future mutating repair needs an idempotency key and an audit row.

`flywheel-loop doctor --scope wire-or-explain` consumes the downstream ledger
stock, not the press directly. The press participates by emitting rows with
usable `consumer`, `verification_probe`, and `tick_status_consequence` fields.

## Halt Behavior

Halt on these breaches:

- Secret-looking evidence would be serialized.
- Worker branch artifacts lack identity proof.
- A row cannot satisfy the B1 required field set.
- An `--apply` run would create a second active row for the same identity.

The correct halt is refusal or duplicate receipt, not best-effort serialization.
The stock is "candidate wire-or-explain rows"; the outflow is a safe append into
The Zest Ledger or an explicit refusal that keeps secrets and malformed rows out
of the ledger.

Part of the Yuzu Method framework by ZestStream.
