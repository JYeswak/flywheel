# Codex Exec PreToolUse Bypass Audit

Date: 2026-05-19
Bead: flywheel-xn62i
Scope: scoped to codex exec PreToolUse bypass audit + fix

## Disposition

`exec_mode_in_use=false`

Disposition: `NOT_IN_USE`

No backport was applied. The pinned local CLI is `codex-cli 0.130.0`, and v0.131 remains out of scope because the watchtower packet names three confirmed regressions. The mitigation is to keep autonomous dispatches on live Codex panes using worker-tick parity, and to make `/flywheel:worker-tick` refuse any future `codex exec` dispatch unless hook firing is verified by `tests/codex-exec-pretooluse-fires.sh` or an accepted divergence is explicitly recorded.

## Evidence

1. Watchtower source exists and is high relevance:
   - `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-19.jsonl`
   - Issue `openai/codex#23411`: "Code Mode `exec` doesn't fire `PreToolUse` hooks (fix patch attached)"
   - Labels: `bug`, `CLI`, `tool-calls`, `hooks`

2. Local CLI is pinned:
   - `codex --version` => `codex-cli 0.130.0`
   - `codex exec --help` is available, but no local flywheel dispatch path requires it.

3. Dispatch path audit:
   - `/Users/josh/.claude/commands/flywheel/dispatch.md` sends worker prompts into existing panes via `ntm send`.
   - `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` defaults to `worker_substrate=codex-pane agent_type=codex`.
   - `/Users/josh/.claude/commands/flywheel/worker-tick.md` describes Codex parity as reading the dispatch packet in the live pane and executing the worker-tick contract.
   - `/tmp/dispatch*` and `/tmp/*dispatch*.md` contained no `codex exec`, `exec-mode`, or `exec mode` launch instruction at audit time.

4. Recent Codex session evidence shows ordinary interactive PreToolUse firing:
   - `rg "Command blocked by PreToolUse hook" /Users/josh/.codex/sessions/2026/05/19` found repeated DCG blocks in live Codex pane sessions.
   - Example paths included mobile-eats, skillos, and flywheel sessions on 2026-05-19.

5. False-positive audit hits were self-referential or watchtower rows:
   - Current user goal text and this audit search contained `codex exec`.
   - Watchtower rows contained issue titles for `codex exec`.
   - These are evidence of awareness, not dispatch invocation.

## Risk

If an orchestrator starts invoking `codex exec` for autonomous workers, PreToolUse-backed protections may be bypassed on the pinned CLI. That would weaken DCG, cross-repo-write guard, and related pretool safety checks for state-mutating work.

## Mitigation

- Treat `codex exec` as blocked for worker dispatch by default.
- Keep autonomous worker execution in live Codex panes through `ntm send` and worker-tick parity.
- Require `tests/codex-exec-pretooluse-fires.sh` live verification before any future exec-mode dispatch.
- Record any exception as `ACCEPTED_DIVERGENCE` with explicit risk and rationale before dispatch.

## Validation

- `bash tests/codex-exec-pretooluse-fires.sh` => `SUMMARY pass=5 fail=0`
- `shellcheck tests/codex-exec-pretooluse-fires.sh` => PASS
- `bash -n tests/codex-exec-pretooluse-fires.sh` => PASS
- Worker-tick contract update committed in `/Users/josh/.claude` as `99addc8`.
