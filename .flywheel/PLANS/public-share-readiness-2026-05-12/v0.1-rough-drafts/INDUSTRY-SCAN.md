# Industry Scan — what we borrowed, where we differ

> *An honest survey of adjacent projects and how flywheel positions among them. Updated 2026-05-12.*

This document exists for two reasons. First, to acknowledge the projects flywheel builds on — there is no clean-room invention here, and credit should be visible. Second, to be specific about where flywheel is genuinely different versus where we're traveling the same road.

The selection criterion was: "if a thoughtful developer evaluating flywheel asked us 'how is this different from X?', X should be in this list."

---

## Personal AI Infrastructure (PAI) — Daniel Miessler

**Repository:** [github.com/danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure)

**What it is:** A "Life Operating System" framing of personal AI. Three-layer stack (PAI OS / Pulse / DA), branded UX with a localhost dashboard at port 31337, one-line install, TELOS-as-mission-anchor, structured memory across 5 tiers (WORK/KNOWLEDGE/LEARNING/RELATIONSHIP/OBSERVABILITY), and an explicit 7-phase Algorithm (OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN).

**What we borrowed:**
- The three-layer-stack framing as a teaching tool for engine vs overlay separation
- TELOS-as-anchor concept (we use MISSION.md; same idea)
- Containment-zone pattern enforced via PreToolUse hooks (we extended into the cross-repo write guards)
- One-line install ergonomics as a non-negotiable for adoption

**Where flywheel is different:**
- **Multi-pane orchestration.** PAI is single-DA. Flywheel ships a bilateral cross-orchestrator protocol with structured handoffs and ratification. Different audience: PAI optimizes for an individual; flywheel optimizes for someone running multiple parallel AI workstreams who needs coordination.
- **Trauma-class promotion ladder.** PAI has no visible equivalent. Our N=1 → N=2 → N=3 → canonical-rule path is core to how flywheel learns; without it, the system is just a collection of skills.
- **Three reasoning spaces (plan/bead/code).** PAI's Algorithm is closer to a linear pipeline. Our explicit cost-of-mistake differentiation between layers is a sharper tool.
- **Doctor/health/repair CLI triad as a foundational pattern.** Every CLI in flywheel ships with all three; PAI doesn't enforce this.

**Where PAI is ahead:**
- Branded UX. PAI has a name people can say; "flywheel" is descriptive.
- One-line install is shipped; ours is specified but not yet built.
- Localhost dashboard. We have data; we don't yet have a presentation layer.

## Aider — Paul Gauthier

**Repository:** [github.com/paul-gauthier/aider](https://github.com/paul-gauthier/aider)

**What it is:** A repository-aware AI pair programmer. Reads your git history, understands your project structure, applies AI-suggested edits with explicit diffs, runs your test suite, commits with structured messages.

**What we borrowed:**
- Repository-awareness as a first-class concern (flywheel's `.flywheel/` directory + canonical CLI scoping doctrine carry the same intent)
- Structured commit message conventions
- The cycle of *think → edit → test → commit* as a unit

**Where flywheel is different:**
- Aider is a *tool that pair-programs*. Flywheel is a *substrate that compounds*. Aider is excellent at the inner loop; flywheel is about what survives between inner loops.
- Flywheel's multi-pane orchestration model assumes you're running multiple AI agents in parallel; Aider is single-process.
- Aider's task model is implicit (the current diff). Flywheel makes the task graph explicit via beads.

**Recommendation:** these tools compose. Use Aider for in-loop AI pair programming; use flywheel for cross-loop substrate accretion.

## LangGraph (LangChain) — Harrison Chase et al.

**Repository:** [github.com/langchain-ai/langgraph](https://github.com/langchain-ai/langgraph)

**What it is:** A library for building stateful, multi-agent applications as directed graphs. Nodes are agents or functions; edges are control flow; state is explicit. Used widely for production AI workflows.

**What we borrowed:**
- Graph-structured workflow as a mental model (the 9 petals are a cycle; the bead dependencies are a DAG)
- State-as-first-class-citizen — flywheel's `.flywheel/` directory is essentially a typed state store
- The principle that orchestration is fundamentally a graph problem

**Where flywheel is different:**
- LangGraph is a *library you build with*. Flywheel is a *system you run alongside*. Different shape of product.
- LangGraph nodes typically execute in the same process; flywheel workers run in separate Claude Code panes.
- LangGraph emphasizes orchestration of LLM calls; flywheel emphasizes orchestration of *agentic sessions* (which contain many LLM calls each).
- LangGraph doesn't have a doctrine corpus, trauma-promotion ladder, or cross-process learning substrate.

**Recommendation:** if you're building a production application where AI agents are first-class infrastructure, use LangGraph. If you're a developer trying to make your own AI-assisted coding productivity compound, flywheel is the closer fit.

## CrewAI — João Moura

**Repository:** [github.com/crewAIInc/crewAI](https://github.com/crewAIInc/crewAI)

**What it is:** A framework for orchestrating role-playing AI agents that collaborate on tasks. Agents have explicit roles (researcher, writer, critic), structured handoffs between them, and a clear "crew" concept.

**What we borrowed:**
- The notion of agents-with-roles as a teaching frame (orchestrator and worker have distinct responsibilities)
- Structured inter-agent handoffs (CrewAI does this in-process; we do it via filesystem)

**Where flywheel is different:**
- CrewAI agents are *LLM-driven personas* in the same process. Flywheel workers are *separate processes* (panes) each running their own AI agent.
- CrewAI's role abstraction is for *collaboration on one task*. Flywheel's orchestrator/worker abstraction is for *parallel execution of many tasks*.
- CrewAI has no equivalent to flywheel's trauma-promotion ladder, substrate-class classifier, or doctrine corpus.

## Microsoft AutoGen

**Repository:** [github.com/microsoft/autogen](https://github.com/microsoft/autogen)

**What it is:** A framework for multi-agent conversation. Agents talk to each other (and to humans) via structured conversation patterns. Strong on agent-to-agent dialogue.

**What we borrowed:**
- The recognition that agent-to-agent coordination is fundamentally a communication problem
- The pattern of structured-conversation-as-coordination-primitive (our cross-orch handoffs are a filesystem-mediated variant)

**Where flywheel is different:**
- AutoGen conversations are turns of dialogue between AI agents. Flywheel cross-orch handoffs are durable filesystem artifacts that survive process restarts.
- AutoGen optimizes for emergent intelligence from multi-agent conversation. Flywheel optimizes for *explicit coordination of independent agentic sessions* — less emergent, more auditable.

## OpenAI Swarm

**Repository:** [github.com/openai/swarm](https://github.com/openai/swarm) (experimental at time of writing)

**What it is:** OpenAI's reference implementation of lightweight multi-agent orchestration. Minimal, educational, focused on the handoff primitive between agents.

**What we borrowed:**
- The handoff primitive as a first-class concept
- The minimalism — flywheel tries to be similarly composable (you can use as much or as little as you want)

**Where flywheel is different:**
- Swarm is intentionally minimal/educational. Flywheel is a working personal system being open-sourced; it has more opinions and more surface area.
- Swarm is OpenAI-API-shaped. Flywheel is agent-CLI-shaped (Claude Code, codex, etc.).

## Cursor and Windsurf — IDE-embedded AI

**What they are:** AI-native IDEs. Cursor (Anysphere) and Windsurf (Codeium) are full-fledged editor environments where AI is deeply integrated into the editing experience.

**What we borrowed:**
- The recognition that AI productivity benefits enormously from being deeply integrated with the project context
- The pattern of multi-file edits as first-class operations

**Where flywheel is different:**
- Cursor/Windsurf are IDEs. Flywheel is a substrate that lives alongside *any* CLI-based agent workflow.
- Cursor/Windsurf are commercial products. Flywheel is open-source under MIT.
- Cursor/Windsurf optimize the inner edit loop. Flywheel optimizes the outer cycle (what accretes between editing sessions).

These are not competitors; they're complements. A user might use Cursor for daily editing, Claude Code for agentic dispatches, and flywheel as the substrate that ties their work together over time.

## Adjacent thinking — Donella Meadows

**Source:** *Thinking in Systems: A Primer* (2008)

**Why this is in an industry scan of AI projects:** because the substrate of flywheel's design discipline is systems thinking, not AI engineering. The leverage-points framework (12 places to intervene in a system, in increasing order of leverage from numbers to paradigms to "the power to transcend paradigms") is referenced throughout flywheel's doctrine corpus.

**What we borrowed:**
- The 12-leverage-points framework as a tool for choosing interventions
- The mirror-stage failure mode (when a system's mitigation has to be applied inside the same boundary it tries to protect — what we call substrate-class self-awareness)
- The principle that paradigm-level changes are highest-leverage but cheapest to fix early

**Why we cite this here:** AI tooling discussions often default to feature comparisons and benchmark battles. The deeper differentiator between systems is the rigor with which they apply systems thinking. We mention Meadows here so prospective adopters know what intellectual tradition we're working in.

## Positioning summary

If you arrived at flywheel from:

- **PAI** — flywheel is what you get if you add multi-pane orchestration, an explicit learning ladder, and three-reasoning-space discipline to the PAI architecture
- **Aider** — flywheel is the cross-session substrate that makes Aider's per-session work compound
- **LangGraph / CrewAI / AutoGen** — flywheel is at the *meta-orchestration* layer (orchestrating sessions of agents, not orchestrating agents within a session). You can use these libraries inside individual flywheel workers.
- **Cursor / Windsurf** — flywheel is the cross-IDE substrate; nothing precludes using both
- **An academic systems-thinking background** — flywheel is one of the rare AI projects that takes Meadows seriously at the doctrine layer; we'd love to hear from you

## What's missing from this scan

We are not exhaustive. Specifically:

- **Multi-agent frameworks** in adjacent ecosystems (Microsoft Semantic Kernel, AutoGPT, BabyAGI variants). Most of these are early-stage or in maintenance mode; they're worth knowing about but didn't shape flywheel directly.
- **Code-generation evaluation suites** (HumanEval, SWE-bench). Flywheel is not in this space; we don't optimize for benchmark scores.
- **Anthropic's own future skill marketplace.** When it ships, it may overlap with flywheel's skill catalog conventions. We'll integrate; we won't compete.

If we missed an adjacent project that's load-bearing for adopters to know about, please open an issue.

---

*This document is part of the flywheel ecosystem. It will be updated as the adjacent project landscape evolves.*
