# Agent Lane Compatibility

Flywheel is designed to run with different coding agents, but public support
copy has to follow evidence. The reduced local lane is the required fallback.
Agent lanes are compatibility targets until their own isolated runtime receipts
exist. Current local receipts prove Claude Code, Codex CLI, Gemini CLI, and
OpenClaw. Codex uses an explicit `FLYWHEEL_CODEX_HOME` credential source while
keeping the target repo and `HOME` isolated; OpenClaw creates a disposable
isolated agent for the smoke turn.

Use this command to inspect the agent-lane surface:

```bash
scripts/agent-lane-probe.sh --json
```

Optional runtime receipts can be supplied by directory:

```bash
scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json
```

Each lane reports:

| Field | Meaning |
|---|---|
| `cli_present` | The command is on `PATH`. This is useful setup evidence only. |
| `runtime_proven` | A lane-specific receipt proved the journey. |
| `public_status` | `compatibility-target` until `runtime_proven=true`. |
| `support_copy_allowed` | Whether public copy may call the lane supported. |
| `evidence` | `registry_valid`, `cli_presence_only`, `blocker_receipt`, or `runtime_receipt`. |

CLI presence is not runtime proof. A machine can have `claude`, `codex`,
`gemini`, or `openclaw` available and still lack auth, daemon state, callback
contracts, receipts, or public-safe setup instructions.

Before changing public copy from compatibility target to supported, produce a
runtime receipt at `receipts/agent-lanes/<lane>.json` with:

- `id` equal to the lane name,
- `schema_version` equal to `flywheel.agent_lane_runtime_receipt.v0`,
- `status` equal to `pass` or `runtime_proven`,
- `runtime_proven` equal to `true`,
- `support_scope` equal to `isolated`,
- `command` naming the `journey-smoke.sh` invocation,
- `private_state_scan.status` equal to `pass`,
- no `private_state_scan.findings` rows, and
- exactly one `journey_stages[]` row with `status=pass` for each of `preflight`, `init`,
  `doctor`, `tick`, `dispatch_or_simulate`, `closeout`, and
  `inspect_next_action`.

A receipt that only says `runtime_proven=true` is not enough. Public support
copy requires evidence that the whole first-run journey completed without
copying private state into the lane.
Duplicate or conflicting required stage rows are treated as ambiguous evidence
and cannot promote support copy.

If a compatibility target lane cannot be proven yet, keep a blocked receipt at
the same path with `schema_version=flywheel.agent_lane_blocker_receipt.v0`,
`status=blocked`, `runtime_proven=false`, `support_copy_allowed=false`, and a
specific `blocker_class`, `blocker_reason`, and `next_action`. Blocked receipts
are useful accountability evidence, not support proof. They keep public copy at
`compatibility-target`.

Then rerun:

```bash
bash tests/agent-lane-probe.sh
bash tests/journey-smoke.sh
bash tests/public-surface-gap-scanner.sh
```

Promotion checklist:

1. Add the lane runtime receipt.
2. Update the support-tier table in `docs/getting-started/first-run.md`.
3. Update the support-tier table in `docs/runbooks/public-release-runbook.md`.
4. Rerun `bash tests/public-docs.sh` and the three commands above.

Do not update only one support-tier table. Runtime support copy must move
together across the first-run guide and release runbook.

If no runtime receipt exists, keep the lane as a compatibility target and point
new users to reduced mode for their first complete journey.
