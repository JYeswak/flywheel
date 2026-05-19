# MP-58 — Agent-tool theory of mind

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Agent-facing tools must anticipate misuse: cluster capabilities, make the right action obvious, intercept confusion early, and put deterministic logic below thin frontends.

## Where it applies

MCP servers, Rust CLIs, agent runtimes, tool registries, session replay, extension policies, unsafe audits, and multi-frontend workspaces.

## Adoption signal

Skill has small tool clusters, Do/Don't docs, fake-CLI stubs or early interceptors, changed-file test matrices, core/harness/frontend layering, and explicit unsafe or public-surface contracts.

## Exemplar skills (≥5)

- `~/.claude/skills/mcp-server-design/SKILL.md:11` — design for agent theory of mind and likely misuse.
- `~/.claude/skills/mcp-server-design/SKILL.md:17` — make the wrong thing impossible and the right thing obvious.
- `~/.claude/skills/mcp-server-design/SKILL.md:71` — cluster tools to seven or fewer per workflow.
- `~/.claude/skills/mcp-server-design/SKILL.md:404` — fake CLI stubs catch agents confusing MCP servers for CLIs.
- `~/.claude/skills/pi-agent-rust/SKILL.md:36` — regressions route to targeted symptom-first command slices.
- `~/.claude/skills/pi-agent-rust/SKILL.md:171` — changed-file matrix minimum tests must pass.
- `~/.claude/skills/rust-core-thin-frontend-workspace/SKILL.md:12` — core logic, verification harness, and thin frontends are separate layers.
- `~/.claude/skills/rust-unsafe-code-exorcist/SKILL.md:616` — unsafe reachable from public API is on the soundness surface.

## Adoption recipes

**Recipe 1 — Misuse list:** every tool documents top mistakes and routes each to a clear error or suggested call.

**Recipe 2 — Thin frontend:** keep CLI/MCP/UI layers as parsing and formatting shells over deterministic core logic.

**Recipe 3 — Targeted proof:** validate changed surfaces with a matrix before broad test runs or DONE callbacks.

## Compliance test

```bash
grep -E "(agent theory of mind|wrong thing impossible|Fake CLI|changed-file matrix|thin frontend|soundness surface)" SKILL.md || fail
```
