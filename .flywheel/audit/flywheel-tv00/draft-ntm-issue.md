## What happened

`ntm config validate --config <path> --json` against an empty TOML emits `valid:true`, `error_count:0`, and `warning_count:3`. The three warnings report unrendered Go template fragments as missing executables:

```
agents.codex executable not found in PATH: {{if
agents.gemini executable not found in PATH: gemini{{if
agents.claude executable not found in PATH: {{memLimitPrefix}}
```

The probe is matching against the first whitespace-delimited token of the loaded default command, which for the built-in defaults is a Go template directive rather than an executable name.

## Repro

Minimal empty TOML:

```bash
echo '# empty' > /tmp/empty.toml
ntm config validate --config /tmp/empty.toml --json
```

Output:

```json
{
  "valid": true,
  "results": [{
    "warnings": [
      {"field": "agents.gemini", "message": "executable not found in PATH: gemini{{if"},
      {"field": "agents.claude", "message": "executable not found in PATH: {{memLimitPrefix}}"},
      {"field": "agents.codex",  "message": "executable not found in PATH: {{if"}
    ]
  }],
  "summary": {"warning_count": 3, "error_count": 0}
}
```

## Expected vs observed

Expected: when the loaded agent command is the built-in default template, either skip the executable-PATH probe (templates render at run-time) or render the template against an empty/default context before probing. The actual executables (`claude`, `codex`, `gemini`) ARE on PATH; the warning's claim ("not found") is false relative to the rendered command.

Observed: probe runs against the unrendered template string. `strings.Fields` splits the template on whitespace and the first non-env-assignment token (a `{{...}}` directive) becomes the alleged executable name.

## File:line citations

- `internal/cli/validate.go:341-368` — `validateAgentExecutables` reads `cfg.Agents.{Claude,Codex,Gemini}` directly, runs `strings.Fields(cmd)`, takes the first non-`=`-containing token, and calls `exec.LookPath(exe)`. No template-rendering pass between load and probe.
- `internal/config/templates.go:227-229` — `DefaultAgentTemplates()` defines the templates that produce the warning text:
  - Claude: `{{memLimitPrefix}} claude ...` → `Fields[0] = "{{memLimitPrefix}}"`
  - Codex: `{{if .SystemPromptFile}}CODEX_SYSTEM_PROMPT=...{{end}}codex ...` → `Fields[0] = "{{if"` (the env-assignment skip in validate.go:350 drops the assignment but the surrounding `{{if`/`{{end}}` tokens are not env assignments)
  - Gemini: `gemini{{if .Model}} ...` → `Fields[0] = "gemini{{if"`

## Why this matters

Downstream tooling that runs `ntm config validate --json` expects warning_count to mean "real configuration drift." Today, every fresh install with an empty/minimal config emits 3 false-positive warnings. Operators learn to ignore `warning_count > 0` from validate, which masks real warnings when they arrive.

The bug also misclassifies what's actually a render-time concern (the template directives) as a load-time validation concern. The runtime template renderer at `templates.go` knows how to handle these directives; the validator does not.

## Out of scope

Not asking for a feature. The contract `ntm config validate --json` already promises `warning_count` reflects real configuration issues; this is a contract violation against the built-in defaults. Either skip executable probing for template-bearing commands, render the template before probing, or detect `{{...}}` directives and emit a warning class like `cannot probe template-bearing default command at validate time` instead of a false PATH-not-found.

## Dedupe

`gh issue list --repo Dicklesworthstone/ntm --state all --search` for `"executable not found template"`, `"template render validate"`, `"memLimitPrefix"`, `"config validate executable PATH"`, and `"default agent command"`. Closest related closed issues are #87 (`memLimitPrefix not defined` template-helper bug) and #85 (`memLimitPrefix breaks agent launch in containers`) — both are runtime template-rendering concerns, not validate-time probe-against-unrendered-template. No open or closed issue matches the exact symptom.
