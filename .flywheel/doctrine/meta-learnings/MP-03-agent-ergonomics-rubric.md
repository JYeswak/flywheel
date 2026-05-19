# MP-03 — Agent-ergonomics 11-dimension rubric

**Discovered:** 2026-05-18 (original investigation)
**Skills exemplifying:** 5+

## Essence

Every CLI surface (subcommand, flag, exit code, JSON envelope field) is independently scorable 0-1000 across 11 dimensions. Stable JSON + exit-code dictionary + stdout-data-stderr-diag discipline non-negotiable. `capabilities --json` + `robot-docs` mandatory.

## Where it applies

Any CLI primarily consumed by AI agents; agent-facing scripts; JSON envelopes emitted to other tools.

## Adoption signal

Skill cites `capabilities --json` OR includes the 11-dim rubric reference.

## Exemplar skills (≥5)

- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:1` — direct exemplar
- `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md:1` — full audit framework
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/subagents/agent-ergo-grader.md:1` — Phase 6 grader
- `~/.claude/skills/canonical-cli-scoping/SKILL.md:451` — robot-mode discipline
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:1` — contract design

## Adoption recipes

**Recipe 1 — Capabilities subcommand:** every CLI exposes `<bin> capabilities --json` returning name, version, schema_version, subcommands, exit codes.

**Recipe 2 — Robot-docs subcommand:** every CLI exposes `<bin> robot-docs` printing paste-ready agent handbook.

**Recipe 3 — Stdout-data-stderr-diag:** outputs go to stdout; diagnostics to stderr. `<bin> X --json | jq ...` works without grep-filtering.

## Compliance test

```bash
"$CLI" capabilities --json | jq -e '.schema_version' >/dev/null || fail
```
