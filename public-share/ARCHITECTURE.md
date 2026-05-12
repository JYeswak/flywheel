# Flywheel — Architecture

> **Status:** v0.1 draft (2026-05-12). Public-share-readiness. Names and surfaces subject to change before v1.0.

Flywheel is a set of cooperating protocols for building AI development systems that compound over time. This document explains what it is, what it isn't, and how the pieces fit.

It is opinionated. It assumes you are using [Claude Code](https://docs.claude.com/en/docs/claude-code) (or a compatible CLI agent such as `codex`). It assumes you want your AI sessions to leave behind durable substrate — not just chat transcripts.

---

## What problem this solves

Most teams using AI coding tools today operate in **session-shaped** time: you open a chat, ask for something, get a result, close the session. The next session starts cold. Nothing accumulates.

Flywheel turns session-shaped time into **flywheel-shaped** time. Each cycle of work improves the substrate (skills, doctrines, task graph, learned patterns) that the next cycle runs on top of. The system gets faster, safer, and more capable with use — not just more verbose.

There are three reasoning spaces, each cheaper-to-fix than the next:

| Space | Cost-of-mistake | Examples |
|-------|------------------|----------|
| **Plan** | Cheapest | Architecture, tradeoffs, "should we even do this?" |
| **Bead** | ~5× plan | Task decomposition, dependencies, acceptance criteria |
| **Code** | ~25× plan | The actual edits, tests, integrations |

Most AI tools push you to code-space immediately. Flywheel keeps you in plan-space until the plan converges; then in bead-space until the task graph is sound; *then* it dispatches code-space work to specialized workers. Mistakes get caught where they're cheap.

## The nine petals (the cycle)

```
   1. INTENT   ──→   2. FIRST PLAN   ──→   3. MULTI-MODEL   ──→   4. SYNTHESIS
       ↑                                    COMPETITION                │
       │                                                                ↓
   9. LEARN / REUSE                                       5. REVIEW / TEST / HARDEN
       ↑                                                                │
       │                                                                ↓
   8. SWARM EXECUTION   ←─   7. TRIAGE / DISPATCH   ←─   6. CONVERT TO BEADS
```

| Petal | What happens |
|---|---|
| **1. Intent** | A short brief: what we're trying to do and why. Not "implement X" — closer to "we need Y because Z." |
| **2. First plan** | One model drafts an approach. Plain prose. |
| **3. Multi-model competition** | Independent drafts from 2-3 models (Claude, Codex, Gemini). Diversity surfaces blindspots. |
| **4. Synthesis** | Reconciliation: take the best of each, name the tradeoffs explicitly. |
| **5. Review / test / harden** | Specifications, acceptance criteria, failure modes. Where you find that two of the drafts assumed something that doesn't hold. |
| **6. Convert to beads** | The plan becomes a task graph: discrete units with dependencies and acceptance criteria. One bead = one PR-shaped change. |
| **7. Triage / dispatch** | Beads ordered by readiness (not by gut). The ones with all dependencies satisfied are dispatched first. |
| **8. Swarm execution** | Each bead goes to a worker — typically a separate Claude Code or Codex pane. Workers run in parallel where dependencies permit. |
| **9. Learn / reuse** | Patterns that recur become skills. Three-strike traumas become canonical L-rules. The substrate accretes. |

This is not a waterfall. It's a cycle. Cycle 1 produces v0.1 of a feature; cycle 2 produces v0.2 with the lessons of v0.1 baked into the plan. The flywheel image is intentional: each cycle adds momentum.

## The promotion ladder (how the system learns)

Failure modes have a structured path from observation to canonical rule:

```
Observation  →  Memory rule       (N=1)    cheap; private; instance-specific
            ↘
              Hardened pattern    (N=2)    confirmed pattern; private; second strike
            ↘
              Canonical L-rule    (N=3)    fleet-wide invariant; published; SATURATION
            ↘
              Meta-rule extension          patterns that govern entire classes of L-rules
```

Most observations stop at N=1. Some get hardened at N=2. The serious ones — patterns that have hurt three times — become L-rules with cross-orchestrator ratification and an explicit promotion receipt.

The threshold is deliberate. Three-strike prevents over-canonicalization-of-noise. The system stays focused on patterns that have actually proven their worth.

**Special class — secrets/credentials**: irreversible-by-design traumas skip the 3-strike gate. A single credential leak qualifies for immediate L-rule promotion because by N=3 the team has had 2 real breaches.

## Three reasoning surfaces — what's where

```
~/.claude/                 Claude Code + global skills + memory + hooks
~/.flywheel/               Flywheel runtime state, authorize-lists, ledgers
~/Developer/<project>/     Per-project work
  └── .flywheel/           Project-level: doctrine, beads, dispatch log,
                            handoffs, audit, evidence
```

Each surface has a different lifetime:

| Surface | Lifetime | Substrate class |
|---------|----------|------------------|
| `~/.claude/skills/` | Persistent across all projects | universal capabilities |
| `~/.flywheel/` | Persistent across sessions; user-owned | runtime state |
| `<project>/.flywheel/` | Versioned with the project | project doctrine + history |
| Working tree | Volatile | code |
| `.beads/issues.jsonl` | Versioned with project | canonical task graph |

## Multi-pane coordination (optional)

A solo user runs flywheel in one Claude Code pane. That works fine.

For larger work, flywheel supports a **multi-pane orchestration** model: one orchestrator pane plans and dispatches; 2-4 worker panes execute beads in parallel. Workers report back via structured callbacks. The orchestrator reaps callbacks, validates, and dispatches the next wave.

This requires [NTM](https://github.com/Dicklesworthstone/ntm) (Jeff Emanuel's named-tmux session manager) and an inter-orchestrator coordination protocol. Adoption is opt-in; nothing in the single-pane path depends on it.

## Cross-orchestrator protocol (for the curious)

When you're running multiple flywheel instances against related projects (say: a private project and the public engine repo), the orchestrators coordinate via filesystem handoffs:

- **Inbox discipline**: every orchestrator reads its inbox of pending handoffs before declaring its tick complete
- **Outbox discipline**: every orchestrator that ships fleet-affecting substrate notifies sister orchestrators before close
- **Bilateral ratification**: structural changes (new L-rules, paradigm shifts) get ratified by at least two orchestrators before becoming canonical

This is a [bilateral protocol](https://en.wikipedia.org/wiki/Bilateralism) for AI systems. It scales linearly in coordination overhead, sublinearly in error rate, and produces auditable cross-system receipts.

## Safety substrate

Flywheel ships several layers of guardrails, all opt-in but recommended:

| Layer | What it does |
|-------|--------------|
| **Destructive Command Guard (DCG)** | Pre-execution check against a deny-list of dangerous shell patterns (`rm -rf` on home, `git reset --hard` without lease, etc.) |
| **Secret-leak PostToolUse hook** | Halts the agent loop if a known secret-shape (AWS AKID, GitHub PAT, JWT, Stripe key) appears in stdout/stderr |
| **Cross-repo write guards** | Both tool-layer (Write/Edit/NotebookEdit) and shell-layer (Bash) hooks default-deny writes from session A's repo to session B's repo unless explicitly authorized |
| **Substrate-class manifest** | Every protection mechanism consults a manifest of what's `production` vs `protection` vs `test-fixture` vs `audit-ledger` — so detectors don't trigger on their own test corpus |
| **Reversibility receipts** | Destructive operations (deletes, force-pushes) produce a byte-equality recovery artifact before execution |

The guiding principle, borrowed from systems thinking: **protection mechanisms must operate at the layer that intercepts the tool, not at a layer the tool bypasses.** A shell-layer guard cannot protect Write/Edit calls; a tool-layer hook cannot protect shell commands. You need both.

## What flywheel is not

- **It is not a chat UI.** It assumes you already have Claude Code.
- **It is not autonomous.** Humans approve plan-space decisions; the system handles bead-space and code-space execution.
- **It is not magic.** It's a set of conventions plus enforcement hooks plus a doctrine corpus.
- **It is not finished.** Several paradigm-level pieces (substrate-class classification, tenant-isolation gates) are weeks old. Use accordingly.

## Inspirations + adjacent projects

| Project | What we borrowed |
|---------|------------------|
| [PAI](https://github.com/danielmiessler/Personal_AI_Infrastructure) (Miessler) | Three-layer stack framing; TELOS-as-anchor; one-line install ergonomics; PreToolUse containment zones |
| [NTM](https://github.com/Dicklesworthstone/ntm) (Emanuel) | Pane management substrate; multi-pane orchestration primitives |
| [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (Emanuel) | Local-first task tracker; single-writer JSONL discipline |
| [Aider](https://aider.chat/) | Repository-aware AI editing patterns |
| [LangGraph](https://langchain-ai.github.io/langgraph/) | Graph-structured agent flows (we use it as a comparison reference, not a dependency) |
| Donella Meadows, *Thinking in Systems* | Leverage-points framework; paradigm-as-leverage; the mirror-stage failure mode |

Where flywheel differs: explicit three-reasoning-spaces (most tools collapse plan/code), the trauma-promotion ladder (most tools have no learning substrate), the cross-orchestrator bilateral protocol (most tools are single-process), the doctor/health/repair CLI triad (most tools have no self-healing).

## Glossary (terms used here that are not common)

- **Petal** — one of the nine phases of the flywheel cycle
- **Bead** — one work unit in the task graph (1 bead = 1 PR-shaped change)
- **L-rule** — a canonical fleet-wide invariant promoted from observed traumas
- **Orchestrator (orch)** — the pane that plans + dispatches + reaps callbacks
- **Worker** — a pane that executes a bead and reports back
- **Substrate class** — the role an artifact plays (production / protection / test-fixture / self-documentation / audit-ledger)
- **Trauma class** — a named failure mode tracked through the promotion ladder
- **Mirror-stage failure** — when a system's mitigation has to be applied INSIDE the same boundary it tries to protect (Meadows)

## Next reads

- [README.md](README.md) — the 5-minute overview
- [HELLO-WORLD.md](HELLO-WORLD.md) — minimal working example
- [ENGINE-OVERLAY-BOUNDARY.md](ENGINE-OVERLAY-BOUNDARY.md) — what's public vs private
- [INSTALLER-DESIGN.md](INSTALLER-DESIGN.md) — how `curl | bash` works safely
- [CHARTER.md](CHARTER.md) — project mission + values

---

*This document is part of the flywheel ecosystem. The canonical version lives at [flywheel.zeststream.ai](https://flywheel.zeststream.ai) once shipped; until then, the source of truth is `public-share/ARCHITECTURE.md` in the [flywheel](https://github.com/JYeswak/flywheel) repository.*
