# Public First-Run Journey Spec

Created: 2026-05-12T21:23Z
Agent: TopazMeadow
Primary downstream beads: B12.0 / `flywheel-uwuxr`, B17 / `flywheel-uqp4v`, B17.5 / `flywheel-7kuil`
Status: implementation input, not a completed journey

## Purpose

The active public-installability goal requires a new operator to move from first
read to first useful loop without Joshua-specific state. This spec turns the
charter, substrate preflight, and harness matrix into a single journey contract
that docs, installer scripts, smoke tests, and website copy can share.

This is not the tutorial, installer, or smoke runner. It is the contract those
surfaces must satisfy before Flywheel can call the public goal complete.

## Source Basis

- `CHARTER.md` public promise and publishability bar.
- `05-INSTALLABILITY-COVERAGE-AUDIT.md` missing-surface audit.
- `09-SUBSTRATE-PREFLIGHT-INVENTORY.md` dependency tiers and reduced-mode exit
  behavior.
- `10-HARNESS-SUPPORT-MATRIX.md` support labels and journey evidence states.
- `README.md` repo-local loop and v2 closeout receipt guidance.
- `templates/flywheel-install/validate-callback-before-close.sh.tmpl` and
  `.flywheel/scripts/validate-callback.py` closeout evidence posture.
- Mobile Eats L170 semantic callback: distinguish registry-valid journeys from
  runtime-proven journeys and route fixture/data blockers as evidence.

## Personas

| Persona | Need | Success signal |
|---|---|---|
| Solo developer | Understand the loop and run it safely in one repo. | Reduced or full mode initializes, doctor explains state, and one next action is visible. |
| Technical lead | Decide whether Flywheel can coordinate multiple agent lanes. | Full-mode preflight identifies NTM, Agent Mail, Beads, DCG, Socraticode, and harness readiness. |
| SMB technical operator | See whether the system creates reliable work receipts instead of opaque agent output. | Validated closeout receipt shows what changed, what was blocked, and what remains. |
| Contributor | Find the extension boundary without inheriting private state. | Public docs name install surfaces, support labels, fixture states, and contribution constraints. |

## Journey Promise

A public first-run path is complete only when the operator can do all of this
from a fresh checkout or public website path:

1. Run preflight and receive an honest `full`, `reduced`, `blocked`, or
   `docs-only` mode decision.
2. Install missing public dependencies or choose reduced mode without hidden
   Joshua state.
3. Initialize Flywheel in a target repo.
4. Run doctor and understand whether the repo can safely tick.
5. Run tick or dry-run tick.
6. Dispatch work through a real harness, or simulate dispatch in reduced mode.
7. Produce and validate a closeout receipt.
8. Inspect the resulting next action in Beads, receipts, or doctor output.

The first value is not "Flywheel installed." The first value is "this repo now
has an inspectable loop state and one credible next action."

## Journey Contract

| Stage | Required command shape | Full-mode expected result | Reduced-mode expected result | Evidence class |
|---|---|---|---|---|
| preflight | `flywheel preflight --json` or `scripts/preflight.sh --json` | Required and full-mode dependencies classified. | Required basics pass and full-mode gaps route to reduced mode. | dependency rows |
| install-or-detect | installer or documented manual path | Missing public dependencies are installed or detected as present. | No full substrate is silently assumed. | install receipt |
| init | `flywheel init --repo <target> --json` or equivalent | Repo-local `.flywheel` surfaces created without private state. | Minimal fixture/local surfaces created. | init receipt |
| doctor | `flywheel doctor --repo <target> --json` | Safe-to-tick or stable failure codes. | Reduced-safe or docs-only decision. | doctor JSON |
| tick | `flywheel-loop tick --repo <target> --json` or dry-run | Next safe action selected from repo state. | Dry-run tick emits deterministic next action. | tick receipt |
| dispatch-or-simulate | `ntm send ...` or fixture simulator | Harness dispatch record names agent, pane/session, reservation, callback contract. | Simulator records no NTM, no Agent Mail, no multi-agent claims. | dispatch receipt |
| validated-closeout | `flywheel-loop validate-receipt --repo <target> --file <receipt> --json` | Closeout passes or fails with stable reason. | Fixture closeout validates the evidence shape. | closeout receipt |
| inspect-next-action | `br list`, receipt viewer, or doctor summary | Operator sees next bead/action/blocker. | Operator sees the same concept without fleet coordination. | inspection output |

## Harness Lanes

Each harness row consumes the support labels from `10-HARNESS-SUPPORT-MATRIX.md`.
The first-run docs may only promote a lane as supported when the row is
`runtime_proven` or carries a clear auth/account blocker.

| Lane | Initial journey expectation | Dispatch behavior |
|---|---|---|
| Claude Code | compatibility-target until receipt | Real dispatch may use Claude-specific docs, but cannot require Joshua hooks. |
| Codex CLI | compatibility-target until receipt | Real dispatch must respect Codex MCP/AGENTS.md differences. |
| Gemini CLI | compatibility-target until smoke | May be registry-valid before runtime proof; public copy must say so. |
| OpenClaw | compatibility-target until smoke | Must account for daemon/gateway shape; do not model it as a generic terminal clone. |
| Reduced local mode | reduced-required | Always available when required basics exist; no multi-agent claims. |

## First-Run Receipt Schema

B17.5 should emit one JSON document per lane:

```json
{
  "schema_version": "flywheel.first_run_journey.v0",
  "generated_at": "2026-05-12T00:00:00Z",
  "repo": "/absolute/path/to/target",
  "mode": "full|reduced|blocked|docs-only",
  "harness": "claude|codex|gemini|openclaw|none",
  "support_label": "supported-by-receipt|supported-docs|compatibility-target|reduced-required|unsupported",
  "evidence_state": "registry_valid|runtime_proven|fixture_blocked|source_gap|unsupported",
  "persona": "solo-developer|technical-lead|smb-operator|contributor",
  "first_value": "repo initialized with passing/explained doctor and visible next action",
  "return_loop": "preflight -> install_or_detect -> init -> doctor -> tick -> dispatch_or_simulate -> validated_closeout -> inspect_next_action",
  "guardrail": "no private state, no destructive mutation, reduced-mode honesty",
  "private_state_scan": {
    "status": "pass|fail|not_run",
    "paths_scanned": [],
    "findings": []
  },
  "stages": {
    "preflight": {
      "status": "pass|warn|fail|skipped",
      "exit_code": 0,
      "required_missing": [],
      "full_mode_missing": []
    },
    "install_or_detect": {
      "status": "pass|warn|fail|skipped",
      "installed": [],
      "detected": []
    },
    "init": {
      "status": "pass|warn|fail|skipped",
      "created_paths": []
    },
    "doctor": {
      "status": "pass|warn|fail|skipped",
      "stable_codes": []
    },
    "tick": {
      "status": "pass|warn|fail|skipped",
      "dry_run": false,
      "next_action": ""
    },
    "dispatch_or_simulate": {
      "status": "pass|warn|fail|skipped",
      "real_dispatch": false,
      "reservation_id": null,
      "callback_contract": ""
    },
    "validated_closeout": {
      "status": "pass|warn|fail|skipped",
      "validator": "",
      "receipt_path": ""
    },
    "inspect_next_action": {
      "status": "pass|warn|fail|skipped",
      "surface": "br|receipt|doctor|docs",
      "summary": ""
    }
  },
  "blockers": [
    {
      "class": "missing-value|stale-product-meaning|auth-test-fixture-gap|selector-drift|source-data-gap|substrate-gap",
      "surface": "preflight|install|init|doctor|tick|dispatch|closeout|inspect",
      "detail": ""
    }
  ]
}
```

## Evidence Semantics

Borrow Mobile Eats' L170 distinction directly:

- `registry_valid`: the lane is documented, structurally valid, and included in
  the support matrix.
- `runtime_proven`: the lane completed the first-run journey against a real repo
  or faithful fixture.
- `fixture_blocked`: auth, local data, or test fixture prevents runtime proof.
- `source_gap`: install source, command name, or daemon API remains unclear.
- `unsupported`: the lane is outside the release or unsafe to recommend.

Selector drift and command drift are executable evidence problems. They do not
change doctrine unless the journey meaning changes.

## Reduced-Mode Rules

Reduced mode is mandatory because the public audience may not have the full
Dicklesworthstone-derived substrate. It must:

- pass with Git, shell, jq, SQLite, and Beads basics;
- explain missing NTM, Agent Mail, DCG, CASS-style memory, Socraticode, and
  harnesses without treating those gaps as surprises;
- use simulated dispatch and fixture closeout;
- produce the same receipt schema as full mode;
- label multi-agent coordination, shared inboxes, and memory as unavailable.

Reduced mode must not say the operator has run a fleet loop.

## Private-State Guardrail

The journey fails if any public path requires or copies:

- `.ntm` runtime state from Joshua's machine;
- Agent Mail archive state from private projects;
- CASS, JSM, or Socraticode local databases that are not created by the public
  setup flow;
- API keys, account tokens, tmux pane scrollback, or private ZestStream repo
  paths;
- SkillOS or Mobile Eats implementation artifacts except as explicitly labeled
  proof-surface references.

B17.5 should scan emitted receipts and generated public docs for private path
markers before calling a row `runtime_proven`.

## Implementation Targets

| Bead | What this spec feeds | Completion requirement |
|---|---|---|
| B6.5 / `flywheel-ezgc7` | Substrate preflight fixtures and command probes. | `scripts/preflight.sh` or equivalent emits dependency rows and mode decision. |
| B12.0 / `flywheel-uwuxr` | `docs/getting-started/first-run.md`. | Docs walk through this exact journey and name reduced/full behavior. |
| B17 / `flywheel-uqp4v` | Fresh-laptop smoke receipt. | One real environment or faithful fixture proves the journey. |
| B17.5 / `flywheel-7kuil` | Multi-harness journey matrix. | Every named lane has registry/runtime evidence state and blocker class. |
| B19 / `flywheel-tl9vp` | Website path. | Website first-run copy matches docs and receipt semantics. |

## Non-Completion Note

This spec does not satisfy B12.0, B17, B17.5, or the active Codex goal. The
public goal remains open until the installer/preflight, first-run docs, smoke
runner, closeout validation, website path, and B0 charter review gate are all
complete and validated.
