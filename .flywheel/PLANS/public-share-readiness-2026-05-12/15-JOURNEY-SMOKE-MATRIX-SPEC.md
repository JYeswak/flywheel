# Journey Smoke Matrix Spec

Created: 2026-05-12T21:31Z
Agent: TopazMeadow
Primary downstream bead: B17.5 / `flywheel-7kuil`
Status: implementation input, not the smoke runner

## Purpose

B17.5 must prove that Flywheel's public first-run path reports harness support
honestly across Claude, Codex, Gemini, OpenClaw, and reduced local mode. This
spec defines the journey-smoke matrix command, row schema, evidence states, and
test expectations needed before public docs can promote any lane.

This is not `journey-smoke`. B17.5 remains open until the runner, fixtures,
matrix output, and tests exist.

## Source Basis

- `10-HARNESS-SUPPORT-MATRIX.md` support labels and evidence states.
- `11-FIRST-RUN-JOURNEY-SPEC.md` first-run receipt schema.
- `14-PREFLIGHT-IMPLEMENTATION-SPEC.md` preflight stage fields.
- Socraticode search: existing Flywheel validation uses receipts,
  `validation-e2e/v1`, `journey-entry/v1`, dispatch-log schemas, and closeout
  validators as mechanical proof instead of prose.
- `evaluation-framework` skill: use deterministic format/content checks before
  model or human evaluation; compare rows against golden expectations.

## Command Shape

The runner may start as `scripts/journey-smoke.sh`, but it should behave like
the eventual `flywheel journey-smoke` subcommand.

Required surfaces:

| Command | Purpose |
|---|---|
| `scripts/journey-smoke.sh --matrix claude,codex,gemini,openclaw,reduced --json` | Run live or configured journey matrix. |
| `scripts/journey-smoke.sh --matrix ... --dry-run --json` | Evaluate lane registry and fixture wiring without live dispatch. |
| `scripts/journey-smoke.sh --fixture fixtures/journey-smoke/<name>.json --json` | Deterministic fixture run. |
| `scripts/journey-smoke.sh --schema` | Emit JSON schemas for the matrix and lane rows. |
| `scripts/journey-smoke.sh validate --receipt <path> --json` | Pure-read receipt validation. |
| `scripts/journey-smoke.sh doctor --json` | Check fixture, schema, and closeout validator availability. |
| `scripts/journey-smoke.sh help evidence-states` | Explain registry/runtime/blocker semantics. |

Live harness invocation should remain opt-in. The default B17.5 dry-run must be
safe on a machine without Claude, Codex, Gemini, OpenClaw, NTM, or Agent Mail.

## Matrix Envelope

The top-level output should be one matrix receipt:

```json
{
  "schema_version": "flywheel.journey_smoke.matrix.v0",
  "generated_at": "2026-05-12T00:00:00Z",
  "command": "journey-smoke",
  "mode": "dry-run|fixture|live",
  "repo": "/absolute/path/to/target",
  "preflight_source": {
    "path": "preflight.json",
    "mode": "reduced",
    "exit_code": 20
  },
  "summary": {
    "lanes_total": 5,
    "runtime_proven": 1,
    "registry_valid": 4,
    "fixture_blocked": 0,
    "source_gap": 0,
    "unsupported": 0
  },
  "lanes": [],
  "private_state_scan": {
    "status": "pass|fail|not_run",
    "findings": []
  },
  "public_copy_gate": {
    "claude_promotable": false,
    "codex_promotable": false,
    "gemini_promotable": false,
    "openclaw_promotable": false,
    "reduced_promotable": true
  }
}
```

`public_copy_gate` is intentionally stricter than row validation. A lane can be
`registry_valid` and still not be promotable as supported-first.

## Lane Row Schema

Each lane row should satisfy:

```json
{
  "lane": "codex",
  "support_label": "supported-first|supported-docs|compatibility-target|reduced-required|unsupported",
  "evidence_state": "registry_valid|runtime_proven|fixture_blocked|source_gap|unsupported",
  "auth_state": "present|missing|not_required|unknown",
  "install_detected": true,
  "detect_command": "codex --version",
  "persona": "solo-developer",
  "first_value": "repo initialized with passing/explained doctor and visible next action",
  "return_loop": "preflight -> install_or_detect -> init -> doctor -> tick -> dispatch_or_simulate -> validated_closeout -> inspect_next_action",
  "guardrail": "no private state, no destructive mutation, reduced-mode honesty",
  "stages": {
    "preflight": "pass|warn|fail|skipped",
    "install_or_detect": "pass|warn|fail|skipped",
    "init": "pass|warn|fail|skipped",
    "doctor": "pass|warn|fail|skipped",
    "tick": "pass|warn|fail|skipped",
    "dispatch_or_simulate": "pass|warn|fail|skipped",
    "validated_closeout": "pass|warn|fail|skipped",
    "inspect_next_action": "pass|warn|fail|skipped"
  },
  "commands": {
    "detect": "codex --version",
    "doctor": "flywheel doctor --json",
    "journey": "scripts/journey-smoke.sh --matrix codex --json"
  },
  "blockers": []
}
```

Every row must include persona, first value, return loop, and guardrail. A row
without those fields is not L170-aligned even if commands pass.

## Evidence State Rules

| State | Required facts |
|---|---|
| `registry_valid` | Lane exists in matrix, support label is allowed, detection command is named, journey fields are present, and no private-state scan fails. |
| `runtime_proven` | All eight stages are `pass` or permitted `warn`, closeout validates, inspection names a next action, and private-state scan passes. |
| `fixture_blocked` | Lane is structurally valid but auth, account, local fixture, or test data prevents runtime proof. |
| `source_gap` | Install source, command name, daemon API, or support contract is unstable or unknown. |
| `unsupported` | Lane is intentionally outside current release; row names safe fallback. |

Rows must not silently convert `fixture_blocked` or `source_gap` into
`runtime_proven`. Public docs can say "target" only when evidence is not yet
runtime-proven.

## Stage Rules

| Stage | Runtime-proven requirement |
|---|---|
| preflight | Consumes B6.5 preflight receipt and records mode/exit code. |
| install-or-detect | Detects the lane command or records explicit no-install needed for reduced. |
| init | Initializes a synthetic target repo without private state. |
| doctor | Emits stable pass/warn/fail JSON. |
| tick | Emits deterministic next action or dry-run next action. |
| dispatch-or-simulate | Real harness dispatch for live lanes; simulator pass for reduced. |
| validated-closeout | Runs `flywheel-loop validate-receipt` or fixture-equivalent validator. |
| inspect-next-action | Shows Beads, receipt, or doctor surface with the next action. |

Reduced lane is runtime-proven when `dispatch_or_simulate=pass` through the
simulator and all unavailable full-mode claims are named. It must not pretend to
use NTM, Agent Mail, shared inboxes, or cross-session memory.

## Blocker Classes

Use stable classes so failures route without doctrine churn:

| Class | Meaning |
|---|---|
| `missing-value` | Journey ran but did not deliver first value or next action. |
| `stale-product-meaning` | Row no longer matches public onboarding semantics. |
| `auth-test-fixture-gap` | Auth, account, or local fixture prevents runtime proof. |
| `selector-drift` | Command, selector, or daemon probe changed. |
| `source-data-gap` | Install source or upstream docs are insufficient. |
| `substrate-gap` | Required local substrate is absent or misconfigured. |
| `private-state-risk` | Output would expose local/private state. |

These classes mirror Mobile Eats L170 routing while staying scoped to Flywheel
onboarding.

## Golden Fixture Expectations

B17.5 should include fixture cases:

| Fixture | Expected result |
|---|---|
| `all-registry-valid.json` | Five rows validate; only reduced is promotable by default. |
| `reduced-runtime-proven.json` | Reduced lane reaches `runtime_proven` with simulator dispatch. |
| `codex-auth-blocked.json` | Codex row is `fixture_blocked`, not `runtime_proven`. |
| `gemini-source-gap.json` | Gemini row is `source_gap` with safe fallback. |
| `openclaw-daemon-gap.json` | OpenClaw row is `source_gap` unless daemon/gateway smoke is present. |
| `private-state-fail.json` | Matrix fails public copy gate when private path markers appear. |
| `malformed-row.json` | Validator exits with stable schema error and no traceback. |

## Test Plan

B17.5 should ship:

```bash
bash tests/journey-smoke-matrix.sh
```

Minimum assertions:

1. `bash -n scripts/journey-smoke.sh` passes.
2. `scripts/journey-smoke.sh --schema | jq empty` passes.
3. `validate --receipt` accepts all golden pass fixtures.
4. Malformed rows fail with stable code and no traceback.
5. Reduced fixture reaches `runtime_proven` and has `dispatch_or_simulate=pass`.
6. Claude/Codex/Gemini/OpenClaw are not promotable unless runtime proof or
   explicit auth/account blocker exists.
7. `private-state-fail.json` fails public copy gate.
8. Every row contains persona, first value, return loop, and guardrail.
9. Blocker classes are from the stable list above.
10. Fixture output contains no `/Users/josh`, pane text, raw env dumps, or
    secret-shaped material outside synthetic markers.

## Public Copy Gate

Docs and website copy may promote:

- reduced local mode when its row is `runtime_proven`;
- Claude or Codex as supported-first only when the row is `runtime_proven` or
  explicitly blocked by an auth/account condition the public docs name;
- Gemini and OpenClaw only as compatibility targets until runtime proof exists.

The matrix should produce a machine-readable copy gate so B12/B13/B15 can fail
if public copy outruns evidence.

## Non-Completion Note

This spec does not satisfy B17.5. B17.5 remains open until the runner, schemas,
fixtures, tests, and public-copy integration exist. The active public
installability goal remains incomplete.
