# Flywheel

Flywheel is the repo-local operating loop I use to make AI-assisted software
work visible, repeatable, and safer to trust.

I built it after 25+ years inside operations work: banking, finance, energy,
telecom, business management, team building, and AI. The pattern kept showing
up before the AI tools existed. Important work gets scattered across people,
systems, notes, approvals, and follow-up. If the route is not visible, the work
depends on memory. If the work depends on memory, the same problems come back.

Flywheel turns that operating discipline toward coding agents. A repo gets a
mission, a current goal, a state file, a loop tick, a way to route work, a way
to inspect what happened, and a receipt when the loop closes. The point is not
to make every reader an agent-systems expert. The point is to show the method
well enough that you can study it, run it, and decide what you trust.

## The Foundation

Flywheel stands on open-source work from
[Jeffrey Emanuel](https://www.jeffreyemanuel.com), also known as
Dicklesworthstone. I cite that directly because attribution is part of the
method.

| Jeffrey substrate | What it gives the work |
|---|---|
| NTM | Named terminal sessions and panes so agent work has stable places to run. |
| Agent Mail | Durable messages, acknowledgements, and thread history between agents. |
| beads | A local issue graph for work, blockers, dependencies, and close evidence. |
| CASS | Memory patterns so useful context does not live only in one transcript. |
| jsm, dcg, ubs | Skill movement, destructive-command safety, and shell discipline that keep the lower layer honest. |

Flywheel and SkillOS are my layer around that substrate. They can run a reduced
public path without private panes, Agent Mail archives, or my local skill
library. When Jeffrey Emanuel's tools are installed, they can also use the
richer local substrate. Flywheel owns the repo-local loop. SkillOS owns
capability status: which skills exist, which ones are adopted, which ones are
blocked, and which ones have proof.

## What This Repo Is

This repository packages the public Flywheel engine:

- repo-local `MISSION.md`, `GOAL.md`, `STATE.md`, and loop config templates;
- doctors, smoke tests, public first-run checks, and closeout receipts;
- install templates for `.flywheel/` state inside another repo;
- public docs for first run, release checks, local GitHub-style preflight, and
  agent-lane support;
- story, naming, safety, and publication evidence used to keep the repo from
  leaking private operator state.

Reduced mode is the required public path. It proves the core loop without
assuming private NTM panes, Agent Mail archives, or a local skill library. Full
mode can use the richer substrate when it is installed.

## How It Works

The loop is intentionally small:

1. **Name the mission.** The repo says what kind of work it owns.
2. **Name the current goal.** The loop keeps one bounded target visible.
3. **Read state before acting.** Agents start from repo-local state, not stale
   memory.
4. **Run a tick.** The tick inspects the repo and chooses the next safe action.
5. **Route bounded work.** Work moves through beads, files, docs, or scripts
   instead of one long chat.
6. **Validate before claiming.** Tests, doctors, and receipts decide what is
   proven.
7. **Keep the lesson.** Useful patterns move into docs, skills, packs, or gates
   so the next repo starts with more of the map.

That is the Flywheel idea: a repo should get smarter as work passes through it.

## Honest State

Flywheel is early public infrastructure. The reduced local path is the trust
floor. Full substrate support depends on what you have installed and what has a
current receipt. A recent public-export receipt shows the intended boundary:
Flywheel classified 14,759 source files, copied 10,274 public-safe files,
excluded 4,043 denylisted paths, and retained a 7,465-row manual-review queue
as evidence while turning a private substrate into an inspectable public one.
That number is a receipt, not a boast; the next export can change it.

The current evidence map lives in
[`docs/evidence/publication-evidence.md`](docs/evidence/publication-evidence.md).

## Take It

When the public repos are live, the normal path is:

```bash
git clone https://github.com/JYeswak/flywheel.git
git clone https://github.com/JYeswak/SkillOS.git
cd flywheel
bash install.sh --dry-run --json
bash install.sh --json
```

The installer is scoped to `~/.flywheel/engine`, and dry-run is available before
files are copied. For a first repo-level proof, start with:

```bash
scripts/preflight.sh --json
scripts/journey-smoke.sh --matrix reduced --dry-run --json
```

Then read [`docs/getting-started/first-run.md`](docs/getting-started/first-run.md).
The hosted `https://flywheel.zeststream.ai/install.sh` endpoint is a checksum
mirror for the same release asset, not a curl-only standalone installer. Clone
the repo or extract the release tarball first so the installer can see its
sibling `scripts/`, `bin/`, and template files.
For Jeffrey Emanuel substrate monitoring, the canonical local helper is
`.flywheel/scripts/jeff-intel-network.sh`; it is an operator surface, not a
requirement for the reduced public first run.

## The Deal

You can use Jeffrey Emanuel's tools directly. You can clone Flywheel and SkillOS
and run the public path without me. The choice is yours: start standalone, add
the richer substrate later, or use only the parts that fit. I am publishing the
method because trust is earned faster when the work is inspectable.

If you want help applying it to a real business workflow, book a 20-minute Peel
session. Free, specific, no pitch at the end:
[`flywheel.zeststream.ai/contact`](https://flywheel.zeststream.ai/contact).

## Study Map

| If you want to understand... | Read |
|---|---|
| The charter and public boundary | [`CHARTER.md`](CHARTER.md) |
| The architecture | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| The first run | [`docs/getting-started/first-run.md`](docs/getting-started/first-run.md) |
| Public release checks | [`docs/runbooks/public-release-runbook.md`](docs/runbooks/public-release-runbook.md) |
| Final cutover boundary | [`docs/runbooks/release-cutover-authorization.md`](docs/runbooks/release-cutover-authorization.md) |
| Local GitHub-style preflight | [`docs/runbooks/local-actions-preflight.md`](docs/runbooks/local-actions-preflight.md) |
| Agent-lane compatibility | [`docs/runbooks/agent-lane-compatibility.md`](docs/runbooks/agent-lane-compatibility.md) |
| Context and model routing | [`docs/runbooks/context-and-model-routing.md`](docs/runbooks/context-and-model-routing.md) |
| Naming | [`docs/brand/naming-conventions.md`](docs/brand/naming-conventions.md) |

## For Operators And Contributors

Contributor workflow, DCO, beads usage, full-substrate quickstart, callback
details, and worker checklist live in [`CONTRIBUTING.md`](CONTRIBUTING.md).
`AGENTS.md` remains the operating doctrine for automated agents working inside
this repo.

For public-surface changes, run:

```bash
bash tests/public-top-level-files.sh
bash tests/public-docs.sh
bash tests/website-static.sh
scripts/zs-frontend-quality-gate.sh --repo "$PWD" --json
```
