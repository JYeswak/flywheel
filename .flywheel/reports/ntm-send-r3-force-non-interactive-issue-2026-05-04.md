## Problem

Automation that performs protected-session recovery currently has to use shell-level confirmation pipes around `ntm send` when a duplicate-work/CASS confirmation can appear. This is fragile for recovery tooling because a stuck interactive confirmation can prevent a worker relaunch/status prompt from landing.

## Current code path observed

- `internal/cli/send.go` exposes `--no-cass-check`, but not a broader non-interactive send mode.
- When similar CASS work is found, `runCassDuplicateCheck` prompts `Continue anyway?` in interactive mode.
- `confirm_huh.go` falls back to reading `y`/`yes` from stdin when not in a TTY.
- `getPromptContent` gives positional arguments and `--file` priority over stdin, which lets wrappers pipe `y` while still passing a prompt.

## Requested flag

Add a narrow force flag to `ntm send`:

```bash
ntm send <session> --pane=<pane> --force-non-interactive "<prompt>"
```

Suggested behavior:

- Never block on an interactive confirmation.
- Bypass confirmation gates that are safe for automated recovery/status sends, starting with CASS duplicate confirmation.
- Fail closed on destructive or ambiguous confirmation classes.
- Emit a JSON field such as `non_interactive_forced=true` when used.
- Keep `--no-cass-check` as the explicit CASS-only bypass; `--force-non-interactive` should be the mechanical wrapper-friendly contract.

## Current local workaround

Protected-session recovery currently uses:

```bash
printf 'y\n' | ntm send "$session" --pane="$pane" --no-cass-check "$prompt" \
  || yes | ntm send "$session" --pane="$pane" --no-cass-check "$prompt"
```

This works because prompt content is positional and stdin remains available for confirmation reads, but it is not a durable CLI contract.

Filed from flywheel worker-recovery-slo-180s as <https://github.com/Dicklesworthstone/ntm/issues/119>.
