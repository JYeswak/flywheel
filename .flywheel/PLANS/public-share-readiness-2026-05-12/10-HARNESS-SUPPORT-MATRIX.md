# Public Harness Support Matrix

Created: 2026-05-12T21:18Z
Agent: TopazMeadow
Primary downstream beads: B12.0 / `flywheel-uwuxr`, B17.5 / `flywheel-7kuil`
Status: implementation input, not a completed support claim

## Purpose

The active goal names Claude, Codex, OpenClaw, Gemini, and reduced local mode.
Public Flywheel docs must not imply equal support for all five lanes until the
first-run journey smoke proves it. This matrix sets the support vocabulary and
the minimum evidence each lane needs before v0.2 can call it supported.

## Source Checks

Live public docs checked on 2026-05-12:

- Anthropic Claude Code setup:
  `https://docs.anthropic.com/en/docs/claude-code/getting-started`
- OpenAI Codex CLI:
  `https://developers.openai.com/codex/cli`
- Google Gemini CLI:
  `https://google-gemini.github.io/gemini-cli/docs/get-started/`
- OpenClaw install docs:
  `https://documentation.openclaw.ai/install`

Local source checks:

- `agentic-coding-flywheel-setup` skill says ACFS installs Claude Code, Codex
  CLI, and Gemini CLI in phase 6 and verifies them with version commands.
- `09-SUBSTRATE-PREFLIGHT-INVENTORY.md` defines the dependency preflight and
  reduced-mode contract.

## Support Labels

| Label | Meaning | Public copy rule |
|---|---|---|
| supported-by-receipt | Flywheel docs and strict runtime receipts prove this lane through the first-run journey. | May appear in install quickstart only after receipt validation. |
| supported-docs | Docs explain setup and verification, but full journey smoke is not green. | Must say "docs-supported, not journey-proven." |
| compatibility-target | Flywheel intends support but has not verified the full lane. | Must not be presented as working. |
| reduced-required | Required no-harness fallback path. | Must be available when full-mode tools are missing. |
| unsupported | Not in v0.2 scope or unsafe to recommend. | Must explain why and name a safe fallback. |

## Matrix

| Lane | Initial label | Public install source | Detect command | Minimum v0.2 evidence | Notes |
|---|---|---|---|---|---|
| Claude Code | compatibility-target until receipt | Official Anthropic setup; ACFS phase 6 | `claude --version` | Strict `flywheel.agent_lane_runtime_receipt.v0` row reaches `runtime_proven`, or the lane stays compatibility-target with an explicit auth/account blocker | Strongest existing internal usage, but public docs must not depend on Joshua's Claude hooks. |
| Codex CLI | compatibility-target until receipt | Official OpenAI Codex CLI docs; ACFS phase 6 | `codex --version` | Strict `flywheel.agent_lane_runtime_receipt.v0` row reaches `runtime_proven`, or the lane stays compatibility-target with an explicit auth/account blocker | Current lane is Codex, so setup can be made concrete; must preserve MCP/AGENTS.md differences from Claude. |
| Gemini CLI | compatibility-target until smoke | Official Google Gemini CLI docs; ACFS phase 6 | `gemini --version` | Support-tier row plus smoke or clear `registry_valid` only status | Install path is known, but Flywheel has not proven dispatch/closeout semantics through Gemini. |
| OpenClaw | compatibility-target until smoke | OpenClaw installer/docs | `openclaw --version`; `openclaw doctor`; `openclaw gateway status` | Support-tier row plus smoke or explicit unsupported reason | OpenClaw is an agent platform with daemon/gateway shape, not just a terminal coding CLI; Flywheel must avoid pretending it is equivalent to Claude/Codex. |
| Reduced local mode | reduced-required | Flywheel-owned docs and fixtures | `flywheel doctor --mode reduced` or equivalent once B5 exists | B17.5 reduced row reaches `dispatch_or_simulate: pass`; B17 fresh-laptop receipt passes in reduced mode if full mode absent | This is mandatory for public installability. It teaches the loop without NTM panes, Agent Mail, or cross-session memory. |

## Journey Evidence States

Use the Mobile Eats L170 distinction directly:

| State | Meaning |
|---|---|
| registry_valid | The lane is documented in the support matrix and validates structurally. |
| runtime_proven | The lane completed the first-run journey receipt on a real or faithful fixture. |
| fixture_blocked | The lane is structurally valid, but test data/auth/local fixture is missing. |
| source_gap | The install source, command name, or support API is not stable enough to publish. |
| unsupported | Flywheel intentionally does not support the lane in this release. |

Selectors, command names, and daemon probes are executable evidence. They are not
the doctrine layer. The doctrine layer is the public journey contract: persona,
first value, return loop, guardrail, and evidence state.

## Minimum First-Run Fields Per Lane

Each B17.5 row should emit:

```json
{
  "lane": "codex",
  "support_label": "supported-by-receipt",
  "evidence_state": "runtime_proven",
  "install_detected": true,
  "auth_state": "present|missing|not_required|unknown",
  "first_value": "repo initialized with passing doctor and next action",
  "return_loop": "tick -> dispatch_or_simulate -> validated_closeout -> inspect",
  "guardrail": "no private state, no destructive mutation, reduced-mode honesty",
  "commands": {
    "detect": "codex --version",
    "doctor": "flywheel doctor --json",
    "journey": "journey-smoke --lane codex --json"
  }
}
```

## Public Copy Constraints

- Do not claim OpenClaw support until a strict runtime receipt proves it.
- Do not claim Gemini support until a strict runtime receipt proves it.
- Claude and Codex may be marketed as first targets only after smoke rows exist.
- Reduced local mode is not a degraded apology; it is the honest fallback that
  makes the public system teachable without full fleet substrate.
- If an auth/account blocker prevents a lane from runtime proof, public copy
  must say `registry_valid` rather than hiding the gap.

## Non-Completion Note

This matrix does not satisfy B12.0 or B17.5. It narrows the implementation target.
B12.0 still needs `docs/getting-started/first-run.md`; B17.5 still needs the
journey-smoke matrix with registry/runtime evidence states.
