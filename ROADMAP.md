# Flywheel Roadmap

> Phased control-plane buildout. Receipts over promises.

Mission anchor:

> *continuous-orchestrator-uptime-self-sustaining-fleet*

The detailed source of truth lives in `.flywheel/PLANS/`. This roadmap is the
front-door view: what the repo is becoming, which plans own the work, and how we
know a phase is done.

Status legend: shipped, partial, planned.

## Phase 0: Doctrine and Loop Substrate

**Status:** shipped, still accreting.

**Scope:** canonical L-rules, repo-local `.flywheel/` install templates,
`flywheel-loop` doctor/tick/receipt surfaces, and the core Beads workflow.

**Evidence:** `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`,
`templates/flywheel-install/`, and the L120-L128 close path.

## Phase 1: Dispatch Enforcement

**Status:** partial.

**Plan:** `.flywheel/PLANS/dispatch-enforcement-2026-05-01.md`

**Scope:** wrapper-required dispatch, callback grammar, pane-state source, mission
fitness, topology proof, and dispatch-log schema v2. The dispatch-trust tripod
is the current load-bearing line: callback contract, wrapper proof, and NTM
pane-state proof.

**Done when:** dispatch rows can be trusted as the replayable source for who was
sent what, why, with which pane-state proof, and what callback closed it.

## Phase 2: Recovery System

**Status:** partial.

**Plan:** `.flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md`

**Scope:** preinstall audit, per-session launchd watcher plists, exactly-one-label
invariants, skillos/flywheel/product repo coverage, recovery snapshots, and
doctor coverage drift.

**Done when:** every active fleet session has an installed, validated,
doctor-visible reboot recovery path with receipts and no stale duplicate labels.

## Phase 3: Plan Convergence Proved With Data

**Status:** shipped as doctrine, active as enforcement.

**Plan:** `.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/`

**Scope:** the Brenner wires: hypothesis slate, prediction lock, idea-duel
deltas, convergence telemetry, EV anchors, and `/brenner` evidence surfaces.

**Done when:** every high-risk plan can prove convergence with data and close
refuses post-hoc rationalization.

## Phase 4: Autonomous Loop and Fleet Fairness

**Status:** planned/partial.

**Plans:** `.flywheel/PLANS/`, especially autonomous-loop and fleet-coherence
arcs.

**Scope:** event-driven Monitor wake, autoloop fairness, hot-pane refill, peer
orchestrator drift alerts, idle-state classification, and fleet health as a
single composite signal.

**Done when:** work does not sit idle while the substrate already knows the next
safe action.

## Phase 5: Ecosystem Polish

**Status:** this bead seeds it.

**Scope:** root docs, GitHub templates, sediment policy, reusable
`ecosystem-polish-scaffold` skill, and three-judges receipts.

**Done when:** every ZestStream repo can run the same scaffold and produce a
clean, evidence-led, low-noise project surface without hand-copying flywheel
docs.

## Quality Bar

Front-facing surfaces get the Jeff / Donella / Joshua sniff:

- **Jeff:** schema, provenance, versioning, and no invented substrate.
- **Donella:** structure-level leverage, rules, information flows, feedback
  loops, and reusable scaffolds.
- **Joshua:** direct voice, receipts over claims, no filler.

The bar is measured in receipts, not adjectives.
