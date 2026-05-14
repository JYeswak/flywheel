# Flywheel Charter

Flywheel exists to make AI-assisted software work compound across sessions,
repos, tools, and operators.

The public project should be useful to a business owner, technical lead, or
developer who finds it without knowing Joshua Nowak, ZestStream's private fleet,
or the local pane history that produced it.

A business owner may arrive from social media with a practical problem: five
systems that do not talk to one another, too much manual work, and no clear way
to judge whether an AI operator knows what they are doing. That person may not
need the deep implementation path. They do need enough of the curtain pulled
back to trust the method, the evidence, and the operating discipline.

A developer should be able to go deeper: understand what Flywheel is, install or
detect its substrate, initialize it in their own repo, run a first loop, inspect
the resulting work state, and adapt the system without inheriting private state.

## Audience

Flywheel is for serious builders who already use coding agents and want durable
operational memory instead of one-off chat sessions.

The first public audience is:

- an SMB owner evaluating whether ZestStream can connect fragmented systems,
  reduce manual work, and show credible proof of execution;
- a solo developer running one agent and wanting a safer loop;
- a technical lead coordinating several agent lanes across a repo;
- an operator who needs repeatable AI-native delivery without hiding the
  evidence trail;
- a contributor deciding whether this repo is coherent enough to extend.

Multi-pane orchestration is an advanced path. A single-pane or reduced local
mode must still teach the core loop.

## Commercial Story

Flywheel is both an engine and a proof surface.

The business-facing story is not that an SMB owner should become an agentic
coding expert. It is that ZestStream has taken a fast-moving, advanced AI coding
ecosystem, adopted the latest useful substrate, and wrapped it in a safer,
inspectable operating loop. Each project leaves behind lessons, receipts,
guards, and patterns that make the next project stronger.

The relationship is similar to a network platform making it easy to get a phone:
the platform does not need to manufacture every device to make the experience
work. Flywheel does not claim to have invented every upstream component. It
assembles, verifies, teaches, and operationalizes the substrate so real projects
can use it.

For a non-technical buyer, the public repo should answer: "Do these people know
how to run this kind of AI work safely?" For a technical reader, it should
answer: "Can I inspect, install, test, and improve the loop myself?"

## Public Promise

A public Flywheel release is not complete unless a new operator can do this from
the repo or website:

1. Read what Flywheel owns and what it deliberately does not own.
2. Run a preflight that detects Git, shell, Python, Node, Rust/Cargo, Go,
   SQLite, tmux, Agent Mail, Beads/`br`, NTM, DCG, CASS-style memory, and
   Socraticode where those substrates are available.
3. Get an honest support tier for Claude, Codex, OpenClaw, Gemini, and reduced
   local mode.
4. Initialize Flywheel in a target repo without copying Joshua-specific state.
5. Run `doctor`, `tick`, dispatch-or-simulate, validated closeout, and
   post-run inspection.
6. See the next useful action in Beads, receipts, or doctor output.
7. Remove Flywheel-managed artifacts without orphaning user state.

If a dependency is missing, Flywheel should say whether the operator is blocked,
in reduced mode, or in a documentation-only path.

## Owned Surfaces

Flywheel owns the operational engine around agentic coding:

- repo initialization templates;
- doctrine, L-rules, memory promotion patterns, and closeout contracts;
- Beads task-graph workflow and dependency discipline;
- Agent Mail coordination patterns and file-reservation expectations;
- Socraticode-first investigation gates for non-trivial repo work;
- doctor, tick, dispatch-or-simulate, validated-closeout, and inspection
  command surfaces;
- installer, preflight, uninstaller, and release smoke contracts;
- public docs and website surfaces that teach the first-run journey.

Flywheel should make state transitions visible. It should prefer receipts over
memory, measured gates over claims, and reversible operations over deletion.

## Boundaries

Flywheel does not own every part of the agentic stack.

SkillOS is the capability control plane. SkillOS owns capability-loop substrate,
skill-surface governance, Jeff-stack capability ingestion, research-triad
signal, and validated self-improving skill loops. Flywheel integrates with that
control plane; it does not redefine the SkillOS mission.

Mobile Eats is a product and journey proof surface. Its L170 semantics matter
because they clarify what a real user journey requires: persona, first value,
return loop, guardrail, and evidence quality. Flywheel imports those semantics
into onboarding and smoke tests; it does not own Mobile Eats product meaning.

Red Hat/SMB positioning is a commercial proof surface. It can explain who this
helps and how ZestStream may support it, but it is not the whole mission.

ZestTube and future public project repos are example proof surfaces. They can
show the kinds of systems Flywheel helps ship, but they should not redefine the
Flywheel engine or leak private project state back into it.

## Excluded State

The public package must not depend on, copy, or imply access to:

- Joshua's local paths, pane scrollback, tmux state, or machine-specific files;
- client repositories, client names, private incidents, or undisclosed work
  product;
- secrets, bearer tokens, API keys, access cookies, or secret-shaped examples;
- mutable local ledgers that only make sense inside ZestStream's private fleet;
- halted propagator scripts or any tool that can clobber another repo without an
  explicit authorization contract;
- private SkillOS, Mobile Eats, or ZestStream state used only as source evidence.

Reusable patterns may be extracted only after classification, depersonalization,
manual-review queue closure, and publishability checks.

## Substrate Attribution

Flywheel depends on a Dicklesworthstone-derived substrate and should say so
plainly. Jeff Emanuel's NTM, Beads, Agent Mail, CASS-style memory, destructive
command guard patterns, and related setup processes are upstream inspiration and
operational dependencies, not anonymous internals.

Jeff's ecosystem evolves quickly and contains unusually advanced agentic coding
ideas. Flywheel's public opportunity is to show how those ideas are implemented
inside a working operating system: commentable, inspectable, tested, and tied to
project outcomes. When upstream improves, Flywheel should adopt the useful
change, verify it in the local substrate, and lock in the lesson so future
projects inherit it.

Public install docs should prefer detection and guided setup over silent
assumption. When the full substrate is unavailable, reduced local mode should
still show the operator the shape of the loop without pretending to provide
multi-agent coordination.

## Publishability Bar

Flywheel is public-ready only when the first read and first command are both
credible.

The bar is:

- a new operator can identify the purpose, start path, commands, and limits;
- claims are tied to executable receipts or clearly labeled roadmap work;
- private state is excluded mechanically, not by memory;
- docs and website pages preserve the same first-run journey;
- install and uninstall are idempotent enough to trust;
- every release can show a journey receipt from preflight through inspection;
- public copy reads like ZestStream work: specific, grounded, and free of
  generic agency voice.
- business-facing copy explains the practical value without pretending the
  reader needs to operate the whole substrate themselves.

Passing tests are not enough if they do not cover the public promise above.

## Governance

Until public governance is formalized, paradigm-level changes require Joshua
Nowak's review. Operational work below that level may move through Beads,
receipts, and cross-agent coordination, but the public charter is the gate that
keeps the release honest.

The B0 acceptance gate for public-share readiness is explicit: the landing
commit that introduces or materially changes this charter must include a
`Reviewed-by: Joshua Nowak <joshua@zeststream.ai>` trailer, or the equivalent
trailer from an explicitly authorized delegate.

## Contribution Direction

Good contributions make the loop easier to install, easier to inspect, or safer
to adapt. The most valuable changes usually do one of these:

- reduce setup ambiguity;
- convert a hidden assumption into a doctor signal;
- turn a one-off recovery into a reusable receipt or repair path;
- improve the reduced-mode path without weakening full-mode guarantees;
- clarify boundaries between Flywheel, SkillOS, product repos, and upstream
  substrate projects.

Flywheel is early. The goal is not to look mature; it is to make the real system
legible enough that others can use it, test it, and improve it.
