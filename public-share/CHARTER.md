# Flywheel — Charter

> *What we are optimizing for, and what we are deliberately not.*

This document is for two audiences. The first is anyone deciding whether to adopt flywheel for their own work. The second is anyone deciding whether to contribute. Both deserve to know what this project is for and where its compass points.

---

## What this project is for

**Building AI development systems that compound.**

Not chat sessions. Not autonomous agents. Systems — durable, opinionated, learning substrate that gets sharper with use and never forgets a lesson it has already paid for.

The premise is that the dominant pattern of AI coding tools — ephemeral sessions, fresh context every time, no shared substrate between runs — leaves enormous value on the table. Each session that ends without contributing back to the system is a session whose lessons evaporate. The teams using AI most effectively are the ones who have figured out how to make work compound across sessions.

Flywheel is what that compounding looks like when you take it seriously.

## Principles

These are the load-bearing convictions behind every design choice.

### 1. Plan-space is cheaper than code-space by an order of magnitude

A bad plan caught at the plan layer costs 30 seconds. The same plan caught after beads are filed costs 5 minutes. The same plan caught after code is written costs an hour. After code is shipped, days.

Flywheel keeps you in plan-space until the plan converges; in bead-space until the task graph is sound; and only then ships work to code-space. Most AI tools collapse these. We do not.

### 2. The system must remember what it learned

A failure mode observed once is a memory entry. A failure mode observed twice is a hardened pattern. A failure mode observed three times is a canonical rule — promoted, ratified, enforced fleet-wide. This is the trauma-class promotion ladder. It is the difference between a chatbot and a system.

The three-strike threshold is deliberate. It prevents over-canonicalization-of-noise. By the third strike, the pattern has earned its rule.

### 3. Protect at the layer that intercepts the tool, not at a layer the tool bypasses

A shell-layer hook cannot protect a Write tool call. A tool-layer hook cannot protect a Bash command. Whichever attack surface you don't cover is the one that fires.

This sounds obvious until you ship it. We learned this the hard way through four instances of cross-repo doctrine clobbers in twelve hours. The lesson is in the doctrine corpus.

### 4. Default-deny, with an explicit-authorize escape hatch

Destructive operations are gated. Cross-repo writes are denied unless an authorize-list entry exists. Secret-shape outputs halt the agent loop unless they match a known synthetic test fixture.

This sounds slow. It is slow. It is also why the system is still alive after thousands of cycles.

### 5. Reversibility before deletion

Every destructive operation produces a recovery artifact before execution. `git rm` over `rm`. Byte-equality archives before `find -delete`. Git stashes labeled before they're dropped. The receipt outlives the action.

### 6. Multi-pane orchestration is opt-in; single-pane works

Some users will only ever run one pane. The system must work for them. The multi-pane orchestration is a power-user feature, not a foundation; nothing in the basic path depends on it.

### 7. Honesty about what works versus what's in flight

Every status section in this codebase distinguishes shipped from in-flight from planned. If we don't know whether something works, we say so. If a paradigm-level decision was made yesterday and hasn't been validated under load, we say so. Pretending mature usually means breaking later.

### 8. Reading and writing the doctrine matter as much as reading and writing the code

Doctrine documents are load-bearing. They explain *why* and codify *how*. Treat them with the same care you treat tests. When a doctrine document conflicts with running code, one of them is wrong; investigate which.

### 9. Donella Meadows is on the editorial board

The leverage-points framework from *Thinking in Systems* — twelve places to intervene, in increasing order of leverage from numbers to paradigm to "the power to transcend paradigms" — is referenced throughout the doctrine corpus. We use it as the framework for deciding what to fix and at what level.

Bringing more rigor to systems thinking than most AI projects is, frankly, our differentiator.

### 10. Build for someone you can imagine — including yourself in six months

Every artifact is written for a real reader. The README is for the developer encountering flywheel for the first time. The architecture spec is for someone deciding whether to invest. The doctrine corpus is for the orchestrator running its tick at 2 AM after a trauma.

If you can't picture who reads it, don't ship it.

## What we are deliberately not doing

There are good things flywheel will not be.

**A chat UI.** Claude Code and its siblings are the chat UI. Flywheel runs alongside.

**A fully autonomous agent.** Humans approve plan-space and paradigm-level decisions. Workers handle bead-space and code-space execution. The orchestrator coordinates. We are not trying to remove the human; we are trying to make the human radically more leveraged.

**A general-purpose framework.** Flywheel is opinionated. It assumes specific tools, specific patterns, specific reasoning surfaces. If you want a general-purpose multi-agent library, look at [LangGraph](https://langchain-ai.github.io/langgraph/) or [CrewAI](https://github.com/crewAIInc/crewAI). We will use frameworks like those underneath as appropriate; we will not become one.

**A commercial product.** ZestStream is the commercial entity. Flywheel itself is open-source under MIT. If we ever monetize anything in this neighborhood, it will be hosted services or premium support — never the engine.

**A perfect system.** We ship at honest quality. We document what works and what doesn't. We promote rules only after three strikes (except for secrets-class, where one strike is plenty). We are calibrated for real use, not demoware.

## Authority and governance

For now, flywheel is built and maintained by Joshua Nowak with assistance from an AI development substrate (the same substrate the project documents). Decision-making authority on paradigm-level changes rests with Joshua; cross-orchestrator coordination handles bead-space and below.

If this project develops a contributor community, the governance model will move toward something more standard — a small maintainer group, an explicit RFC process for paradigm changes, and a public roadmap. We are not there yet.

In the meantime:

- **Bugs / issues**: file at the public repo when it lands; until then, this README is the source of truth
- **Doctrine proposals**: written as `.md` files with frontmatter; submitted via PR; reviewed for paradigm coherence + cost-of-mistake
- **L-rule promotions**: require evidence of three strikes (or secrets-class qualification) + ratification by at least one other orchestrator
- **Breaking changes**: announced in advance with migration guides

## Inspiration and intellectual debt

Flywheel is not a clean-room invention. It draws heavily from:

- **Donella Meadows** — systems thinking; leverage points; mirror-stage failure modes
- **Daniel Miessler's [PAI](https://github.com/danielmiessler/Personal_AI_Infrastructure)** — three-layer stack; TELOS-as-anchor; containment zones
- **Jeff Emanuel's [NTM](https://github.com/Dicklesworthstone/ntm) and [beads_rust](https://github.com/Dicklesworthstone/beads_rust)** — the substrates flywheel runs on; the inspiration for several of our coordination patterns
- **The Anthropic Claude Code team** — for building the substrate that makes flywheel's orchestration approach viable

We owe these projects + people a lot. Where we have learned from them, we cite them. Where we extend their work, we say so.

## Closing

Flywheel is opinionated, early, and deliberately incomplete. It is built by someone who is using it daily and is willing to ship it under the principle that "share-worthy whether shared or not" forces better discipline.

If you adopt it and it helps: tell us what you built. If it doesn't help: tell us why. Both are valuable signal.

If you ship something built on flywheel that you are proud of, that's the highest compliment.

---

*This charter is part of the flywheel ecosystem. It will evolve as the project matures, but its principles are intended to be stable.*
