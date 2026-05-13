# Support

Flywheel has two support paths:

- Public project questions: open a GitHub issue with the command, expected
  result, observed result, operating system, shell, and whether you ran reduced
  or full mode.
- ZestStream/commercial questions: email `joshua@zeststream.ai`.

Do not include secrets, raw environment dumps, private pane scrollback, client
data, or token fragments in issues. Use redacted evidence and synthetic
fixtures.

## Supported Modes

| Mode | Support status |
|---|---|
| Reduced local mode | Required public path. Should work without NTM, Agent Mail, Socraticode, or cross-session memory. |
| Full mode with Beads, Agent Mail, NTM, Socraticode, and DCG | Supported when those tools are installed and configured. |
| Claude, Codex, Gemini, OpenClaw harnesses | Compatibility targets until the journey-smoke matrix marks a row as runtime-proven. |

If a command fails, start with:

```bash
scripts/preflight.sh --json
scripts/journey-smoke.sh --matrix reduced --dry-run --json
```

Attach the redacted JSON output or summarize the failing keys.
