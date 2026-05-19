---
title: "skill-discoveries-aggregator doctrine"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# skill-discoveries-aggregator doctrine

**Bead origin:** flywheel-4s3oy.
**Donella triage:** "skill discoveries are filed in every callback (sd_ids field)
but nothing reads them back. ~5-15 skill discoveries per session vanish into
log files. A stock nobody can query is functionally not a stock."

## Stock vs flow framing

Each worker callback emits a `skill_discoveries=N sd_ids=<list>` envelope and
appends a `skill-discovery/v1` row to
`~/.local/state/flywheel/skill-discoveries.jsonl`. That's the *flow*. The
question Donella asks: where's the *stock*? What does the accumulated row
history *tell us about ourselves over time*?

Without a periodic rollup, the answer was nowhere. Each row was filed, then
read by exactly nobody. Same paradigm-tier failure as L62 / L63: a substrate
is filed but not surfaced.

## Pipeline

```
~/.local/state/flywheel/skill-discoveries.jsonl
        │
        ▼
.flywheel/scripts/skill-discoveries-aggregator.sh
   --apply [--week=YYYY-WW] [--out=...]      (read-only on the source jsonl)
        │
        ▼
.flywheel/reports/skill-discoveries-weekly-<YYYY-WW>.md
```

## Sources read (read-only)

| Source                                        | Purpose                          |
|-----------------------------------------------|----------------------------------|
| `~/.local/state/flywheel/skill-discoveries.jsonl` | primary truth (one JSON per row) |
| `.flywheel/dispatch-log.jsonl`                | cross-reference (presence probe) |
| `.flywheel/audit/<bead>/evidence.md`          | prose mention discovery          |

The schema in skill-discoveries.jsonl is heterogeneous (different rows have
different keys depending on which worker filed them). The aggregator
normalizes:

| Normalized field | Source priority                                         |
|------------------|---------------------------------------------------------|
| `candidate`      | `candidate_skill_name` → `topic` → `proposed_skill` → `<unknown>` |
| `kind`           | `discovery_kind` → `kind` → `unknown`                  |
| `worker`         | `worker_identity` → `worker-N` (from `worker_pane`) → `unknown` |

## Output sections (AG3)

- **Headline** — total entries / unique candidates / distinct workers in the week
- **Top N most-cited classes** — frequency-ranked, default `TOP_N=10`
- **First-time-this-week** — candidates with no prior occurrence anywhere in the source
- **Cross-worker agreements** — the load-bearing section: a class cited by
  ≥2 distinct workers means convergent evolution → strong promotion signal
- **By kind** — distribution across `pattern-emerged`, `pattern-recurrence`,
  `skill-found-but-incomplete`, etc.
- **By worker** — who filed what
- **Long-tail** — one-off observations to scan for sleeper hits

## Cadence

- Launchd label: `ai.zeststream.skill-discoveries-weekly`
- Sunday 09:00 local (post-Petal-9 of the prior week)
- Idempotent: skip if this week's report exists

## Boundary (this bead is OBSERVE only)

- Read-only on the source jsonl
- No mutations to closed beads
- Rollup is markdown for Joshua skim + structured JSON envelope for future
  automation
- **Auto-promotion of frequent classes to canonical L-rules is OUT OF SCOPE**
  for this bead. That's a separate followup once the rollup has burned in for
  several weeks and Joshua has read enough to validate the threshold for
  promotion.

## CLI doctrine (canonical-cli-scoping triad)

- `--info` (help)
- `--schema` (one-line emit schema)
- `--examples` (curated invocations)
- `--doctor [--json]` (read-only health probe of source jsonl)
- `--apply [--week=YYYY-WW] [--out=PATH] [--json]` (mutation: writes report)
- Stable exit codes: 0 success, 1 internal, 2 bad arg / missing dep, 3 empty week

## Schema

Rollup envelope validates against
`.flywheel/validation-schema/v1/skill-discoveries-weekly.v1.schema.json`
(schema_version: `skill-discoveries-weekly.v1`).

## Read recipe for Joshua

A 90-second skim:
1. **Cross-worker agreements** first — if 2+ workers independently file the
   same class, that's a candidate for canonical-rule promotion.
2. **First-time-this-week** — what new pattern emerged?
3. **Top N** — the recurring classes need a closer look at promotion
   readiness.
4. **Long-tail** — scan for surprising one-offs that might be sleeper hits.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
