# Public Preflight Implementation Spec

Created: 2026-05-12T21:29Z
Agent: TopazMeadow
Primary downstream bead: B6.5 / `flywheel-ezgc7`
Status: implementation input, not the preflight script

## Purpose

`09-SUBSTRATE-PREFLIGHT-INVENTORY.md` defines what public preflight must detect.
This spec defines how B6.5 should implement it as a canonical command surface
with deterministic fixtures, reduced-mode resolution, and stable error
semantics.

This is intentionally not `scripts/preflight.sh`. B6.5 remains open until the
script, fixtures, tests, and first-run journey integration exist.

## Source Basis

- `09-SUBSTRATE-PREFLIGHT-INVENTORY.md` dependency matrix and exit codes.
- `11-FIRST-RUN-JOURNEY-SPEC.md` first-run receipt stages.
- `canonical-cli-scoping` skill: inspectable command surface, JSON envelopes,
  self-documentation, validation, audit, and domain exit codes.
- Socraticode search result: `templates/flywheel-install/polish-gate` fixture
  tests prove malformed manifests should return stable errors without Python or
  shell tracebacks.
- Local patterns:
  - `tests/polish-preflight-quality-gate-canonical-cli.sh`
  - `templates/flywheel-install/tests/test_polish_gate_discovery.sh`

## Command Shape

B6.5 may start as `scripts/preflight.sh`, but it should behave like the eventual
`flywheel preflight` subcommand.

Required surfaces:

| Command | Purpose |
|---|---|
| `scripts/preflight.sh --json` | Live preflight, emits full result envelope. |
| `scripts/preflight.sh --fixture fixtures/preflight/<name>.json --json` | Deterministic fixture run, no live commands. |
| `scripts/preflight.sh --schema` | Emits JSON schema for result envelope and dependency rows. |
| `scripts/preflight.sh --examples --json` | Emits example commands and expected exit classes. |
| `scripts/preflight.sh validate --fixture <path> --json` | Pure-read fixture validation. |
| `scripts/preflight.sh doctor --json` | Checks script dependencies and fixture directory health. |
| `scripts/preflight.sh health --json` | Lightweight preflight health summary. |
| `scripts/preflight.sh quickstart` | Human-readable minimal first-run path. |
| `scripts/preflight.sh help exit-codes` | Documents domain exit codes. |

Mutating or install-applying behavior does not belong in B6.5. If the later
installer wants `repair` or `install`, it should call preflight as a read-only
resolver first.

## Result Envelope

Every run should emit:

```json
{
  "schema_version": "flywheel.preflight.v0",
  "command": "preflight",
  "mode": "full|reduced|blocked|docs-only",
  "exit_code": 20,
  "generated_at": "2026-05-12T00:00:00Z",
  "host": {
    "os": "darwin|linux|unknown",
    "arch": "arm64|x86_64|unknown",
    "fixture": false
  },
  "summary": {
    "required_missing": [],
    "full_mode_missing": ["ntm", "agent-mail"],
    "enhanced_missing": [],
    "misconfigured": [],
    "warnings": []
  },
  "dependencies": [],
  "harnesses": [],
  "reduced_mode": {
    "available": true,
    "reason": "full-mode substrate missing but first-run simulator remains runnable",
    "unavailable_claims": ["multi-agent coordination", "shared inboxes", "cross-session memory"]
  },
  "next_action": {
    "kind": "continue|install|blocked|docs-only",
    "command": "docs/getting-started/first-run.md#reduced-mode"
  }
}
```

The envelope must not include raw environment dumps, secret values, home
directory-specific state, pane text, or unredacted command stderr.

## Dependency Row Schema

Each row should extend the inventory contract:

```json
{
  "id": "ntm",
  "kind": "substrate|runtime|harness|enhancement",
  "tier": "required|full-mode|enhanced|optional|supported-first|compatibility-target",
  "status": "present|missing|misconfigured|unknown",
  "mode_effect": "full|reduced|blocked|docs-only",
  "detect_command": "ntm --version",
  "evidence": {
    "source": "live|fixture",
    "exit_code": 127,
    "stdout_excerpt": "",
    "stderr_excerpt": "command not found",
    "version": null
  },
  "install_hint": "ACFS phase 8 or manual NTM install docs",
  "reduced_mode_consequence": "dispatch simulation only"
}
```

Excerpt fields must be bounded and scrubbed. Preflight should print command
names and status, not local secrets or full logs.

## Fixture Schema

Fixture files should define command outcomes, not expected final decisions. The
resolver should compute the decision so fixture tests catch logic drift.

```json
{
  "schema_version": "flywheel.preflight.fixture.v0",
  "name": "partial",
  "host": {
    "os": "darwin",
    "arch": "arm64"
  },
  "commands": {
    "git --version": {
      "exit_code": 0,
      "stdout": "git version 2.45.0",
      "stderr": ""
    },
    "ntm --version": {
      "exit_code": 127,
      "stdout": "",
      "stderr": "ntm: command not found"
    }
  }
}
```

Fixture validation should fail when:

- `schema_version` is missing or unsupported;
- `commands` is not an object;
- any command result lacks `exit_code`;
- stdout/stderr fields are not strings;
- a fixture contains secret-shaped values without synthetic markers;
- a fixture names a command that the dependency matrix cannot consume.

## Resolver Rules

The mode resolver should be deterministic:

1. If any `required` dependency is `missing`, `misconfigured`, or `unknown`,
   mode is `blocked`, exit `30`.
2. Else if all required and full-mode dependencies are present, mode is `full`,
   exit `0` unless enhanced/optional warnings exist.
3. Else if required dependencies are present and the reduced-mode minimum is
   present, mode is `reduced`, exit `20`.
4. Else if required basics are present but Beads or closeout fixture support is
   missing, mode is `docs-only`, exit `30` with a docs-only reason.
5. Fixture or schema errors exit `40` and must not print tracebacks.

Reduced-mode minimum for B6.5:

- Git
- POSIX shell
- `jq`
- SQLite
- `br` or a fixture-backed Beads simulator explicitly marked as simulator
- closeout validator fixture path

Do not treat missing NTM, Agent Mail, DCG, CASS-style memory, Socraticode, or a
harness as a blocked install when reduced mode is available. Do name the claims
that are unavailable.

## Exit Codes

| Exit | Meaning |
|---:|---|
| 0 | Full-mode preflight passes. |
| 10 | Full-mode passes with enhanced/optional warnings. |
| 20 | Reduced mode selected and first-run tutorial remains runnable. |
| 30 | Blocked or docs-only: required dependency or reduced-mode minimum missing. |
| 40 | Internal error, malformed fixture, unsupported fixture, or schema violation. |
| 64 | Usage error. |

`help exit-codes` and `--examples --json` must both expose these codes.

## Required Fixtures

| Fixture | Expected mode | Expected exit | Purpose |
|---|---|---:|---|
| `fresh.json` | `blocked` | 30 | Proves a new machine without required basics does not fake success. |
| `partial.json` | `reduced` | 20 | Proves missing full-mode substrate still teaches the loop. |
| `existing.json` | `full` | 0 | Proves all full-mode dependencies produce full support. |
| `reduced.json` | `reduced` | 20 | Proves explicit reduced substrate can run simulator/closeout path. |
| `misconfigured.json` | `blocked` | 30 | Proves commands that exist but fail health checks are not counted present. |
| `malformed.json` | none | 40 | Proves stable fixture error handling without traceback. |

## Test Plan

B6.5 should ship one focused test:

```bash
bash tests/preflight-fixtures.sh
```

Minimum assertions:

1. `bash -n scripts/preflight.sh` passes.
2. `scripts/preflight.sh --schema | jq empty` passes.
3. Every required fixture validates.
4. Fixture modes and exit codes match the table above.
5. Malformed fixtures return exit `40`, no stdout, and stderr has a stable
   `ERROR:` line plus `Suggested action:`.
6. Fixture runs do not execute live commands.
7. `--examples --json` names full, reduced, blocked, and docs-only examples.
8. `help exit-codes` names all domain exit codes.
9. `doctor --json` reports fixture directory health.
10. No fixture or output contains `/Users/josh`, raw env dumps, pane text, or
    secret-shaped material outside synthetic markers.

## Integration With First-Run Journey

The first-run journey should consume preflight as stage `preflight` and copy
only these fields into its receipt:

- `mode`
- `exit_code`
- `summary.required_missing`
- `summary.full_mode_missing`
- `summary.misconfigured`
- `reduced_mode.available`
- `reduced_mode.unavailable_claims`
- `next_action`

The journey should not duplicate every dependency row unless it is producing a
diagnostic bundle. The public tutorial can link to the preflight JSON for detail.

## Non-Completion Note

This spec does not satisfy B6.5. B6.5 remains open until `scripts/preflight.sh`,
schemas, fixtures, fixture tests, and first-run journey integration exist. The
active public-installability goal remains incomplete.
