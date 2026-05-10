# Draft: Jeffrey Emanuel ntm upstream issue

Repo: `Dicklesworthstone/ntm`
Status: HELD-FOR-JOSHUA-REVISION (per session pattern; do not post until
Joshua reviews and approves)
Anonymized per `jeff-issue-chain` v1.1 (no flywheel paths, no bead IDs,
no internal session names, no doctrine-line references)

## Title

`ntm wait --json` emits ANSI-colored human text on timeout instead of JSON

## Body

When `ntm wait <session> --until=idle --any --timeout=<dur> --json` exceeds
its timeout, the command exits 1 (correctly) but the output written to
stderr is ANSI-colored human text rather than a JSON object. Downstream
wrappers requesting `--json` for machine-readable receipts have to detect
this and synthesize their own JSON envelope.

### Reproduction

```bash
$ ntm wait <some-session> --until=idle --any --timeout=1s --json
[ANSI cyan]⏳[/] Waiting for '<some-session>' until idle (timeout: 1s)...
[ANSI red]✗[/] Timeout after 1s
$ echo $?
1
```

The output above is rendered with literal terminal escape sequences in the
captured bytes. Piping to `jq` fails because the output is not JSON.

### Expected

When `--json` is set, all command outcomes — including timeout — should
emit a parseable JSON object. Suggested shape:

```json
{
  "session": "<session>",
  "outcome": "timeout",
  "until": "idle",
  "any": true,
  "timeout": "1s",
  "exit_code": 1,
  "elapsed_ms": <int>,
  "panes": []
}
```

### Why this matters

Dispatch automation that polls a session for idle workers needs a
machine-readable signal whether the wait finished, timed out, or hit
an error. Today the code path is:

```bash
output="$(ntm wait <session> --until=idle --any --timeout=<dur> --json 2>&1)" || rc=$?
if jq -e . >/dev/null 2>&1 <<<"$output"; then
  jq -c --argjson rc "$rc" '. + {exit_code:$rc}' <<<"$output"
else
  jq -nc --arg output "$output" --argjson rc "$rc" '{exit_code:$rc,raw:$output}'
fi
```

— a jq-fallback wrap that exists only because the timeout path doesn't
honor `--json`. With the upstream fix, that fallback can be deleted and
the merge can be unconditional.

### Workaround

Downstream wrappers detect non-JSON output via `jq -e .` and synthesize a
`{exit_code, native_command, raw}` envelope so dispatch automation has a
JSON shape to consume.

### Environment

- ntm version: built from current `main`
- Platform: macOS Apple Silicon
- Triggered when wait condition is not met within timeout window

### Related context

This is the same `--json`-on-error class as: when `--json` is requested,
ALL exit paths should produce JSON, including error/timeout paths. The
"happy path emits JSON, error path emits human text" pattern is a common
CLI discoverability anti-pattern that breaks pipelines.

Thank you for ntm — the wait/assign/grep substrate is foundational to the
downstream automation we run on top of it.
