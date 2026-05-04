# ntm send R3 gate workaround research — 2026-05-04

## Scope

Dispatch: worker-recovery-slo-180s, L93 workaround research.

Question: how should protected-session recovery send relaunch/status prompts through `ntm send` while the upstream CLI lacks an explicit `--force-non-interactive` send flag?

## Source survey

- `/Users/josh/Developer/ntm/internal/cli/send.go:543-545` documents the CASS duplicate check and the existing `--no-cass-check` bypass.
- `/Users/josh/Developer/ntm/internal/cli/send.go:747-753` wires `--cass-check`, `--no-cass-check`, and `--dry-run`.
- `/Users/josh/Developer/ntm/internal/cli/send.go:868-890` gives positional prompt arguments priority over piped stdin, so stdin can still carry a confirmation answer when the prompt is passed as an argument.
- `/Users/josh/Developer/ntm/internal/cli/send.go:2868-2879` prompts `Continue anyway?` when CASS duplicate work is found in interactive mode.
- `/Users/josh/Developer/ntm/internal/cli/confirm_huh.go:17-22` falls back to simple stdin confirmation when not attached to a TTY.
- `/Users/josh/Developer/ntm/internal/cli/confirm_huh.go:61-68` accepts `y` or `yes` from stdin.

## Workarounds

1. Preferred recovery path: pass the prompt as a positional argument and include `--no-cass-check`.
   - Command shape: `ntm send <session> --pane=<pane> --no-cass-check "<prompt>"`
   - Why: avoids the known duplicate-work confirmation gate entirely for recovery/status prompts.

2. Finite confirmation pipe.
   - Command shape: `printf 'y\n' | ntm send <session> --pane=<pane> --no-cass-check "<prompt>"`
   - Why: positional arguments preserve prompt content while stdin remains available to `confirmSimple`.
   - Copy-test: PASS in `tests/ntm-send-r3-workaround-copy-tests.sh`.

3. Infinite confirmation pipe fallback.
   - Command shape: `yes | ntm send <session> --pane=<pane> --no-cass-check "<prompt>"`
   - Why: survives repeated confirmation reads; use only under timeout to avoid hanging if the process waits.
   - Copy-test: PASS in `tests/ntm-send-r3-workaround-copy-tests.sh`.

4. JSON preflight.
   - Command shape: `ntm send <session> --pane=<pane> --json --dry-run "<prompt>"`
   - Why: detects a duplicate gate as a machine-readable error instead of a stuck interactive prompt. Wrapper then retries with `--no-cass-check` only for recovery/status prompt classes.

5. Prompt-file with finite confirmation pipe.
   - Command shape: `printf 'y\n' | ntm send <session> --pane=<pane> --file <prompt_file> --no-cass-check`
   - Why: `--file` wins before stdin prompt ingestion, so stdin remains available to confirmation code.

6. Robot-send fallback.
   - Command shape: `ntm --robot-send=<session> --panes=<pane> --msg="<prompt>"`
   - Why: skips the human-facing `send` command path; use only when ordinary `ntm send` is blocked and robot send capability is confirmed healthy.

## Adopted in protected-session-recovery

The protected recovery primitive uses:

```bash
printf 'y\n' | ntm send "$session" --pane="$pane" --no-cass-check "$prompt" \
  || yes | ntm send "$session" --pane="$pane" --no-cass-check "$prompt"
```

It still requires the evidence-based recovery gate before any respawn/relaunch action.

## Upstream issue

Desired upstream behavior:

```bash
ntm send <session> --pane=<pane> --force-non-interactive --no-cass-check "<prompt>"
```

Acceptance:

- `--force-non-interactive` must never read from stdin for confirmations.
- The flag must fail closed if a non-bypassable destructive confirmation appears.
- JSON output must include `non_interactive_forced=true`.
- Existing `--no-cass-check` remains the narrow CASS bypass.

Filing status: filed as <https://github.com/Dicklesworthstone/ntm/issues/119>.
