# Flywheel — Roadmap

> *What we ship next, in what order, and why.*

This roadmap is for adopters who want to know what's coming, and for collaborators who want to know where to help. Dates are intentions, not contracts.

The roadmap is organized into three **waves**, each a coherent investment with shippable outcomes.

---

## Wave 1 — Public-share-readiness foundation (✓ shipped 2026-05-12)

The artifacts in this directory, plus the supporting commits in the parent repo. The intent of Wave 1: establish that flywheel is a real project with real documentation, before any installer ships.

**Shipped:**
- [README.md](README.md) — front door
- [ARCHITECTURE.md](ARCHITECTURE.md) — technical deep-dive
- [CHARTER.md](CHARTER.md) — mission + principles + non-goals
- [ENGINE-OVERLAY-BOUNDARY.md](ENGINE-OVERLAY-BOUNDARY.md) — what's public vs private
- [INSTALLER-DESIGN.md](INSTALLER-DESIGN.md) — specification for `curl | bash` with safety guarantees
- [HELLO-WORLD.md](HELLO-WORLD.md) — 20-minute minimal working example
- [LICENSE](LICENSE) — MIT

**Decisions ratified in Wave 1:**
- License: MIT
- Methodology name retained: "flywheel"
- Hosting target: `flywheel.zeststream.ai` (subdomain of existing ZestStream property)
- Single-pane fallback supported in v0.1; multi-pane is opt-in
- Bleeding-edge paradigm work (substrate-class L162, tenant-isolation L164/L168) deferred to v0.2

## Wave 2 — Shippable engine (target: June 2026)

The transition from "we wrote about it" to "you can install it."

### Wave 2a — De-personalization sweep (~2 weeks of orchestrated agent work)

Audit the existing doctrine corpus (~30 documents) and memory rules (~150 entries) and classify each per the [engine/overlay boundary](ENGINE-OVERLAY-BOUNDARY.md). Two output trees:

- `engine/doctrine/` — universal patterns; published with the engine
- `engine/memory/` — universal memory rules; published
- `overlay/...` — anything instance-anchored stays in the user's private overlay

Specific patterns to apply during the sweep:

- Replace specific names (`Joshua`, client names) with `{operator}`, `{client-A}`, etc.
- Replace specific dates with `{date}` or "the source incident" when not load-bearing
- Replace specific repo paths with parameters
- Replace specific bead IDs with `{bead-id}` placeholders
- Preserve all paradigm-level content; remove all instance-level content
- Where a rule cites a real past incident for emphasis, abstract the incident to the pattern

### Wave 2b — Installer implementation (~1 week)

Per [INSTALLER-DESIGN.md](INSTALLER-DESIGN.md):

- Implement `install.sh` to the design contract
- Implement `uninstall.sh` to the design contract
- Implement `flywheel doctor --post-install`
- SHA-256 release signing pipeline
- Versioned releases (start at `v0.2.0`)
- Hosting at `flywheel.zeststream.ai/install.sh`

### Wave 2c — Public repo extraction (~3 days)

Once the de-personalization sweep is complete:

- Initialize standalone repository at `github.com/JYeswak/flywheel` (or `github.com/JYeswak/zeststream-flywheel` — naming TBD)
- Migrate `public-share/` artifacts to the new repo root
- Migrate engine doctrines + memory + scripts + hooks
- Publish v0.2.0 with release notes
- Update the README in the current `flywheel` (private) repo to point at the public engine
- Verify `curl | bash` works end-to-end

### Wave 2d — Hello-world example repo (~2 days)

The hello-doctor example from [HELLO-WORLD.md](HELLO-WORLD.md) shipped as a standalone, clone-able example repo. Includes:

- The working tool
- A pre-populated `.flywheel/` directory showing what completed substrate looks like
- A `cycle-2-tutorial.md` showing how to extend the example into a second cycle

## Wave 3 — Adoption surface (target: July-August 2026)

Once people can install flywheel, make it easy for them to learn it, contribute to it, and surface what they build.

### Wave 3a — Documentation website (~2 weeks)

Hosted at `flywheel.zeststream.ai`. Built with Nextra (we already have a [`documentation-website-for-software-project`](https://github.com/JYeswak/flywheel/tree/main/skills/documentation-website-for-software-project) skill).

Top-level structure:
- Home (the README, polished)
- Quickstart (an enhanced HELLO-WORLD)
- Concepts (the architecture; the 9 petals; reasoning spaces; trauma promotion)
- Reference (every L-rule + every doctrine, browsable)
- Skills catalog (the public skills, with examples)
- Cookbook (patterns people send in)
- Changelog

### Wave 3b — Dashboard (~1 week)

A local terminal-UI (or web-UI) for inspecting flywheel runtime state:
- Current cycle status
- In-flight bead dispatches
- Recent cross-orch handoffs
- Trauma ledger
- Skill catalog freshness

PAI ships this at `localhost:31337` and it's good. We borrow the pattern.

### Wave 3c — Governance + contribution (~3 days)

- `CONTRIBUTING.md` — how to propose new doctrines, skills, patterns
- `CODE-OF-CONDUCT.md` — standard
- RFC process for paradigm-level changes (L-rule promotions, substrate-class extensions)
- Maintainer model (start: one maintainer; explicit path to expansion)
- First-issue labels for new contributors

### Wave 3d — Plugin / skill marketplace pattern (~1 week)

Public distribution model for skills. Options under consideration:
- Pure GitHub-search-based (skills declare themselves with a `flywheel-skill: true` marker)
- Centralized registry at `flywheel.zeststream.ai/skills/`
- Piggyback on Anthropic's skill marketplace if/when that ships

Decision pending after observing real adoption patterns.

## Wave 4 — Ecosystem maturity (open-ended)

Long-horizon work, sequenced opportunistically as the project matures.

- **Telemetry (opt-in only)** — anonymized usage stats so we know what's working publicly. Strict zero-PII contract.
- **Conformance test suite** — for forks and downstream variants to claim compatibility
- **Versioned migration guides** — for v1.0 → v2.0 transitions and any breaking changes
- **Community forum** — Discord or Discourse, depending on maintainer bandwidth
- **First public talk / blog post** — if and when there's a real adopter story worth telling

We will not do Wave 4 things until they're clearly load-bearing for adopters.

## What this roadmap deliberately doesn't promise

- **A specific date for Wave 2 GA.** We ship when it's good, not when the calendar says we should.
- **Feature parity with PAI or LangGraph or CrewAI.** We're not trying to match feature lists; we're trying to provide a different shape of value.
- **Enterprise support.** Flywheel is open-source under MIT. If hosted services or premium support ever exist, they'll be a separate offering.
- **A migration path for arbitrary AI tooling.** Flywheel is opinionated about its substrate (Claude Code, NTM, beads). If you're using a fundamentally different stack, parts of this won't apply.

## How to influence the roadmap

When public adoption begins (Wave 2 ship):

- Open an issue at the public repo with concrete use-cases
- Propose RFCs for paradigm-level changes via the process documented in `CONTRIBUTING.md`
- Send pull requests for skill additions, doctrine refinements, or new patterns

Until then: this roadmap is a one-person plan. We'll widen the input surface as the project matures.

---

*This roadmap is a living document. It will be revised when assumptions change. The principles in [CHARTER.md](CHARTER.md) are stable; the timelines and sequencing here are not.*
