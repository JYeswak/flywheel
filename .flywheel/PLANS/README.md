---
title: Flywheel multi-phase plans
type: readme
created: 2026-05-10
auto_generated: true
bead: flywheel-s8tdd
parent: filesystem-as-rag
---

# `.flywheel/PLANS/`

Multi-phase planning artifacts authored by the `/flywheel:plan` skill
(5-phase pipeline: RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH).
Each subdirectory is one plan, durable across Claude Code sessions.

## Naming convention

`<plan-slug>/` — one directory per plan. Slug derived from the plan
topic (kebab-case).

## Canonical contents

| File | Purpose |
|---|---|
| `STATE.json` | machine-readable plan progress (current phase, round counts, convergence flags) |
| `intent.md` | original intent statement (Phase 0 input) |
| `research.md` | Phase 1 research outputs (multi-source citations) |
| `plan-v<N>.md` | iterative plan rounds (Phase 2 REFINE) |
| `audit-v<N>.md` | jeff-convergence-audit reports (Phase 3) |
| `beads.md` | decomposed bead graph (Phase 4) |
| `polished/` | per-round bead-polish artifacts (Phase 5) |
| `transcripts/` | full per-phase conversation logs |

## STATE.json schema

```json
{
  "schema_version": "flywheel-plan-state/v1",
  "plan_slug": "<slug>",
  "current_phase": "RESEARCH|REFINE|AUDIT|DECOMPOSE|POLISH|complete",
  "phase_round_counts": {"RESEARCH": 1, "REFINE": 3, ...},
  "convergence": {"audit_pass": true, "polish_rounds": 6},
  "started_at": "<iso>",
  "last_updated": "<iso>"
}
```

## Lifecycle

Plans are append-only during their lifetime. After bead decomposition
lands, the plan dir remains as historical receipt. Per F2 lint rule,
this dir must have either a README.md (this file) or canonical
content for each plan slug.

## Cross-references

- `/flywheel:plan` skill — `~/.claude/skills/flywheel/plan.md`
- Doctrine: `.flywheel/doctrine/filesystem-as-rag.md`
- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
