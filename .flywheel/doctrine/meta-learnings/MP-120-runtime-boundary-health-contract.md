# MP-120 - Runtime boundary health contract

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Runtime-specific systems need explicit health probes, boundary separation, version pins, and compile-time or checkpoint guarantees that prevent silent drift across language and execution boundaries.

## Where it applies

Python virtualenvs, Rust workspaces, React/Next.js apps, MCP servers, async runtimes, generated CLIs, and any system where runtime coupling can break without changing business logic.

## Adoption signal

The skill states runtime prerequisites, separates reusable core from thin wiring, pins or validates versions, probes health before recovery, and uses type/checkpoint/performance rules to catch boundary errors early.

## Exemplar skills (>=5)

- `~/.claude/skills/python-health/SKILL.md:12` - broken virtualenv symlinks, cache growth, and version drift silently break dispatch.
- `~/.claude/skills/python-health/SKILL.md:15` - multiple Python minor versions can be correct and must not be consolidated blindly.
- `~/.claude/skills/python-health/SKILL.md:20` - Python health starts with an exit-coded probe.
- `~/.claude/skills/rust-best-practices/SKILL.md:36` - reusable logic belongs in core while filesystem, environment, stdout, runtime, and CLI parsing stay in the CLI crate.
- `~/.claude/skills/rust-best-practices/SKILL.md:42` - Rust code should make invalid states unrepresentable and catch errors at compile time.
- `~/.claude/skills/react-best-practices/SKILL.md:23` - React/Next performance rules are prioritized by impact across async, bundle, server, client, render, and JS categories.
- `~/.claude/skills/react-best-practices/SKILL.md:40` - async work avoids waterfalls by checking cheap conditions and parallelizing independent work.
- `~/.claude/skills/fastmcp-rust/SKILL.md:16` - Rust MCP servers use first-class cancellation, macros, and structured concurrency.
- `~/.claude/skills/fastmcp-rust/SKILL.md:80` - long-running MCP tools need checkpoints to avoid orphan tasks on disconnect.

## Adoption recipes

**Recipe 1 - Runtime probe:** verify interpreter/toolchain/framework health and version distribution before repair or codegen.

**Recipe 2 - Boundary split:** keep pure reusable logic separate from CLI, IO, runtime, and framework wiring.

**Recipe 3 - Early-failure guarantee:** use type checks, compile checks, performance rules, and cancellation checkpoints before runtime side effects.

## Compliance test

```bash
grep -E "(runtime|version|health-probe|venv|core|cli|compile|checkpoint|structured concurrency|performance)" SKILL.md || exit 1
```
