# Public Substrate Preflight Inventory

Created: 2026-05-12T21:16Z
Agent: TopazMeadow
Primary downstream bead: B6.5 / `flywheel-ezgc7`
Status: implementation input, not a completed preflight script

## Purpose

The active public-installability goal requires Flywheel to install or detect the
Dicklesworthstone-derived substrate and to fall back honestly when the full stack
is not available. This inventory turns that requirement into a preflight contract
for B6/B6.5/B12.0/B17.5.

This is not a pinned installer. B6.5 must still live-probe upstream install
commands, pin versions or SHAs, and write fixture-backed tests.

## Source Basis

- `CHARTER.md` public promise and substrate attribution.
- `05-INSTALLABILITY-COVERAGE-AUDIT.md` A1 dependency matrix.
- `04-BEADS-DAG.md` B6/B6.5/B12.0/B17.5 acceptance.
- `dicklesworthstone-stack` skill:
  - `references/COMMANDS.md`
  - `references/INVENTORY.md`
  - `references/DOCTRINE.md`
- `agentic-coding-flywheel-setup` skill:
  - `SKILL.md`
  - `references/TOOL-INVENTORY.md`
- Live GitHub spot-check on 2026-05-12 for:
  - `https://github.com/Dicklesworthstone/mcp_agent_mail`
  - `https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup`
  - `https://github.com/Dicklesworthstone/destructive_command_guard`
  - `https://github.com/Dicklesworthstone/cass_memory_system`

## Support Tier Model

| Tier | Meaning | Installer behavior |
|---|---|---|
| required | Flywheel cannot run the first local loop without it. | Fail preflight with blocking reason. |
| full-mode | Needed for multi-agent or full public journey. | Warn and route to reduced mode if absent. |
| enhanced | Improves inspection, debugging, or fleet ergonomics. | Warn only; do not block reduced mode. |
| optional | Useful but not part of v0.2 first-run promise. | Report as absent without warning. |

Reduced mode must still support a visible loop shape: initialize a repo, run
doctor, run a local tick or dry-run tick, simulate dispatch, validate closeout
against a fixture, and inspect next action. It must not claim multi-agent
coordination, shared inboxes, or cross-session memory.

## Preflight Matrix

| Dependency | Tier | Purpose | Detect command | Install hint | Reduced-mode consequence |
|---|---|---|---|---|---|
| Git | required | source checkout, repo init, audit trail | `git --version` | system package, Xcode CLT, or Homebrew | block |
| POSIX shell | required | installer and command wrappers | `sh -c 'echo ok'` plus `${SHELL:-}` | system shell | block |
| Bash 4+ or compatible zsh path | required | portable scripts and associative behavior caveats | `bash --version`; on macOS also detect `/opt/homebrew/bin/bash` | Homebrew `bash` on macOS; apt package on Linux | block if script requires Bash 4 and no fallback |
| jq | required | JSON receipts and doctor parsing | `jq --version` | Homebrew or apt | block |
| Python 3.10+ | full-mode | Agent Mail, helper scripts, MCP utilities | `python3 --version` | uv, pyenv, Homebrew, apt | no Agent Mail server; single-agent only |
| Node 18+ / Bun | full-mode | ACFS, docs site, CASS-style memory, agent CLIs | `node --version`; `bun --version` if used | nvm, Homebrew, apt, Bun installer | no docs dev server or Node-backed memory |
| Rust/Cargo | full-mode | DCG and Rust-backed Jeff tools | `cargo --version` | rustup | reduced mode must warn that destructive command guard is not enforced |
| Go | enhanced | `ntm`, `beads_viewer`, and Go-installed tools where source build is needed | `go version` | Homebrew, apt, tarball, or ACFS phase 5 | skip visual/Go build path |
| SQLite | required | Beads state and local ledgers | `sqlite3 --version` | system package or Homebrew | block |
| tmux | full-mode | NTM pane orchestration | `tmux -V` | Homebrew or apt | simulated dispatch only |
| `br` / Beads | required | repo-local work graph | `br --version`; `br where` inside target repo | package/source path to be pinned by B6.5 | block real loop; docs-only if absent |
| NTM | full-mode | multi-pane dispatch and pane-state truth | `ntm --version`; `ntm health <session>` only after session exists | ACFS phase 8 or Jeff install path | dispatch simulation only |
| Agent Mail / `mcp_agent_mail` | full-mode | inboxes, file reservations, cross-agent coordination | `python -c 'import mcp_agent_mail'`; HTTP health if server running | upstream one-line installer or Python package path after live probe | no reservations or cross-agent mail; single-agent only |
| DCG | full-mode | destructive command guard | `dcg --version`; dry-run command check once API is pinned | upstream `destructive_command_guard` install script or cargo build after live probe | warn; require manual caution and block destructive tutorial steps |
| CASS-style memory | enhanced | cross-session memory and retrieval | HTTP health endpoint once configured | upstream `cass_memory_system` Node service after live probe | no cross-session memory claims |
| Socraticode | full-mode | codebase semantic search before non-trivial edits | MCP health/about probe; local CLI if exposed | MCP setup docs to be authored by B12.x | non-trivial repo edits unsupported; docs-only or manual search |
| `beads_viewer` | enhanced | graph visualization and PageRank triage | `beads_viewer --version` or `--help` | `go install` or source build after live probe | CLI-only Beads inspection |
| Claude Code | supported-first harness | first-class operator harness | `claude --version` | ACFS phase 6 or official install docs | use another harness or reduced mode |
| Codex CLI | supported-first harness | first-class operator harness | `codex --version` | ACFS phase 6 or official install docs | use another harness or reduced mode |
| OpenClaw | compatibility-target harness | named by objective; support must be honest | command name unresolved until B6.5 live probe | no install hint until probe | label compatibility-target or unsupported, not supported |
| Gemini CLI | compatibility-target harness | alternative operator harness | `gemini --version` if CLI exists | ACFS phase 6 or official install docs after probe | label compatibility-target unless smoke-proven |

## Preflight JSON Contract

B6.5 should emit one row per dependency with stable fields:

```json
{
  "id": "agent-mail",
  "tier": "full-mode",
  "status": "present|missing|misconfigured|unknown",
  "mode_effect": "full|reduced|blocked|docs-only",
  "detect_command": "python -c 'import mcp_agent_mail'",
  "evidence": {
    "exit_code": 0,
    "stdout_excerpt": "OK",
    "version": "..."
  },
  "install_hint": "live-probed upstream command or docs URL",
  "notes": "No secrets or raw env output."
}
```

Whole-run exit codes:

| Exit | Meaning |
|---:|---|
| 0 | full-mode preflight passes |
| 10 | full-mode passes with enhanced/optional warnings |
| 20 | reduced mode selected and first-run tutorial remains runnable |
| 30 | blocked: required dependency missing |
| 40 | preflight internal error or malformed fixture |

## Fixture Set For B6.5

Minimum fixture files:

- `fixtures/preflight/fresh.json`: nothing installed except system shell and Git.
- `fixtures/preflight/partial.json`: required basics plus missing full-mode tools.
- `fixtures/preflight/existing.json`: all full-mode tools present.
- `fixtures/preflight/reduced.json`: required basics plus enough to run simulated
  dispatch and fixture closeout.
- `fixtures/preflight/misconfigured.json`: commands exist but fail health checks.

The fixture runner should not call live tools. It should simulate command
presence, versions, exit codes, and stdout/stderr excerpts so the reduced-mode
resolver is deterministic.

## Open Questions For B6.5

1. Whether macOS public support starts at Homebrew-first or ACFS remains
   Ubuntu-first with macOS as manual setup.
2. The exact OpenClaw command name, install path, and support tier.
3. Whether Gemini CLI support should be smoke-proven in v0.2 or documented as a
   compatibility target.
4. Whether `br` installation should use `beads_rust`, Homebrew tap, or an
   already-distributed binary path.
5. Whether Agent Mail public setup should prefer Python `mcp_agent_mail` or the
   emerging Rust path; B6.5 should live-probe both but pin one as canonical.

## Non-Completion Note

This inventory does not satisfy B6.5. It only narrows the implementation target.
B6.5 remains open until `scripts/preflight.sh` exists, fixture cases pass, and
the public first-run journey consumes the preflight result.
