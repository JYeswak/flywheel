---
title: "Skill Autoresearch Tooling Preference Class"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# Skill Autoresearch Tooling Preference Class

## Rule

`skill-autoresearch` is suited for Python-operational skill targets. It is not
the primary evaluator or rewrite driver for shell-first flywheel surfaces.

Shell-first targets must be routed through explicit shell tooling guidance:
existing entrypoints, canonical CLI scoping, `doctor` / `health` / `repair`,
`validate` / `audit` / `why`, `--dry-run` / `--apply`, JSON schemas, stable
exit codes, Beads ownership, and JSM mutation discipline.

Python-friendly targets may use `skill-autoresearch` when the target skill is
intended to own Python operational tooling, especially `skill-builder`-managed
skills where a Python script under `scripts/` is the expected substrate.

## Evidence

The `skill-autoresearch` contract is Python-biased at the operational tooling
gate:

| Source | Evidence |
|---|---|
| `/Users/josh/.claude/skills/skill-autoresearch/SKILL.md:107` | Gate 6 measures a Python script with dataclasses, `--config`, and JSON mode. |
| `/Users/josh/.claude/skills/skill-autoresearch/references/enhancement-patterns.md:46` | Missing-structure repair creates `scripts/` with an operational Python script. |
| `/Users/josh/.claude/skills/skill-autoresearch/references/gate-rubric.md:244` | Operational tooling explicitly scores the quality of Python files in `scripts/`. |
| `/Users/josh/.claude/skills/skill-autoresearch/scripts/skill-grader.py:942` | The scorer implements Gate 6 as Python tooling quality. |

The grader also has a process-skill accommodation: process skills can zero out
operational tooling and source weights. That helps lean skills, but it does not
make `skill-autoresearch` a good fit for shell-first flywheel skills that own
real shell CLIs and orchestration contracts.

## Failure Beads

These beads closed scope-pass but below the four-lens quality bar because the
target class and evaluator substrate disagreed:

| Bead | Target | Reported Score | Root Cause | Routing |
|---|---|---:|---|---|
| `flywheel-spdu` | `beads-br` skill enhancement | `brand:4,sniff:4,jeff:5,public:3` | `skill_autoresearch_operational_tooling_python_preference_mismatch` | Park as known-pattern-mismatch; re-author with shell-first guidance. |
| `flywheel-2gvl` | `mutation-safety-contract` skillos request | `brand:4,sniff:5,jeff:5,public:4` | Same mismatch class | Park as known-pattern-mismatch; re-author as shell-first contract request. |
| `flywheel-njzi` | `ipc-transport-contract` skillos request | `brand:4,sniff:5,jeff:5,public:4` | Same mismatch class | Park as known-pattern-mismatch; re-author as transport-shell contract request. |

Do not redispatch these as-is. Any successor work must state the shell-first
substrate before asking a worker to enhance or draft a skill.

## Working Pattern

These beads applied similar Jeff-derived patterns without falling into the
Python-vs-shell mismatch class:

| Bead | Surface | Score Band | Why It Worked |
|---|---|---:|---|
| `flywheel-werb` | `agent-memory` | 8-9 | Treated the target as memory/doctrine workflow, not Python tooling. |
| `flywheel-w304` | `accretive-cron-orchestration` | 8-9 | Preserved orchestration shell contracts and cadence receipts. |
| `flywheel-puwl` | `agent-orchestration` | 8-9 | Kept agent orchestration as an operational protocol surface. |
| `flywheel-raq3` | `validation-fixture-contract` | 8-9 | Anchored changes in fixtures and validation receipts. |
| `flywheel-cmf4` | `failure-taxonomy-receipts` | 8-9 | Routed the pattern through durable receipt taxonomy. |

## Routing Table

| Target Class | Examples | Primary Route | `skill-autoresearch` Role |
|---|---|---|---|
| Shell-first flywheel skill | `canonical-cli-scoping`, `jsm`, `beads-br`, `agent-orchestration` | Shell-first packet guidance plus local tests | Forbidden as primary evaluator; optional reference only after shell contract is explicit. |
| Skillos request for shell contracts | `mutation-safety-contract`, `ipc-transport-contract` | Re-author request with shell-first acceptance gates | Forbidden as primary evaluator. |
| Python-operational skill | `skill-builder`-managed skill with intended Python `scripts/` tool | `skill-autoresearch` loop | Allowed. |
| Unknown skill-enhance target | No target skill or ambiguous substrate | Add routing note or park as `known-pattern-mismatch` | Review required. |

## Dispatch Contract

`build-dispatch-packet.sh` now emits a `SKILL-AUTORESEARCH TOOLING PREFERENCE
BLOCK` for skill-enhance packets. The block classifies detected target skills
and sets `skill_autoresearch_primary_route` to:

| Value | Meaning |
|---|---|
| `forbidden` | Shell-first target detected. Use shell-first tooling guidance. |
| `allowed` | Python-friendly target detected. `skill-autoresearch` can drive the loop. |
| `review_required` | Target class is unknown. Add a routing note before dispatch. |

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:8,public:9`

Public lens: a skeptical operator can see exactly which dispatches to avoid, a
maintainer can verify the packet block and test, and a future worker can route
successor skill-enhance work without redispatching the failed beads.
