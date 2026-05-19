# MP-15 — Canonical CLI scoping

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Every aggregator-CLI exposes the doctor/health/repair triad + validate/audit/why + per-adapter scoping + upstream-bug surfacing. Skip these and the CLI becomes a black box for agents.

## Where it applies

Any CLI binary (br, bv, mem, cm, ntm, jsm, caam, etc.); especially adapter-based aggregators.

## Adoption signal

CLI exposes `doctor` + `health` + `repair` subcommands AND `validate` + `audit` + `why` companions.

## Exemplar skills (≥5)

- `~/.claude/skills/canonical-cli-scoping/SKILL.md:1` — direct exemplar
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md:451` — canonical doctor surface
- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:1` — agent-ergonomics rubric (sister)
- `~/.claude/skills/beads-br/SKILL.md:1` — `br` CLI canonical example
- `~/.claude/skills/beads-bv/SKILL.md:1` — `bv` CLI canonical example
- `~/.claude/skills/ntm/SKILL.md:1` — ntm CLI canonical example
- `~/.claude/skills/jsm/SKILL.md:1` — jsm CLI canonical example

## Adoption recipes

**Recipe 1 — Triad mandatory:** any new CLI ships with doctor/health/repair from v0.1.

**Recipe 2 — Aggregator scoping:** if CLI aggregates adapters, each adapter gets its own scoped doctor + named in `<cli> doctor capabilities --json`.

**Recipe 3 — Upstream-bug surfacing:** when adapter probe fails, error message names the upstream owner + how to file.

## Compliance test

```bash
# Top-level CLI binaries MUST expose doctor + health.
which "$CLI" >/dev/null && "$CLI" doctor --help >/dev/null 2>&1 && "$CLI" health --help >/dev/null 2>&1 || fail
```
