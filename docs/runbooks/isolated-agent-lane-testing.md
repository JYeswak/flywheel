# Isolated Agent Lane Testing

This runbook is the proof path for Claude, Codex, Gemini, and OpenClaw support.
It exists because command presence is not end-to-end support.

## What The Harness Proves

`scripts/isolated-agent-lane-smoke.sh` creates a disposable environment:

| Surface | Isolation |
|---|---|
| `HOME` | Temporary directory. |
| `XDG_CONFIG_HOME` | Temporary directory. |
| `XDG_CACHE_HOME` | Temporary directory. |
| Public package | Fresh public export unless `--skip-assemble` is used for tests. |
| Install prefix | Temporary `engine/` directory. |
| Target repo | Temporary git repo. |
| Agent receipts | Caller-selected receipt directory. |

The harness then runs the public reduced path from install to closeout:

```bash
scripts/isolated-agent-lane-smoke.sh \
  --receipt-dir state/isolated-agent-lanes \
  --json > state/isolated-agent-lane-smoke.receipt.json
```

Expected reduced-mode result:

```bash
jq '{status, reduced:.reduced_journey.runtime_proven, support_copy_gate}' \
  state/isolated-agent-lane-smoke.receipt.json
```

`reduced` must be `true`. Claude, Codex, Gemini, and OpenClaw stay `false`
until each lane has its own live adapter receipt.

Live-adapter proof is opt-in because it may spend provider tokens or require
local credentials:

```bash
scripts/isolated-agent-lane-smoke.sh \
  --lanes claude,codex,gemini,openclaw \
  --receipt-dir state/isolated-agent-lanes \
  --live-adapters \
  --adapter-timeout 45 \
  --json > state/isolated-agent-lane-smoke.receipt.json
```

The live adapter must respond inside the disposable repo. The receipt still has
to pass the reduced journey and private-state scan before support copy can move
from `compatibility-target` to `supported`.

## Runtime Promotion Rule

A lane can move from compatibility target to supported only when the receipt in
`receipts/agent-lanes/<lane>.json` validates as
`flywheel.agent_lane_runtime_receipt.v0` and proves exactly one passing row for:

- `preflight`
- `init`
- `doctor`
- `tick`
- `dispatch_or_simulate`
- `closeout`
- `inspect_next_action`

The receipt must also include `support_scope=isolated`,
`private_state_scan.status=pass`, and no `private_state_scan.findings` rows.

Run the gate:

```bash
scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json
```

If `support_copy_allowed` is not `true`, public copy must stay
`compatibility-target`.

Adapter blockers are explicit:

| Class | Meaning |
|---|---|
| `install_required` | The CLI is not installed in the current PATH. |
| `auth_required` | The CLI exists, but isolated credentials are missing or unusable. |
| `daemon_unavailable` | The CLI or local gateway timed out or was not running. |
| `isolated_runtime_receipt_missing` | The CLI exists, but no passing live runtime proof exists yet. |

## Strict Blocker Mode

Use `--require-runtime` when you need the command to fail until all requested
agent lanes are truly proven:

```bash
scripts/isolated-agent-lane-smoke.sh \
  --lanes claude,codex,gemini,openclaw \
  --receipt-dir state/isolated-agent-lanes \
  --require-runtime \
  --json
```

Exit `20` means reduced mode passed but one or more named agent lanes still lack
isolated runtime proof. That is a publication blocker for supported-copy claims,
not a blocker for the reduced public fallback.

## CI And Local Use

Fast contract test:

```bash
bash tests/isolated-agent-lane-smoke.sh
```

Full local proof before publication work:

```bash
bash tests/github-workflows.sh
scripts/local-actions-preflight.sh --dry-run
scripts/isolated-agent-lane-smoke.sh --receipt-dir state/isolated-agent-lanes --json \
  > state/isolated-agent-lane-smoke.receipt.json
```

GitHub Actions remains the final hosted-runner approval surface. The isolated
harness keeps local proof cheap and catches overclaims before that spend.

## Current Interpretation

As of the current publication lane, reduced mode is runtime-proven. Claude Code,
Codex CLI, Gemini CLI, and OpenClaw are compatibility targets because the public
engine still needs real credentialed `--live-adapters` receipts before any of
those lanes can be advertised as fully supported.
