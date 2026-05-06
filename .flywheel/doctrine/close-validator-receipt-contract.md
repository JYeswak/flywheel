# Close-Validator Receipt Contract

Contract version: `close-validator-receipt-contract/v1`

This contract is the Wave 2 close-validator receipt surface for the
mission-lock paradigm extension. It closes SEC-002, SEC-004, IDEM-002,
IDEM-005, and CSR-004 by making DONE callback receipts mechanically checkable
before bead close.

## Scope

Every DONE callback sent to `flywheel:1` is untrusted input until close
validation accepts it. The close-validator consumes the callback envelope, the
worker evidence paths, the dispatch L112 verifier, skill route receipts, and
append-only close ledger rows. It may reject closure, request a fix bead, or
route a re-dispatch. It must not reinterpret missing evidence as success.

The existing close handler at
`~/.claude/commands/flywheel/_shared/close-handler.md` remains the operational
orchestrator flow. This document defines the receipt contract that flow checks.
Wave 1 idempotency deliverables are cited as inputs only:
`.flywheel/scripts/idempotency-replay-guard.sh` and
`.flywheel/validation-schema/v1/dispatch-receipt.schema.json`.

## Skill Receipts

DONE receipts MUST include non-empty `skill_receipts[]`. A callback that only
mentions prose such as `skills_consulted=...` is incomplete for strict close;
it may help triage, but it is not a close receipt.

Each skill receipt MUST include:

- `schema_version`
- `receipt_identity_key`
- `skill`
- `resolved_to`
- `source`
- `path`
- `sha`
- `version`
- `freshness_status`
- `route_allowed`
- `checked_at`
- `action_taken`
- `policy_version`

Credential-touching receipts additionally require `credential_touch=true`,
`secret_value_allowed=false`, and `safe_wrapper`. Rotation or destructive
credential work also requires `joshua_explicit_rotation_approval`.

Route receipts cite the Wave 2 dispatch-author contract by name:
`.flywheel/doctrine/dispatch-author-skill-routing-contract.md`. That sibling
artifact is owned by the dispatch-author bead; this contract references its
route receipt schema without editing it.

## Stale-Route Checks

At close time, every skill receipt is rechecked for stale route evidence. The
validator fails when any selected, alias, or skip receipt has one of these
states:

- `route_allowed=false`
- missing `path`, `sha`, `version`, `checked_at`, or `source`
- `freshness_status` outside `fresh`, `current`, or `warn`
- `resolved_to` empty or inconsistent with the selected skill/alias

The intent is CSR-004: old dispatches cannot keep naming a skill after rename,
deletion, blocked route health, or catalog drift unless the close receipt says
how the stale route was resolved.

## Credential Immutability

The close-validator is read-only with respect to credential stores. It may fail
closure, open or update beads, demand additional receipts, and record sanitized
evidence. It MUST NOT rotate tokens, edit `.env`, write vault values, mutate MCP
secret config, or mark credential repair complete from pane text.

Receipts must follow SEC-001 sanitization rules. They may name secret classes,
secret keys, vault paths, and safe helper commands. They must never include
secret values, token fragments, raw env output, Agent Mail bearer tokens, or
registration tokens.

## Duplicate-Close Reconciliation

Close receipts MUST include `close_identity_key` and
`dedupe_policy=latest-row-by-ref_id-event`. The close identity covers the bead
id, task id, close event type, L112 output hash, and evidence path set. Replayed
close attempts use the Wave 1 replay guard model: first look for an existing
completed close row, then return `already_completed` or reconcile to the prior
row instead of appending conflicting truth.

If a duplicate close is detected, the receipt must include `previous_close_row`
or an equivalent prior receipt reference. Duplicate reconciliation is a pass
only when the new receipt points to the prior truth and keeps append-only ledger
semantics intact.

## L112 Hashes

Every L112 verifier result emits deterministic hashes:

- `l112.command_hash = sha256:<hash of verifier command text>`
- `l112.output_hash = sha256:<hash of observed stdout token/text>`
- `l112.observed`
- `l112.expected`
- `l112.timeout_sec`

The close-validator compares `observed` with `expected` and recomputes
`output_hash` from `observed`. A mismatch fails close even if the callback
claims `l112_observed=OK...`.

## Sanitized Evidence Joins

Evidence joins may contain repo-relative file paths, short command outputs,
ledger row references, and redacted log excerpts. They must be safe to copy into
callbacks, INCIDENTS, `.beads/issues.jsonl`, and pane captures.

The sanitizer rejects common secret shapes, including `sk-ant-`, `sk-proj-`,
classic GitHub PATs, fine-grained GitHub PATs, `github_pat_`, AWS access keys,
Google API keys, JWTs, `Bearer ...`, Slack tokens, and long base64-like blobs
near secret words. Synthetic tokens in tests must be scrubbed to a marker such
as `[SCRUBBED:github_token]`.

## Conformance Probe

The repo-local probe is:

```bash
.flywheel/scripts/close-validator-contract-probe.sh \
  --callback-file /tmp/close-receipt.json \
  --close-ledger .beads/issues.jsonl \
  --json
```

It is read-only. It accepts JSON close receipts directly and accepts DONE text
only for parse diagnostics. Strict PASS requires structured receipt fields.
Exit codes are:

- `0`: pass, including duplicate-close reconciled to prior truth
- `1`: contract failure
- `64`: usage or malformed probe invocation

## Versioning

This document is `close-validator-receipt-contract/v1`. Additive fields may be
introduced under the same version when old receipts remain valid. Any change
that weakens required fields, changes duplicate-close semantics, or alters
secret detection behavior requires `v2` and a migration note in INCIDENTS.
