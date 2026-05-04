# Validation Receipt Schema v1

Canonical path: `.flywheel/validation-schema/v1/`

This directory defines the first machine-readable receipt contract for validating worker callbacks before the orchestrator summarizes, integrates, closes, reopens, or routes learning events. A worker `DONE` or `BLOCKED` callback is a claim; this receipt is the proof envelope the later B02-B14 beads consume.

## Files

| path | purpose |
|---|---|
| `schema.json` | JSON Schema contract for validation receipts. |
| `tick-receipt.schema.json` | JSON Schema contract for tick receipts with VALIDATE phase summaries. |
| `parse.sh` | Read-only parser and semantic invariant checker. |
| `dispatch-template-audit.sh` | Read-only audit for dispatch packets and the shared dispatch template. |
| `fixtures/pass/*.json` | Receipts that must validate. |
| `fixtures/fail/*.json` | Receipts that must be rejected with deterministic JSON errors. |
| `fixtures/dispatch-template/*.md` | Valid and invalid dispatch-packet fixtures for B02. |

## Parser

Run:

```bash
bash .flywheel/validation-schema/v1/parse.sh .flywheel/validation-schema/v1/fixtures/pass/*.json
bash .flywheel/validation-schema/v1/parse.sh .flywheel/validation-schema/v1/fixtures/fail/*.json
```

Exit codes:

| code | meaning |
|---:|---|
| 0 | every supplied receipt is valid |
| 1 | at least one supplied receipt is invalid |
| 2 | usage error |

The parser emits JSON with stable keys: `schema`, `valid`, `files_checked`, `results[]`, and `errors[]`. Error rows are sorted by file, code, and message.

## Dispatch Template Audit

B02 adds a required `VALIDATION BLOCK` to the shared worker dispatch template at
`/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`. The audit
checks that a packet or template includes the validation schema/parser refs,
callback fields, Agent Mail reservation/release instructions, L52/L53 receipts,
L70 chain fields, agent-context proof, and the orchestrator-side
`validate-callback` step.

Run:

```bash
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/validation-schema/v1/fixtures/dispatch-template/valid-*.md
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/validation-schema/v1/fixtures/dispatch-template/invalid-*.md
```

The first two commands must exit 0. The invalid fixture command must exit 1
with deterministic JSON errors.

## Required Fields And 3-Q Mapping

| field | purpose | Q1 validated | Q2 documented | Q3 surfaced |
|---|---|---|---|---|
| `schema_version` | Pins this contract to `validation-receipt/v1`. | Parser rejects wrong versions. | This README and `schema.json`. | Canonical path is registered in `.flywheel/canonical-paths.txt`. |
| `dispatch_id` | Connects receipt to the dispatched work. | Non-empty id required. | Used by B02/B03 dispatch docs. | Can be routed into dispatch logs and learn ledgers. |
| `callback_ref` | Records callback transport, session, pane, kind, timestamp, and raw ref. | Parser rejects malformed refs. | Transport/kind enums in schema. | Lets orchestrator trace the callback source. |
| `status` | Validation verdict: `pass`, `fail`, or `unknown` only. | Parser rejects any other value. | Enum documented in schema. | Downstream doctor/tick can count pass/fail/unknown. |
| `failure_classes[]` | Names machine-actionable failures. | `fail` requires at least one; `pass` forbids them. | Class array documented in schema. | Feeds fix-bead, reopen, fuckup, and learn routing. |
| `evidence[]` | Typed proof references. | Parser checks type/ref shape and secret-like values. | Supported types listed below. | Durable refs are usable by B06/B07/B09. |
| `artifact_checks[]` | Checks claimed artifact paths and status. | `pass` cannot include missing artifacts. | Shape documented in schema. | Feeds missing-artifact doctor/reopen signals. |
| `runtime_context` | Separates agent context from orchestrator shell context. | Timeout/unresponsive maps to `unknown`; drift cannot pass. | L69 behavior encoded in README/schema. | Feeds `agent_context_probe_drift_count`. |
| `bead_actions[]` | Records bead filed/updated/no-bead/reopen decisions. | Weak `no_bead_reason` is rejected. | Action enum documented in schema. | Feeds L52 and auto-open/reopen logic. |
| `learn_route` | States how the event enters or skips `/flywheel:learn`. | Route and reason required. | Route enum documented in schema. | B09 uses it for exactly-once learning. |
| `chain_blocker` | Records next phase, capacity, and blocker reason. | Capacity plus next phase cannot silently pass without a blocker reason. | L70 behavior documented here. | Feeds `ticks_punted_count`. |

## Evidence Types

The schema supports the required typed references:

- `path`
- `command`
- `dispatch_log`
- `bead_id`
- `commit_sha`
- `transcript_hash`
- `joshua_confirmation_hash`

It also supports `fuckup_log` because L53 requires BLOCKED callbacks to surface a durable trauma row.

## Fixture Coverage

| fixture | directory | required class covered |
|---|---|---|
| `valid-done.json` | `pass` | valid DONE, typed artifact evidence |
| `runtime-unresponsive-unknown.json` | `pass` | runtime-unresponsive maps to `unknown`, never `pass` |
| `valid-no-bead-reason.json` | `pass` | valid no-bead reason |
| `missing-artifact-done.json` | `fail` | missing-artifact DONE cannot pass |
| `blocked-without-fuckup.json` | `fail` | BLOCKED without fuckup evidence |
| `context-drift-pass.json` | `fail` | context drift cannot pass |
| `invalid-no-bead-reason.json` | `fail` | weak no-bead reason |
| `closed-bead-missing-artifact.json` | `fail` | closed bead claim with missing artifact |
| `tick-punted.json` | `fail` | next phase with capacity and no chain blocker |
| `valid-claude-worker.md` | `dispatch-template` | valid Claude worker packet with validation block |
| `valid-codex-worker.md` | `dispatch-template` | valid Codex worker packet with validation block |
| `invalid-missing-validation-block.md` | `dispatch-template` | packet missing validation callback instructions |

## Safety

Fixtures use synthetic paths, hashes, command refs, transcript hashes, and Joshua-confirmation hashes. They do not include real secrets or real Agent Mail tokens. The parser also rejects common token-shaped fixture values.
