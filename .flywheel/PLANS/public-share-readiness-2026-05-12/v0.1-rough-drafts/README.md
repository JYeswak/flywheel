# Flywheel

**A toolkit for AI development systems that learn from their own work.**

Most AI coding tools operate one session at a time. You open a chat, ask for something, get a result, close the session — and the next session starts cold. Nothing accumulates.

Flywheel is the opposite. It is a set of cooperating protocols — task tracker, doctrine corpus, multi-pane orchestration, safety hooks, learned-pattern promotion — that turn each cycle of AI work into substrate the next cycle can build on. The system gets faster, safer, and more capable with use.

It is opinionated. It assumes [Claude Code](https://docs.claude.com/en/docs/claude-code) (or a compatible CLI agent). It assumes you'd rather invest 30 minutes of setup once than re-explain your project to a fresh chat every Monday.

---

## What's in the box

| Component | What it does |
|-----------|--------------|
| **The cycle** — 9 phases from *intent* to *learned reuse* | A predictable rhythm for AI-assisted work; lessons from cycle N bake into cycle N+1 |
| **Three reasoning spaces** — plan / bead / code | Mistakes caught where they're cheap (plan-space is ~25× cheaper than code-space) |
| **Trauma-class promotion ladder** | Recurring failure modes graduate from instance memory → hardened pattern → canonical rule across three strikes |
| **Multi-pane orchestration** (optional) | One orchestrator pane plans + dispatches; workers run beads in parallel; structured callbacks reconcile |
| **Safety substrate** | Destructive command guard, secret-leak detection, cross-repo write hooks, substrate-class self-awareness |
| **Doctor / health / repair triad** | Every CLI in the system has a `doctor` subcommand that detects, diagnoses, and (where safe) repairs its own state |

The full architecture is in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Who this is for

Flywheel is designed for the developer who:

- Has Claude Code (or `codex` / similar) running daily
- Wants their AI sessions to compound into a real system instead of evaporating into chat history
- Is comfortable trading 30 minutes of setup for a sustained productivity step-change
- Cares about safety as much as speed — values the kind of guardrails that prevent you from clobbering production
- Reads `git log` and finds documentation as load-bearing as code

Flywheel is **not** for:

- People who want a chat UI with no setup
- People who want fully autonomous agents with no human in the loop
- People who are happy with their current session-shaped workflow

## What it looks like in practice

You start a project. You invoke `/flywheel:init`. You write a `MISSION.md` that anchors what you're building and why. You write a first plan in plain prose. You compete two more drafts from other models against it; you synthesize the strongest version. You convert the plan into beads. You dispatch the beads to workers — each in its own pane. You reap callbacks, validate the work, ship. You write a closeout receipt that says what changed and what was learned.

The next cycle starts richer than the last. Patterns that surfaced get promoted into skills. Failure modes that fired three times become canonical rules. Your task tracker, your doctrine corpus, your skill catalog — all of it accretes.

That's the flywheel. Each cycle adds momentum.

## Honest status (v0.1, May 2026)

This project is in **early-stage open development**. We're shipping it under the principle that "share-worthy whether shared or not" forces better architectural discipline.

| What works | Status |
|---|---|
| The 9-petal cycle | Proven across hundreds of cycles in private development |
| Plan/bead/code reasoning spaces | Foundational; battle-tested |
| Trauma-class promotion ladder | 168+ canonical L-rules promoted; pattern validated |
| Multi-pane orchestration via NTM | Reliable for 2-4 worker panes; daily use |
| Cross-repo write hooks (tool + shell layers) | Shipped 2026-05-12; both layers empirically verified |
| Doctor / health / repair triad | Core CLI primitives ship with all three |
| Beads task tracker | Local-first SQLite + JSONL; daily use; thousands of beads |

| In flight | Status |
|---|---|
| Substrate-class classifier paradigm (L162) | Shipped 2026-05-12; bleeding-edge; v0.2 candidate |
| Tenant-verification gate (L164) | Ratified 2026-05-12; rolling out per-repo |
| `.zs-tenant.yaml` consumer-repo discipline (L168) | Ratified 2026-05-12; fleet bootstrap in progress |
| Public one-line installer | Designed; not yet shipped |
| Documentation website | Planned for [flywheel.zeststream.ai](https://flywheel.zeststream.ai) |
| Hello-world example repo | Drafting |

## Quickstart (when v0.2 ships)

```sh
# Install (placeholder — not live yet)
curl -sSL https://flywheel.zeststream.ai/install.sh | bash

# In your project
cd ~/Developer/myproject
flywheel init

# Start a cycle
flywheel plan "what we're trying to do"
```

For the current pre-v0.2 path (manual setup), see [`HELLO-WORLD.md`](HELLO-WORLD.md).

## What flywheel borrowed and where it differs

Flywheel stands on the shoulders of several adjacent projects. Notably:

- **[PAI](https://github.com/danielmiessler/Personal_AI_Infrastructure)** by Daniel Miessler — three-layer stack framing, TELOS-as-anchor concept, PreToolUse containment zones, one-line install ergonomics. Flywheel adopts the framing and adds: multi-pane coordination, trauma-class promotion, explicit three-reasoning-spaces, doctor/health/repair triad.
- **[NTM](https://github.com/Dicklesworthstone/ntm)** by Jeff Emanuel — named-tmux session management substrate that the multi-pane orchestration depends on.
- **[beads_rust](https://github.com/Dicklesworthstone/beads_rust)** by Jeff Emanuel — local-first task tracker with single-writer JSONL discipline.
- **Donella Meadows, *Thinking in Systems*** — the leverage-points framework that informs paradigm-class decisions across the doctrine corpus.

Where flywheel goes furthest beyond these: the **bilateral cross-orchestrator protocol** (multi-system coordination with structured handoffs and ratification receipts) and the **trauma-class promotion ladder** (a learning substrate that turns operational pain into canonical doctrine).

## License

[MIT](LICENSE) — see `LICENSE` file. You may use, modify, and redistribute. We'd love to hear what you build.

## Where to go from here

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — the technical deep-dive
- [`CHARTER.md`](CHARTER.md) — project mission, values, what we're optimizing for
- [`HELLO-WORLD.md`](HELLO-WORLD.md) — minimal working example
- [`ENGINE-OVERLAY-BOUNDARY.md`](ENGINE-OVERLAY-BOUNDARY.md) — what flywheel ships vs what you bring
- [`INSTALLER-DESIGN.md`](INSTALLER-DESIGN.md) — how `curl | bash` works without making you nervous

## Contact

Built by [Joshua Nowak](https://github.com/JYeswak) at [ZestStream](https://zeststream.ai). Public issues + discussion at [github.com/JYeswak/flywheel](https://github.com/JYeswak/flywheel) once the public repo lands.

For now: this is the source of truth.
